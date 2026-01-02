/**
 * Firebase Cloud Functions for Connectly App
 * Handles Calendly webhook events and manages scheduled calls
 */

import {onRequest, onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from 'firebase-admin';
import axios from 'axios';
import {handleCalendlyWebhook} from "./calendly-webhook";
import {CalendlyInviteeResponse} from "./types/calendly";

/**
 * Type representing a single available timeslot returned to clients.
 */
export type AvailableTimeSlot = {
  status: string;
  invitees_remaining: number | null;
  start_time: string; // ISO string with microsecond precision, e.g. 2020-01-02T20:00:00.000000Z
  scheduling_url: string | null;
};

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


export const availableTimes = onCall(
  {
    region: "us-central1",
    memory: "128MiB",
    timeoutSeconds: 30,
  },
  async (request) => {
    if (!admin.apps.length) {
      admin.initializeApp();
    }

    const mentorId = request.data?.mentorId;
    const startDateInput = request.data?.startDate;

    
    try {
      const firestore = admin.firestore();
      // Expected path: mentors/{mentorId}/calendlyInfo/{docId}
      // Fetch the first document in the subcollection so the client doesn't need to know docId
      const subcollSnap = await firestore
        .collection('mentors')
        .doc(mentorId)
        .collection('calendlyInfo')
        .limit(1)
        .get();

      if (subcollSnap.empty) {
        return { error: 'No calendlyInfo document found for mentorId: ' + mentorId };
      }

      const data = subcollSnap.docs[0].data() || {};
      const access_token = typeof data.access_token === 'string' ? data.access_token : null;
      const event_type_uri = typeof data.event_type_uri === 'string' ? data.event_type_uri : null;

      if (!access_token || !event_type_uri) {
        return { error: 'Missing access_token or event_type_uri in calendlyInfo' };
      }

      // Compute start and end times for a 7-day window (UTC)
      // Enforce that start_time is at least 2 hours in the future.
      const now = startDateInput && typeof startDateInput === 'string' ? new Date(startDateInput) : new Date();
      // Normalize requested date to UTC midnight
      let start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
      const minStart = new Date(Date.now() + 2 * 60 * 60 * 1000);
      if (start.getTime() < minStart.getTime()) {
        start = minStart;
      }
      const end = new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000);

      const fmt = (d: Date) => d.toISOString().replace('.000Z', '.000000Z');

      const params = new URLSearchParams({
        event_type: event_type_uri,
        start_time: fmt(start),
        end_time: fmt(end),
      });

      const url = `https://api.calendly.com/event_type_available_times?${params.toString()}`;

      logger.info('Fetching Calendly available times', {mentorId, url});

      // Use axios for HTTP requests (axios throws on non-2xx by default, so we handle status manually)
      const resp = await axios.get(url, {
        headers: {
          Authorization: `Bearer ${access_token}`,
          'Content-Type': 'application/json',
        },
        timeout: 15000,
        validateStatus: () => true,
      });

      if (resp.status < 200 || resp.status >= 300) {
        const text = typeof resp.data === 'string' ? resp.data : JSON.stringify(resp.data).slice(0, 2000);
        logger.error('Calendly API returned non-OK', {status: resp.status, body: text});
        return { error: `Calendly API error: ${resp.status}`, details: resp.data };
      }

      const body = resp.data;

      const collection = Array.isArray(body?.collection) ? body.collection : [];

      // Map Calendly response items to our AvailableTimeSlot type
      const availableTimeSlots: AvailableTimeSlot[] = collection.slice(0, 1000).map((item: any) => ({
        status: item?.status,
        invitees_remaining: item.invitees_remaining,
        start_time: item.start_time,
        scheduling_url: item.scheduling_url,
      }));
      logger.info('Fetched available time slots', {mentorId, count: availableTimeSlots.length});

      return {
        message: `Available times for mentorId: ${mentorId}`,
        availableTimeSlots,
        raw: body,
      };
    } catch (error) {
      logger.error('Error in availableTimes callable', {error});
      return { error: 'Internal error fetching available times' };
    }
  }
);

export const scheduleCalendlyInvitee = onCall(
  {
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (request) => {
    if (!admin.apps.length) {
      admin.initializeApp();
    }

    const mentorId = request.data?.mentorId;
    const userId = request.data?.userId;
    const startTime = request.data?.startTime;

    if (typeof mentorId !== 'string' || mentorId.length === 0) {
      return {error: 'mentorId is required'};
    }

    if (typeof userId !== 'string' || userId.length === 0) {
      return {error: 'userId is required'};
    }

    if (typeof startTime !== 'string' || startTime.length === 0) {
      return {error: 'startTime is required'};
    }

    try {
      const firestore = admin.firestore();

      const [calendlyInfoSnapshot, userDoc] = await Promise.all([
        firestore
          .collection('mentors')
          .doc(mentorId)
          .collection('calendlyInfo')
          .limit(1)
          .get(),
        firestore.collection('users').doc(userId).get(),
      ]);

      if (calendlyInfoSnapshot.empty) {
        return {error: `No calendlyInfo found for mentorId: ${mentorId}`};
      }

      if (!userDoc.exists) {
        return {error: `No user found for userId: ${userId}`};
      }

      const calendlyInfo = calendlyInfoSnapshot.docs[0].data() || {};
      const access_token = typeof calendlyInfo.access_token === 'string' ? calendlyInfo.access_token : null;
      const event_type_uri = typeof calendlyInfo.event_type_uri === 'string' ? calendlyInfo.event_type_uri : null;

      if (!access_token || !event_type_uri) {
        return {error: 'Missing access_token or event_type_uri in calendlyInfo'};
      }

      const userData = userDoc.data() || {};
      const email = typeof userData.email === 'string' ? userData.email : '';
      const firstName = typeof userData.firstName === 'string' ? userData.firstName : undefined;
      const lastName = typeof userData.lastName === 'string' ? userData.lastName : undefined;
      const derivedNameParts = [firstName, lastName].filter(
        (value): value is string => typeof value === 'string' && value.trim().length > 0
      );
      const displayName =
        typeof userData.name === 'string' && userData.name.trim().length > 0
          ? userData.name
          : derivedNameParts.join(' ');
      const timezone =
        typeof userData.timezone === 'string' && userData.timezone.trim().length > 0
          ? userData.timezone
          : 'UTC';

      if (!email) {
        return {error: `User ${userId} does not have an email on file`};
      }

      const payload = {
        event_type: event_type_uri,
        start_time: startTime,
        invitee: {
          name: displayName || email,
          first_name: firstName,
          last_name: lastName,
          email,
          timezone,
        },
        location: {
          kind: 'zoom_conference',
          connected: true,
        },
      };

      logger.info('Scheduling Calendly invitee', {
        mentorId,
        userId,
        startTime,
      });

      const resp = await axios.post('https://api.calendly.com/invitees', payload, {
        headers: {
          Authorization: `Bearer ${access_token}`,
          'Content-Type': 'application/json',
        },
        timeout: 15000,
        validateStatus: () => true,
      });

      if (resp.status < 200 || resp.status >= 300) {
        const text =
          typeof resp.data === 'string' ? resp.data : JSON.stringify(resp.data).slice(0, 2000);
        logger.error('Calendly invitee API returned non-OK', {
          status: resp.status,
          body: text,
        });
        return {error: `Calendly invitee API error: ${resp.status}`, details: resp.data};
      }

      const body = resp.data as CalendlyInviteeResponse;
      const resource = body?.resource;

      if (!resource) {
        logger.error('Calendly invitee response missing resource field', {body});
        return {error: 'Calendly invitee response malformed'};
      }

      logger.info('Calendly invitee scheduled successfully', {
        mentorId,
        userId,
        inviteeUri: resource.uri,
      });

      return {
        message: 'Invitee scheduled successfully',
        resource,
      };
    } catch (error) {
      logger.error('Error scheduling Calendly invitee', {error});
      return {error: 'Failed to schedule Calendly invitee'};
    }
  }
);
