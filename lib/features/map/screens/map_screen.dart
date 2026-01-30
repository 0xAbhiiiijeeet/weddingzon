import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/map_provider.dart';
import '../../feed/screens/user_profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().initLocation();
    });
  }

  Future<void> _handleRetry() async {
    final provider = context.read<MapProvider>();

    if (provider.isPermissionDeniedForever) {
      await Geolocator.openAppSettings();
    } else {
      await provider.initLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Consumer<MapProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentLocation == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(provider.error!, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleRetry,
                    icon: Icon(
                      provider.isPermissionDeniedForever
                          ? Icons.settings
                          : Icons.refresh,
                    ),
                    label: Text(
                      provider.isPermissionDeniedForever
                          ? 'Open Settings'
                          : 'Retry',
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.currentLocation == null) {
            return const Center(child: Text('Waiting for location...'));
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: provider.currentLocation!,
                  initialZoom: 13.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.weddingzon.app',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: provider.currentLocation!,
                        radius: provider.radius * 1000.0,
                        useRadiusInMeter: true,
                        color: Colors.blue.withOpacity(0.1),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 1,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: provider.currentLocation!,
                        width: 60,
                        height: 60,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                      ...provider.nearbyUsers.map((user) {
                        return Marker(
                          point: LatLng(
                            user.coordinates[1],
                            user.coordinates[0],
                          ),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileScreen(
                                    username: user.username,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.deepPurple,
                                      width: 2,
                                    ),
                                    image: DecorationImage(
                                      image: user.profilePhoto != null
                                          ? NetworkImage(user.profilePhoto!)
                                          : const AssetImage(
                                                  'assets/icons/default_avatar.png',
                                                )
                                                as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),

                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Autocomplete<Map<String, dynamic>>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.length < 3) {
                              return const Iterable<
                                Map<String, dynamic>
                              >.empty();
                            }
                            return provider.getSuggestions(
                              textEditingValue.text,
                            );
                          },
                          displayStringForOption:
                              (Map<String, dynamic> option) =>
                                  option['display_name'] ?? '',
                          onSelected: (Map<String, dynamic> selection) {
                            if (selection['lat'] != null &&
                                selection['lon'] != null) {
                              provider.moveToLocation(
                                selection['lat'],
                                selection['lon'],
                              );
                              _mapController.move(
                                LatLng(selection['lat'], selection['lon']),
                                13.0,
                              );
                              FocusScope.of(context).unfocus();
                            }
                          },
                          fieldViewBuilder:
                              (
                                BuildContext context,
                                TextEditingController textEditingController,
                                FocusNode focusNode,
                                VoidCallback onFieldSubmitted,
                              ) {
                                return TextField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    hintText: 'Search City or Pincode...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: provider.isLoading
                                        ? const Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              textEditingController.clear();
                                              provider.initLocation();
                                            },
                                          ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                  ),
                                  onSubmitted: (String value) {
                                    if (value.trim().isNotEmpty) {
                                      provider.searchLocation(value).then((
                                        success,
                                      ) {
                                        if (success &&
                                            provider.currentLocation != null) {
                                          _mapController.move(
                                            provider.currentLocation!,
                                            13.0,
                                          );
                                        }
                                      });
                                    }
                                  },
                                );
                              },
                          optionsViewBuilder:
                              (
                                BuildContext context,
                                AutocompleteOnSelected<Map<String, dynamic>>
                                onSelected,
                                Iterable<Map<String, dynamic>> options,
                              ) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width -
                                          64,
                                      constraints: const BoxConstraints(
                                        maxHeight: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                              final Map<String, dynamic>
                                              option = options.elementAt(index);
                                              return ListTile(
                                                title: Text(
                                                  option['display_name'] ?? '',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                leading: const Icon(
                                                  Icons.location_on,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                onTap: () => onSelected(option),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                );
                              },
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 180,
                    right: 20,
                    child: FloatingActionButton(
                      heroTag: 'gps_button',
                      onPressed: () async {
                        await provider.initLocation();
                        if (provider.currentLocation != null) {
                          _mapController.move(provider.currentLocation!, 13.0);
                        }
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),

              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Search Radius',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('${provider.radius} km'),
                          ],
                        ),
                        Slider(
                          value: provider.radius.toDouble(),
                          min: 5,
                          max: 500,
                          divisions: 99,
                          label: '${provider.radius} km',
                          onChanged: (value) {
                            provider.updateRadius(value.toInt());
                          },
                        ),
                        Text(
                          'Found ${provider.nearbyUsers.length} users near you',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
