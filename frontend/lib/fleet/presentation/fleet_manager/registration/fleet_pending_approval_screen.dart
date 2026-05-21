import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../application/blocs/fleet_registration_bloc.dart';
import '../../../domain/fleet_manager/models/fleet.dart';

class FleetPendingApprovalScreen extends StatefulWidget {
  final Fleet fleet;
  const FleetPendingApprovalScreen({super.key, required this.fleet});

  @override
  State<FleetPendingApprovalScreen> createState() =>
      _FleetPendingApprovalScreenState();
}

class _FleetPendingApprovalScreenState
    extends State<FleetPendingApprovalScreen> {
  void _startStripeOnboarding() {
    context
        .read<FleetRegistrationBloc>()
        .add(FleetStripeOnboardingRequested(widget.fleet.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Submitted')),
      body: BlocConsumer<FleetRegistrationBloc, FleetRegistrationState>(
        listener: (context, state) {
          if (state is FleetRegistrationStripeUrl) {
            Navigator.of(context).pushNamed(
              '/fleet/stripe-onboarding',
              arguments: state.onboardingUrl,
            );
          } else if (state is FleetRegistrationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is FleetRegistrationLoading;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    size: 80, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  'Application Under Review',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your fleet "${widget.fleet.companyName}" has been submitted. A Neighborly admin will review it and notify you by email.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                if (!widget.fleet.hasStripeAccount) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'While you wait, set up your payment account so payouts are ready on approval.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _startStripeOnboarding,
                      icon: const Icon(Icons.payment),
                      label: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Set Up Payment Account'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
