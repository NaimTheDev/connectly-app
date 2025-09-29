/**
 * Calendly webhook handler for processing invitee events
 */

import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';
import {Request} from 'firebase-functions/v2/https';
import {Response} from 'express';
import {CalendlyWebhookEvent, CalendlyWebhookPayload, CalendlyEventType} from './types/calendly';
import {
  validateCalendlySignature,
  extractSignature,
  validateWebhookPayload,
} from './utils/signature-validation';
import {getUserIdByEmail, isValidEmail} from './utils/user-lookup';
import {
  handleInviteeCreated,
  handleInviteeCanceled,
  scheduledCallExists,
} from './utils/scheduled-call-handler';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Main Calendly webhook handler function
 * Processes invitee.created and invitee.canceled events
 */
export async function handleCalendlyWebhook(req: Request, res: Response): Promise<void> {
  const correlationId = generateCorrelationId();
  
  try {
    logger.info('Calendly webhook received', {
      correlationId,
      method: req.method,
      headers: sanitizeHeaders(req.headers),
    });

    // Only accept POST requests
    if (req.method !== 'POST') {
      logger.warn('Invalid HTTP method', {correlationId, method: req.method});
      res.status(405).json({error: 'Method not allowed'});
      return;
    }

    // Skip signature validation for now (can be enabled later)
    logger.info('Skipping webhook signature validation', {correlationId});

    // Parse and validate webhook payload
    let webhookPayload: CalendlyWebhookPayload;
    let eventType: string;
    
    try {
      // Check if this is a wrapped webhook event or direct payload
      const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
      
      if (body.event && body.payload) {
        // Wrapped format: {event: "invitee.created", payload: {...}}
        eventType = body.event;
        webhookPayload = body.payload;
      } else {
        // Direct payload format (what you provided)
        webhookPayload = body;
        eventType = webhookPayload.status === 'canceled' ? 'invitee.canceled' : 'invitee.created';
      }
    } catch (error) {
      logger.error('Failed to parse webhook payload', {correlationId, error});
      res.status(400).json({error: 'Invalid JSON payload'});
      return;
    }

    if (!validateWebhookPayload(webhookPayload)) {
      logger.warn('Invalid webhook payload structure', {correlationId});
      res.status(400).json({error: 'Invalid payload structure'});
      return;
    }

    logger.info('Processing Calendly webhook event', {
      correlationId,
      eventType,
      inviteeEmail: webhookPayload.email,
    });

    // Process the webhook event
    const result = await processWebhookEvent(webhookPayload, eventType, correlationId);
    
    if (result.success) {
      logger.info('Webhook processed successfully', {
        correlationId,
        eventType,
        documentId: result.documentId,
      });
      res.status(200).json({
        success: true,
        message: 'Webhook processed successfully',
        correlationId,
      });
    } else {
      logger.warn('Webhook processing failed', {
        correlationId,
        eventType,
        reason: result.reason,
      });
      res.status(200).json({
        success: false,
        message: result.reason,
        correlationId,
      });
    }
  } catch (error) {
    logger.error('Unexpected error processing webhook', {correlationId, error});
    res.status(500).json({
      error: 'Internal server error',
      correlationId,
    });
  }
}

/**
 * Processes the webhook event based on its type
 */
async function processWebhookEvent(
  webhookPayload: CalendlyWebhookPayload,
  eventType: string,
  correlationId: string
): Promise<{success: boolean; reason?: string; documentId?: string}> {
  const inviteeEmail = webhookPayload.email;

  // Validate email format
  if (!isValidEmail(inviteeEmail)) {
    return {success: false, reason: 'Invalid email format'};
  }

  // Find the user by email
  const userId = await getUserIdByEmail(inviteeEmail);
  if (!userId) {
    logger.info('User not found for email, skipping webhook', {
      correlationId,
      email: inviteeEmail,
    });
    return {success: false, reason: 'User not found'};
  }

  // Handle different event types
  switch (eventType) {
    case CalendlyEventType.INVITEE_CREATED:
      return await handleInviteeCreatedEvent(userId, webhookPayload, eventType, correlationId);
    
    case CalendlyEventType.INVITEE_CANCELED:
      return await handleInviteeCanceledEvent(userId, webhookPayload, correlationId);
    
    default:
      logger.info('Unsupported event type, ignoring', {
        correlationId,
        eventType,
      });
      return {success: false, reason: 'Unsupported event type'};
  }
}

/**
 * Handles invitee.created events
 */
async function handleInviteeCreatedEvent(
  userId: string,
  webhookPayload: CalendlyWebhookPayload,
  eventType: string,
  correlationId: string
): Promise<{success: boolean; reason?: string; documentId?: string}> {
  try {
    const calendlyEventUri = webhookPayload.scheduled_event.uri;
    
    // Check if this call already exists to prevent duplicates
    const exists = await scheduledCallExists(userId, calendlyEventUri);
    if (exists) {
      logger.info('Scheduled call already exists, skipping creation', {
        correlationId,
        userId,
        calendlyEventUri,
      });
      return {success: false, reason: 'Call already exists'};
    }

    // Create the scheduled call
    const documentId = await handleInviteeCreated(userId, webhookPayload, eventType);
    
    return {success: true, documentId};
  } catch (error) {
    logger.error('Error handling invitee.created event', {
      correlationId,
      userId,
      error,
    });
    return {success: false, reason: 'Failed to create scheduled call'};
  }
}

/**
 * Handles invitee.canceled events
 */
async function handleInviteeCanceledEvent(
  userId: string,
  webhookPayload: CalendlyWebhookPayload,
  correlationId: string
): Promise<{success: boolean; reason?: string; documentId?: string}> {
  try {
    const success = await handleInviteeCanceled(userId, webhookPayload);
    
    if (success) {
      return {success: true};
    } else {
      return {success: false, reason: 'Failed to update scheduled call'};
    }
  } catch (error) {
    logger.error('Error handling invitee.canceled event', {
      correlationId,
      userId,
      error,
    });
    return {success: false, reason: 'Failed to cancel scheduled call'};
  }
}

/**
 * Generates a unique correlation ID for request tracking
 */
function generateCorrelationId(): string {
  return `calendly_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Sanitizes headers for logging (removes sensitive information)
 */
function sanitizeHeaders(headers: Record<string, any>): Record<string, any> {
  const sanitized = {...headers};
  
  // Remove sensitive headers
  delete sanitized['calendly-webhook-signature'];
  delete sanitized['Calendly-Webhook-Signature'];
  delete sanitized['authorization'];
  delete sanitized['Authorization'];
  
  return sanitized;
}