# Implementation Plan: Seller Web Platform

## Task List

- [ ] 1. Set up project infrastructure and development environment
  - Initialize Go backend project with module structure
  - Set up Next.js frontend project with TypeScript
  - Configure PostgreSQL database with Docker
  - Set up Redis for caching and sessions
  - Configure RabbitMQ for message queuing
  - Create Docker Compose for local development
  - Set up environment configuration management
  - _Requirements: All_

- [ ] 2. Implement database schema and migrations
  - Create migration system using golang-migrate
  - Implement vendors table and indexes
  - Implement business_hours table
  - Implement products, product_images, product_variants tables
  - Implement categories table with hierarchy support
  - Implement inventory table with constraints
  - Implement orders, order_items, order_events tables
  - Implement addresses table
  - Implement transactions and payouts tables
  - Implement deliveries and shipments tables
  - Implement notifications table
  - Create seed data for development
  - _Requirements: All data-related requirements_

- [ ] 3. Build authentication service
- [ ] 3.1 Implement vendor registration endpoint
  - Create registration request validation
  - Implement password hashing with bcrypt
  - Generate unique vendor IDs
  - Store vendor credentials in database
  - Return JWT token on successful registration
  - _Requirements: 1.1_

- [ ]* 3.2 Write property test for vendor registration
  - **Property 1: Unique vendor account creation**
  - **Validates: Requirements 1.1**

- [ ] 3.3 Implement vendor login endpoint
  - Validate login credentials
  - Verify password hash
  - Generate JWT access and refresh tokens
  - Store session in Redis
  - Return authentication response
  - _Requirements: 1.2, 1.3_

- [ ]* 3.4 Write property tests for authentication
  - **Property 2: Valid credential authentication**
  - **Property 3: Invalid credential rejection**
  - **Validates: Requirements 1.2, 1.3**

- [ ] 3.5 Implement password reset workflow
  - Create password reset request endpoint
  - Generate unique time-limited reset tokens
  - Store tokens in Redis with expiration
  - Integrate email notification (stub for now)
  - Create password reset confirmation endpoint
  - _Requirements: 1.5_

- [ ]* 3.6 Write property test for password reset
  - **Property 5: Password reset token generation**
  - **Validates: Requirements 1.5**

- [ ] 3.7 Implement session management
  - Create session validation middleware
  - Implement 30-minute inactivity timeout
  - Handle session refresh
  - Implement logout endpoint
  - _Requirements: 12.3_

- [ ]* 3.8 Write property test for session timeout
  - **Property 65: Session timeout enforcement**
  - **Validates: Requirements 12.3**

- [ ]* 3.9 Write unit tests for authentication service
  - Test registration with duplicate email rejection
  - Test login with incorrect password
  - Test token expiration handling
  - Test session refresh logic
  - _Requirements: 1.1, 1.2, 1.3, 1.5, 12.3_


- [ ] 4. Build vendor service
- [ ] 4.1 Implement vendor profile CRUD operations
  - Create get vendor profile endpoint
  - Create update vendor profile endpoint
  - Validate contact information formats (email, phone)
  - Handle business hours configuration
  - _Requirements: 2.1, 2.3, 2.4, 2.5_

- [ ]* 4.2 Write property tests for vendor profile
  - **Property 6: Store information persistence**
  - **Property 9: Contact information format validation**
  - **Property 10: Settings persistence across sessions**
  - **Validates: Requirements 2.1, 2.4, 2.5**

- [ ] 4.3 Implement image upload for logos and banners
  - Create image upload endpoint with multipart form support
  - Validate image format (JPEG, PNG) and size limits
  - Upload images to AWS S3 (or local storage for dev)
  - Generate and store image URLs
  - _Requirements: 2.2_

- [ ]* 4.4 Write property test for image validation
  - **Property 7: Image validation**
  - **Validates: Requirements 2.2**

- [ ] 4.5 Implement business hours availability calculation
  - Create function to check if store is currently open
  - Handle timezone conversions
  - Support closed days
  - _Requirements: 2.3_

- [ ]* 4.6 Write property test for business hours
  - **Property 8: Business hours availability calculation**
  - **Validates: Requirements 2.3**

- [ ]* 4.7 Write unit tests for vendor service
  - Test profile update with invalid email format
  - Test image upload with unsupported format
  - Test business hours edge cases (midnight, timezone boundaries)
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 5. Build product service
- [ ] 5.1 Implement product CRUD operations
  - Create product creation endpoint with validation
  - Validate required fields (name, price, vendor_id)
  - Validate price is positive
  - Create product listing endpoint with pagination
  - Create product update endpoint
  - Create product deletion endpoint (soft delete)
  - _Requirements: 3.1, 3.3, 3.5, 3.6_

- [ ]* 5.2 Write property tests for product operations
  - **Property 11: Product creation with validation**
  - **Property 13: Price positivity validation**
  - **Property 15: Product update synchronization**
  - **Property 16: Soft delete preservation**
  - **Validates: Requirements 3.1, 3.3, 3.5, 3.6**

- [ ] 5.3 Implement product image management
  - Handle multiple image uploads per product
  - Store images with display order
  - Optimize images for web and mobile
  - Generate thumbnail versions
  - _Requirements: 3.2_

- [ ]* 5.4 Write property test for image optimization
  - **Property 12: Image optimization**
  - **Validates: Requirements 3.2**

- [ ] 5.5 Implement category management
  - Create category hierarchy structure
  - Assign products to categories
  - Support parent-child category relationships
  - _Requirements: 3.4_

- [ ]* 5.6 Write property test for category hierarchy
  - **Property 14: Category hierarchy maintenance**
  - **Validates: Requirements 3.4**

- [ ] 5.7 Implement product variants
  - Create variant CRUD operations
  - Link variants to parent products
  - Support variant-specific pricing adjustments
  - _Requirements: 3.7_

- [ ]* 5.8 Write property test for variant inventory
  - **Property 17: Variant inventory isolation**
  - **Validates: Requirements 3.7**

- [ ]* 5.9 Write unit tests for product service
  - Test product creation with missing required fields
  - Test price validation with zero and negative values
  - Test soft delete preserves order references
  - Test variant creation and associations
  - _Requirements: 3.1, 3.3, 3.6, 3.7_


- [ ] 6. Build inventory service
- [ ] 6.1 Implement inventory tracking system
  - Create inventory initialization for products
  - Implement inventory update endpoint
  - Validate non-negative inventory values
  - Support variant-specific inventory
  - _Requirements: 4.1, 4.4_

- [ ]* 6.2 Write property tests for inventory management
  - **Property 18: Inventory initialization**
  - **Property 20: Non-negative inventory validation**
  - **Validates: Requirements 4.1, 4.4**

- [ ] 6.3 Implement inventory decrement on order
  - Create function to decrement inventory when order is placed
  - Implement atomic inventory updates to prevent race conditions
  - Handle variant inventory separately
  - _Requirements: 4.2_

- [ ]* 6.4 Write property test for inventory decrement
  - **Property 19: Order inventory decrement**
  - **Validates: Requirements 4.2**

- [ ] 6.5 Implement overselling prevention
  - Validate available stock before accepting orders
  - Lock inventory during order processing
  - Reject orders exceeding available stock
  - _Requirements: 4.6_

- [ ]* 6.6 Write property test for overselling prevention
  - **Property 22: Overselling prevention**
  - **Validates: Requirements 4.6**

- [ ] 6.7 Implement low stock alerts
  - Create low stock threshold configuration per product
  - Monitor inventory levels
  - Trigger notifications when threshold is reached
  - _Requirements: 4.5_

- [ ]* 6.8 Write property test for low stock alerts
  - **Property 21: Low stock alert triggering**
  - **Validates: Requirements 4.5**

- [ ]* 6.9 Write unit tests for inventory service
  - Test inventory update with negative values
  - Test concurrent inventory updates
  - Test low stock alert at exact threshold
  - _Requirements: 4.1, 4.2, 4.4, 4.5, 4.6_

- [ ] 7. Build order service
- [ ] 7.1 Implement order creation and retrieval
  - Create order ingestion endpoint (from buyer app)
  - Store order with pending status
  - Create order listing endpoint with filters
  - Create order details endpoint
  - Implement order search by number, customer, date, status
  - _Requirements: 5.1, 5.2, 5.6_

- [ ]* 7.2 Write property tests for order management
  - **Property 23: Order creation with pending status**
  - **Property 24: Order detail completeness**
  - **Property 28: Order search filtering**
  - **Validates: Requirements 5.1, 5.2, 5.6**

- [ ] 7.3 Implement order acceptance workflow
  - Create order acceptance endpoint
  - Update order status to processing
  - Trigger buyer notification
  - Record event in order history
  - _Requirements: 5.3, 5.7_

- [ ]* 7.4 Write property tests for order workflows
  - **Property 25: Order acceptance workflow**
  - **Property 29: Order event logging**
  - **Validates: Requirements 5.3, 5.7**

- [ ] 7.5 Implement order rejection workflow
  - Create order rejection endpoint with reason
  - Update order status to cancelled
  - Trigger refund processing (integrate with payment service)
  - Record event in order history
  - _Requirements: 5.4, 5.7_

- [ ]* 7.6 Write property test for order rejection
  - **Property 26: Order rejection with refund**
  - **Validates: Requirements 5.4**

- [ ] 7.7 Implement ready for delivery workflow
  - Create mark ready endpoint
  - Trigger delivery coordination (integrate with delivery service)
  - Update order status
  - Record event in order history
  - _Requirements: 5.5, 5.7_

- [ ]* 7.8 Write property test for delivery coordination
  - **Property 27: Delivery coordination trigger**
  - **Validates: Requirements 5.5**

- [ ]* 7.9 Write unit tests for order service
  - Test order creation with invalid data
  - Test order filtering with multiple criteria
  - Test order status transitions
  - Test event logging for all status changes
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_


- [ ] 8. Build payment service with Chipper Cash integration
- [ ] 8.1 Implement Chipper Cash API client
  - Create HTTP client for Chipper Cash API
  - Implement authentication with API keys
  - Create payment processing request function
  - Create refund processing request function
  - Handle API errors and timeouts
  - _Requirements: 6.1, 6.5_

- [ ] 8.2 Implement commission calculation
  - Create function to calculate 3% commission
  - Calculate net earnings (gross - commission)
  - Store transaction with all amounts
  - _Requirements: 6.1_

- [ ]* 8.3 Write property test for commission calculation
  - **Property 30: Commission calculation accuracy**
  - **Validates: Requirements 6.1**

- [ ] 8.4 Implement transaction recording and display
  - Store all transaction details in database
  - Create transaction history endpoint
  - Display gross, commission, and net amounts
  - Support filtering by date range
  - _Requirements: 6.2, 6.3_

- [ ]* 8.5 Write property tests for transaction management
  - **Property 31: Transaction display completeness**
  - **Property 32: Payment history completeness**
  - **Validates: Requirements 6.2, 6.3**

- [ ] 8.6 Implement payout processing
  - Create payout request endpoint
  - Validate minimum payout threshold
  - Validate available balance
  - Calculate payout amount from net earnings
  - Process payout through Chipper Cash
  - _Requirements: 6.4, 6.6_

- [ ]* 8.7 Write property tests for payout
  - **Property 33: Payout calculation**
  - **Property 35: Payout validation**
  - **Validates: Requirements 6.4, 6.6**

- [ ] 8.8 Implement refund processing
  - Create refund initiation function
  - Reverse commission calculation
  - Adjust vendor earnings
  - Update transaction status
  - _Requirements: 6.5_

- [ ]* 8.9 Write property test for refund
  - **Property 34: Refund commission reversal**
  - **Validates: Requirements 6.5**

- [ ] 8.10 Implement payment retry logic
  - Queue failed payment requests in RabbitMQ
  - Implement exponential backoff retry
  - Maximum 3 retry attempts
  - Alert on persistent failures
  - _Requirements: 15.1_

- [ ]* 8.11 Write property test for payment retry
  - **Property 70: Payment retry with backoff**
  - **Validates: Requirements 15.1**

- [ ]* 8.12 Write unit tests for payment service
  - Test commission calculation with various amounts
  - Test payout validation with insufficient balance
  - Test refund processing updates earnings correctly
  - Test Chipper Cash API error handling
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 15.1_

- [ ] 9. Build delivery service with Uber API integration
- [ ] 9.1 Implement Uber Delivery API client
  - Create HTTP client for Uber API
  - Implement OAuth authentication
  - Create delivery request function with pickup/dropoff details
  - Create delivery status tracking function
  - Handle API errors and timeouts
  - _Requirements: 7.1, 7.6_

- [ ]* 9.2 Write property test for delivery request
  - **Property 36: Delivery request data completeness**
  - **Validates: Requirements 7.1**

- [ ] 9.3 Implement delivery coordination workflow
  - Trigger delivery request when order is ready
  - Store delivery ID and tracking information
  - Update order status on pickup confirmation
  - Send buyer notification on status changes
  - _Requirements: 7.2_

- [ ]* 9.4 Write property test for pickup confirmation
  - **Property 37: Pickup confirmation workflow**
  - **Validates: Requirements 7.2**

- [ ] 9.5 Implement delivery completion and failure handling
  - Update order status on delivery completion
  - Record delivery timestamp
  - Handle delivery failures with vendor notification
  - Provide reschedule and cancel options
  - _Requirements: 7.4, 7.5_

- [ ]* 9.6 Write property tests for delivery outcomes
  - **Property 39: Delivery completion recording**
  - **Property 40: Delivery failure handling**
  - **Validates: Requirements 7.4, 7.5**

- [ ] 9.7 Implement delivery tracking display
  - Create endpoint to fetch real-time delivery status
  - Display tracking information to vendor
  - _Requirements: 7.6_

- [ ]* 9.8 Write property test for shipment tracking
  - **Property 41: Shipment tracking display**
  - **Validates: Requirements 7.6**

- [ ] 9.9 Implement delivery API fallback
  - Detect Uber API failures
  - Notify vendor of failure
  - Provide manual delivery coordination interface
  - _Requirements: 15.2_

- [ ]* 9.10 Write property test for delivery fallback
  - **Property 71: Delivery integration fallback**
  - **Validates: Requirements 15.2**

- [ ]* 9.11 Write unit tests for delivery service
  - Test delivery request with missing address details
  - Test status update handling
  - Test failure notification
  - Test Uber API error handling
  - _Requirements: 7.1, 7.2, 7.4, 7.5, 7.6, 15.2_


- [ ] 10. Build shipping service with Skynet integration
- [ ] 10.1 Implement Skynet Shipping API client
  - Create HTTP client for Skynet API
  - Implement authentication
  - Create shipping label generation function
  - Create tracking number retrieval function
  - Handle API errors and timeouts
  - _Requirements: 7.3_

- [ ]* 10.2 Write property test for shipping label generation
  - **Property 38: Shipping label generation**
  - **Validates: Requirements 7.3**

- [ ] 10.3 Implement shipping data caching and sync
  - Cache shipping data locally when Skynet is unavailable
  - Implement background sync when connection is restored
  - Queue shipping requests during outages
  - _Requirements: 15.3_

- [ ]* 10.4 Write property test for shipping cache and sync
  - **Property 72: Shipping data caching and sync**
  - **Validates: Requirements 15.3**

- [ ]* 10.5 Write unit tests for shipping service
  - Test label generation with valid data
  - Test tracking number format validation
  - Test caching behavior during API outage
  - Test sync after reconnection
  - _Requirements: 7.3, 15.3_

- [ ] 11. Build notification service
- [ ] 11.1 Implement notification system core
  - Create notification creation function
  - Store notifications in database
  - Implement notification preferences per vendor
  - Support multiple channels (email, SMS, in-app)
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [ ] 11.2 Implement notification queue processing
  - Set up RabbitMQ consumer for notification queue
  - Process notifications asynchronously
  - Handle delivery failures with retry
  - Track notification delivery status
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.6_

- [ ] 11.3 Implement notification triggers
  - Trigger notification on new order
  - Trigger notification on low stock alert
  - Trigger notification on payout processed
  - Trigger notification on buyer message
  - Trigger notification on delivery status change
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.6_

- [ ]* 11.4 Write property tests for notifications
  - **Property 48: Immediate order notification**
  - **Property 49: Low stock alert delivery**
  - **Property 50: Payout notification with details**
  - **Property 51: Message notification delivery**
  - **Property 52: Notification channel preference**
  - **Property 53: Delivery status notification**
  - **Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5, 9.6**

- [ ]* 11.5 Write unit tests for notification service
  - Test notification creation for each event type
  - Test channel selection based on preferences
  - Test notification queue processing
  - Test delivery failure retry logic
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [ ] 12. Build analytics service
- [ ] 12.1 Implement dashboard metrics calculation
  - Calculate total sales for period
  - Calculate order count for period
  - Calculate revenue and commission for period
  - Calculate net earnings
  - Create dashboard endpoint
  - _Requirements: 8.1, 8.6_

- [ ]* 12.2 Write property tests for analytics
  - **Property 42: Dashboard metrics calculation**
  - **Property 47: Commission display in analytics**
  - **Validates: Requirements 8.1, 8.6**

- [ ] 12.3 Implement sales trend reporting
  - Aggregate sales data by time intervals
  - Generate chart data for visualization
  - Support various time ranges (day, week, month, year)
  - _Requirements: 8.2_

- [ ]* 12.4 Write property test for sales trends
  - **Property 43: Sales trend generation**
  - **Validates: Requirements 8.2**

- [ ] 12.5 Implement product performance analytics
  - Calculate top-selling products
  - Calculate revenue by category
  - Rank products by sales volume and revenue
  - _Requirements: 8.3_

- [ ]* 12.6 Write property test for product performance
  - **Property 44: Product performance ranking**
  - **Validates: Requirements 8.3**

- [ ] 12.7 Implement date range filtering
  - Filter all analytics queries by date range
  - Support custom date range selection
  - Handle timezone conversions
  - _Requirements: 8.5_

- [ ]* 12.8 Write property test for date filtering
  - **Property 46: Date range filtering**
  - **Validates: Requirements 8.5**

- [ ] 12.9 Implement report export
  - Generate CSV export for sales data
  - Generate PDF export for reports
  - Include all relevant data in exports
  - _Requirements: 8.4_

- [ ]* 12.10 Write property test for report export
  - **Property 45: Report export format**
  - **Validates: Requirements 8.4**

- [ ]* 12.11 Write unit tests for analytics service
  - Test metrics calculation with various data sets
  - Test sales trend aggregation
  - Test product ranking with ties
  - Test date filtering edge cases
  - Test export file generation
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_


- [ ] 13. Build AI customer service (Premium feature)
- [ ] 13.1 Implement premium subscription management
  - Create subscription tier tracking
  - Implement feature flag system for premium features
  - Create subscription upgrade/downgrade endpoints
  - _Requirements: 10.1, 10.5_

- [ ]* 13.2 Write property tests for premium features
  - **Property 54: Premium feature activation**
  - **Property 58: Premium feature access**
  - **Validates: Requirements 10.1, 10.5**

- [ ] 13.3 Implement AI response suggestion system
  - Integrate with AI/LLM service (OpenAI, Claude, or similar)
  - Process buyer messages
  - Generate response suggestions
  - Return suggestions to vendor
  - _Requirements: 10.2_

- [ ]* 13.4 Write property test for AI suggestions
  - **Property 55: AI response suggestion generation**
  - **Validates: Requirements 10.2**

- [ ] 13.5 Implement automated AI responses
  - Create automated response configuration
  - Detect common customer inquiries
  - Generate and send automated responses
  - Maintain conversation context
  - _Requirements: 10.3, 10.4_

- [ ]* 13.6 Write property tests for AI automation
  - **Property 56: Automated response handling**
  - **Property 57: AI conversation context maintenance**
  - **Validates: Requirements 10.3, 10.4**

- [ ]* 13.7 Write unit tests for AI service
  - Test premium feature access control
  - Test AI response generation
  - Test automated response triggering
  - Test context maintenance across messages
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 14. Implement multi-currency support
- [ ] 14.1 Implement currency management
  - Create currency configuration per vendor
  - Store base currency for each vendor
  - Display all amounts in vendor base currency
  - _Requirements: 11.1_

- [ ]* 14.2 Write property test for currency display
  - **Property 59: Currency display consistency**
  - **Validates: Requirements 11.1**

- [ ] 14.3 Implement currency conversion
  - Integrate with exchange rate API
  - Convert payment amounts to vendor base currency
  - Handle real-time rate updates
  - _Requirements: 11.2, 11.4_

- [ ]* 14.4 Write property tests for currency conversion
  - **Property 60: Payment currency conversion**
  - **Property 62: Buyer currency display**
  - **Validates: Requirements 11.2, 11.4**

- [ ] 14.5 Implement multi-language product support
  - Store product descriptions in multiple languages
  - Support language selection per product
  - Retrieve descriptions based on buyer language
  - _Requirements: 11.3_

- [ ]* 14.6 Write property test for multi-language support
  - **Property 61: Multi-language product support**
  - **Validates: Requirements 11.3**

- [ ] 14.7 Implement commission with currency conversion
  - Calculate 3% commission after currency conversion
  - Handle rounding appropriately
  - _Requirements: 11.5_

- [ ]* 14.8 Write property test for multi-currency commission
  - **Property 63: Commission calculation with conversion**
  - **Validates: Requirements 11.5**

- [ ]* 14.9 Write unit tests for multi-currency
  - Test currency conversion with various rates
  - Test commission calculation in different currencies
  - Test language retrieval for products
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ] 15. Implement security features
- [ ] 15.1 Implement data encryption
  - Encrypt sensitive data at rest in database
  - Use AES-256 encryption for sensitive fields
  - Implement key management
  - _Requirements: 12.2_

- [ ]* 15.2 Write property test for data encryption
  - **Property 64: Data encryption at rest**
  - **Validates: Requirements 12.2**

- [ ] 15.3 Implement suspicious activity detection
  - Monitor login patterns
  - Detect unusual activity (multiple failed logins, unusual locations)
  - Temporarily lock accounts on suspicious activity
  - Send security notifications
  - _Requirements: 12.4_

- [ ]* 15.4 Write property test for security response
  - **Property 66: Suspicious activity response**
  - **Validates: Requirements 12.4**

- [ ] 15.5 Implement data export for GDPR compliance
  - Create data export endpoint
  - Include all vendor-related data
  - Generate downloadable archive
  - _Requirements: 12.5_

- [ ]* 15.6 Write property test for data export
  - **Property 67: Data export completeness**
  - **Validates: Requirements 12.5**

- [ ] 15.7 Implement PCI compliance for payments
  - Ensure no complete card details are stored
  - Use tokenization for payment methods
  - Validate Chipper Cash handles card data
  - _Requirements: 12.6_

- [ ]* 15.8 Write property test for PCI compliance
  - **Property 68: Payment card data exclusion**
  - **Validates: Requirements 12.6**

- [ ]* 15.9 Write unit tests for security features
  - Test encryption and decryption
  - Test suspicious activity detection
  - Test data export includes all tables
  - Test card data is never stored
  - _Requirements: 12.2, 12.4, 12.5, 12.6_


- [ ] 16. Implement API Gateway and middleware
- [ ] 16.1 Create API Gateway service
  - Set up Gin router with route groups
  - Implement request routing to microservices
  - Configure CORS middleware
  - Implement rate limiting
  - Add request logging middleware
  - _Requirements: All_

- [ ] 16.2 Implement authentication middleware
  - Validate JWT tokens on protected routes
  - Extract vendor ID from token
  - Handle token expiration
  - _Requirements: 1.2, 12.3_

- [ ] 16.3 Implement error handling middleware
  - Standardize error response format
  - Handle panics gracefully
  - Log errors with context
  - _Requirements: 15.4, 15.5_

- [ ]* 16.4 Write property test for API timeout handling
  - **Property 73: API timeout graceful handling**
  - **Validates: Requirements 15.4**

- [ ]* 16.5 Write property test for error logging
  - **Property 74: Integration error logging**
  - **Validates: Requirements 15.5**

- [ ]* 16.6 Write unit tests for API Gateway
  - Test rate limiting enforcement
  - Test authentication middleware with invalid tokens
  - Test error response formatting
  - Test CORS configuration
  - _Requirements: All_

- [ ] 17. Build Next.js frontend - Authentication pages
- [ ] 17.1 Create login page
  - Design login form with email and password
  - Implement form validation
  - Call login API endpoint
  - Store JWT token in secure cookie
  - Redirect to dashboard on success
  - _Requirements: 1.2, 1.3_

- [ ] 17.2 Create registration page
  - Design registration form with required fields
  - Implement form validation
  - Call registration API endpoint
  - Handle success and error states
  - _Requirements: 1.1_

- [ ] 17.3 Create password reset flow
  - Design password reset request page
  - Design password reset confirmation page
  - Implement email input and validation
  - Call password reset API endpoints
  - _Requirements: 1.5_

- [ ] 17.4 Implement authentication context
  - Create React context for auth state
  - Manage token storage and retrieval
  - Implement protected route wrapper
  - Handle session expiration
  - _Requirements: 1.2, 12.3_

- [ ]* 17.5 Write unit tests for auth pages
  - Test form validation
  - Test API call handling
  - Test error display
  - Test redirect behavior
  - _Requirements: 1.1, 1.2, 1.3, 1.5_

- [ ] 18. Build Next.js frontend - Dashboard
- [ ] 18.1 Create dashboard layout
  - Design sidebar navigation
  - Create header with vendor info
  - Implement responsive layout
  - _Requirements: 8.1_

- [ ] 18.2 Implement dashboard metrics display
  - Fetch dashboard metrics from API
  - Display total sales, order count, revenue
  - Display commission deductions
  - Show metrics for selected period
  - _Requirements: 8.1, 8.6_

- [ ] 18.3 Create sales trend charts
  - Integrate Chart.js for visualizations
  - Display line/bar charts for sales trends
  - Support date range selection
  - _Requirements: 8.2, 8.5_

- [ ] 18.4 Implement top products display
  - Fetch and display top-selling products
  - Show revenue by category
  - _Requirements: 8.3_

- [ ]* 18.5 Write unit tests for dashboard
  - Test metrics calculation display
  - Test chart rendering
  - Test date range filtering
  - _Requirements: 8.1, 8.2, 8.3, 8.5, 8.6_

- [ ] 19. Build Next.js frontend - Vendor Profile
- [ ] 19.1 Create vendor profile page
  - Display current vendor information
  - Create edit form for profile fields
  - Implement contact information validation
  - Call vendor update API
  - _Requirements: 2.1, 2.4_

- [ ] 19.2 Implement logo and banner upload
  - Create image upload component
  - Preview images before upload
  - Validate file format and size
  - Call image upload API
  - Display uploaded images
  - _Requirements: 2.2_

- [ ] 19.3 Implement business hours configuration
  - Create UI for setting hours per day
  - Support closed days
  - Save business hours configuration
  - _Requirements: 2.3_

- [ ]* 19.4 Write unit tests for profile pages
  - Test form validation
  - Test image upload validation
  - Test business hours configuration
  - _Requirements: 2.1, 2.2, 2.3, 2.4_


- [ ] 20. Build Next.js frontend - Product Management
- [ ] 20.1 Create product listing page
  - Display products in grid/list view
  - Implement pagination
  - Add search and filter functionality
  - Show product status (active, out of stock)
  - _Requirements: 3.1, 3.5_

- [ ] 20.2 Create product creation/edit form
  - Design form with all product fields
  - Implement validation (required fields, price positivity)
  - Handle multiple image uploads
  - Support category selection
  - Support variant creation
  - Call product API endpoints
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.7_

- [ ] 20.3 Implement product deletion
  - Add delete button with confirmation
  - Call delete API endpoint
  - Update product list after deletion
  - _Requirements: 3.6_

- [ ]* 20.4 Write unit tests for product pages
  - Test form validation
  - Test image upload handling
  - Test category selection
  - Test variant management
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6, 3.7_

- [ ] 21. Build Next.js frontend - Inventory Management
- [ ] 21.1 Create inventory dashboard
  - Display all products with inventory levels
  - Highlight low stock items
  - Show out of stock products
  - _Requirements: 4.1, 4.3, 4.5_

- [ ] 21.2 Implement inventory update interface
  - Create inline editing for inventory quantities
  - Validate non-negative values
  - Call inventory update API
  - Show success/error feedback
  - _Requirements: 4.1, 4.4_

- [ ] 21.3 Implement low stock alerts display
  - Show notifications for low stock items
  - Allow threshold configuration per product
  - _Requirements: 4.5_

- [ ]* 21.4 Write unit tests for inventory pages
  - Test inventory display
  - Test quantity validation
  - Test low stock alert display
  - _Requirements: 4.1, 4.3, 4.4, 4.5_

- [ ] 22. Build Next.js frontend - Order Management
- [ ] 22.1 Create order listing page
  - Display orders with status badges
  - Implement filters (status, date range, customer)
  - Add search by order number
  - Show order summary information
  - _Requirements: 5.1, 5.6_

- [ ] 22.2 Create order details page
  - Display complete order information
  - Show customer details and delivery address
  - Display ordered items with quantities and prices
  - Show order timeline/history
  - _Requirements: 5.2, 5.7_

- [ ] 22.3 Implement order action buttons
  - Add accept order button
  - Add reject order button with reason input
  - Add mark ready for delivery button
  - Handle API calls and update UI
  - _Requirements: 5.3, 5.4, 5.5_

- [ ]* 22.4 Write unit tests for order pages
  - Test order filtering
  - Test order search
  - Test order actions
  - Test order timeline display
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

- [ ] 23. Build Next.js frontend - Payments and Payouts
- [ ] 23.1 Create transaction history page
  - Display all transactions with details
  - Show gross amount, commission, net earnings
  - Implement date range filtering
  - Add export functionality
  - _Requirements: 6.2, 6.3_

- [ ] 23.2 Create payout request interface
  - Display available balance
  - Show minimum payout threshold
  - Create payout request form
  - Call payout API endpoint
  - Display payout history
  - _Requirements: 6.4, 6.6_

- [ ]* 23.3 Write unit tests for payment pages
  - Test transaction display
  - Test payout validation
  - Test export functionality
  - _Requirements: 6.2, 6.3, 6.4, 6.6_

- [ ] 24. Build Next.js frontend - Delivery and Shipping
- [ ] 24.1 Create delivery tracking interface
  - Display delivery status for orders
  - Show real-time tracking information
  - Display delivery timeline
  - _Requirements: 7.2, 7.4, 7.6_

- [ ] 24.2 Implement shipping label display
  - Show shipping labels for orders
  - Display tracking numbers
  - Provide download option for labels
  - _Requirements: 7.3_

- [ ] 24.3 Handle delivery failures
  - Display failure notifications
  - Provide reschedule and cancel options
  - _Requirements: 7.5_

- [ ]* 24.4 Write unit tests for delivery pages
  - Test tracking display
  - Test label download
  - Test failure handling UI
  - _Requirements: 7.2, 7.3, 7.4, 7.5, 7.6_


- [ ] 25. Build Next.js frontend - Analytics and Reports
- [ ] 25.1 Create analytics dashboard
  - Display comprehensive metrics
  - Show sales trends with charts
  - Display product performance
  - Implement date range selector
  - _Requirements: 8.1, 8.2, 8.3, 8.5_

- [ ] 25.2 Implement report export
  - Add export buttons for CSV and PDF
  - Call export API endpoints
  - Handle file download
  - _Requirements: 8.4_

- [ ]* 25.3 Write unit tests for analytics pages
  - Test metrics display
  - Test chart rendering
  - Test export functionality
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 26. Build Next.js frontend - Notifications
- [ ] 26.1 Create notification center
  - Display in-app notifications
  - Show unread notification count
  - Mark notifications as read
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.6_

- [ ] 26.2 Implement notification preferences
  - Create settings page for notification preferences
  - Allow channel selection (email, SMS, in-app)
  - Save preferences via API
  - _Requirements: 9.5_

- [ ]* 26.3 Write unit tests for notification UI
  - Test notification display
  - Test preference saving
  - Test unread count
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [ ] 27. Build Next.js frontend - Premium AI Features
- [ ] 27.1 Create AI customer service interface
  - Display buyer messages
  - Show AI-generated response suggestions
  - Allow vendor to send suggested or custom responses
  - _Requirements: 10.2_

- [ ] 27.2 Implement automated response configuration
  - Create settings for enabling automation
  - Configure which inquiries to auto-respond
  - Display conversation history with context
  - _Requirements: 10.3, 10.4_

- [ ] 27.3 Implement premium subscription UI
  - Show subscription status
  - Display premium features
  - Add upgrade/downgrade options
  - _Requirements: 10.1, 10.5_

- [ ]* 27.4 Write unit tests for AI features
  - Test message display
  - Test suggestion rendering
  - Test automation configuration
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 28. Implement mobile responsiveness
- [ ] 28.1 Make all pages mobile-responsive
  - Use Tailwind responsive utilities
  - Test on various screen sizes
  - Optimize touch interactions
  - Ensure functionality parity with desktop
  - _Requirements: 14.2_

- [ ]* 28.2 Write property test for API functionality parity
  - **Property 69: API functionality parity**
  - **Validates: Requirements 14.2**

- [ ] 29. Checkpoint - Integration testing
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 30. Implement end-to-end integration tests
- [ ] 30.1 Create end-to-end test suite
  - Set up test environment with test database
  - Create test data factories
  - _Requirements: All_

- [ ] 30.2 Test complete order flow
  - Register vendor
  - Add products with inventory
  - Receive order
  - Accept order
  - Process payment
  - Coordinate delivery
  - Complete delivery
  - Verify commission and payout
  - _Requirements: 1.1, 3.1, 4.1, 5.1, 5.3, 6.1, 7.1, 7.4_

- [ ] 30.3 Test multi-vendor scenario
  - Create multiple vendors
  - Add products from each
  - Place orders to different vendors
  - Verify independent processing
  - _Requirements: All vendor-related requirements_

- [ ] 30.4 Test error recovery scenarios
  - Simulate payment API failure
  - Verify retry and recovery
  - Simulate delivery API failure
  - Verify fallback handling
  - _Requirements: 15.1, 15.2, 15.3_

- [ ] 31. Performance optimization
- [ ] 31.1 Implement caching strategy
  - Cache product catalogs in Redis
  - Cache vendor profiles
  - Implement cache invalidation on updates
  - _Requirements: 13.1, 13.2_

- [ ] 31.2 Optimize database queries
  - Add appropriate indexes
  - Optimize N+1 queries
  - Implement query result caching
  - _Requirements: 13.5_

- [ ] 31.3 Implement CDN for static assets
  - Configure CloudFront or similar CDN
  - Serve images and static files from CDN
  - Implement cache headers
  - _Requirements: 13.1_

- [ ] 32. Final checkpoint - Comprehensive testing
  - Run all unit tests
  - Run all property-based tests
  - Run integration tests
  - Verify all requirements are met
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 33. Documentation and deployment preparation
- [ ] 33.1 Create API documentation
  - Document all API endpoints
  - Include request/response examples
  - Document authentication requirements
  - _Requirements: All_

- [ ] 33.2 Create deployment documentation
  - Document infrastructure requirements
  - Create deployment scripts
  - Document environment variables
  - Create monitoring and alerting setup guide
  - _Requirements: All_

- [ ] 33.3 Create user documentation
  - Write vendor onboarding guide
  - Document all platform features
  - Create troubleshooting guide
  - _Requirements: All_
