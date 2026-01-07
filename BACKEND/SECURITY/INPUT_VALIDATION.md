# Input Validation

## Principles

1. **Validate on client AND server** — client for UX, server for security
2. **Whitelist, don't blacklist** — define what's allowed, reject everything else
3. **Sanitize before storage** — clean data before writing to database
4. **Escape before display** — prevent XSS when rendering user content

---

## Validation Rules by Field Type

### Text Fields

| Field Type | Min | Max | Pattern | Sanitization |
|------------|-----|-----|---------|--------------|
| Display name | 1 | 100 | `^[\w\s\-'\.]+$` | Trim, normalize whitespace |
| Store name | 2 | 100 | `^[\w\s\-'\.&]+$` | Trim, normalize whitespace |
| Email | 5 | 254 | RFC 5322 | Lowercase, trim |
| Phone | 7 | 20 | `^\+?[\d\s\-\(\)]+$` | Remove non-digits except + |
| Product name | 1 | 200 | Any printable | Trim, strip HTML |
| Product description | 0 | 5000 | Any printable | Strip dangerous HTML |
| Address | 5 | 500 | Any printable | Trim |
| Message | 1 | 5000 | Any printable | Strip dangerous HTML |
| URL | 10 | 2000 | Valid URL | Validate protocol (https only) |

### Numeric Fields

| Field Type | Min | Max | Precision |
|------------|-----|-----|-----------|
| Price | 0 | 999999999 | 2 decimals |
| Quantity | 0 | 999999 | Integer |
| Discount % | 0 | 100 | 2 decimals |
| Rating | 1 | 5 | 1 decimal |
| Latitude | -90 | 90 | 6 decimals |
| Longitude | -180 | 180 | 6 decimals |

---

## Client-Side Validation (Flutter)

```dart
// lib/utils/validators.dart

class Validators {
  // Email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    value = value.trim().toLowerCase();
    if (value.length > 254) {
      return 'Email is too long';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }
  
  // Phone
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length < 7 || cleaned.length > 20) {
      return 'Enter a valid phone number';
    }
    return null;
  }
  
  // Display name
  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 1 || value.trim().length > 100) {
      return 'Name must be 1-100 characters';
    }
    final nameRegex = RegExp(r"^[\w\s\-'\.]+$", unicode: true);
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name contains invalid characters';
    }
    return null;
  }
  
  // Store name
  static String? storeName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Store name is required';
    }
    if (value.trim().length < 2 || value.trim().length > 100) {
      return 'Store name must be 2-100 characters';
    }
    return null;
  }
  
  // Price
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'Enter a valid price';
    }
    if (price < 0) {
      return 'Price cannot be negative';
    }
    if (price > 999999999) {
      return 'Price is too high';
    }
    return null;
  }
  
  // Quantity
  static String? quantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    final qty = int.tryParse(value);
    if (qty == null) {
      return 'Enter a valid number';
    }
    if (qty < 0) {
      return 'Quantity cannot be negative';
    }
    if (qty > 999999) {
      return 'Quantity is too high';
    }
    return null;
  }
  
  // URL
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    try {
      final uri = Uri.parse(value);
      if (!uri.isAbsolute || !['http', 'https'].contains(uri.scheme)) {
        return 'Enter a valid URL';
      }
    } catch (_) {
      return 'Enter a valid URL';
    }
    return null;
  }
  
  // Generic text with length limits
  static String? text(String? value, {
    required String fieldName,
    int minLength = 0,
    int maxLength = 1000,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$fieldName is required' : null;
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (value.trim().length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    return null;
  }
}
```

### Form Usage

```dart
// In a form
TextFormField(
  controller: _emailController,
  validator: Validators.email,
  decoration: InputDecoration(labelText: 'Email'),
),

TextFormField(
  controller: _priceController,
  validator: Validators.price,
  keyboardType: TextInputType.numberWithOptions(decimal: true),
  decoration: InputDecoration(labelText: 'Price'),
),
```

---

## Server-Side Validation (Cloud Functions)

```typescript
// functions/src/utils/validators.ts

export class Validators {
  static email(value: unknown): string {
    if (typeof value !== 'string') {
      throw new ValidationError('Email must be a string');
    }
    const email = value.trim().toLowerCase();
    if (email.length < 5 || email.length > 254) {
      throw new ValidationError('Invalid email length');
    }
    const emailRegex = /^[\w.\-]+@[\w.\-]+\.\w{2,}$/;
    if (!emailRegex.test(email)) {
      throw new ValidationError('Invalid email format');
    }
    return email;
  }
  
  static string(
    value: unknown,
    fieldName: string,
    options: { minLength?: number; maxLength?: number; required?: boolean } = {}
  ): string {
    const { minLength = 0, maxLength = 1000, required = true } = options;
    
    if (value === undefined || value === null || value === '') {
      if (required) {
        throw new ValidationError(`${fieldName} is required`);
      }
      return '';
    }
    
    if (typeof value !== 'string') {
      throw new ValidationError(`${fieldName} must be a string`);
    }
    
    const trimmed = value.trim();
    if (trimmed.length < minLength) {
      throw new ValidationError(`${fieldName} must be at least ${minLength} characters`);
    }
    if (trimmed.length > maxLength) {
      throw new ValidationError(`${fieldName} must be less than ${maxLength} characters`);
    }
    
    return trimmed;
  }
  
  static number(
    value: unknown,
    fieldName: string,
    options: { min?: number; max?: number; integer?: boolean } = {}
  ): number {
    const { min = -Infinity, max = Infinity, integer = false } = options;
    
    if (typeof value !== 'number' || isNaN(value)) {
      throw new ValidationError(`${fieldName} must be a number`);
    }
    
    if (integer && !Number.isInteger(value)) {
      throw new ValidationError(`${fieldName} must be an integer`);
    }
    
    if (value < min) {
      throw new ValidationError(`${fieldName} must be at least ${min}`);
    }
    if (value > max) {
      throw new ValidationError(`${fieldName} must be at most ${max}`);
    }
    
    return value;
  }
  
  static price(value: unknown): number {
    const price = this.number(value, 'Price', { min: 0, max: 999999999 });
    // Round to 2 decimal places
    return Math.round(price * 100) / 100;
  }
  
  static enum<T extends string>(value: unknown, fieldName: string, allowedValues: T[]): T {
    if (typeof value !== 'string' || !allowedValues.includes(value as T)) {
      throw new ValidationError(`${fieldName} must be one of: ${allowedValues.join(', ')}`);
    }
    return value as T;
  }
  
  static array<T>(
    value: unknown,
    fieldName: string,
    itemValidator: (item: unknown) => T,
    options: { minLength?: number; maxLength?: number } = {}
  ): T[] {
    const { minLength = 0, maxLength = 100 } = options;
    
    if (!Array.isArray(value)) {
      throw new ValidationError(`${fieldName} must be an array`);
    }
    
    if (value.length < minLength) {
      throw new ValidationError(`${fieldName} must have at least ${minLength} items`);
    }
    if (value.length > maxLength) {
      throw new ValidationError(`${fieldName} must have at most ${maxLength} items`);
    }
    
    return value.map((item, index) => {
      try {
        return itemValidator(item);
      } catch (error) {
        throw new ValidationError(`${fieldName}[${index}]: ${error.message}`);
      }
    });
  }
}

export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}
```

### Usage in Cloud Functions

```typescript
// functions/src/products/createProduct.ts
import { Validators, ValidationError } from '../utils/validators';

export const createProduct = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Not authenticated');
  }
  
  try {
    // Validate all inputs
    const product = {
      name: Validators.string(data.name, 'Product name', { minLength: 1, maxLength: 200 }),
      description: Validators.string(data.description, 'Description', { required: false, maxLength: 5000 }),
      price: Validators.price(data.price),
      stock: Validators.number(data.stock, 'Stock', { min: 0, max: 999999, integer: true }),
      category: Validators.string(data.category, 'Category', { maxLength: 100 }),
      status: Validators.enum(data.status, 'Status', ['active', 'draft', 'archived']),
      tags: Validators.array(data.tags || [], 'Tags', 
        (tag) => Validators.string(tag, 'Tag', { maxLength: 50 }),
        { maxLength: 20 }
      ),
    };
    
    // Sanitize text fields
    product.name = sanitizeText(product.name);
    product.description = sanitizeHtml(product.description);
    
    // Save to Firestore...
    
  } catch (error) {
    if (error instanceof ValidationError) {
      throw new functions.https.HttpsError('invalid-argument', error.message);
    }
    throw error;
  }
});
```

---

## Sanitization

### Text Sanitization

```typescript
// functions/src/utils/sanitize.ts

// Remove control characters and normalize whitespace
export function sanitizeText(text: string): string {
  return text
    .replace(/[\x00-\x1F\x7F]/g, '') // Remove control characters
    .replace(/\s+/g, ' ')            // Normalize whitespace
    .trim();
}

// Strip all HTML tags
export function stripHtml(text: string): string {
  return text.replace(/<[^>]*>/g, '');
}

// Allow safe HTML (for rich text fields)
import sanitizeHtml from 'sanitize-html';

export function sanitizeRichText(html: string): string {
  return sanitizeHtml(html, {
    allowedTags: ['b', 'i', 'em', 'strong', 'p', 'br', 'ul', 'ol', 'li', 'a'],
    allowedAttributes: {
      'a': ['href', 'target'],
    },
    allowedSchemes: ['https'],
    transformTags: {
      'a': (tagName, attribs) => ({
        tagName,
        attribs: {
          ...attribs,
          target: '_blank',
          rel: 'noopener noreferrer',
        },
      }),
    },
  });
}

// Sanitize filename
export function sanitizeFilename(filename: string): string {
  return filename
    .replace(/[^a-zA-Z0-9.\-_]/g, '_')
    .replace(/\.{2,}/g, '.')
    .substring(0, 255);
}
```

---

## SQL/NoSQL Injection Prevention

Firestore is generally safe from injection, but still validate:

```typescript
// NEVER do this
const query = db.collection('products').where('name', '==', userInput);

// ALWAYS validate first
const safeName = Validators.string(userInput, 'Search term', { maxLength: 200 });
const query = db.collection('products').where('name', '==', safeName);
```

### Path Traversal Prevention

```typescript
// Validate document IDs
export function validateDocumentId(id: unknown): string {
  if (typeof id !== 'string') {
    throw new ValidationError('Invalid document ID');
  }
  
  // Firestore document IDs cannot contain /
  if (id.includes('/') || id.includes('..')) {
    throw new ValidationError('Invalid document ID');
  }
  
  if (id.length === 0 || id.length > 1500) {
    throw new ValidationError('Invalid document ID length');
  }
  
  return id;
}

// Usage
const productId = validateDocumentId(data.productId);
const productRef = db.collection('vendors').doc(vendorId).collection('products').doc(productId);
```

---

## File Upload Validation

```typescript
// functions/src/utils/fileValidation.ts

const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB

export function validateImageUpload(file: {
  contentType: string;
  size: number;
  name: string;
}): void {
  // Check content type
  if (!ALLOWED_IMAGE_TYPES.includes(file.contentType)) {
    throw new ValidationError(`Invalid file type. Allowed: ${ALLOWED_IMAGE_TYPES.join(', ')}`);
  }
  
  // Check size
  if (file.size > MAX_IMAGE_SIZE) {
    throw new ValidationError(`File too large. Maximum size: ${MAX_IMAGE_SIZE / 1024 / 1024}MB`);
  }
  
  // Check extension matches content type
  const ext = file.name.split('.').pop()?.toLowerCase();
  const expectedExts: Record<string, string[]> = {
    'image/jpeg': ['jpg', 'jpeg'],
    'image/png': ['png'],
    'image/webp': ['webp'],
    'image/gif': ['gif'],
  };
  
  if (!ext || !expectedExts[file.contentType]?.includes(ext)) {
    throw new ValidationError('File extension does not match content type');
  }
}
```

---

## Validation Error Responses

```typescript
// Consistent error format
interface ValidationErrorResponse {
  code: 'invalid-argument';
  message: string;
  details?: {
    field: string;
    error: string;
  }[];
}

// Example response
{
  "code": "invalid-argument",
  "message": "Validation failed",
  "details": [
    { "field": "price", "error": "Price must be a positive number" },
    { "field": "name", "error": "Name is required" }
  ]
}
```
