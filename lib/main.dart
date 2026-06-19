import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  final service = container.read(superAdminServiceProvider);
  await service.initializeAuth();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);
    final service = ref.watch(superAdminServiceProvider);

    Widget homeWidget;

    if (authStateAsync.hasValue) {
      final session = authStateAsync.value!.session;
      homeWidget = session != null ? const HomeScreen() : const LoginScreen();
    } else {
      // The pure 'supabase' package might not immediately emit an event on the
      // onAuthStateChange stream, so we check the session synchronously to avoid
      // being stuck in a loading state.
      final session = service.client.auth.currentSession;
      homeWidget = session != null ? const HomeScreen() : const LoginScreen();
    }

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SuperAdmin',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: homeWidget,
    );
  }
}
