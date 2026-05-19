# Sprint 2 — WTC Chat App Backend Design

## Overview

Build a Java Spring Boot + MongoDB backend for the WTC CRM Chat platform, replacing Supabase. The iOS SwiftUI app will be rewired to consume the new REST APIs and WebSocket real-time channel.

## Stack

- Java 17, Spring Boot 3.3, Spring Security (JWT), Spring Data MongoDB, Spring WebSocket (STOMP)
- MongoDB (NoSQL)
- Differential: WebSocket real-time messaging

## MongoDB Collections

### users
```json
{
  "_id": "ObjectId",
  "email": "string (unique)",
  "password": "string (bcrypt)",
  "fullName": "string",
  "phone": "string?",
  "avatarUrl": "string?",
  "role": "OPERATOR | CLIENT",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### customers
```json
{
  "_id": "ObjectId",
  "userId": "string (ref users._id)",
  "tags": ["string"],
  "score": "int (0-100)",
  "status": "ACTIVE | INACTIVE | PENDING",
  "notes": ["{ text, createdAt, createdBy }"],
  "segmentIds": ["string"],
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### segments
```json
{
  "_id": "ObjectId",
  "name": "string",
  "description": "string?",
  "tags": ["string"],
  "createdBy": "string (ref users._id)",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### messages
```json
{
  "_id": "ObjectId",
  "type": "CHAT | CAMPAIGN",
  "senderId": "string (ref users._id)",
  "recipientId": "string? (ref users._id)",
  "segmentTags": ["string?"],
  "content": {
    "title": "string",
    "body": "string",
    "imageUrl": "string?",
    "buttons": [{ "label": "string", "action": "string" }]
  },
  "status": "SENT | DELIVERED | READ | FAILED",
  "readAt": "datetime?",
  "starred": "boolean",
  "createdAt": "datetime"
}
```

### campaigns
```json
{
  "_id": "ObjectId",
  "name": "string",
  "segmentId": "string (ref segments._id)",
  "content": {
    "title": "string",
    "body": "string",
    "imageUrl": "string?",
    "buttons": [{ "label": "string", "action": "string" }]
  },
  "deeplink": "string?",
  "status": "DRAFT | SENT",
  "sentAt": "datetime?",
  "sentBy": "string (ref users._id)",
  "messageCount": "int",
  "createdAt": "datetime"
}
```

### notifications
```json
{
  "_id": "ObjectId",
  "userId": "string (ref users._id)",
  "title": "string",
  "body": "string",
  "type": "MESSAGE | CAMPAIGN | SYSTEM",
  "read": "boolean",
  "messageId": "string? (ref messages._id)",
  "createdAt": "datetime"
}
```

### audit_logs
```json
{
  "_id": "ObjectId",
  "userId": "string",
  "action": "string (CREATE|READ|UPDATE|DELETE)",
  "resource": "string (collection name)",
  "resourceId": "string",
  "details": "string?",
  "ipAddress": "string?",
  "timestamp": "datetime"
}
```

## API Endpoints

### 1. Auth & Authorization
| Method | Path | Role | Description |
|--------|------|------|-------------|
| POST | /api/auth/register | PUBLIC | Register new user |
| POST | /api/auth/login | PUBLIC | Login, returns JWT |
| POST | /api/auth/refresh | AUTH | Refresh JWT token |

JWT payload: `{ sub: userId, role: OPERATOR|CLIENT, exp }`

### 2. CRM & Customers
| Method | Path | Role | Description |
|--------|------|------|-------------|
| GET | /api/customers | OPERATOR | List all customers (with filters: tag, status, score) |
| POST | /api/customers | OPERATOR | Create customer profile |
| GET | /api/customers/{id} | OPERATOR | Get customer detail |
| PUT | /api/customers/{id} | OPERATOR | Update customer (tags, score, status) |
| GET | /api/customers/{id}/timeline | OPERATOR | Profile 360: messages + campaigns + notes |
| POST | /api/customers/{id}/notes | OPERATOR | Add quick note |

### 3. Segments
| Method | Path | Role | Description |
|--------|------|------|-------------|
| GET | /api/segments | OPERATOR | List all segments |
| POST | /api/segments | OPERATOR | Create segment |
| PUT | /api/segments/{id} | OPERATOR | Update segment |
| DELETE | /api/segments/{id} | OPERATOR | Delete segment |

### 4. Chat & Messaging
| Method | Path | Role | Description |
|--------|------|------|-------------|
| POST | /api/messages | OPERATOR | Send message (1:1 or segment) |
| GET | /api/messages/{id} | AUTH | Get message detail |
| GET | /api/inbox/{customerId} | AUTH | Get customer inbox |
| PUT | /api/messages/{id}/read | AUTH | Mark as read |
| PUT | /api/messages/{id}/star | AUTH | Toggle star |

### 5. Campaigns
| Method | Path | Role | Description |
|--------|------|------|-------------|
| GET | /api/campaigns | OPERATOR | List campaigns |
| POST | /api/campaigns | OPERATOR | Create campaign |
| POST | /api/campaigns/{id}/send | OPERATOR | Send campaign to segment |

### 6. Notifications
| Method | Path | Role | Description |
|--------|------|------|-------------|
| GET | /api/notifications | AUTH | Get user notifications |
| PUT | /api/notifications/{id}/read | AUTH | Mark as read |
| PUT | /api/notifications/read-all | AUTH | Mark all as read |

### 7. Audit
| Method | Path | Role | Description |
|--------|------|------|-------------|
| GET | /api/audit-logs | OPERATOR | List audit logs (filterable) |

## WebSocket (STOMP)

- Endpoint: `/ws`
- Subscribe: `/topic/messages/{userId}` — new messages
- Subscribe: `/topic/notifications/{userId}` — new notifications
- When a message is sent via REST, the service broadcasts to WebSocket subscribers

## Security

- BCrypt password hashing
- JWT with 24h expiry, refresh token with 7d expiry
- Role-based access: OPERATOR (full CRM access), CLIENT (own data only)
- CORS configured for iOS app

## Audit Logging

- AOP aspect intercepts all controller methods
- Logs: userId, action, resource, resourceId, timestamp, IP
- Stored in audit_logs collection

## iOS Integration Changes

1. Replace `SupabaseService` → `APIService` (URLSession + JWT)
2. Replace `RealtimeService` → `WebSocketService` (StompClientLib or raw WebSocket)
3. Auth: login → store JWT in Keychain → attach Bearer token to requests
4. Models stay the same structure (just different JSON field mapping)

## Seed Data

Same test profiles from Sprint 1 migrated to MongoDB format, plus operator accounts.
