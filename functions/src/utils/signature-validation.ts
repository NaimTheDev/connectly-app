/**
 * Calendly webhook signature validation utility
 */

import * as crypto from 'crypto';
import * as logger from 'firebase-functions/logger';

/**
 * Validates the Calendly webhook signature.
 *
 * Calendly sends `Calendly-Webhook-Signature: t=<unix_ts>,v1=<hex_digest>`.
 * The signed payload is constructed as `<timestamp>.<raw_body>` and hashed
 * with HMAC-SHA256, producing a hex digest.
 *
 * @param rawBody - The raw request body string (before any JSON.parse)
 * @param signatureHeader - Full value of the Calendly-Webhook-Signature header
 * @param secret - The webhook signing secret from environment variables
 * @returns true if the signature is valid
 */
export function validateCalendlySignature(
  rawBody: string,
  signatureHeader: string,
  secret: string
): boolean {
  try {
    // Parse "t=<timestamp>,v1=<hexdigest>"
    const parts: Record<string, string> = {};
    for (const part of signatureHeader.split(',')) {
      const [key, value] = part.split('=');
      if (key && value !== undefined) parts[key.trim()] = value.trim();
    }

    const timestamp = parts['t'];
    const receivedHex = parts['v1'];

    if (!timestamp || !receivedHex) {
      logger.warn('Calendly signature header missing t or v1 fields');
      return false;
    }

    // Signed payload: "<timestamp>.<raw_body>"
    const signedPayload = `${timestamp}.${rawBody}`;

    const expectedHex = crypto
      .createHmac('sha256', secret)
      .update(signedPayload, 'utf8')
      .digest('hex');

    // Constant-time comparison to prevent timing attacks
    return crypto.timingSafeEqual(
      Buffer.from(receivedHex, 'hex'),
      Buffer.from(expectedHex, 'hex')
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