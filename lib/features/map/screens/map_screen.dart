import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../../feed/screens/user_profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().initLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.initLocation(),
                    child: const Text('Retry'),
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
                  // Radius Circle
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: provider.currentLocation!,
                        radius:
                            provider.radius *
                            1000.0, // Convert km to meters? No, CircleLayer uses radius in logical pixels usually or radius in meters if useRadiusInMeter is true.
                        // Since flutter_map 6+, CircleMarker radius is screens points unless useRadiusInMeter is true
                        useRadiusInMeter: true,
                        color: Colors.blue.withOpacity(0.1),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 1,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Current User Marker
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
                      // Nearby Users Markers
                      ...provider.nearbyUsers.map((user) {
                        return Marker(
                          point: LatLng(
                            user.coordinates[1],
                            user.coordinates[0],
                          ), // [lng, lat] from mongo
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
                ],
              ),

              // Radius Control and Info
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
                            // Optionally animate map to bounds if needed
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
