/**
 * Calendly webhook signature validation utility
 */

import * as crypto from 'crypto';
import * as logger from 'firebase-functions/logger';

/**
 * Validates the Calendly webhook signature
 * @param payload - The raw request body as a string
 * @param signature - The signature from the request headers
 * @param secret - The webhook secret from environment variables
 * @returns boolean indicating if the signature is valid
 */
export function validateCalendlySignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  try {
    // Calendly uses HMAC-SHA256 with base64 encoding
    const expectedSignature = crypto
      .createHmac('sha256', secret)
      .update(payload, 'utf8')
      .digest('base64');

    // Compare signatures using a constant-time comparison to prevent timing attacks
    return crypto.timingSafeEqual(
      Buffer.from(signature, 'base64'),
      Buffer.from(expectedSignature, 'base64')
    );
  } catch (error) {
    logger.error('Error validating Calendly signature:', error);
    return false;
  }
}

/**
 * Extracts the signature from the Calendly webhook headers
 * @param headers - The request headers
 * @returns The signature string or null if not found
 */
export function extractSignature(headers: Record<string, string | string[] | undefined>): string | null {
  const signature = headers['calendly-webhook-signature'] || headers['Calendly-Webhook-Signature'];
  
  if (Array.isArray(signature)) {
    return signature[0] || null;
  }
  
  return signature || null;
}

/**
 * Validates that the webhook payload has the required structure
 * @param payload - The parsed webhook payload
 * @returns boolean indicating if the payload is valid
 */
export function validateWebhookPayload(payload: any): boolean {
  try {
    // Check for required top-level fields
    if (!payload || typeof payload !== 'object') {
      return false;
    }

    // Check for required fields in the direct payload format
    const requiredFields = ['email', 'name', 'scheduled_event'];
    for (const field of requiredFields) {
      if (!(field in payload)) {
        logger.warn(`Missing required field: ${field}`);
        return false;
      }
    }

    // Validate email
    if (typeof payload.email !== 'string') {
      logger.warn('Email field must be a string');
      return false;
    }

    // Validate scheduled_event structure
    if (!payload.scheduled_event || typeof payload.scheduled_event !== 'object') {
      logger.warn('scheduled_event field must be an object');
      return false;
    }

    // Check required fields in scheduled_event
    const eventRequiredFields = ['uri', 'start_time', 'end_time'];
    for (const field of eventRequiredFields) {
      if (!(field in payload.scheduled_event)) {
        logger.warn(`Missing required field in scheduled_event: ${field}`);
        return false;
      }
    }

    return true;
  } catch (error) {
    logger.error('Error validating webhook payload structure:', error);
    return false;
  }
}