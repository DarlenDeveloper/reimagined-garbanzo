# GlowCart Supabase Architecture Proposal

## Overview

This document outlines a hybrid architecture using **Supabase** as the primary backend platform for GlowCart, replacing the standalone Go API approach.

---

## 1. Why Supabase?

### What You Get Out of the Box

| Feature | Supabase Service | Replaces |
|---------|------------------|----------|
| PostgreSQL Database | Supabase DB | Self-hosted Postgres |
| Authentication | Supabase Auth | `auth/` service |
| OAuth (Google, Facebook, Apple) | Supabase Auth | `oauth/` service |
| File Storage (S3-compatible) | Supabase Storage | `media/` service |
| Real-time Subscriptions | Supabase Realtime | WebSocket server |
| Auto-generated REST API | PostgREST | Basic CRUD endpoints |
| Row Level Security | RLS Policies | `rbac/` service (partially) |
| Database Functions | PL/pgSQL | Triggers, computed fields |
| Edge Functions | Deno Runtime | Complex business logic |

### What You Still Need Custom Logic For

| Feature | Why Custom? |
|---------|-------------|
| Order Processing | Complex state machine, inventory updates, notifications |
| Chipper Cash Integration | External API, webhook handling, commission calculation |
| Uber Delivery Integration | External API, real-time tracking, driver assignment |
| Skynet Shipping Integration | External API, label generation, tracking |
| Analytics Aggregation | Complex queries, report generation |
| AI Customer Service | LLM API calls, conversation management |
| BNPL Logic | Installment calculations, payment schedules |

---

## 2. Architecture Options

### Option A: Pure Supabase (Edge Functions Only)

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                  │
├─────────────────────────────────────────────────────────────────┤
│  Flutter Buyer App          │          Next.js Seller Portal    │
│  (Supabase Flutter SDK)     │          (Supabase JS SDK)        │
└──────────────┬──────────────┴──────────────┬────────────────────┘
               │                              │
               ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SUPABASE CLOUD                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Auth      │  │   Storage   │  │  Realtime   │              │
│  │             │  │             │  │             │              │
│  │ • Email     │  │ • Products  │  │ • Chat      │              │
│  │ • OAuth     │  │ • Avatars   │  │ • Orders    │              │
│  │ • JWT       │  │ • Documents │  │ • Notifs    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    PostgreSQL Database                       ││
│  │  • All 100+ tables                                          ││
│  │  • Row Level Security (RLS)                                 ││
│  │  • Database Functions & Triggers                            ││
│  │  • PostgREST auto-generated API                             ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Edge Functions (Deno)                     ││
│  │                                                              ││
│  │  • process-order      • chipper-webhook                     ││
│  │  • create-delivery    • uber-webhook                        ││
│  │  • create-shipment    • skynet-webhook                      ││
│  │  • calculate-analytics • ai-chat                            ││
│  │  • process-payout     • generate-report                     ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     EXTERNAL SERVICES                            │
├─────────────────────────────────────────────────────────────────┤
│  Chipper Cash    │    Uber API    │    Skynet    │    OpenAI    │
└─────────────────────────────────────────────────────────────────┘
```

**Pros:**
- Single platform, simpler deployment
- No separate server to manage
- Automatic scaling
- Lower operational overhead

**Cons:**
- Edge Functions have cold starts (~200-500ms)
- 50MB memory limit per function
- Deno/TypeScript only (no Go)
- Harder to debug complex logic
- Vendor lock-in to Supabase

---

### Option B: Hybrid (Supabase + Go API)

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                  │
├─────────────────────────────────────────────────────────────────┤
│  Flutter Buyer App          │          Next.js Seller Portal    │
└──────────────┬──────────────┴──────────────┬────────────────────┘
               │                              │
               │  ┌───────────────────────────┤
               │  │                           │
               ▼  ▼                           ▼
┌──────────────────────────┐    ┌─────────────────────────────────┐
│     SUPABASE CLOUD       │    │         GO API SERVER           │
├──────────────────────────┤    ├─────────────────────────────────┤
│                          │    │                                 │
│  Auth (login, OAuth)     │    │  Order Processing               │
│  Storage (files)         │    │  • Create order                 │
│  Realtime (chat, notifs) │    │  • Update status                │
│  Database (all tables)   │    │  • Cancel/refund                │
│  PostgREST (simple CRUD) │    │                                 │
│                          │    │  Payment (Chipper Cash)         │
│  Used for:               │    │  • Process payment              │
│  • User registration     │    │  • Handle webhooks              │
│  • File uploads          │    │  • Calculate commission         │
│  • Chat messages         │    │  • Process payouts              │
│  • Product browsing      │    │                                 │
│  • Cart management       │    │  Delivery (Uber)                │
│  • Wishlist              │    │  • Create delivery              │
│  • Reviews               │    │  • Track driver                 │
│  • Social posts          │    │  • Handle webhooks              │
│                          │    │                                 │
└──────────────────────────┘    │  Shipping (Skynet)              │
               │                │  • Create shipment              │
               │                │  • Generate labels              │
               │                │  • Track packages               │
               │                │                                 │
               │                │  Analytics                      │
               │                │  • Dashboard metrics            │
               │                │  • Report generation            │
               │                │                                 │
               │                │  AI Customer Service            │
               │                │  • Chat with LLM                │
               │                │  • Escalation handling          │
               │                │                                 │
               └───────────────►│  (Connects to same Supabase DB) │
                                └─────────────────────────────────┘
                                               │
                                               ▼
                                ┌─────────────────────────────────┐
                                │       EXTERNAL SERVICES         │
                                ├─────────────────────────────────┤
                                │ Chipper │ Uber │ Skynet │ OpenAI│
                                └─────────────────────────────────┘
```

**Pros:**
- Best of both worlds
- Go for complex, performance-critical logic
- Supabase for commodity features
- Easier to test and debug Go code
- No vendor lock-in for business logic
- Can scale Go API independently

**Cons:**
- Two systems to manage
- Need to deploy/host Go API somewhere
- Slightly more complex architecture

---

### Option C: Supabase + Serverless Go (AWS Lambda / Cloud Run)

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                  │
└──────────────┬──────────────────────────────┬───────────────────┘
               │                              │
               ▼                              ▼
┌──────────────────────────┐    ┌─────────────────────────────────┐
│     SUPABASE CLOUD       │    │    SERVERLESS GO FUNCTIONS      │
├──────────────────────────┤    ├─────────────────────────────────┤
│  Auth, Storage, Realtime │    │  AWS Lambda / Google Cloud Run  │
│  Database, PostgREST     │    │                                 │
│                          │    │  • order-processor              │
│                          │    │  • payment-handler              │
│                          │    │  • delivery-service             │
│                          │    │  • shipping-service             │
│                          │    │  • analytics-aggregator         │
│                          │    │  • ai-chat-handler              │
└──────────────────────────┘    └─────────────────────────────────┘
```

**Pros:**
- Go code, serverless scaling
- Pay per invocation
- No server management

**Cons:**
- Cold starts for Go lambdas
- More complex deployment
- Multiple cloud providers

---

## 3. Recommendation: Option B (Hybrid)

I recommend **Option B** for GlowCart because:

1. **Order processing is critical** — needs reliable, testable code
2. **Payment handling requires precision** — commission calculations, refunds
3. **External APIs are complex** — Uber/Skynet need proper error handling
4. **You already have Go experience** — from the initial scaffolding
5. **Easier debugging** — local Go development vs cloud functions

---

## 4. Service Responsibility Matrix

### Handled by Supabase Directly (via SDK)

| Service | How |
|---------|-----|
| `auth/` | Supabase Auth |
| `oauth/` | Supabase Auth (Google, Facebook, Apple) |
| `media/` | Supabase Storage |
| `chat/` | Supabase Realtime + messages table |
| `notification/` | Supabase Realtime + notifications table |
| `cart/` | PostgREST + RLS |
| `wishlist/` | PostgREST + RLS |
| `review/` | PostgREST + RLS |
| `question/` | PostgREST + RLS |
| `social/` | PostgREST + RLS |
| `story/` | PostgREST + RLS |
| `follower/` | PostgREST + RLS |
| `address/` | PostgREST + RLS |
| `settings/` | PostgREST + RLS |
| `faq/` | PostgREST + RLS |

### Handled by Database Functions (PL/pgSQL)

| Service | How |
|---------|-----|
| `inventory/` | Triggers on order insert/update |
| `rbac/` | RLS policies + role checks |
| `audit-log/` | Triggers on all tables |
| `interests/` | Triggers on user behavior |

### Handled by Go API

| Service | Why |
|---------|-----|
| `order/` | Complex state machine, multi-table transactions |
| `payment/` | Chipper Cash API, commission logic |
| `delivery/` | Uber API integration |
| `shipping/` | Skynet API integration |
| `analytics/` | Complex aggregations, report generation |
| `report/` | PDF/CSV generation |
| `subscription/` | Billing logic, feature gating |
| `bnpl/` | Installment calculations |
| `coupon/` | Validation logic, usage tracking |
| `rewards/` | Points calculation, tier logic |
| `ai-customer-service/` | LLM API calls |
| `push-notification/` | FCM/APNs integration |
| `webhook/` | External webhook handling |
| `search/` | Full-text search optimization |
| `location/` | Geolocation queries |

---

## 5. Database Design

### Tables Managed via Supabase Dashboard/Migrations

All 100+ tables from the original plan remain, but now with:

1. **RLS Policies** — Row-level security for multi-tenant access
2. **Database Functions** — Triggers for inventory, audit logs
3. **Foreign Key Constraints** — Referential integrity
4. **Indexes** — Performance optimization

### Example RLS Policy (Products)

```sql
-- Vendors can only see their own products
CREATE POLICY "Vendors see own products" ON products
  FOR SELECT
  USING (vendor_id = auth.uid() OR auth.jwt() ->> 'user_type' = 'buyer');

-- Vendors can only update their own products
CREATE POLICY "Vendors update own products" ON products
  FOR UPDATE
  USING (vendor_id = auth.uid());
```

### Example Trigger (Inventory)

```sql
-- Auto-decrement inventory on order creation
CREATE OR REPLACE FUNCTION decrement_inventory()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE inventory
  SET quantity = quantity - NEW.quantity
  WHERE product_id = NEW.product_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_order_item_insert
  AFTER INSERT ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION decrement_inventory();
```

---

## 6. Go API Structure (Simplified)

Since Supabase handles auth, storage, and simple CRUD, the Go API is much leaner:

```
glowcart-api/
├── cmd/
│   └── api/
│       └── main.go
├── internal/
│   ├── config/
│   ├── middleware/          # JWT validation (from Supabase)
│   ├── handlers/
│   │   ├── orders/          # Order processing
│   │   ├── payments/        # Chipper Cash
│   │   ├── delivery/        # Uber
│   │   ├── shipping/        # Skynet
│   │   ├── analytics/       # Metrics
│   │   └── webhooks/        # External webhooks
│   ├── services/
│   └── integrations/
│       ├── supabase/        # Supabase client
│       ├── chipper/
│       ├── uber/
│       └── skynet/
├── go.mod
└── Dockerfile
```

### Go API Endpoints (Reduced)

```
# Orders (complex logic)
POST   /api/v1/orders                 # Create order (inventory check, payment)
PUT    /api/v1/orders/:id/accept      # Accept order
PUT    /api/v1/orders/:id/reject      # Reject order
PUT    /api/v1/orders/:id/ready       # Mark ready
PUT    /api/v1/orders/:id/cancel      # Cancel with refund

# Payments
POST   /api/v1/payments/process       # Process payment via Chipper
POST   /api/v1/payments/payout        # Request payout
POST   /api/v1/payments/refund        # Process refund

# Delivery
POST   /api/v1/delivery/create        # Create Uber delivery
GET    /api/v1/delivery/:id/track     # Get tracking

# Shipping
POST   /api/v1/shipping/create        # Create Skynet shipment
GET    /api/v1/shipping/:id/label     # Get shipping label

# Analytics
GET    /api/v1/analytics/dashboard    # Dashboard metrics
GET    /api/v1/analytics/export       # Export report

# Webhooks
POST   /api/v1/webhooks/chipper       # Chipper Cash webhook
POST   /api/v1/webhooks/uber          # Uber webhook
POST   /api/v1/webhooks/skynet        # Skynet webhook
```

---

## 7. Client SDK Usage

### Flutter (Buyer App)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

// Initialize
await Supabase.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key',
);

final supabase = Supabase.instance.client;

// Auth
await supabase.auth.signInWithOAuth(Provider.google);

// Fetch products (direct to Supabase)
final products = await supabase
  .from('products')
  .select('*, vendor:vendors(*)')
  .eq('status', 'active')
  .limit(20);

// Create order (via Go API)
final response = await http.post(
  Uri.parse('$goApiUrl/api/v1/orders'),
  headers: {'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}'},
  body: jsonEncode(orderData),
);

// Real-time chat
supabase
  .from('messages')
  .stream(primaryKey: ['id'])
  .eq('conversation_id', conversationId)
  .listen((messages) => updateUI(messages));
```

### Next.js (Seller Portal)

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

// Auth
await supabase.auth.signInWithPassword({ email, password });

// Fetch vendor's products (direct to Supabase)
const { data: products } = await supabase
  .from('products')
  .select('*')
  .eq('vendor_id', vendorId);

// Process order (via Go API)
const response = await fetch(`${GO_API_URL}/api/v1/orders/${orderId}/accept`, {
  method: 'PUT',
  headers: {
    'Authorization': `Bearer ${session.access_token}`,
  },
});

// Real-time order updates
supabase
  .channel('orders')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'orders' }, 
    (payload) => handleOrderUpdate(payload))
  .subscribe();
```

---

## 8. Deployment

### Supabase
- Hosted on Supabase Cloud (managed)
- Or self-hosted via Docker (optional)

### Go API
- **Option 1:** Railway / Render / Fly.io (simple)
- **Option 2:** AWS ECS / Google Cloud Run (scalable)
- **Option 3:** VPS with Docker (budget)

### Recommended: Railway

```bash
# Deploy Go API to Railway
railway login
railway init
railway up
```

---

## 9. Cost Estimate

### Supabase Pro Plan ($25/month)
- 8GB database
- 250GB bandwidth
- 100GB storage
- Unlimited API requests
- Daily backups

### Go API Hosting (Railway ~$5-20/month)
- Depends on usage
- Pay per resource

### Total: ~$30-50/month to start

---

## 10. Migration Path

### Phase 1: Setup Supabase
1. Create Supabase project
2. Run database migrations
3. Configure Auth providers
4. Set up Storage buckets
5. Create RLS policies

### Phase 2: Build Go API
1. Scaffold Go project
2. Implement order processing
3. Integrate Chipper Cash
4. Integrate Uber API
5. Integrate Skynet API

### Phase 3: Connect Clients
1. Update Flutter app to use Supabase SDK
2. Update Next.js portal to use Supabase SDK
3. Point complex operations to Go API

---

## 11. Questions for You

1. **Option A, B, or C?** — Pure Supabase, Hybrid, or Serverless Go?
2. **Self-hosted or Cloud?** — Supabase Cloud or self-hosted?
3. **Go API hosting preference?** — Railway, Render, AWS, or VPS?
4. **Any services I should move between categories?**
5. **Timeline expectations?**

---

## 12. Next Steps (After Approval)

1. Finalize architecture choice
2. Create Supabase project
3. Write complete database migrations
4. Implement RLS policies
5. Scaffold Go API (if hybrid)
6. Update client SDKs

---

*Awaiting your review and feedback.*so 
                    ┌─────────────────┐
                    │  Load Balancer  │
                    │  (Oracle LB)    │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   Go API #1     │ │   Go API #2     │ │   Go API #3     │
│   (Instance)    │ │   (Instance)    │ │   (Instance)    │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             ▼
              ┌─────────────────────────────┐
              │   Managed Database          │
              │   (Oracle Autonomous DB     │
              │    or Supabase Cloud Pro)   │
              └─────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
     ┌─────────────────┐          ┌─────────────────┐
     │  Redis Cluster  │          │  Object Storage │
     │  (Managed)      │          │  (Oracle/S3)    │
     └─────────────────┘          └─────────────────┘
