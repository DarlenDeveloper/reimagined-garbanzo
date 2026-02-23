# POP Rebranding Rules

## CRITICAL RULE: NEVER TOUCH BACKEND LOGIC

When rebranding screens, you must:

### ✅ ALLOWED CHANGES (UI/Frontend Only):
1. **Colors**: Change Colors.black → Color(0xFF1a1a1a), green → POP red (#fb2a0a)
2. **Styling**: Update button styles, borders, shadows, spacing
3. **Assets**: Replace logos, images with POP branded versions
4. **Fonts**: Ensure Poppins font is used consistently
5. **Animations**: Add or modify UI animations (fade, slide, etc.)
6. **Layout**: Adjust padding, margins, alignment for better UI
7. **Text**: Update copy to say "POP" instead of "Wibble/PURL"

### ❌ FORBIDDEN CHANGES (Backend/Logic):
1. **Navigation Flow**: NEVER change `context.go()`, `context.push()` routes
2. **API Calls**: NEVER modify service calls, Firebase operations
3. **State Management**: NEVER change controllers, state variables logic
4. **Validation Logic**: NEVER modify form validation rules
5. **Business Logic**: NEVER change conditions, calculations, data processing
6. **Authentication Flow**: NEVER modify signup/login sequences
7. **Data Models**: NEVER change how data is structured or saved

## Seller App Signup Flow (MUST PRESERVE):

```
Email Signup:
Signup Screen → Email/Password → sendEmailVerification() → /verify-email → /account-type → /store-setup → /dashboard

Google Signup:
Signup Screen → Google Auth → /account-type → /store-setup → /dashboard
```

## Example of Correct Rebranding:

### ❌ WRONG (Changes navigation):
```dart
// BEFORE
if (mounted) context.go('/verify-email');

// AFTER - WRONG!
if (mounted) context.go('/dashboard'); // ❌ Changed flow!
```

### ✅ CORRECT (Only changes UI):
```dart
// BEFORE
Container(
  decoration: BoxDecoration(color: Colors.black),
  child: Text('Sign Up'),
)

// AFTER - CORRECT!
Container(
  decoration: BoxDecoration(
    color: Color(0xFFb71000), // Only changed color
    borderRadius: BorderRadius.circular(26), // Only changed styling
  ),
  child: Text('Sign Up'), // Same text, same logic
)
```

## POP Brand Colors:
- **Main Red**: #fb2a0a (primary brand color, icons, accents, links)
- **Button Red**: #b71000 (buttons and CTAs only)
- **Dark Text**: #1a1a1a (readable text instead of pure black)
- **Background**: #F9F9F9 (card backgrounds)

## Verification Checklist Before Committing:
- [ ] No `context.go()` or `context.push()` routes were changed
- [ ] No service method calls were modified
- [ ] No Firebase operations were altered
- [ ] No validation logic was changed
- [ ] Only UI elements (colors, spacing, fonts) were updated
- [ ] All navigation flows remain identical to original
- [ ] Backend logic is completely untouched

## When in Doubt:
**If you're not sure if something is UI or backend → DON'T TOUCH IT!**

Ask the user first before making any changes to:
- Navigation routes
- Service calls
- State management
- Data processing
- Authentication flows
