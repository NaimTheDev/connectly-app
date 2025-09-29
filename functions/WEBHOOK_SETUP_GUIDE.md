# Calendly Webhook Setup Guide

## Step-by-Step Process

### 1. First Deploy the Cloud Function (Without Secret)

Since you need the webhook URL before creating the Calendly subscription, deploy the function first:

```bash
# Deploy without the secret initially
cd functions
firebase deploy --only functions
```

The function will be available at:
```
https://us-central1-halal-social-prod.cloudfunctions.net/calendlyWebhook
```

### 2. Create Calendly Webhook Subscription

Use the Calendly API to create a webhook subscription. **This is where you get the signing secret:**

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

**The response will include the signing secret:**

```json
{
  "resource": {
    "uri": "https://api.calendly.com/webhook_subscriptions/WEBHOOK_ID",
    "callback_url": "https://us-central1-halal-social-prod.cloudfunctions.net/calendlyWebhook",
    "created_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z",
    "retry_started_at": null,
    "state": "active",
    "events": ["invitee.created", "invitee.canceled"],
    "scope": "organization",
    "organization": "https://api.calendly.com/organizations/YOUR_ORG_ID",
    "user": null,
    "creator": "https://api.calendly.com/users/YOUR_USER_ID",
    "signing_key": "YOUR_WEBHOOK_SIGNING_SECRET_HERE"  ← THIS IS WHAT YOU NEED
  }
}
```

### 3. Set the Signing Secret in Firebase

Copy the `signing_key` from the response and set it in Firebase Functions:

```bash
firebase functions:config:set calendly.webhook_secret="YOUR_WEBHOOK_SIGNING_SECRET_HERE"
```

### 4. Redeploy with the Secret

```bash
firebase deploy --only functions
```

## Alternative: Get Your Calendly Access Token

If you don't have a Calendly access token yet:

### Option A: Personal Access Token (Easiest)
1. Go to [Calendly Developer Settings](https://calendly.com/integrations/api_webhooks)
2. Generate a Personal Access Token
3. Use this token in the API calls above

### Option B: OAuth App (For Production)
1. Create an OAuth app in Calendly Developer Console
2. Implement OAuth flow to get access token
3. Use the access token for API calls

## Getting Your Organization URI

You'll also need your organization URI for the webhook subscription:

```bash
curl -H "Authorization: Bearer YOUR_CALENDLY_ACCESS_TOKEN" \
  https://api.calendly.com/users/me
```

The response will include your organization URI:
```json
{
  "resource": {
    "uri": "https://api.calendly.com/users/YOUR_USER_ID",
    "name": "Your Name",
    "slug": "your-slug",
    "email": "your@email.com",
    "scheduling_url": "https://calendly.com/your-slug",
    "timezone": "America/New_York",
    "avatar_url": "https://...",
    "created_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z",
    "current_organization": "https://api.calendly.com/organizations/YOUR_ORG_ID"  ← USE THIS
  }
}
```

## Complete Example Script

Here's a complete script to set everything up:

```bash
#!/bin/bash

# 1. Deploy function first
cd functions
firebase deploy --only functions

# 2. Get your user info and organization URI
CALENDLY_TOKEN="your_personal_access_token_here"
ORG_URI=$(curl -s -H "Authorization: Bearer $CALENDLY_TOKEN" \
  https://api.calendly.com/users/me | \
  jq -r '.resource.current_organization')

echo "Organization URI: $ORG_URI"

# 3. Create webhook subscription and get signing secret
WEBHOOK_RESPONSE=$(curl -s -X POST https://api.calendly.com/webhook_subscriptions \
  -H "Authorization: Bearer $CALENDLY_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"url\": \"https://us-central1-halal-social-prod.cloudfunctions.net/calendlyWebhook\",
    \"events\": [\"invitee.created\", \"invitee.canceled\"],
    \"organization\": \"$ORG_URI\",
    \"scope\": \"organization\"
  }")

SIGNING_SECRET=$(echo $WEBHOOK_RESPONSE | jq -r '.resource.signing_key')
echo "Signing Secret: $SIGNING_SECRET"

# 4. Set the secret in Firebase
firebase functions:config:set calendly.webhook_secret="$SIGNING_SECRET"

# 5. Redeploy with the secret
firebase deploy --only functions

echo "✅ Webhook setup complete!"
echo "Webhook URL: https://us-central1-halal-social-prod.cloudfunctions.net/calendlyWebhook"
```

## Testing the Webhook

Once everything is set up, you can test by:

1. Creating a test event in Calendly
2. Booking the event
3. Checking Firebase Functions logs: `firebase functions:log`
4. Verifying the document was created in Firestore

## Troubleshooting

- **401 Unauthorized**: Check that the signing secret is correctly set
- **User not found**: Ensure the invitee email matches a user in your Firebase users collection
- **Function timeout**: Check Firebase Functions logs for detailed error messages