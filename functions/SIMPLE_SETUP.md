# Simple Calendly Webhook Setup (No Signature Validation)

## Quick Setup Steps

### 1. Deploy the Cloud Function

```bash
cd functions
firebase deploy --only functions
```

Your webhook URL will be:
```
https://us-central1-halal-social-prod.cloudfunctions.net/calendlyWebhook
```

### 2. Create Calendly Webhook Subscription

You need a Calendly Personal Access Token:
1. Go to [Calendly Developer Settings](https://calendly.com/integrations/api_webhooks)
2. Generate a Personal Access Token

Get your organization URI:
```bash
curl -H "Authorization: Bearer YOUR_CALENDLY_ACCESS_TOKEN" \
  https://api.calendly.com/users/me
```

Look for `current_organization` in the response.

Create the webhook subscription:
```bash
curl -X POST https://api.calendly.com/webhook_subscriptions \
  -H "Authorization: Bearer YOUR_CALENDLY_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://us-central1-halal-social-prod.cloudfunctions.net/calendlyWebhook",
    "events": [
      "invitee.created",
      "invitee.canceled"
    ],
    "organization": "YOUR_ORGANIZATION_URI",
    "scope": "organization"
  }'
```

### 3. Test the Webhook

That's it! No secrets to configure. The function will:

1. ✅ Accept webhook events from Calendly
2. ✅ Map invitee emails to Firebase users
3. ✅ Create/update documents in `users/{userId}/scheduled_calls/`
4. ✅ Your Flutter app will automatically show the new calls

### 4. Monitor the Function

View logs to see webhook events being processed:
```bash
firebase functions:log
```

### 5. Test with a Real Booking

1. Create a test event type in Calendly
2. Book a meeting using an email that exists in your Firebase users collection
3. Check the logs and Firestore to see the scheduled call document created

## What Happens When a Webhook is Received

1. **Calendly sends webhook** → Cloud Function receives it
2. **Function validates payload** → Checks for required fields
3. **Looks up user by email** → Finds Firebase user with matching email
4. **Creates/updates Firestore document** → In `users/{userId}/scheduled_calls/`
5. **Your app updates automatically** → Via existing providers and UI

## Data Structure Created

The function creates documents in your Firestore that match your existing ScheduledCall model:

```typescript
// Collection: users/{userId}/scheduled_calls/{callId}
{
  calendlyEventUri: "https://api.calendly.com/scheduled_events/GBGBDCAADAEDCRZ2",
  cancelUrl: "https://calendly.com/cancellations/AAAAAAAAAAAAAAAA",
  createdAt: Timestamp,
  endTime: "2019-08-24T14:15:22.123456Z",
  eventType: "https://api.calendly.com/event_types/GBGBDCAADAEDCRZ2",
  inviteeEmail: "test@example.com",
  inviteeName: "John Doe",
  mentorUri: "https://api.calendly.com/users/GBGBDCAADAEDCRZ2",
  rescheduleUrl: "https://calendly.com/reschedulings/AAAAAAAAAAAAAAAA",
  rescheduled: false,
  startTime: "2019-08-24T14:15:22.123456Z",
  status: "active", // or "canceled"
  timezone: "America/New_York",
  joinUrl: "string" // if location type supports it
}
```

## Webhook Payload Format

The function handles the actual Calendly webhook payload format you provided:

**For invitee.created events:**
- `status: "active"`
- `canceled: false`

**For invitee.canceled events:**
- `status: "canceled"`
- `canceled: true`
- `cancellation: { canceled_by, reason, canceler_type, created_at }`

## Troubleshooting

- **Function not receiving webhooks**: Check the webhook URL in Calendly settings
- **User not found logs**: Ensure the invitee email matches a user in your Firebase users collection
- **No documents created**: Check Firebase Functions logs for errors
- **Function timeout**: The function has a 60-second timeout, which should be plenty

## Adding Signature Validation Later

If you want to add signature validation later for security:

1. Get the signing secret from your webhook subscription response
2. Set it in Firebase: `firebase functions:config:set calendly.webhook_secret="SECRET"`
3. Uncomment the signature validation code in `calendly-webhook.ts`
4. Redeploy: `firebase deploy --only functions`

For now, the function works without any secrets or complex setup!