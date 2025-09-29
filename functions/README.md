# Calendly Webhook Handler - Firebase Cloud Functions

This Firebase Cloud Function handles Calendly webhook events and creates/updates scheduled calls in Firestore.

## Features

- ✅ Handles `invitee.created` and `invitee.canceled` events
- ✅ Webhook signature validation for security
- ✅ Maps Calendly invitee emails to Firebase users
- ✅ Creates/updates documents in `users/{userId}/scheduled_calls` collection
- ✅ Comprehensive error handling and logging
- ✅ Duplicate event prevention

## Setup

### 1. Environment Variables

Set the Calendly webhook secret in Firebase Functions config:

```bash
firebase functions:config:set calendly.webhook_secret="your_webhook_secret_here"
```

Or use environment variables (for local development):

```bash
cp .env.example .env
# Edit .env and add your webhook secret
```

### 2. Deploy Functions

```bash
# Build and deploy
npm run build
npm run deploy

# Or deploy directly
firebase deploy --only functions
```

### 3. Webhook URL

After deployment, your webhook URL will be:
```
https://us-central1-halal-social-prod.cloudfunctions.net/calendlyWebhook
```

### 4. Create Calendly Webhook Subscription

Use this URL to create a webhook subscription via Calendly API:

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

## Local Development

### 1. Install Dependencies

```bash
npm install
```

### 2. Start Emulator

```bash
npm run serve
```

The function will be available at:
```
http://localhost:5001/halal-social-prod/us-central1/calendlyWebhook
```

### 3. Test Webhook

You can test the webhook locally using curl:

```bash
curl -X POST http://localhost:5001/halal-social-prod/us-central1/calendlyWebhook \
  -H "Content-Type: application/json" \
  -H "Calendly-Webhook-Signature: test_signature" \
  -d '{
    "created_at": "2024-01-01T00:00:00.000000Z",
    "event": "invitee.created",
    "payload": {
      "email": "test@example.com",
      "name": "Test User",
      "event": {
        "uri": "https://api.calendly.com/scheduled_events/test123",
        "start_time": "2024-01-01T10:00:00.000000Z",
        "end_time": "2024-01-01T11:00:00.000000Z",
        "event_type": "30 Minute Meeting"
      }
    }
  }'
```

## Monitoring

### Logs

View function logs:

```bash
firebase functions:log
```

### Health Check

Check if the function is running:

```bash
curl https://us-central1-halal-social-prod.cloudfunctions.net/healthCheck
```

## Data Structure

The function creates documents in Firestore with this structure:

```typescript
// Collection: users/{userId}/scheduled_calls/{callId}
{
  calendlyEventUri: string;
  cancelUrl: string;
  createdAt: Timestamp;
  endTime: string;
  eventType: string;
  inviteeEmail: string;
  inviteeName: string;
  mentorUri: string;
  rescheduleUrl: string;
  rescheduled: boolean;
  startTime: string;
  status: "active" | "canceled";
  timezone: string;
  joinUrl?: string;
}
```

## Supported Events

- `invitee.created` - Creates a new scheduled call document
- `invitee.canceled` - Updates the call status to "canceled"

## Security

- Webhook signature validation using HMAC-SHA256
- CORS restrictions to Calendly domains
- Input validation and sanitization
- Structured logging without sensitive data exposure

## Error Handling

The function handles various error scenarios:

- Invalid webhook signatures (401)
- Missing or invalid payload (400)
- User not found (200 with warning log)
- Firestore errors (500)
- Duplicate events (200 with info log)

All errors are logged with correlation IDs for debugging.