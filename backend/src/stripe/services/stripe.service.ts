import { Injectable, Logger } from '@nestjs/common';
import Stripe from 'stripe';
import { env } from '../../config/env';

@Injectable()
export class StripeService {
  private readonly logger = new Logger(StripeService.name);
  private stripe: Stripe;

  constructor() {
    this.stripe = new Stripe(env.STRIPE.SECRET_KEY || '', {
      apiVersion: '2025-06-30.basil' as any,
    });
  }

  getStripe(): Stripe {
    return this.stripe;
  }

  async createConnectAccount(data: {
    email: string;
    country: string;
    type: string;
    businessName?: string;
  }): Promise<Stripe.Account> {
    return this.stripe.accounts.create({
      type: data.type as any,
      email: data.email,
      country: data.country,
      business_profile: data.businessName ? { name: data.businessName } : undefined,
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
    });
  }

  async createAccountLink(accountId: string, refreshUrl: string, returnUrl: string): Promise<Stripe.AccountLink> {
    return this.stripe.accountLinks.create({
      account: accountId,
      refresh_url: refreshUrl,
      return_url: returnUrl,
      type: 'account_onboarding',
    });
  }

  async retrieveAccount(accountId: string): Promise<Stripe.Account> {
    return this.stripe.accounts.retrieve(accountId);
  }

  async createTransfer(params: {
    amount: number;
    currency: string;
    destination: string;
    transferGroup?: string;
    metadata?: Record<string, string>;
  }): Promise<Stripe.Transfer> {
    return this.stripe.transfers.create({
      amount: params.amount,
      currency: params.currency,
      destination: params.destination,
      transfer_group: params.transferGroup,
      metadata: params.metadata,
    });
  }

  async createPaymentIntent(params: {
    amount: number;
    currency: string;
    customerId?: string;
    applicationFeeAmount?: number;
    transferData?: { destination: string };
    metadata?: Record<string, string>;
  }): Promise<Stripe.PaymentIntent> {
    return this.stripe.paymentIntents.create({
      amount: params.amount,
      currency: params.currency,
      customer: params.customerId,
      application_fee_amount: params.applicationFeeAmount,
      transfer_data: params.transferData,
      metadata: params.metadata,
      automatic_payment_methods: { enabled: true },
    });
  }

  constructWebhookEvent(payload: Buffer, signature: string, secret: string): Stripe.Event {
    return this.stripe.webhooks.constructEvent(payload, signature, secret);
  }
}
