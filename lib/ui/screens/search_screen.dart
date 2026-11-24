import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../widgets/song_tile.dart';

/// Instant Search and Filter Screen for local Dynamics library
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      backgroundColor: DynamicsTheme.nearBlack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search',
                    style: TextStyle(
                      color: DynamicsTheme.textBase,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pill Search Input Container
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: DynamicsTheme.midDark,
                      borderRadius: DynamicsTheme.radiusPill,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: DynamicsTheme.textMuted,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: DynamicsTheme.textBase,
                              fontSize: 14,
                            ),
                            cursorColor: DynamicsTheme.spotifyGreen,
                            decoration: const InputDecoration(
                              hintText: 'What do you want to listen to?',
                              hintStyle: TextStyle(
                                color: DynamicsTheme.textMuted,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) => library.setSearchQuery(val),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              library.setSearchQuery('');
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: DynamicsTheme.textMuted,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Results or Prompt
            Expanded(
              child: library.searchQuery.isEmpty
                  ? _buildInitialSearchPrompt()
                  : library.songs.isEmpty
                      ? _buildNoResults()
                      : ListView.builder(
                          itemCount: library.songs.length,
                          itemBuilder: (context, index) {
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
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialSearchPrompt() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 56,
            color: DynamicsTheme.borderGray,
          ),
          SizedBox(height: 14),
          Text(
            'Search Your Library',
            style: TextStyle(
              color: DynamicsTheme.textBase,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Find songs by title, artist, or album',
            style: TextStyle(
              color: DynamicsTheme.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: DynamicsTheme.textMuted,
          ),
          SizedBox(height: 14),
          Text(
            'No matching tracks found',
            style: TextStyle(
              color: DynamicsTheme.textBase,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try searching with a different term',
            style: TextStyle(
              color: DynamicsTheme.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
