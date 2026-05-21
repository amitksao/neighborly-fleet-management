import { Injectable, Logger } from '@nestjs/common';
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';
import { env } from '../../config/env';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private ses: SESClient;

  constructor() {
    this.ses = new SESClient({
      region: env.AWS.REGION,
      credentials:
        env.AWS.ACCESS_KEY_ID && env.AWS.SECRET_ACCESS_KEY
          ? {
              accessKeyId: env.AWS.ACCESS_KEY_ID,
              secretAccessKey: env.AWS.SECRET_ACCESS_KEY,
            }
          : undefined,
    });
  }

  async sendEmail(to: string, subject: string, html: string): Promise<void> {
    const from = env.AWS.SES.FROM_EMAIL;
    if (!from) {
      this.logger.warn('SES FROM_EMAIL not configured — skipping email');
      return;
    }
    try {
      await this.ses.send(
        new SendEmailCommand({
          Source: from,
          Destination: { ToAddresses: [to] },
          Message: {
            Subject: { Data: subject },
            Body: { Html: { Data: html } },
          },
          ReplyToAddresses: env.AWS.SES.REPLY_TO_EMAIL ? [env.AWS.SES.REPLY_TO_EMAIL] : undefined,
        }),
      );
      this.logger.log(`Email sent to ${to}: ${subject}`);
    } catch (error) {
      this.logger.error(`Email send failed to ${to}:`, error);
    }
  }

  async sendFleetApprovalEmail(to: string, companyName: string): Promise<void> {
    await this.sendEmail(
      to,
      'Your Fleet Has Been Approved — Neighborly',
      `<h2>Congratulations, ${companyName}!</h2>
       <p>Your fleet has been approved on Neighborly. You can now start managing rides.</p>`,
    );
  }

  async sendFleetRejectionEmail(to: string, companyName: string, reason: string): Promise<void> {
    await this.sendEmail(
      to,
      'Fleet Application Update — Neighborly',
      `<h2>Hi ${companyName},</h2>
       <p>Unfortunately your fleet application was not approved at this time.</p>
       <p><strong>Reason:</strong> ${reason}</p>
       <p>Please contact support if you have questions.</p>`,
    );
  }

  async sendDriverInviteEmail(to: string, fleetName: string, inviteToken: string): Promise<void> {
    const link = `${env.APP_BASE_URL}/fleet/driver/accept-invite?token=${inviteToken}`;
    await this.sendEmail(
      to,
      `You've been invited to join ${fleetName} on Neighborly`,
      `<h2>Driver Invitation</h2>
       <p>You have been invited to join <strong>${fleetName}</strong> as a driver.</p>
       <p><a href="${link}">Accept Invitation</a></p>
       <p>This link expires in 7 days.</p>`,
    );
  }

  async sendPayoutEmail(
    to: string,
    driverName: string,
    amount: number,
    currency: string,
  ): Promise<void> {
    await this.sendEmail(
      to,
      'Payout Sent — Neighborly Fleet',
      `<h2>Hi ${driverName},</h2>
       <p>A payout of <strong>${(amount / 100).toFixed(2)} ${currency.toUpperCase()}</strong> has been sent to your account.</p>`,
    );
  }
}
