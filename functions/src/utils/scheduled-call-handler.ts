/**
 * Scheduled call handler utility for managing Firestore operations
 */

import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';
import {Timestamp} from 'firebase-admin/firestore';
import {CalendlyWebhookEvent, CalendlyWebhookPayload, CalendlyEventType, ScheduledCallData} from '../types/calendly';
import {extractMentorUri, findUserById} from './user-lookup';

/**
 * Maps Calendly webhook data to ScheduledCall Firestore document format
 * @param webhookPayload - The Calendly webhook payload
 * @param eventType - The webhook event type
 * @param mentorId - Optional mentor user ID to fetch mentor name
 * @returns The mapped ScheduledCallData object
 */
export async function mapCalendlyToScheduledCall(webhookPayload: CalendlyWebhookPayload, eventType: string, mentorId?: string): Promise<ScheduledCallData> {
  logger.info('🔄 Starting mapCalendlyToScheduledCall', {
    eventType,
    hasScheduledEvent: !!webhookPayload.scheduled_event,
    payloadKeys: Object.keys(webhookPayload),
    mentorId
  });

  try {
    const {scheduled_event} = webhookPayload;

    if (!scheduled_event) {
      logger.error('❌ Missing scheduled_event in webhook payload');
      throw new Error('Missing scheduled_event in webhook payload');
    }

    logger.info('📊 Extracting data from webhook payload', {
      calendlyEventUri: scheduled_event.uri,
      eventType: scheduled_event.event_type,
      startTime: scheduled_event.start_time,
      endTime: scheduled_event.end_time,
      inviteeEmail: webhookPayload.email,
      inviteeName: webhookPayload.name
    });

    // Fetch mentor name if mentorId is provided
    let mentorName = '';
    if (mentorId && mentorId.trim() !== '') {
      const mentorData = await findUserById(mentorId);
      mentorName = mentorData?.name || mentorData?.displayName || '';
      logger.info('📝 Fetched mentor name', {
        mentorId,
        mentorName,
        hasMentorData: !!mentorData
      });
    }

    const mappedData = {
      calendlyEventUri: scheduled_event.uri,
      cancelUrl: webhookPayload.cancel_url,
      createdAt: Timestamp.fromDate(new Date(webhookPayload.created_at)),
      endTime: scheduled_event.end_time,
      eventType: scheduled_event.event_type,
      inviteeEmail: webhookPayload.email,
      inviteeName: webhookPayload.name,
      mentorUri: extractMentorUri(scheduled_event.event_memberships),
      mentorName,
      rescheduleUrl: webhookPayload.reschedule_url,
      rescheduled: webhookPayload.rescheduled,
      startTime: scheduled_event.start_time,
      status: determineCallStatus(eventType, webhookPayload.status),
      timezone: webhookPayload.timezone,
      joinUrl: scheduled_event.location?.join_url || undefined,
    };

    logger.info('✅ Successfully mapped Calendly data', {
      mappedDataKeys: Object.keys(mappedData),
      status: mappedData.status,
      mentorUri: mappedData.mentorUri,
      mentorName: mappedData.mentorName
    });

    return mappedData;
  } catch (error) {
    logger.error('❌ Error in mapCalendlyToScheduledCall:', error);
    throw error;
  }
}

/**
 * Determines the call status based on the webhook event type and payload status
 * @param eventType - The Calendly event type
 * @param payloadStatus - The status from the payload
 * @returns The normalized status string
 */
function determineCallStatus(eventType: string, payloadStatus: string): string {
  switch (eventType) {
    case CalendlyEventType.INVITEE_CREATED:
      return 'active';
    case CalendlyEventType.INVITEE_CANCELED:
      return 'canceled';
    case CalendlyEventType.INVITEE_RESCHEDULED:
      return 'rescheduled';
    default:
      return payloadStatus || 'active';
  }
}

/**
 * Creates a new scheduled call document in Firestore
 * @param userId - The Firebase user ID
 * @param scheduledCallData - The scheduled call data
 * @returns The document ID of the created call
 */
export async function createScheduledCall(
  userId: string,
  scheduledCallData: ScheduledCallData
): Promise<string> {
  logger.info('🔄 Starting createScheduledCall', {
    userId,
    dataKeys: Object.keys(scheduledCallData),
    calendlyEventUri: scheduledCallData.calendlyEventUri
  });

  try {
    const firestore = admin.firestore();
    
    logger.info('📝 Attempting to write to Firestore', {
      collection: `users/${userId}/scheduled_calls`,
      dataToWrite: {
        calendlyEventUri: scheduledCallData.calendlyEventUri,
        eventType: scheduledCallData.eventType,
        status: scheduledCallData.status,
        inviteeEmail: scheduledCallData.inviteeEmail,
        inviteeName: scheduledCallData.inviteeName
      }
    });
    
    // Create document in users/{userId}/scheduled_calls collection
    const docRef = await firestore
      .collection('users')
      .doc(userId)
      .collection('scheduled_calls')
      .add(scheduledCallData);

    logger.info('✅ Successfully created scheduled call document', {
      documentId: docRef.id,
      userId,
      path: `users/${userId}/scheduled_calls/${docRef.id}`
    });
    
    return docRef.id;
  } catch (error) {
    logger.error('❌ Error creating scheduled call', {
      userId,
      error: error instanceof Error ? error.message : String(error),
      errorStack: error instanceof Error ? error.stack : undefined,
      scheduledCallData: {
        calendlyEventUri: scheduledCallData.calendlyEventUri,
        eventType: scheduledCallData.eventType,
        status: scheduledCallData.status
      }
    });
    throw error;
  }
}

/**
 * Updates an existing scheduled call document
 * @param userId - The Firebase user ID
 * @param calendlyEventUri - The Calendly event URI to find the document
 * @param updateData - The data to update
 * @returns boolean indicating success
 */
export async function updateScheduledCall(
  userId: string,
  calendlyEventUri: string,
  updateData: Partial<ScheduledCallData>
): Promise<boolean> {
  try {
    const firestore = admin.firestore();
    
    // Find the document by calendlyEventUri
    const querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('scheduled_calls')
      .where('calendlyEventUri', '==', calendlyEventUri)
      .limit(1)
      .get();

    if (querySnapshot.empty) {
      logger.warn(`No scheduled call found for user ${userId} with event URI: ${calendlyEventUri}`);
      return false;
    }

    const docRef = querySnapshot.docs[0].ref;
    await docRef.update({
      ...updateData,
      updatedAt: Timestamp.now(),
    });

    logger.info(`Updated scheduled call document: ${docRef.id} for user: ${userId}`);
    return true;
  } catch (error) {
    logger.error(`Error updating scheduled call for user ${userId}:`, error);
    return false;
  }
}

/**
 * Handles invitee.created events by creating a new scheduled call
 * @param userId - The Firebase user ID
 * @param webhookPayload - The Calendly webhook payload
 * @param eventType - The webhook event type
 * @returns The document ID of the created call
 */
export async function handleInviteeCreated(
  userId: string,
  mentorId: string,
  webhookPayload: CalendlyWebhookPayload,
  eventType: string
): Promise<string> {
  logger.info('🚀 Starting handleInviteeCreated', {
    userId,
    eventType,
    payloadPreview: {
      email: webhookPayload.email,
      name: webhookPayload.name,
      created_at: webhookPayload.created_at,
      hasScheduledEvent: !!webhookPayload.scheduled_event,
      scheduledEventUri: webhookPayload.scheduled_event?.uri
    }
  });

  // Log the complete webhook payload for debugging
  logger.info('📄 Complete webhook payload received:', {
    fullPayload: JSON.stringify(webhookPayload, null, 2)
  });

  try {
    logger.info('🔧 Step 1: Mapping Calendly data to ScheduledCall format');
    const scheduledCallData = await mapCalendlyToScheduledCall(webhookPayload, eventType, mentorId);
    
    logger.info('🔧 Step 2: Creating scheduled call in Firestore for both user and mentor');
    
    // Create scheduled call document for the user (invitee)
    const userDocumentId = await createScheduledCall(userId, scheduledCallData);
    logger.info('✅ Created scheduled call for user', {
      userId,
      documentId: userDocumentId
    });
    
    // Create scheduled call document for the mentor (only if mentorId is provided)
    let mentorDocumentId: string | undefined;
    if (mentorId && mentorId.trim() !== '') {
      mentorDocumentId = await createScheduledCall(mentorId, scheduledCallData);
      logger.info('✅ Created scheduled call for mentor', {
        mentorId,
        documentId: mentorDocumentId
      });
    } else {
      logger.warn('⚠️ MentorId is empty, skipping mentor scheduled call creation');
    }
    
    logger.info('✅ Successfully completed handleInviteeCreated', {
      userId,
      mentorId: mentorId || 'none',
      userDocumentId,
      mentorDocumentId: mentorDocumentId || 'skipped',
      eventType
    });
    
    return userDocumentId;
  } catch (error) {
    logger.error('❌ Error in handleInviteeCreated:', {
      userId,
      eventType,
      error: error instanceof Error ? error.message : String(error),
      errorStack: error instanceof Error ? error.stack : undefined
    });
    throw error;
  }
}

/**
 * Handles invitee.canceled events by updating the call status
 * @param userId - The Firebase user ID
 * @param webhookPayload - The Calendly webhook payload
 * @returns boolean indicating success
 */
export async function handleInviteeCanceled(
  userId: string,
  webhookPayload: CalendlyWebhookPayload
): Promise<boolean> {
  const updateData: Partial<ScheduledCallData> = {
    status: 'canceled',
    // Add cancellation details if available
    ...(webhookPayload.cancellation && {
      canceledAt: Timestamp.fromDate(new Date(webhookPayload.cancellation.created_at)),
      canceledBy: webhookPayload.cancellation.canceled_by,
      cancellationReason: webhookPayload.cancellation.reason,
    }),
  };

  return await updateScheduledCall(userId, webhookPayload.scheduled_event.uri, updateData);
}

/**
 * Checks if a scheduled call already exists for the given event URI
 * @param userId - The Firebase user ID
 * @param calendlyEventUri - The Calendly event URI
 * @returns boolean indicating if the call exists
 */
export async function scheduledCallExists(
  userId: string,
  calendlyEventUri: string
): Promise<boolean> {
  try {
    const firestore = admin.firestore();
    
    const querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('scheduled_calls')
      .where('calendlyEventUri', '==', calendlyEventUri)
      .limit(1)
      .get();

    return !querySnapshot.empty;
  } catch (error) {
    logger.error(`Error checking if scheduled call exists for user ${userId}:`, error);
    return false;
  }
}

/**
 * Generates a unique document ID based on the Calendly event URI
 * @param calendlyEventUri - The Calendly event URI
 * @returns A sanitized document ID
 */
export function generateDocumentId(calendlyEventUri: string): string {
  // Extract the event ID from the URI and sanitize it for Firestore
  const eventId = calendlyEventUri.split('/').pop() || '';
  return eventId.replace(/[^a-zA-Z0-9]/g, '_');
}