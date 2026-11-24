import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/storage_service.dart';

/// Personalized Offline User Profile and Listening Statistics Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    final profile = storage.isInitialized ? storage.getUserProfile() : null;
    final totalSongs = storage.isInitialized ? storage.totalSongsCount : 0;
    final topTracks = storage.isInitialized ? storage.getTopPlayedSongs(limit: 5) : [];

    return Scaffold(
      backgroundColor: DynamicsTheme.nearBlack,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            // User Header
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: DynamicsTheme.midDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: DynamicsTheme.spotifyGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? 'Rey Cannavaro',
                        style: const TextStyle(
                          color: DynamicsTheme.textBase,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?.bio ?? 'Living in Dynamics 🎧',
                        style: const TextStyle(
                          color: DynamicsTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Statistics Row (Cards)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'LISTENING TIME',
                    value: profile?.formattedListeningTime ?? '0 secs',
                    icon: Icons.timer_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'TOTAL TRACKS',
                    value: '$totalSongs',
                    icon: Icons.library_music_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Top Played Tracks Section
            const Text(
              'Top Played Tracks',
              style: TextStyle(
                color: DynamicsTheme.textBase,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            if (topTracks.isEmpty)
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: DynamicsTheme.darkSurface,
                  borderRadius: DynamicsTheme.radiusCard,
                ),
                child: const Text(
                  'Listen to songs for at least 30 seconds to see your top played tracks here.',
                  style: TextStyle(color: DynamicsTheme.textMuted, fontSize: 13),
                ),
              )
            else
              ...List.generate(topTracks.length, (index) {
                final song = topTracks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                            color: DynamicsTheme.spotifyGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: DynamicsTheme.textBase, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: DynamicsTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: DynamicsTheme.midDark,
                          borderRadius: DynamicsTheme.radiusBadge,
                        ),
                        child: Text(
                          '${song.playCount} plays',
                          style: const TextStyle(color: DynamicsTheme.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: DynamicsTheme.darkSurface,
        borderRadius: DynamicsTheme.radiusCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: DynamicsTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Icon(icon, size: 16, color: DynamicsTheme.textMuted),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: DynamicsTheme.textBase,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
