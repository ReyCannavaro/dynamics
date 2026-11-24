import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/player_provider.dart';
import '../widgets/mini_player.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

/// Main navigation scaffold holding BottomNavigationBar and floating MiniPlayer
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final currentSong = player.currentSong;

    return Scaffold(
      backgroundColor: DynamicsTheme.nearBlack,
      body: Stack(
        children: [
          // Screen View Stack
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating Mini Player docked above BottomNavigationBar
          if (currentSong != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(
                song: currentSong,
                isPlaying: player.isPlaying,
                progress: player.progress,
                onTap: () {
                  // Full player modal / screen will be wired in Stage 5
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Now Playing: ${currentSong.title}'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: DynamicsTheme.darkSurface,
                    ),
                  );
                },
                onPlayPause: () => player.togglePlayPause(),
                onToggleFavorite: () => player.toggleFavorite(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: DynamicsTheme.darkCard, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: DynamicsTheme.darkSurface,
          selectedItemColor: DynamicsTheme.textBase,
          unselectedItemColor: DynamicsTheme.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_filled),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
