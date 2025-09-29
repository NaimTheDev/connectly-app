/**
 * Firebase Cloud Functions for Connectly App
 * Handles Calendly webhook events and manages scheduled calls
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {handleCalendlyWebhook} from "./calendly-webhook";

/**
 * Calendly webhook endpoint
 * Processes invitee.created and invitee.canceled events
 *
 * URL: https://us-central1-halal-social-prod.cloudfunctions.net/calendlyWebhook
 */
export const calendlyWebhook = onRequest(
  {
    // Function configuration
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
    maxInstances: 100,
    
    // CORS configuration for Calendly webhooks
    cors: [
      "https://calendly.com",
      "https://api.calendly.com",
    ],
    
  },
  async (request, response) => {
    try {
      await handleCalendlyWebhook(request, response);
    } catch (error) {
      logger.error("Unhandled error in calendlyWebhook function:", error);
      response.status(500).json({
        error: "Internal server error",
        timestamp: new Date().toISOString(),
      });
    }
  }
);

/**
 * Health check endpoint for monitoring
 */
export const healthCheck = onRequest(
  {
    region: "us-central1",
    memory: "128MiB",
    timeoutSeconds: 10,
  },
  (request, response) => {
    response.status(200).json({
      status: "healthy",
      timestamp: new Date().toISOString(),
      version: "1.0.0",
    });
  }
);
