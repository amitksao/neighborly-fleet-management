import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/cubits/auth_cubit.dart';
import '../../core/injection.dart';
import '../../fleet/domain/fleet_manager/fleet_manager_repository.dart';
import '../../fleet/domain/fleet_manager/models/fleet.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Initial screen. Checks stored credentials and routes accordingly:
///   - No token              → /login
///   - Has token, no fleet   → /fleet/register
///   - Fleet pending/rejected → /fleet/pending-approval
///   - Fleet approved        → /fleet/dashboard
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check for password reset token in URL query params (web only)
    if (kIsWeb) {
      final uri = Uri.parse(html.window.location.href);
      final resetToken = uri.queryParameters['reset_token'];
      if (resetToken != null && resetToken.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(
            '/reset-password',
            arguments: resetToken,
          );
        });
        return;
      }
    }
    context.read<AuthCubit>().checkAuth();
  }

  Future<void> _routeFromAuth(AuthAuthenticated state) async {
    final fleetId = state.user.fleetManagerOf;

    if (fleetId == null) {
      Navigator.of(context).pushReplacementNamed('/fleet/register');
      return;
    }

    try {
      final fleet = await getIt<FleetManagerRepository>().getFleet(fleetId);
      if (!mounted) return;

      if (fleet.isApproved) {
        Navigator.of(context)
            .pushReplacementNamed('/fleet/dashboard', arguments: fleet.id);
      } else {
        Navigator.of(context)
            .pushReplacementNamed('/fleet/pending-approval', arguments: fleet);
      }
    } catch (_) {
      // Fleet fetch failed — send to register so they can retry
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/fleet/register');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _routeFromAuth(state);
        } else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_shipping_rounded, size: 72, color: Colors.blue),
              SizedBox(height: 24),
              Text(
                'Neighborly Fleet',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
