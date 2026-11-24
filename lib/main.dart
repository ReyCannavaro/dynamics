import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'services/audio_player_service.dart';
import 'services/storage_service.dart';
import 'ui/screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark navigation bar and status bar for complete Spotify dark immersion
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: DynamicsTheme.darkSurface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize offline storage & background audio services
  await StorageService.instance.init();
  await AudioPlayerService.instance.init();

  runApp(const DynamicsApp());
}

class DynamicsApp extends StatelessWidget {
  const DynamicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: MaterialApp(
        title: 'Dynamics',
        debugShowCheckedModeBanner: false,
        theme: DynamicsTheme.themeData,
        home: const MainScaffold(),
      ),
    );
  }
}
