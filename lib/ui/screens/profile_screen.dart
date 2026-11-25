import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/player_provider.dart';
import '../../providers/profile_provider.dart';
import '../widgets/pill_button.dart';

/// Personalized Offline User Profile and Dynamics Wrapped Statistics Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, ProfileProvider profileProvider) {
    final nameController = TextEditingController(text: profileProvider.displayName);
    final bioController = TextEditingController(text: profileProvider.bio);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DynamicsTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: DynamicsTheme.radiusCard,
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: DynamicsTheme.textBase,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Display Name',
              style: TextStyle(color: DynamicsTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              style: const TextStyle(color: DynamicsTheme.textBase, fontSize: 14),
              cursorColor: DynamicsTheme.spotifyGreen,
              decoration: InputDecoration(
                filled: true,
                fillColor: DynamicsTheme.midDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: DynamicsTheme.radiusSmall,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Bio / Tagline',
              style: TextStyle(color: DynamicsTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: bioController,
              style: const TextStyle(color: DynamicsTheme.textBase, fontSize: 14),
              cursorColor: DynamicsTheme.spotifyGreen,
              decoration: InputDecoration(
                filled: true,
                fillColor: DynamicsTheme.midDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: DynamicsTheme.radiusSmall,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: DynamicsTheme.textMuted)),
          ),
          PillButton(
            label: 'Save',
            variant: PillButtonVariant.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            onTap: () {
              profileProvider.updateProfile(
                displayName: nameController.text,
                bio: bioController.text,
              );
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final playerProvider = context.watch<PlayerProvider>();

    return Scaffold(
      backgroundColor: DynamicsTheme.nearBlack,
      body: SafeArea(
        child: RefreshIndicator(
          color: DynamicsTheme.spotifyGreen,
          backgroundColor: DynamicsTheme.darkSurface,
          onRefresh: () async => profileProvider.refresh(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            children: [
              // User Header Section
              Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: DynamicsTheme.midDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: DynamicsTheme.spotifyGreen, width: 2.0),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 42,
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
                          profileProvider.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DynamicsTheme.textBase,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profileProvider.bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DynamicsTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        PillButton(
                          label: 'Edit Profile',
                          variant: PillButtonVariant.dark,
                          fontSize: 11,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          onTap: () => _showEditProfileDialog(context, profileProvider),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // "Dynamics Wrapped" Section Header
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: DynamicsTheme.spotifyGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'DYNAMICS WRAPPED',
                    style: TextStyle(
                      color: DynamicsTheme.spotifyGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Statistics Row (Cards)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'LISTENING TIME',
                      value: profileProvider.formattedListeningTime,
                      icon: Icons.timer_outlined,
                      subtitle: 'Local playback duration',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'TOTAL TRACKS',
                      value: '${profileProvider.totalSongs}',
                      icon: Icons.library_music_outlined,
                      subtitle: 'In offline library',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'FAVORITES',
                      value: '${profileProvider.totalFavorites}',
                      icon: Icons.favorite_rounded,
                      subtitle: 'Liked songs',
                      iconColor: DynamicsTheme.spotifyGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'EXPERIENCE',
                      value: '100% Ad-Free',
                      icon: Icons.verified_rounded,
                      subtitle: 'Offline & private',
                      iconColor: DynamicsTheme.spotifyGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Top 5 Most Played Tracks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Top Played Tracks',
                    style: TextStyle(
                      color: DynamicsTheme.textBase,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (profileProvider.topTracks.isNotEmpty)
                    const Text(
                      'Tap to play',
                      style: TextStyle(color: DynamicsTheme.textMuted, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              if (profileProvider.topTracks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: DynamicsTheme.darkSurface,
                    borderRadius: DynamicsTheme.radiusCard,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.insights_rounded, color: DynamicsTheme.textMuted, size: 24),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Play your songs for at least 30 seconds to unlock your Top Played Tracks ranking!',
                          style: TextStyle(color: DynamicsTheme.textMuted, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(profileProvider.topTracks.length, (index) {
                  final song = profileProvider.topTracks[index];
                  final isCurrent = playerProvider.currentSong?.id == song.id;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => playerProvider.playSong(song, contextQueue: profileProvider.topTracks),
                      borderRadius: DynamicsTheme.radiusCard,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '#${index + 1}',
                                style: const TextStyle(
                                  color: DynamicsTheme.spotifyGreen,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
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
                                    style: TextStyle(
                                      color: isCurrent ? DynamicsTheme.spotifyGreen : DynamicsTheme.textBase,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: DynamicsTheme.midDark,
                                borderRadius: DynamicsTheme.radiusBadge,
                              ),
                              child: Text(
                                '${song.playCount} ${song.playCount == 1 ? 'play' : 'plays'}',
                                style: const TextStyle(
                                  color: DynamicsTheme.spotifyGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 32),

              // Offline Privacy & Security Badge
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: DynamicsTheme.darkSurface,
                  borderRadius: DynamicsTheme.radiusCard,
                  border: Border.all(color: DynamicsTheme.borderGray, width: 0.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: DynamicsTheme.spotifyGreen, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline & Private By Design',
                            style: TextStyle(
                              color: DynamicsTheme.textBase,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Zero analytics, zero tracking, and zero ads. All your listening statistics remain safely on your device.',
                            style: TextStyle(color: DynamicsTheme.textMuted, fontSize: 11, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80), // Padding for MiniPlayer
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
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
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Icon(icon, size: 16, color: iconColor ?? DynamicsTheme.textMuted),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DynamicsTheme.textBase,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: DynamicsTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
