import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { StripeService } from './stripe.service';
import { StripeConnectAccount } from '../entities/stripe-connect-account.entity';
import { stripeConfig, StripeAccountStatus, StripeAccountType, StripeCapability } from '../../config/stripe';
import { User } from '../../users/entities/user.entity';

@Injectable()
export class StripeConnectService {
  private readonly logger = new Logger(StripeConnectService.name);

  constructor(
    @InjectRepository(StripeConnectAccount)
    private readonly connectAccountRepository: Repository<StripeConnectAccount>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly stripeService: StripeService,
  ) {}

  async createConnectAccount(
    userId: string,
    data: { email: string; country?: string; businessName?: string; accountType?: StripeAccountType; phone?: string },
  ): Promise<{ account: StripeConnectAccount; onboardingUrl: string }> {
    const existing = await this.connectAccountRepository.findOne({ where: { userId } });
    if (existing) {
      throw new BadRequestException('User already has a Stripe Connect account');
    }

    const country = data.country || 'US';
    const accountType = data.accountType || StripeAccountType.EXPRESS;

    const stripeAccount = await this.stripeService.createConnectAccount({
      email: data.email,
      country,
      type: accountType,
      businessName: data.businessName,
    });

    const accountLink = await this.stripeService.createAccountLink(
      stripeAccount.id,
      stripeConfig.ONBOARDING.REFRESH_URL,
      stripeConfig.ONBOARDING.RETURN_URL,
    );

    const account = this.connectAccountRepository.create({
      userId,
      stripeAccountId: stripeAccount.id,
      accountType,
      status: StripeAccountStatus.PENDING,
      capabilities: [StripeCapability.CARD_PAYMENTS, StripeCapability.TRANSFERS],
      email: data.email,
      country,
      businessName: data.businessName,
      onboardingUrl: accountLink.url,
      onboardingUrlExpiresAt: new Date(accountLink.expires_at * 1000),
    });

    await this.connectAccountRepository.save(account);

    return { account, onboardingUrl: accountLink.url };
  }

  async refreshOnboardingUrl(
    userId: string,
  ): Promise<{ onboardingUrl: string }> {
    const account = await this.connectAccountRepository.findOne({ where: { userId } });
    if (!account) throw new NotFoundException('No Stripe Connect account found');

    const accountLink = await this.stripeService.createAccountLink(
      account.stripeAccountId,
      stripeConfig.ONBOARDING.REFRESH_URL,
      stripeConfig.ONBOARDING.RETURN_URL,
    );

    account.onboardingUrl = accountLink.url;
    account.onboardingUrlExpiresAt = new Date(accountLink.expires_at * 1000);
    await this.connectAccountRepository.save(account);

    return { onboardingUrl: accountLink.url };
  }

  async getConnectAccount(userId: string): Promise<StripeConnectAccount | null> {
    return this.connectAccountRepository.findOne({ where: { userId } });
  }

  async handleAccountUpdated(stripeAccountId: string, payoutsEnabled: boolean): Promise<void> {
    const account = await this.connectAccountRepository.findOne({ where: { stripeAccountId } });
    if (!account) {
      this.logger.warn(`No local account found for Stripe account ${stripeAccountId}`);
      return;
    }
    account.payoutsEnabled = payoutsEnabled;
    account.status = payoutsEnabled ? StripeAccountStatus.ACTIVE : StripeAccountStatus.PENDING;
    await this.connectAccountRepository.save(account);
    this.logger.log(`Updated Stripe Connect account ${stripeAccountId}: payoutsEnabled=${payoutsEnabled}`);
  }
}
