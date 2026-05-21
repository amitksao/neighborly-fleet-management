export enum NotificationPriority {
  HIGH = 'high',
  NORMAL = 'normal',
  LOW = 'low',
}

export enum NotificationType {
  RIDE_REQUEST = 'ride_request',
  RIDE_ACCEPTED = 'ride_accepted',
  RIDE_REJECTED = 'ride_rejected',
  RIDE_STARTED = 'ride_started',
  RIDE_COMPLETED = 'ride_completed',
  RIDE_CANCELLED = 'ride_cancelled',
  PAYMENT_SUCCESS = 'payment_success',
  PAYMENT_FAILED = 'payment_failed',
  DRIVER_ARRIVED = 'driver_arrived',
  SCHEDULED_RIDE_REMINDER = 'scheduled_ride_reminder',
  GENERAL = 'general',
  FLEET_REGISTRATION = 'fleet_registration',
  FLEET_APPROVED = 'fleet_approved',
  FLEET_REJECTED = 'fleet_rejected',
  FLEET_DRIVER_BGC = 'fleet_driver_bgc',
  FLEET_BGC_PASSED = 'fleet_bgc_passed',
  FLEET_BGC_FAILED = 'fleet_bgc_failed',
  FLEET_RIDE_ASSIGNMENT = 'fleet_ride_assignment',
  FLEET_RIDE_ACCEPTED = 'fleet_ride_accepted',
  FLEET_PAYOUT = 'fleet_payout',
  ACCOUNT_ONBOARDING_COMPLETE = 'account_onboarding_complete',
}

export interface BaseNotificationData {
  title: string;
  body: string;
  type: NotificationType;
  priority?: NotificationPriority;
  data?: Record<string, any>;
  imageUrl?: string;
  sound?: string;
  badge?: number;
}

export interface DeviceNotificationPayload extends BaseNotificationData {
  deviceToken: string;
}

export interface TopicNotificationPayload extends BaseNotificationData {
  topic: string;
}

export interface MultiDeviceNotificationPayload extends BaseNotificationData {
  deviceTokens: string[];
}

export interface NotificationResult {
  success: boolean;
  messageId?: string;
  deviceToken?: string;
  error?: string;
}

export interface BulkNotificationResult {
  successCount: number;
  failureCount: number;
  results: NotificationResult[];
}
