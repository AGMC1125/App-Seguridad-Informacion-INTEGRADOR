import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/session_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/privacy_policy_screen.dart';
import '../../features/auth/presentation/screens/terms_and_conditions_screen.dart';
import '../../features/auth/presentation/widgets/session_guard.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/generator/presentation/screens/generator_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/dictionary/presentation/family_screen.dart';
import '../../features/dictionary/presentation/word_detail_screen.dart';
import '../../screens/security_check_screen.dart';
import 'route_names.dart';

// ── RouterNotifier ─────────────────────────────────────────────────────────────

/// Puente entre Riverpod y GoRouter.
///
/// GoRouter necesita un [Listenable] para saber cuándo re-evaluar el [redirect].
/// Esta clase escucha [sessionNotifierProvider] y llama [notifyListeners] cada
/// vez que el estado de sesión cambia (login, logout, wipe remoto), lo que
/// hace que GoRouter vuelva a correr el redirect automáticamente.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen<SessionState>(
      sessionNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }
}

// ── AppRouter Provider ─────────────────────────────────────────────────────────

/// Provider que expone la instancia configurada de [GoRouter].
///
/// Al ser un [Provider] de Riverpod, el router puede leer el estado de sesión
/// directamente via [ref.read] dentro del callback [redirect], manteniendo
/// la fuente de verdad en un solo lugar.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    debugLogDiagnostics: false,

    /// El router re-evalúa [redirect] cada vez que [RouterNotifier] notifica
    /// un cambio — es decir, cada vez que [SessionState] muta.
    refreshListenable: notifier,

    /// Punto de entrada inicial: el redirect decide qué mostrar.
    initialLocation: RouteNames.login,

    // ── Redirect centralizado — guard de autenticación ───────────────────────
    //
    // Este callback es la única fuente de verdad para la protección de rutas.
    // Se ejecuta ANTES de renderizar cualquier pantalla, incluyendo deep links.
    //
    // Reglas:
    //   1. Usuario no autenticado en ruta protegida  → /login
    //   2. Usuario autenticado en ruta pública       → /home
    //   3. Cualquier otro caso                       → null (continuar)
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = ref.read(sessionNotifierProvider).isLoggedIn;
      final location  = state.matchedLocation;

      final isPublicRoute =
          location == RouteNames.login   ||
          location == RouteNames.register ||
          location == RouteNames.privacy  ||
          location == RouteNames.terms;

      // Regla 1: no autenticado, ruta protegida → login
      if (!isLoggedIn && !isPublicRoute) return RouteNames.login;

      // Regla 2: autenticado, ruta pública → home
      if (isLoggedIn && isPublicRoute) return RouteNames.home;

      // Regla 3: todo OK
      return null;
    },

    routes: [
      // ── Rutas públicas ──────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const SecurityCheckScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.privacy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: RouteNames.terms,
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),

      // ── Rutas protegidas (dentro del ShellRoute) ───────────────────────────
      //
      // ShellRoute envuelve TODAS las rutas autenticadas con [SessionGuard].
      // Esto garantiza que:
      //   - El ActivityDetector registra interacción en cualquier pantalla.
      //   - Los snackbars de advertencia/wipe se muestran en toda la app.
      //   - No se duplica este código en cada pantalla individual.
      ShellRoute(
        builder: (context, state, child) => SessionGuard(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RouteNames.generator,
            builder: (context, state) => const GeneratorScreen(),
          ),
          GoRoute(
            path: RouteNames.history,
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: RouteNames.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: RouteNames.family,
            builder: (context, state) => const FamilyScreen(),
            routes: [
              // /family/word/:word — parámetro de path para la palabra
              GoRoute(
                path: RouteNames.wordDetail,
                builder: (context, state) => WordDetailScreen(
                  word: state.pathParameters['word']!,
                  // El avatar seleccionado se pasa como extra para mantener
                  // el path limpio sin query params
                  initialAvatarCode: state.extra as String? ?? 'nino',
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
