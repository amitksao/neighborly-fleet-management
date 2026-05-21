// Stripe onboarding is handled by features/auth/stripe_onboarding_screen.dart
// and routed via '/fleet/stripe-onboarding' in app.dart.
//
// To trigger onboarding from a screen:
//   1. Dispatch FleetStripeOnboardingRequested(fleetId) to FleetRegistrationBloc.
//   2. Listen for FleetRegistrationStripeUrl and navigate:
//
//      if (state is FleetRegistrationStripeUrl) {
//        Navigator.of(context).pushNamed(
//          '/fleet/stripe-onboarding',
//          arguments: state.onboardingUrl,
//        );
//      }
