/**
 * Thin Calendly REST API helpers shared across Cloud Functions.
 */

import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';
import axios from 'axios';

/**
 * Reads a mentor's stored Calendly access token from the first document in
 * mentors/{mentorId}/calendlyInfo (written during the OAuth callback).
 * @param mentorId - The mentor's Firebase user ID
 * @returns The access token, or null when none is available
 */
export async function getMentorAccessToken(mentorId: string): Promise<string | null> {
  if (!mentorId || mentorId.trim() === '') return null;

  try {
    const firestore = admin.firestore();
    const subcollSnap = await firestore
      .collection('mentors')
      .doc(mentorId)
      .collection('calendlyInfo')
      .limit(1)
      .get();

    if (subcollSnap.empty) return null;

    const data = subcollSnap.docs[0].data() || {};
    return typeof data.access_token === 'string' ? data.access_token : null;
  } catch (error) {
    logger.error('Error reading mentor Calendly access token', {mentorId, error});
    return null;
  }
}

/**
 * Location details for a scheduled event, extracted from the Calendly API.
 */
export interface EventLocation {
  joinUrl: string | null;
  status: string | null;
  type: string | null;
}

const EMPTY_LOCATION: EventLocation = {joinUrl: null, status: null, type: null};

/**
 * Fetches the full Calendly scheduled event and returns its location details.
 *
 * The `invitee.created` webhook payload does NOT reliably include `join_url`, so
 * it must be read from GET /scheduled_events/{uuid}. `scheduledEventUri` is
 * already the full API URL (e.g. https://api.calendly.com/scheduled_events/AAAA).
 *
 * @param accessToken - The mentor's Calendly access token
 * @param scheduledEventUri - The scheduled event URI from the webhook payload
 * @returns The location's joinUrl/status/type (nulls on any failure)
 */
export async function fetchEventLocation(
  accessToken: string,
  scheduledEventUri: string
): Promise<EventLocation> {
  try {
    const resp = await axios.get(scheduledEventUri, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      timeout: 15000,
      validateStatus: () => true,
    });

    if (resp.status < 200 || resp.status >= 300) {
      logger.warn('Calendly scheduled_events GET returned non-OK', {
        status: resp.status,
        scheduledEventUri,
      });
      return {...EMPTY_LOCATION};
    }

    const location = resp.data?.resource?.location ?? {};
    return {
      joinUrl: typeof location.join_url === 'string' ? location.join_url : null,
      status: typeof location.status === 'string' ? location.status : null,
      type: typeof location.type === 'string' ? location.type : null,
    };
  } catch (error) {
    logger.error('Error fetching Calendly scheduled event location', {scheduledEventUri, error});
    return {...EMPTY_LOCATION};
  }
}

/** Promise-based delay helper. */
function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Resolves the meeting join URL for a scheduled event, retrying briefly while
 * the video provider (e.g. Zoom) is still provisioning the link
 * (`location.status === 'processing'`). Stops early for any terminal state
 * (link ready, `failed`, or no video location) to avoid wasted latency.
 *
 * @param accessToken - The mentor's Calendly access token
 * @param scheduledEventUri - The scheduled event URI from the webhook payload
 * @param attempts - Maximum number of GET attempts (default 3)
 * @param delayMs - Delay between attempts in ms (default 1500)
 * @returns The resolved location details
 */
export async function resolveJoinUrl(
  accessToken: string,
  scheduledEventUri: string,
  attempts = 3,
  delayMs = 1500
): Promise<EventLocation> {
  let last: EventLocation = {...EMPTY_LOCATION};

  for (let i = 0; i < attempts; i++) {
    last = await fetchEventLocation(accessToken, scheduledEventUri);
    // Got the link, or reached a terminal (non-processing) state — stop retrying.
    if (last.joinUrl || last.status !== 'processing') return last;
    if (i < attempts - 1) await delay(delayMs);
  }

  return last;
}
