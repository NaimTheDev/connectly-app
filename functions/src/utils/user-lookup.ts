/**
 * User lookup utility for mapping Calendly invitee emails to Firebase users
 */

import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';

/**
 * Looks up a Firebase user by email address
 * @param email - The email address to search for
 * @returns The user document data and ID, or null if not found
 */
export async function findUserByEmail(email: string): Promise<{
  uid: string;
  data: FirebaseFirestore.DocumentData;
} | null> {
  try {
    const firestore = admin.firestore();
    
    // Query the users collection for a document with matching email
    const userQuery = await firestore
      .collection('users')
      .where('email', '==', email.toLowerCase().trim())
      .limit(1)
      .get();

    if (userQuery.empty) {
      logger.info(`No user found with email: ${email}`);
      return null;
    }

    const userDoc = userQuery.docs[0];
    return {
      uid: userDoc.id,
      data: userDoc.data(),
    };
  } catch (error) {
    logger.error(`Error looking up user by email ${email}:`, error);
    return null;
  }
}

/**
 * Looks up a Firebase user by user ID
 * @param userId - The Firebase user ID to search for
 * @returns The user document data, or null if not found
 */
export async function findUserById(userId: string): Promise<FirebaseFirestore.DocumentData | null> {
  try {
    const firestore = admin.firestore();
    
    const userDoc = await firestore
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      logger.info(`No user found with ID: ${userId}`);
      return null;
    }

    return userDoc.data() || null;
  } catch (error) {
    logger.error(`Error looking up user by ID ${userId}:`, error);
    return null;
  }
}

/**
 * Alternative lookup using Firebase Auth (if users are stored in Auth only)
 * @param email - The email address to search for
 * @returns The Firebase Auth user record, or null if not found
 */
export async function findAuthUserByEmail(email: string): Promise<admin.auth.UserRecord | null> {
  try {
    const userRecord = await admin.auth().getUserByEmail(email.toLowerCase().trim());
    return userRecord;
  } catch (error) {
    if ((error as any).code === 'auth/user-not-found') {
      logger.info(`No auth user found with email: ${email}`);
      return null;
    }
    logger.error(`Error looking up auth user by email ${email}:`, error);
    return null;
  }
}

/**
 * Gets the user ID for a given email, trying Firestore first, then Auth
 * @param email - The email address to search for
 * @returns The user ID or null if not found
 */
export async function getUserIdByEmail(email: string): Promise<string | null> {
  try {
    // First try to find user in Firestore users collection
    const firestoreUser = await findUserByEmail(email);
    if (firestoreUser) {
      return firestoreUser.uid;
    }

    // If not found in Firestore, try Firebase Auth
    const authUser = await findAuthUserByEmail(email);
    if (authUser) {
      return authUser.uid;
    }

    return null;
  } catch (error) {
    logger.error(`Error getting user ID for email ${email}:`, error);
    return null;
  }
}

/**
 * Validates that an email address is in a valid format
 * @param email - The email address to validate
 * @returns boolean indicating if the email is valid
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Extracts the mentor URI from Calendly event data
 * @param eventMemberships - The event memberships array from Calendly
 * @returns The mentor URI or empty string if not found
 */
export function extractMentorUri(eventMemberships: any[]): string {
  logger.info('🔍 Extracting mentor URI from event memberships', {
    eventMemberships,
    isArray: Array.isArray(eventMemberships),
    length: eventMemberships?.length || 0
  });

  try {
    if (!Array.isArray(eventMemberships) || eventMemberships.length === 0) {
      logger.warn('⚠️ No event memberships provided or empty array');
      return '';
    }

    // Get the first event membership (typically the mentor/host)
    const mentorMembership = eventMemberships[0];
    const mentorUri = mentorMembership?.user || '';
    
    logger.info('✅ Successfully extracted mentor URI', {
      mentorUri,
      mentorMembership
    });
    
    return mentorUri;
  } catch (error) {
    logger.error('❌ Error extracting mentor URI:', {
      error: error instanceof Error ? error.message : String(error),
      eventMemberships
    });
    return '';
  }
}