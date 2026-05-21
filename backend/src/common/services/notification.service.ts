import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { env } from '../../config/env';
import {
  DeviceNotificationPayload,
  MultiDeviceNotificationPayload,
  TopicNotificationPayload,
  NotificationResult,
  BulkNotificationResult,
} from '../interfaces/notification.interface';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);
  private initialized = false;

  constructor() {
    this.initFirebase();
  }

  private initFirebase() {
    if (admin.apps.length > 0) {
      this.initialized = true;
      return;
    }
    const projectId = env.FIREBASE.PROJECT_ID;
    const clientEmail = env.FIREBASE.CLIENT_EMAIL;
    const privateKey = env.FIREBASE.PRIVATE_KEY?.replace(/\\n/g, '\n');

    if (!projectId || !clientEmail || !privateKey) {
      this.logger.warn('Firebase credentials not configured — push notifications disabled');
      return;
    }

    try {
      admin.initializeApp({
        credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
      });
      this.initialized = true;
      this.logger.log('Firebase Admin initialized');
    } catch (error) {
      this.logger.error('Firebase init failed:', error);
    }
  }

  async sendToDevice(payload: DeviceNotificationPayload): Promise<NotificationResult> {
    if (!this.initialized || !payload.deviceToken) {
      return { success: false, error: 'Firebase not initialized or no device token' };
    }
    try {
      const messageId = await admin.messaging().send({
        token: payload.deviceToken,
        notification: { title: payload.title, body: payload.body },
        data: payload.data
          ? Object.fromEntries(
              Object.entries(payload.data).map(([k, v]) => [k, String(v)]),
            )
          : undefined,
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      return { success: true, messageId, deviceToken: payload.deviceToken };
    } catch (error) {
      this.logger.error(`Push send failed for token ${payload.deviceToken}:`, error);
      return { success: false, error: error.message, deviceToken: payload.deviceToken };
    }
  }

  async sendToMultipleDevices(payload: MultiDeviceNotificationPayload): Promise<BulkNotificationResult> {
    if (!this.initialized || !payload.deviceTokens?.length) {
      return { successCount: 0, failureCount: payload.deviceTokens?.length ?? 0, results: [] };
    }
    const results = await Promise.all(
      payload.deviceTokens.map((token) => this.sendToDevice({ ...payload, deviceToken: token })),
    );
    return {
      successCount: results.filter((r) => r.success).length,
      failureCount: results.filter((r) => !r.success).length,
      results,
    };
  }

  async sendToTopic(payload: TopicNotificationPayload): Promise<NotificationResult> {
    if (!this.initialized) {
      return { success: false, error: 'Firebase not initialized' };
    }
    try {
      const messageId = await admin.messaging().send({
        topic: payload.topic,
        notification: { title: payload.title, body: payload.body },
        data: payload.data
          ? Object.fromEntries(
              Object.entries(payload.data).map(([k, v]) => [k, String(v)]),
            )
          : undefined,
      });
      return { success: true, messageId };
    } catch (error) {
      this.logger.error(`Topic send failed for topic ${payload.topic}:`, error);
      return { success: false, error: error.message };
    }
  }

  async subscribeToTopic(deviceToken: string, topic: string): Promise<boolean> {
    if (!this.initialized) return false;
    try {
      await admin.messaging().subscribeToTopic(deviceToken, topic);
      return true;
    } catch {
      return false;
    }
  }

  async unsubscribeFromTopic(deviceToken: string, topic: string): Promise<boolean> {
    if (!this.initialized) return false;
    try {
      await admin.messaging().unsubscribeFromTopic(deviceToken, topic);
      return true;
    } catch {
      return false;
    }
  }

  async notifyUser(
    deviceToken: string | undefined,
    payload: Omit<DeviceNotificationPayload, 'deviceToken'>,
  ): Promise<NotificationResult> {
    if (!deviceToken) return { success: false, error: 'No device token' };
    return this.sendToDevice({ ...payload, deviceToken });
  }
}
