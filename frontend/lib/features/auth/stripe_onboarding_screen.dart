import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the Stripe Connect onboarding URL in the external browser.
/// Stripe redirects back to the app (or a return URL) when done.
/// The user taps "I've completed setup" to dismiss and return to the app.
class StripeOnboardingScreen extends StatelessWidget {
  final String onboardingUrl;
  const StripeOnboardingScreen({super.key, required this.onboardingUrl});

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.parse(onboardingUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open onboarding link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Account Setup')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment, size: 72, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Set Up Stripe Payments',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You\'ll be redirected to Stripe to complete your payment account setup. Return here when done.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launch(context),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open Stripe Onboarding'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('I\'ve Completed Setup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
