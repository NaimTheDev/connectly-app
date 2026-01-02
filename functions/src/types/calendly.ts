/**
 * TypeScript definitions for Calendly webhook events
 * Based on actual webhook payload structure
 */

import {Timestamp} from 'firebase-admin/firestore';

/**
 * Main webhook payload structure (this is the root object sent by Calendly)
 */
export interface CalendlyWebhookPayload {
  cancel_url: string;
  created_at: string;
  email: string;
  event: string; // URI to the scheduled event
  first_name?: string;
  last_name?: string;
  name: string;
  new_invitee?: string | null;
  old_invitee?: string | null;
  questions_and_answers: QuestionAnswer[];
  reschedule_url: string;
  rescheduled: boolean;
  status: string; // "active" or "canceled"
  text_reminder_number?: string | null;
  timezone: string;
  updated_at: string;
  uri: string; // URI to the invitee
  canceled: boolean;
  routing_form_submission?: string | null;
  cancellation?: CalendlyCancellation;
  scheduling_method?: string | null;
  invitee_scheduled_by?: string | null;
  scheduled_event: CalendlyScheduledEvent;
}

export interface CalendlyScheduledEvent {
  uri: string;
  name: string;
  meeting_notes_plain?: string;
  meeting_notes_html?: string;
  status: string;
  start_time: string;
  end_time: string;
  event_type: string;
  location?: CalendlyLocation;
  invitees_counter: CalendlyInviteesCounter;
  created_at: string;
  updated_at: string;
  event_memberships: CalendlyEventMembership[];
  event_guests: CalendlyEventGuest[];
}

export interface CalendlyLocation {
  type: string;
  location?: string;
  status?: string;
  join_url?: string;
  data?: Record<string, any>;
}

export interface CalendlyInviteesCounter {
  total: number;
  active: number;
  limit: number;
}

export interface CalendlyEventMembership {
  user: string;
  user_email?: string;
  user_name?: string;
}

export interface CalendlyEventGuest {
  email: string;
  created_at: string;
  updated_at: string;
}

export interface CalendlyCalendarEvent {
  kind: string;
  external_id: string;
}

export interface QuestionAnswer {
  question: string;
  answer: string;
  position: number;
}







export interface CalendlyCancellation {
  canceled_by: string;
  reason?: string;
  canceler_type: string;
  created_at: string;
}



/**
 * Supported Calendly webhook event types
 */
export enum CalendlyEventType {
  INVITEE_CREATED = 'invitee.created',
  INVITEE_CANCELED = 'invitee.canceled',
  INVITEE_RESCHEDULED = 'invitee.rescheduled',
  INVITEE_PAYMENT_CREATED = 'invitee_payment.created',
  INVITEE_NO_SHOW_CREATED = 'invitee_no_show.created',
  INVITEE_NO_SHOW_DELETED = 'invitee_no_show.deleted',
}

/**
 * Wrapper for webhook events with event type
 */
export interface CalendlyWebhookEvent {
  created_at: string;
  event: string; // The event type (e.g., "invitee.created")
  payload: CalendlyWebhookPayload;
}

/**
 * Mapped data structure for Firestore ScheduledCall document
 */
export interface ScheduledCallData {
  calendlyEventUri: string;
  cancelUrl: string;
  createdAt: Timestamp;
  endTime: string;
  eventType: string;
  inviteeEmail: string;
  inviteeName: string;
  mentorUri: string;
  mentorName: string;
  payment?: string;
  reconfirmation?: string;
  rescheduleUrl: string;
  rescheduled: boolean;
  startTime: string;
  status: string;
  timezone: string;
  joinUrl?: string;
}

export interface CalendlyInviteeTracking {
  utm_campaign?: string;
  utm_source?: string;
  utm_medium?: string;
  utm_content?: string;
  utm_term?: string;
  salesforce_uuid?: string;
}

export interface CalendlyInviteePayment {
  external_id?: string;
  provider?: string;
  amount?: number;
  currency?: string;
  terms?: string;
  successful?: boolean;
}

export interface CalendlyNoShow {
  uri: string;
  created_at: string;
}

export interface CalendlyReconfirmation {
  created_at: string;
  confirmed_at?: string;
}

export interface CalendlyInviteeResource {
  uri: string;
  email: string;
  first_name?: string;
  last_name?: string;
  name: string;
  status: string;
  questions_and_answers: QuestionAnswer[];
  timezone?: string;
  event: string;
  created_at: string;
  updated_at: string;
  tracking?: CalendlyInviteeTracking | null;
  text_reminder_number?: string | null;
  rescheduled?: boolean;
  old_invitee?: string | null;
  new_invitee?: string | null;
  cancel_url?: string | null;
  reschedule_url?: string | null;
  routing_form_submission?: string | null;
  cancellation?: CalendlyCancellation;
  payment?: CalendlyInviteePayment;
  no_show?: CalendlyNoShow;
  reconfirmation?: CalendlyReconfirmation;
  scheduling_method?: string;
  invitee_scheduled_by?: string | null;
}

export interface CalendlyInviteeResponse {
  resource: CalendlyInviteeResource;
}
