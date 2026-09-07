# Webhook Notify

MongoDB Atlas Data API was retired on September 30, 2025. This version keeps
the notification use case without executing render widgets supplied by a
remote document.

Configure a public HTTPS endpoint. A `204` response or an empty `message`
hides the app. A notification response is a bounded JSON object:

```json
{
  "title": "Front door",
  "message": "The door has been open for five minutes.",
  "color": "#991b1b"
}
```

`title` and `color` are optional. If configured, the bearer token is stored as
a user-owned encrypted credential and sent as `Authorization: Bearer ...`.
