export const stripeConfig = {
  PUBLISHABLE_KEY: process.env.STRIPE_PUBLISHABLE_KEY,
  SECRET_KEY: process.env.STRIPE_SECRET_KEY,
  WEBHOOK_SECRET: process.env.STRIPE_WEBHOOK_SECRET,
  STRIPE_WEBHOOK_SECRET_CONNECT: process.env.STRIPE_CONNECT_WEBHOOK_SECRET,
  CONNECT_CLIENT_ID: process.env.STRIPE_CONNECT_CLIENT_ID,
  ENVIRONMENT: process.env.NODE_ENV || 'development',
  IS_LIVE: process.env.NODE_ENV === 'production',
  STRIPE_API_VERSION:
    process.env.NODE_ENV === 'production'
      ? '2026-03-25.dahlia'
      : '2025-07-30.basil',
  ONBOARDING: {
    REFRESH_URL: process.env.STRIPE_REFRESH_URL || 'http://localhost:3000/stripe/connect/refresh',
    RETURN_URL: process.env.STRIPE_RETURN_URL || 'http://localhost:3000/stripe/connect/return',
  },
  PLATFORM_FEE_PERCENTAGE: parseFloat(process.env.STRIPE_PLATFORM_FEE_PERCENTAGE || '2.9'),
  PLATFORM_FEE_FIXED: parseInt(process.env.STRIPE_PLATFORM_FEE_FIXED || '30'),
  PAYOUT_SCHEDULE: process.env.STRIPE_PAYOUT_SCHEDULE || 'manual',
  PAYOUT_DELAY_DAYS: parseInt(process.env.STRIPE_PAYOUT_DELAY_DAYS || '7'),
  DEFAULT_CURRENCY: process.env.STRIPE_DEFAULT_CURRENCY || 'usd',
  SUPPORTED_CURRENCIES: ['usd', 'eur', 'gbp', 'cad', 'aud'],
} as const;

export enum StripeAccountType {
  EXPRESS = 'express',
  STANDARD = 'standard',
  CUSTOM = 'custom',
}

export enum StripeAccountStatus {
  PENDING = 'pending',
  ACTIVE = 'active',
  RESTRICTED = 'restricted',
  DISABLED = 'disabled',
}

export enum StripeCapability {
  CARD_PAYMENTS = 'card_payments',
  TRANSFERS = 'transfers',
  TAX_REPORTING_US_1099_K = 'tax_reporting_us_1099_k',
  CARD_ISSUING = 'card_issuing',
}

export enum StripeRequirement {
  CURRENTLY_DUE = 'currently_due',
  EVENTUALLY_DUE = 'eventually_due',
  PAST_DUE = 'past_due',
  PENDING_VERIFICATION = 'pending_verification',
}
