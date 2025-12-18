# GlowCart Supabase Backend

## Architecture Overview

This backend uses a **hybrid Supabase + Edge Functions** approach:

- **Supabase Core**: Auth, Database, Storage, Realtime
- **Edge Functions**: Complex business logic, external integrations
- **Database Functions**: Triggers, RLS policies, computed fields

## Project Structure

```
supabase/
├── migrations/           # Database schema migrations
├── functions/            # Edge Functions (Deno/TypeScript)
│   ├── orders/          # Order processing
│   ├── payments/        # Chipper Cash integration
│   ├── delivery/        # Uber API integration
│   ├── shipping/        # Skynet integration
│   ├── analytics/       # Metrics aggregation
│   └── webhooks/        # External webhook handlers
├── seed.sql             # Initial seed data
└── config.toml          # Supabase configuration
```

## What Supabase Handles Directly

| Feature | Supabase Service |
|---------|------------------|
| Authentication | Supabase Auth (email, OAuth) |
| User sessions | Supabase Auth + JWT |
| File uploads | Supabase Storage |
| Real-time chat | Supabase Realtime |
| Notifications | Supabase Realtime + DB |
| CRUD operations | PostgREST (auto-generated) |
| Access control | Row Level Security (RLS) |

## What Edge Functions Handle

| Feature | Why Edge Function? |
|---------|-------------------|
| Order processing | Complex state machine |
| Chipper Cash | External API + webhooks |
| Uber Delivery | External API + tracking |
| Skynet Shipping | External API + labels |
| Commission calc | Business logic |
| Analytics | Aggregation queries |
| AI Customer Service | LLM API calls |

## Quick Start

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Run migrations
supabase db push

# Deploy edge functions
supabase functions deploy
```

## Environment Variables

Create a `.env` file:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# External APIs
CHIPPER_CASH_API_KEY=
CHIPPER_CASH_WEBHOOK_SECRET=
UBER_CLIENT_ID=
UBER_CLIENT_SECRET=
SKYNET_API_KEY=
```
