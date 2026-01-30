import 'package:flutter/material.dart';

class UserCardWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const UserCardWidget({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String username = user['username'] ?? 'Unknown';
    final String profilePhoto = user['profilePhoto'] ?? '';
    final String firstName = user['first_name'] ?? user['firstName'] ?? '';
    final String lastName = user['last_name'] ?? user['lastName'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String displayName = fullName.isNotEmpty ? fullName : username;
    final String aboutMe = user['about_me'] ?? user['aboutMe'] ?? '';
    final int age = user['age'] ?? 0;
    final String city = user['city'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: profilePhoto.isNotEmpty
                    ? NetworkImage(profilePhoto)
                    : null,
                child: profilePhoto.isEmpty
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (age > 0 || city.isNotEmpty)
                      Row(
                        children: [
                          if (age > 0) ...[
                            const Icon(
                              Icons.cake,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$age years',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          if (age > 0 && city.isNotEmpty)
                            const Text(
                              ' • ',
                              style: TextStyle(color: Colors.grey),
                            ),
                          if (city.isNotEmpty) ...[
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                city,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (aboutMe.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        aboutMe,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}