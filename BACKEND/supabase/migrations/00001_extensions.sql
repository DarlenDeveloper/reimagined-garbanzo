-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For fuzzy search
CREATE EXTENSION IF NOT EXISTS "postgis";  -- For geolocation

-- Custom types
CREATE TYPE user_type AS ENUM ('buyer', 'vendor_owner', 'vendor_admin', 'vendor_manager', 'vendor_staff');
CREATE TYPE vendor_status AS ENUM ('pending', 'active', 'suspended', 'closed');
CREATE TYPE subscription_tier AS ENUM ('free', 'premium');
CREATE TYPE product_status AS ENUM ('draft', 'active', 'out_of_stock', 'discontinued');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'processing', 'ready', 'in_transit', 'delivered', 'cancelled', 'refunded');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE delivery_status AS ENUM ('pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'failed', 'cancelled');
CREATE TYPE shipment_status AS ENUM ('pending', 'label_created', 'picked_up', 'in_transit', 'delivered', 'returned');
CREATE TYPE post_type AS ENUM ('regular', 'promo', 'story');
CREATE TYPE notification_type AS ENUM ('order', 'payment', 'delivery', 'review', 'follow', 'promo', 'system');
