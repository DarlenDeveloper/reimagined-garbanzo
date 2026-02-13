# Purl Platform - Transactional Email System

## Overview

This document covers the email infrastructure for Purl.

### Phase 1 (Launch): Firebase Auth Built-in
- Email verification → Firebase Auth (automatic)
- Password reset → Firebase Auth (automatic)
- No external provider needed

### Phase 2 (Later): Add SendGrid/Resend
- Order confirmations
- Payment receipts
- Order status updates
- RBAC invite codes
- Marketing emails

---

## Phase 1: Firebase Auth Emails (Current)

Firebase Auth handles verification and password reset automatically. Customize templates in:
**Firebase Console → Authentication → Templates**

### Email Verification (Flutter)
```dart
// Send verification email
await FirebaseAuth.instance.currentUser?.sendEmailVerification();

// Check if verified
if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
  // Proceed
}
```

### Password Reset (Flutter)
```dart
// Send reset email
await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
```

### Customize Templates (Firebase Console)
- Sender name: `Purl`
- Reply-to: `support@purl.co.ke`
- Subject and body text customizable
- Limited HTML support

---

## Phase 2: SendGrid Integration (Future)

When ready to add order emails, receipts, etc., implement the following:

---

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Cloud Function │────▶│  /mail collection │────▶│ Firebase Extension│
│  (trigger)      │     │  (Firestore)      │     │ (Trigger Email)   │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                                                          ▼
                                                 ┌─────────────────┐
                                                 │  SendGrid SMTP  │
                                                 │  (or Resend)    │
                                                 └────────┬────────┘
                                                          │
                                                          ▼
                                                 ┌─────────────────┐
                                                 │  User's Inbox   │
                                                 └─────────────────┘
```

---

## Setup Instructions

### Step 1: Create SendGrid Account

1. Go to [sendgrid.com](https://sendgrid.com) and create account
2. Verify your sender domain (for deliverability)
3. Create an API key with "Mail Send" permissions
4. Note your SMTP credentials:
   - Host: `smtp.sendgrid.net`
   - Port: `587` (TLS) or `465` (SSL)
   - Username: `apikey`
   - Password: `your_api_key`

### Step 2: Install Firebase Extension

```bash
# Install via CLI
firebase ext:install firebase/firestore-send-email --project=purl-platform-prod
```

Configuration prompts:

| Setting | Value |
|---------|-------|
| SMTP connection URI | `smtps://apikey:YOUR_API_KEY@smtp.sendgrid.net:465` |
| Email documents collection | `mail` |
| Default FROM address | `noreply@purl.co.ke` |
| Default Reply-To | `support@purl.co.ke` |
| Users collection (optional) | `users` |
| Templates collection | `emailTemplates` |

### Step 3: Configure Sender Authentication (Critical for Deliverability)

In SendGrid dashboard:
1. **Settings → Sender Authentication**
2. **Authenticate your domain** (e.g., `purl.co.ke`)
3. Add DNS records (SPF, DKIM, DMARC):

```dns
# SPF Record
TXT  @  "v=spf1 include:sendgrid.net ~all"

# DKIM Record (SendGrid provides this)
CNAME  s1._domainkey  s1.domainkey.u12345.wl.sendgrid.net

# DMARC Record
TXT  _dmarc  "v=DMARC1; p=quarantine; rua=mailto:dmarc@purl.co.ke"
```

---

## Firestore Collections

### Mail Collection (Outbox)

```
/mail/{mailId}
├── to: string | string[]           // Recipient(s)
├── cc: string[]?                   // CC recipients
├── bcc: string[]?                  // BCC recipients
├── from: string?                   // Override default FROM
├── replyTo: string?                // Reply-to address
├── message: map
│   ├── subject: string
│   ├── text: string                // Plain text version
│   └── html: string                // HTML version
├── template: map?                  // Use template instead of message
│   ├── name: string                // Template name
│   └── data: map                   // Template variables
├── headers: map?                   // Custom headers
├── delivery: map (auto-populated)
│   ├── state: 'PENDING' | 'PROCESSING' | 'SUCCESS' | 'ERROR'
│   ├── attempts: number
│   ├── startTime: timestamp
│   ├── endTime: timestamp
│   ├── error: string?
│   └── info: map                   // SendGrid response
└── createdAt: timestamp
```

### Email Templates Collection

```
/emailTemplates/{templateName}
├── subject: string                 // Subject with {{variables}}
├── html: string                    // HTML body with {{variables}}
├── text: string                    // Plain text fallback
├── attachments: array?             // Default attachments
└── updatedAt: timestamp
```

---

## Email Templates

### 1. Email Verification

**Template name:** `emailVerification`

```html
<!-- /emailTemplates/emailVerification -->
{
  "subject": "Verify your Purl account",
  "html": "
    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
      <div style='background: #6366f1; padding: 20px; text-align: center;'>
        <img src='https://purl.co.ke/logo-white.png' alt='Purl' height='40'>
      </div>
      <div style='padding: 30px; background: #ffffff;'>
        <h2 style='color: #1f2937;'>Welcome to Purl, {{displayName}}!</h2>
        <p style='color: #4b5563; line-height: 1.6;'>
          Thanks for signing up. Please verify your email address by entering this code:
        </p>
        <div style='background: #f3f4f6; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;'>
          <span style='font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #6366f1;'>{{verificationCode}}</span>
        </div>
        <p style='color: #6b7280; font-size: 14px;'>
          This code expires in 15 minutes. If you didn't create an account, ignore this email.
        </p>
      </div>
      <div style='padding: 20px; background: #f9fafb; text-align: center; color: #9ca3af; font-size: 12px;'>
        © 2026 Purl. All rights reserved.<br>
        Nairobi, Kenya
      </div>
    </div>
  ",
  "text": "Welcome to Purl, {{displayName}}!\n\nYour verification code is: {{verificationCode}}\n\nThis code expires in 15 minutes."
}
```

### 2. Password Reset

**Template name:** `passwordReset`

```html
{
  "subject": "Reset your Purl password",
  "html": "
    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
      <div style='background: #6366f1; padding: 20px; text-align: center;'>
        <img src='https://purl.co.ke/logo-white.png' alt='Purl' height='40'>
      </div>
      <div style='padding: 30px; background: #ffffff;'>
        <h2 style='color: #1f2937;'>Password Reset Request</h2>
        <p style='color: #4b5563; line-height: 1.6;'>
          Hi {{displayName}}, we received a request to reset your password. Use this code:
        </p>
        <div style='background: #fef2f2; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px; border: 1px solid #fecaca;'>
          <span style='font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #dc2626;'>{{resetCode}}</span>
        </div>
        <p style='color: #6b7280; font-size: 14px;'>
          This code expires in 15 minutes. If you didn't request this, please ignore this email or contact support if you're concerned.
        </p>
      </div>
      <div style='padding: 20px; background: #f9fafb; text-align: center; color: #9ca3af; font-size: 12px;'>
        © 2026 Purl. All rights reserved.
      </div>
    </div>
  ",
  "text": "Hi {{displayName}},\n\nYour password reset code is: {{resetCode}}\n\nThis code expires in 15 minutes."
}
```

### 3. Order Confirmation

**Template name:** `orderConfirmation`

```html
{
  "subject": "Order Confirmed - {{orderNumber}}",
  "html": "
    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
      <div style='background: #6366f1; padding: 20px; text-align: center;'>
        <img src='https://purl.co.ke/logo-white.png' alt='Purl' height='40'>
      </div>
      <div style='padding: 30px; background: #ffffff;'>
        <div style='text-align: center; margin-bottom: 20px;'>
          <span style='font-size: 48px;'>✓</span>
          <h2 style='color: #059669; margin: 10px 0;'>Order Confirmed!</h2>
        </div>
        <p style='color: #4b5563;'>Hi {{customerName}}, your order has been confirmed.</p>
        
        <div style='background: #f3f4f6; padding: 15px; border-radius: 8px; margin: 20px 0;'>
          <p style='margin: 0; color: #6b7280;'><strong>Order Number:</strong> {{orderNumber}}</p>
          <p style='margin: 5px 0 0; color: #6b7280;'><strong>Store:</strong> {{vendorName}}</p>
        </div>
        
        <h3 style='color: #1f2937; border-bottom: 1px solid #e5e7eb; padding-bottom: 10px;'>Order Summary</h3>
        {{#each items}}
        <div style='display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #f3f4f6;'>
          <span style='color: #4b5563;'>{{this.name}} × {{this.quantity}}</span>
          <span style='color: #1f2937; font-weight: 500;'>KES {{this.subtotal}}</span>
        </div>
        {{/each}}
        
        <div style='margin-top: 15px; text-align: right;'>
          <p style='color: #6b7280; margin: 5px 0;'>Subtotal: KES {{subtotal}}</p>
          <p style='color: #6b7280; margin: 5px 0;'>Delivery: KES {{deliveryFee}}</p>
          <p style='color: #1f2937; font-size: 18px; font-weight: bold; margin: 10px 0;'>Total: KES {{total}}</p>
        </div>
        
        <div style='background: #eff6ff; padding: 15px; border-radius: 8px; margin-top: 20px;'>
          <p style='margin: 0; color: #1e40af;'><strong>Delivery Address:</strong></p>
          <p style='margin: 5px 0 0; color: #3b82f6;'>{{deliveryAddress}}</p>
        </div>
      </div>
      <div style='padding: 20px; background: #f9fafb; text-align: center; color: #9ca3af; font-size: 12px;'>
        Track your order in the Purl app<br>
        © 2026 Purl. All rights reserved.
      </div>
    </div>
  ",
  "text": "Order Confirmed!\n\nOrder: {{orderNumber}}\nStore: {{vendorName}}\nTotal: KES {{total}}\n\nDelivery to: {{deliveryAddress}}"
}
```

### 4. Payment Receipt

**Template name:** `paymentReceipt`

```html
{
  "subject": "Payment Receipt - {{orderNumber}}",
  "html": "
    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
      <div style='background: #6366f1; padding: 20px; text-align: center;'>
        <img src='https://purl.co.ke/logo-white.png' alt='Purl' height='40'>
      </div>
      <div style='padding: 30px; background: #ffffff;'>
        <h2 style='color: #1f2937;'>Payment Receipt</h2>
        <p style='color: #4b5563;'>Thank you for your payment, {{customerName}}.</p>
        
        <table style='width: 100%; border-collapse: collapse; margin: 20px 0;'>
          <tr style='background: #f3f4f6;'>
            <td style='padding: 12px; color: #6b7280;'>Transaction ID</td>
            <td style='padding: 12px; color: #1f2937; font-weight: 500;'>{{transactionId}}</td>
          </tr>
          <tr>
            <td style='padding: 12px; color: #6b7280; border-bottom: 1px solid #e5e7eb;'>Order Number</td>
            <td style='padding: 12px; color: #1f2937; border-bottom: 1px solid #e5e7eb;'>{{orderNumber}}</td>
          </tr>
          <tr style='background: #f3f4f6;'>
            <td style='padding: 12px; color: #6b7280;'>Payment Method</td>
            <td style='padding: 12px; color: #1f2937;'>{{paymentMethod}}</td>
          </tr>
          <tr>
            <td style='padding: 12px; color: #6b7280; border-bottom: 1px solid #e5e7eb;'>Date</td>
            <td style='padding: 12px; color: #1f2937; border-bottom: 1px solid #e5e7eb;'>{{paymentDate}}</td>
          </tr>
          <tr style='background: #ecfdf5;'>
            <td style='padding: 12px; color: #059669; font-weight: bold;'>Amount Paid</td>
            <td style='padding: 12px; color: #059669; font-weight: bold; font-size: 18px;'>KES {{amount}}</td>
          </tr>
        </table>
        
        <p style='color: #6b7280; font-size: 14px;'>
          This receipt serves as confirmation of your payment. Keep it for your records.
        </p>
      </div>
      <div style='padding: 20px; background: #f9fafb; text-align: center; color: #9ca3af; font-size: 12px;'>
        Questions? Contact support@purl.co.ke<br>
        © 2026 Purl. All rights reserved.
      </div>
    </div>
  ",
  "text": "Payment Receipt\n\nTransaction: {{transactionId}}\nOrder: {{orderNumber}}\nAmount: KES {{amount}}\nMethod: {{paymentMethod}}\nDate: {{paymentDate}}"
}
```

### 5. RBAC Invite Code (Store Runner)

**Template name:** `storeInvite`

```html
{
  "subject": "You're invited to join {{storeName}} on Purl",
  "html": "
    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
      <div style='background: #6366f1; padding: 20px; text-align: center;'>
        <img src='https://purl.co.ke/logo-white.png' alt='Purl' height='40'>
      </div>
      <div style='padding: 30px; background: #ffffff;'>
        <h2 style='color: #1f2937;'>You're Invited! 🎉</h2>
        <p style='color: #4b5563; line-height: 1.6;'>
          <strong>{{inviterName}}</strong> has invited you to join <strong>{{storeName}}</strong> as a store team member on Purl.
        </p>
        
        <div style='background: #faf5ff; padding: 25px; text-align: center; margin: 25px 0; border-radius: 12px; border: 2px dashed #a855f7;'>
          <p style='color: #7c3aed; margin: 0 0 10px; font-size: 14px;'>Your Access Code</p>
          <span style='font-size: 40px; font-weight: bold; letter-spacing: 12px; color: #7c3aed;'>{{accessCode}}</span>
        </div>
        
        <div style='background: #fef3c7; padding: 15px; border-radius: 8px; margin: 20px 0;'>
          <p style='margin: 0; color: #92400e; font-size: 14px;'>
            ⏰ <strong>This code expires in 15 minutes.</strong> Enter it in the Purl Admin app to join the team.
          </p>
        </div>
        
        <h3 style='color: #1f2937;'>How to Join:</h3>
        <ol style='color: #4b5563; line-height: 1.8;'>
          <li>Download the <strong>Purl Admin</strong> app</li>
          <li>Create an account or log in</li>
          <li>Tap "Join as Store Runner"</li>
          <li>Enter the 4-digit code above</li>
        </ol>
      </div>
      <div style='padding: 20px; background: #f9fafb; text-align: center; color: #9ca3af; font-size: 12px;'>
        © 2026 Purl. All rights reserved.
      </div>
    </div>
  ",
  "text": "You're invited to join {{storeName}} on Purl!\n\nAccess Code: {{accessCode}}\n\nThis code expires in 15 minutes.\n\n1. Download Purl Admin app\n2. Log in or create account\n3. Tap 'Join as Store Runner'\n4. Enter the code"
}
```

### 6. Order Status Update

**Template name:** `orderStatusUpdate`

```html
{
  "subject": "Order Update - {{orderNumber}} is {{status}}",
  "html": "
    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
      <div style='background: #6366f1; padding: 20px; text-align: center;'>
        <img src='https://purl.co.ke/logo-white.png' alt='Purl' height='40'>
      </div>
      <div style='padding: 30px; background: #ffffff;'>
        <div style='text-align: center; margin-bottom: 20px;'>
          <span style='font-size: 48px;'>{{statusEmoji}}</span>
          <h2 style='color: #1f2937; margin: 10px 0;'>{{statusTitle}}</h2>
        </div>
        
        <p style='color: #4b5563; text-align: center;'>{{statusMessage}}</p>
        
        <div style='background: #f3f4f6; padding: 15px; border-radius: 8px; margin: 20px 0; text-align: center;'>
          <p style='margin: 0; color: #6b7280;'>Order Number</p>
          <p style='margin: 5px 0 0; color: #1f2937; font-size: 18px; font-weight: bold;'>{{orderNumber}}</p>
        </div>
        
        {{#if trackingUrl}}
        <div style='text-align: center; margin: 25px 0;'>
          <a href='{{trackingUrl}}' style='background: #6366f1; color: white; padding: 12px 30px; border-radius: 8px; text-decoration: none; font-weight: 500;'>
            Track Delivery
          </a>
        </div>
        {{/if}}
      </div>
      <div style='padding: 20px; background: #f9fafb; text-align: center; color: #9ca3af; font-size: 12px;'>
        © 2026 Purl. All rights reserved.
      </div>
    </div>
  ",
  "text": "{{statusTitle}}\n\nOrder: {{orderNumber}}\n{{statusMessage}}\n\n{{#if trackingUrl}}Track: {{trackingUrl}}{{/if}}"
}
```

### 7. Welcome Email

**Template name:** `welcome`

```html
{
  "subject": "Welcome to Purl! 🛍️",
  "html": "
    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
      <div style='background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); padding: 40px 20px; text-align: center;'>
        <img src='https://purl.co.ke/logo-white.png' alt='Purl' height='50'>
        <h1 style='color: white; margin: 20px 0 0;'>Welcome to Purl!</h1>
      </div>
      <div style='padding: 30px; background: #ffffff;'>
        <p style='color: #4b5563; font-size: 16px; line-height: 1.6;'>
          Hi {{displayName}}, 👋
        </p>
        <p style='color: #4b5563; line-height: 1.6;'>
          Welcome to Purl — your new favorite way to discover and shop from local stores. We're excited to have you!
        </p>
        
        <h3 style='color: #1f2937; margin-top: 25px;'>Here's what you can do:</h3>
        <ul style='color: #4b5563; line-height: 2;'>
          <li>🏪 Discover amazing local stores</li>
          <li>📱 Follow your favorites for updates</li>
          <li>🛒 Shop and checkout seamlessly</li>
          <li>🚚 Track deliveries in real-time</li>
          <li>💬 Chat directly with sellers</li>
        </ul>
        
        <div style='text-align: center; margin: 30px 0;'>
          <a href='https://purl.co.ke/app' style='background: #6366f1; color: white; padding: 14px 35px; border-radius: 8px; text-decoration: none; font-weight: 500;'>
            Start Shopping
          </a>
        </div>
      </div>
      <div style='padding: 20px; background: #f9fafb; text-align: center; color: #9ca3af; font-size: 12px;'>
        Follow us: Instagram | Twitter | Facebook<br>
        © 2026 Purl. All rights reserved.
      </div>
    </div>
  ",
  "text": "Welcome to Purl, {{displayName}}!\n\nWe're excited to have you. Start discovering amazing local stores and shop seamlessly.\n\nHappy shopping!"
}
```

---

## Cloud Functions - Email Triggers

### Email Verification Code

```typescript
// functions/src/email/sendVerificationEmail.ts
import * as functions from 'firebase-functions';
import { FieldValue } from 'firebase-admin/firestore';

export const sendVerificationEmail = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  
  const { email } = data;
  
  // Generate 6-digit code
  const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
  
  // Store code with expiry (15 minutes)
  await db.collection('verificationCodes').doc(userId).set({
    code: verificationCode,
    email: email,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + 15 * 60 * 1000),
    attempts: 0
  });
  
  // Get user display name
  const user = await db.collection('users').doc(userId).get();
  const displayName = user.data()?.displayName || 'there';
  
  // Queue email
  await db.collection('mail').add({
    to: email,
    template: {
      name: 'emailVerification',
      data: {
        displayName,
        verificationCode
      }
    },
    createdAt: FieldValue.serverTimestamp()
  });
  
  return { success: true, message: 'Verification email sent' };
});

// Verify the code
export const verifyEmailCode = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  
  const { code } = data;
  
  const verificationDoc = await db.collection('verificationCodes').doc(userId).get();
  
  if (!verificationDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'No verification code found');
  }
  
  const verificationData = verificationDoc.data()!;
  
  // Check expiry
  if (verificationData.expiresAt.toDate() < new Date()) {
    throw new functions.https.HttpsError('deadline-exceeded', 'Code expired');
  }
  
  // Check attempts (max 5)
  if (verificationData.attempts >= 5) {
    throw new functions.https.HttpsError('resource-exhausted', 'Too many attempts');
  }
  
  // Increment attempts
  await verificationDoc.ref.update({ attempts: FieldValue.increment(1) });
  
  // Verify code
  if (verificationData.code !== code) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid code');
  }
  
  // Mark email as verified
  await db.collection('users').doc(userId).update({
    emailVerified: true,
    emailVerifiedAt: FieldValue.serverTimestamp()
  });
  
  // Delete verification doc
  await verificationDoc.ref.delete();
  
  return { success: true, message: 'Email verified' };
});
```

### Password Reset

```typescript
// functions/src/email/sendPasswordReset.ts
export const sendPasswordResetEmail = functions.https.onCall(async (data) => {
  const { email } = data;
  
  // Find user by email
  const usersSnapshot = await db.collection('users')
    .where('email', '==', email.toLowerCase())
    .limit(1)
    .get();
  
  if (usersSnapshot.empty) {
    // Don't reveal if email exists - security best practice
    return { success: true, message: 'If email exists, reset code sent' };
  }
  
  const userId = usersSnapshot.docs[0].id;
  const displayName = usersSnapshot.docs[0].data().displayName || 'there';
  
  // Generate 6-digit code
  const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
  
  // Store reset code
  await db.collection('passwordResets').doc(userId).set({
    code: resetCode,
    email: email.toLowerCase(),
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + 15 * 60 * 1000),
    attempts: 0,
    used: false
  });
  
  // Queue email
  await db.collection('mail').add({
    to: email,
    template: {
      name: 'passwordReset',
      data: {
        displayName,
        resetCode
      }
    },
    createdAt: FieldValue.serverTimestamp()
  });
  
  return { success: true, message: 'If email exists, reset code sent' };
});
```

### Order Confirmation Email

```typescript
// functions/src/email/sendOrderConfirmation.ts
export const onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snapshot, context) => {
    const order = snapshot.data();
    
    // Get buyer email
    const buyer = await db.collection('users').doc(order.buyerId).get();
    const buyerEmail = buyer.data()?.email;
    
    if (!buyerEmail) return;
    
    // Format items for template
    const items = order.items.map((item: any) => ({
      name: item.name,
      quantity: item.quantity,
      subtotal: (item.price * item.quantity).toLocaleString()
    }));
    
    // Queue email
    await db.collection('mail').add({
      to: buyerEmail,
      template: {
        name: 'orderConfirmation',
        data: {
          customerName: order.buyerName,
          orderNumber: order.orderNumber,
          vendorName: order.vendorName,
          items,
          subtotal: order.subtotal.toLocaleString(),
          deliveryFee: order.deliveryFee.toLocaleString(),
          total: order.total.toLocaleString(),
          deliveryAddress: `${order.deliveryAddress.street}, ${order.deliveryAddress.city}`
        }
      },
      createdAt: FieldValue.serverTimestamp()
    });
  });
```

### Payment Receipt Email

```typescript
// functions/src/email/sendPaymentReceipt.ts
export const onPaymentCompleted = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Only send when payment status changes to completed
    if (before.paymentStatus !== 'completed' && after.paymentStatus === 'completed') {
      const buyer = await db.collection('users').doc(after.buyerId).get();
      const buyerEmail = buyer.data()?.email;
      
      if (!buyerEmail) return;
      
      await db.collection('mail').add({
        to: buyerEmail,
        template: {
          name: 'paymentReceipt',
          data: {
            customerName: after.buyerName,
            transactionId: after.pesapalTransactionId || context.params.orderId,
            orderNumber: after.orderNumber,
            paymentMethod: after.paymentMethod || 'Mobile Money',
            paymentDate: new Date().toLocaleDateString('en-KE', {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
              hour: '2-digit',
              minute: '2-digit'
            }),
            amount: after.total.toLocaleString()
          }
        },
        createdAt: FieldValue.serverTimestamp()
      });
    }
  });
```

### Order Status Update Email

```typescript
// functions/src/email/sendOrderStatusUpdate.ts
const STATUS_CONFIG: Record<string, { emoji: string; title: string; message: string }> = {
  accepted: {
    emoji: '👍',
    title: 'Order Accepted',
    message: 'Great news! The store has accepted your order and is preparing it.'
  },
  processing: {
    emoji: '👨‍🍳',
    title: 'Order Being Prepared',
    message: 'Your order is being prepared with care.'
  },
  ready: {
    emoji: '📦',
    title: 'Ready for Pickup',
    message: 'Your order is packed and ready! A rider will pick it up soon.'
  },
  picked_up: {
    emoji: '🚴',
    title: 'Order Picked Up',
    message: 'A rider has picked up your order and is on the way!'
  },
  delivered: {
    emoji: '✅',
    title: 'Order Delivered',
    message: 'Your order has been delivered. Enjoy!'
  },
  cancelled: {
    emoji: '❌',
    title: 'Order Cancelled',
    message: 'Your order has been cancelled. If you paid, a refund will be processed.'
  }
};

export const onOrderStatusChange = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Only send if status changed
    if (before.status === after.status) return;
    
    const statusConfig = STATUS_CONFIG[after.status];
    if (!statusConfig) return;
    
    const buyer = await db.collection('users').doc(after.buyerId).get();
    const buyerEmail = buyer.data()?.email;
    
    if (!buyerEmail) return;
    
    await db.collection('mail').add({
      to: buyerEmail,
      template: {
        name: 'orderStatusUpdate',
        data: {
          orderNumber: after.orderNumber,
          status: after.status,
          statusEmoji: statusConfig.emoji,
          statusTitle: statusConfig.title,
          statusMessage: statusConfig.message,
          trackingUrl: after.uberTrackingUrl || null
        }
      },
      createdAt: FieldValue.serverTimestamp()
    });
  });
```

### RBAC Invite Email

```typescript
// functions/src/email/sendStoreInvite.ts
export const sendStoreInviteEmail = async (
  email: string,
  accessCode: string,
  storeName: string,
  inviterName: string
) => {
  await db.collection('mail').add({
    to: email,
    template: {
      name: 'storeInvite',
      data: {
        storeName,
        inviterName,
        accessCode
      }
    },
    createdAt: FieldValue.serverTimestamp()
  });
};

// Called from generateAccessCode function in RBAC
// After generating the code, send email:
// await sendStoreInviteEmail(email, code, vendorData.storeName, adminData.displayName);
```

### Welcome Email (After First Login)

```typescript
// functions/src/email/sendWelcomeEmail.ts
export const onUserCreated = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snapshot, context) => {
    const user = snapshot.data();
    
    if (!user.email) return;
    
    // Only send to buyers (vendors get different onboarding)
    if (user.userType !== 'buyer') return;
    
    await db.collection('mail').add({
      to: user.email,
      template: {
        name: 'welcome',
        data: {
          displayName: user.displayName || 'there'
        }
      },
      createdAt: FieldValue.serverTimestamp()
    });
  });
```

---

## Firestore Security Rules for Email

```javascript
// Only Cloud Functions can write to mail collection
match /mail/{mailId} {
  allow read: if false;  // No client reads
  allow write: if false; // Only Cloud Functions via Admin SDK
}

// Templates readable by admins only
match /emailTemplates/{templateId} {
  allow read: if false;  // Only Cloud Functions
  allow write: if false; // Manual updates or admin panel
}

// Verification codes - no client access
match /verificationCodes/{docId} {
  allow read, write: if false;
}

// Password resets - no client access
match /passwordResets/{docId} {
  allow read, write: if false;
}
```

---

## Monitoring & Debugging

### Check Email Delivery Status

```typescript
// Query mail collection for failed emails
const failedEmails = await db.collection('mail')
  .where('delivery.state', '==', 'ERROR')
  .orderBy('createdAt', 'desc')
  .limit(50)
  .get();

failedEmails.docs.forEach(doc => {
  console.log('Failed email:', doc.id, doc.data().delivery.error);
});
```

### Email Analytics Dashboard Query

```typescript
// Get email stats for last 7 days
const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

const stats = {
  sent: 0,
  delivered: 0,
  failed: 0
};

const emails = await db.collection('mail')
  .where('createdAt', '>=', sevenDaysAgo)
  .get();

emails.docs.forEach(doc => {
  const state = doc.data().delivery?.state;
  if (state === 'SUCCESS') stats.delivered++;
  else if (state === 'ERROR') stats.failed++;
  stats.sent++;
});
```

---

## Rate Limits & Best Practices

### SendGrid Limits

| Plan | Emails/Day | Emails/Month |
|------|------------|--------------|
| Free | 100 | 100 |
| Essentials | 100K | 100K |
| Pro | 1.5M | Unlimited |

### Best Practices

1. **Always include plain text version** — improves deliverability
2. **Use consistent FROM address** — builds sender reputation
3. **Include unsubscribe link** for marketing emails (CAN-SPAM compliance)
4. **Monitor bounce rates** — remove invalid emails
5. **Don't send too fast** — spread bulk sends over time
6. **Test templates** before deploying

---

## Implementation Checklist

- [ ] Create SendGrid account and verify domain
- [ ] Add DNS records (SPF, DKIM, DMARC)
- [ ] Install Firebase Trigger Email extension
- [ ] Create email templates in Firestore
- [ ] Implement verification code functions
- [ ] Implement password reset functions
- [ ] Add order confirmation trigger
- [ ] Add payment receipt trigger
- [ ] Add order status update trigger
- [ ] Add RBAC invite email
- [ ] Add welcome email
- [ ] Test all email flows
- [ ] Set up monitoring for failed emails
