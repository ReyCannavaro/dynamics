import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../widgets/pill_button.dart';
import '../widgets/song_tile.dart';

/// Primary Home & Library Screen for Dynamics
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      backgroundColor: DynamicsTheme.nearBlack,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar / Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dynamics',
                          style: TextStyle(
                            color: DynamicsTheme.textBase,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        // Loading indicator if importing
                        if (library.isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(DynamicsTheme.spotifyGreen),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick Action Buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          PillButton(
                            label: 'Import Files',
                            icon: Icons.audio_file_rounded,
                            variant: PillButtonVariant.primary,
                            onTap: () => library.importFiles(),
                          ),
                          const SizedBox(width: 10),
                          PillButton(
                            label: 'Import Folder',
                            icon: Icons.folder_open_rounded,
                            variant: PillButtonVariant.dark,
                            onTap: () => library.importFolder(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            context: context,
                            label: 'All Tracks',
                            isSelected: library.sortOption != SortOption.favorites &&
                                library.sortOption != SortOption.mostPlayed,
                            onTap: () => library.setSortOption(SortOption.dateAdded),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context: context,
                            label: 'Favorites',
                            isSelected: library.sortOption == SortOption.favorites,
                            onTap: () => library.setSortOption(SortOption.favorites),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context: context,
                            label: 'Most Played',
                            isSelected: library.sortOption == SortOption.mostPlayed,
                            onTap: () => library.setSortOption(SortOption.mostPlayed),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Count Header
                    if (library.songs.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${library.songs.length} ${library.songs.length == 1 ? 'song' : 'songs'}',
                            style: const TextStyle(
                              color: DynamicsTheme.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          PopupMenuButton<SortOption>(
                            color: DynamicsTheme.darkSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: DynamicsTheme.radiusCard,
                            ),
                            child: const Row(
                              children: [
                                Text('Sort', style: TextStyle(color: DynamicsTheme.textMuted, fontSize: 13)),
                                SizedBox(width: 4),
                                Icon(Icons.sort_rounded, color: DynamicsTheme.textMuted, size: 16),
                              ],
                            ),
                            onSelected: (opt) => library.setSortOption(opt),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: SortOption.title,
                                child: Text('By Title (A-Z)', style: TextStyle(color: DynamicsTheme.textBase, fontSize: 13)),
                              ),
                              const PopupMenuItem(
                                value: SortOption.artist,
                                child: Text('By Artist (A-Z)', style: TextStyle(color: DynamicsTheme.textBase, fontSize: 13)),
                              ),
                              const PopupMenuItem(
                                value: SortOption.mostPlayed,
                                child: Text('By Most Played', style: TextStyle(color: DynamicsTheme.textBase, fontSize: 13)),
                              ),
                              const PopupMenuItem(
                                value: SortOption.dateAdded,
                                child: Text('Recently Added', style: TextStyle(color: DynamicsTheme.textBase, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Track List or Empty State
            if (library.songs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context, library),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = library.songs[index];
                    final isCurrent = player.currentSong?.id == song.id;

                    return SongTile(
                      song: song,
                      isCurrent: isCurrent,
                      isPlaying: player.isPlaying,
                      onTap: () => player.playSong(song, contextQueue: library.songs),
                      onToggleFavorite: () => library.toggleFavorite(song.id),
                      onDelete: () => library.deleteSong(song.id),
                    );
                  },
                  childCount: library.songs.length,
                ),
              ),

            // Bottom padding for mini-player
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: isSelected ? DynamicsTheme.spotifyGreen : DynamicsTheme.midDark,
          borderRadius: DynamicsTheme.radiusFullPill,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : DynamicsTheme.textBase,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, LibraryProvider library) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: DynamicsTheme.darkSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_off_rounded,
                size: 36,
                color: DynamicsTheme.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Library is Empty',
              style: TextStyle(
                color: DynamicsTheme.textBase,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Import your MP3, FLAC, or M4A music files to start listening with offline synced lyrics and zero ads.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DynamicsTheme.textMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            PillButton(
              label: 'Import Music Now',
              icon: Icons.add_rounded,
              variant: PillButtonVariant.primary,
              onTap: () => library.importFiles(),
            ),
          ],
        ),
      ),
    );
  }
}
