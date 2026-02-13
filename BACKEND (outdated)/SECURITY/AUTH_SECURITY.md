# Authentication Security

## Password Requirements

| Requirement | Value |
|-------------|-------|
| Minimum length | 8 characters |
| Uppercase | At least 1 |
| Lowercase | At least 1 |
| Number | At least 1 |
| Special character | Recommended, not required |
| Max length | 128 characters |
| Common passwords | Blocked (top 10,000 list) |

### Client-Side Validation

```dart
// lib/utils/validators.dart
class PasswordValidator {
  static const int minLength = 8;
  static const int maxLength = 128;
  
  static ValidationResult validate(String password) {
    final errors = <String>[];
    
    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters');
    }
    if (password.length > maxLength) {
      errors.add('Password must be less than $maxLength characters');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain an uppercase letter');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain a lowercase letter');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain a number');
    }
    
    // Check common passwords
    if (_commonPasswords.contains(password.toLowerCase())) {
      errors.add('This password is too common');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      strength: _calculateStrength(password),
    );
  }
  
  static PasswordStrength _calculateStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
  
  static const _commonPasswords = [
    'password', '123456', '12345678', 'qwerty', 'abc123',
    'password1', '111111', '1234567', 'iloveyou', 'adobe123',
    // ... top 10,000 list
  ];
}

enum PasswordStrength { weak, medium, strong }

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final PasswordStrength strength;
  
  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.strength,
  });
}
```

---

## Account Lockout

### Policy

| Trigger | Action | Duration |
|---------|--------|----------|
| 5 failed logins | Lock account | 30 minutes |
| 10 failed logins | Lock account | 2 hours |
| 20 failed logins | Lock account | 24 hours + email alert |
| Suspicious activity | Lock account | Until manual review |

### Implementation

```typescript
// functions/src/auth/accountLockout.ts
export async function handleFailedLogin(email: string, ip: string): Promise<void> {
  const db = admin.firestore();
  const userRef = db.collection('_authSecurity').doc(email.toLowerCase());
  
  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(userRef);
    const data = doc.data() || { failedAttempts: 0, attempts: [] };
    
    const newAttempts = data.failedAttempts + 1;
    const attempt = { timestamp: Date.now(), ip, success: false };
    
    let lockDuration = 0;
    let alertLevel = 'none';
    
    if (newAttempts >= 20) {
      lockDuration = 24 * 60 * 60 * 1000; // 24 hours
      alertLevel = 'critical';
    } else if (newAttempts >= 10) {
      lockDuration = 2 * 60 * 60 * 1000; // 2 hours
      alertLevel = 'warning';
    } else if (newAttempts >= 5) {
      lockDuration = 30 * 60 * 1000; // 30 minutes
      alertLevel = 'info';
    }
    
    transaction.set(userRef, {
      failedAttempts: newAttempts,
      attempts: [...(data.attempts || []).slice(-50), attempt], // Keep last 50
      lockedUntil: lockDuration ? Date.now() + lockDuration : null,
      lastFailedAt: Date.now(),
    }, { merge: true });
    
    // Send alerts
    if (alertLevel !== 'none') {
      await sendSecurityAlert(email, alertLevel, newAttempts);
    }
    
    // Email user about lockout
    if (lockDuration > 0) {
      await sendLockoutEmail(email, lockDuration);
    }
  });
}

export async function handleSuccessfulLogin(email: string): Promise<void> {
  const db = admin.firestore();
  await db.collection('_authSecurity').doc(email.toLowerCase()).set({
    failedAttempts: 0,
    lockedUntil: null,
    lastSuccessAt: Date.now(),
  }, { merge: true });
}

export async function isAccountLocked(email: string): Promise<{
  locked: boolean;
  lockedUntil?: number;
  reason?: string;
}> {
  const db = admin.firestore();
  const doc = await db.collection('_authSecurity').doc(email.toLowerCase()).get();
  const data = doc.data();
  
  if (!data?.lockedUntil) {
    return { locked: false };
  }
  
  if (data.lockedUntil > Date.now()) {
    return {
      locked: true,
      lockedUntil: data.lockedUntil,
      reason: 'Too many failed login attempts',
    };
  }
  
  return { locked: false };
}
```

---

## Session Management

### Session Timeout

```dart
// lib/services/session_service.dart
class SessionService {
  static const Duration inactivityTimeout = Duration(minutes: 30);
  Timer? _inactivityTimer;
  DateTime? _lastActivity;
  
  void startMonitoring() {
    _lastActivity = DateTime.now();
    _resetTimer();
    
    // Listen to user activity
    // Touch events, keyboard, etc.
  }
  
  void recordActivity() {
    _lastActivity = DateTime.now();
    _resetTimer();
  }
  
  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, _onTimeout);
  }
  
  void _onTimeout() {
    // Show warning dialog
    _showTimeoutWarning();
  }
  
  Future<void> _showTimeoutWarning() async {
    // Give user 60 seconds to respond
    final shouldExtend = await showDialog<bool>(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => SessionTimeoutDialog(
        onExtend: () => Navigator.pop(context, true),
        onLogout: () => Navigator.pop(context, false),
      ),
    );
    
    if (shouldExtend == true) {
      recordActivity();
    } else {
      await signOut();
    }
  }
  
  Future<void> signOut() async {
    _inactivityTimer?.cancel();
    await FirebaseAuth.instance.signOut();
    // Navigate to login
  }
}
```

### Multi-Device Session Management

```typescript
// functions/src/auth/sessionManagement.ts
export async function registerDevice(
  userId: string,
  deviceInfo: DeviceInfo
): Promise<string> {
  const db = admin.firestore();
  const sessionId = generateSecureToken();
  
  await db.collection('users').doc(userId).collection('sessions').doc(sessionId).set({
    id: sessionId,
    deviceId: deviceInfo.deviceId,
    deviceName: deviceInfo.deviceName,
    platform: deviceInfo.platform,
    fcmToken: deviceInfo.fcmToken,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
    ip: deviceInfo.ip,
    userAgent: deviceInfo.userAgent,
  });
  
  return sessionId;
}

export async function revokeSession(
  userId: string,
  sessionId: string
): Promise<void> {
  const db = admin.firestore();
  await db.collection('users').doc(userId).collection('sessions').doc(sessionId).delete();
  
  // Optionally revoke Firebase Auth refresh tokens
  // await admin.auth().revokeRefreshTokens(userId);
}

export async function revokeAllSessions(userId: string): Promise<void> {
  const db = admin.firestore();
  const sessions = await db.collection('users').doc(userId).collection('sessions').get();
  
  const batch = db.batch();
  sessions.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  
  // Revoke Firebase Auth tokens
  await admin.auth().revokeRefreshTokens(userId);
}
```

---

## Re-authentication for Sensitive Actions

```dart
// lib/services/auth_service.dart
class AuthService {
  Future<bool> reauthenticate(String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return false;
      
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }
  
  Future<void> changePassword(String currentPassword, String newPassword) async {
    // Require re-authentication
    final reauthed = await reauthenticate(currentPassword);
    if (!reauthed) {
      throw AuthException('Current password is incorrect');
    }
    
    // Validate new password
    final validation = PasswordValidator.validate(newPassword);
    if (!validation.isValid) {
      throw AuthException(validation.errors.first);
    }
    
    await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
  }
  
  Future<void> deleteAccount(String password) async {
    // Require re-authentication
    final reauthed = await reauthenticate(password);
    if (!reauthed) {
      throw AuthException('Password is incorrect');
    }
    
    // Call Cloud Function to handle data cleanup
    await FirebaseFunctions.instance
        .httpsCallable('deleteUserAccount')
        .call();
    
    // Delete Firebase Auth account
    await FirebaseAuth.instance.currentUser!.delete();
  }
}
```

---

## OAuth Security

### Google Sign-In

```dart
// Ensure proper scopes
final GoogleSignInAccount? googleUser = await GoogleSignIn(
  scopes: ['email', 'profile'], // Minimal scopes
).signIn();
```

### Apple Sign-In

```dart
// Request minimal data
final credential = await SignInWithApple.getAppleIDCredential(
  scopes: [
    AppleIDAuthorizationScopes.email,
    AppleIDAuthorizationScopes.fullName,
  ],
);
```

### Token Validation (Server-Side)

```typescript
// functions/src/auth/validateOAuth.ts
export async function validateGoogleToken(idToken: string): Promise<DecodedIdToken> {
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Verify token is recent (within 5 minutes)
    const tokenAge = Date.now() / 1000 - decodedToken.auth_time;
    if (tokenAge > 300) {
      throw new Error('Token too old');
    }
    
    return decodedToken;
  } catch (error) {
    throw new functions.https.HttpsError('unauthenticated', 'Invalid token');
  }
}
```

---

## Security Headers (Web)

If deploying web version:

```json
// firebase.json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          { "key": "X-Frame-Options", "value": "DENY" },
          { "key": "X-Content-Type-Options", "value": "nosniff" },
          { "key": "X-XSS-Protection", "value": "1; mode=block" },
          { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
          { "key": "Content-Security-Policy", "value": "default-src 'self'; script-src 'self' 'unsafe-inline' https://apis.google.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https://*.googleapis.com https://*.firebaseio.com wss://*.firebaseio.com" }
        ]
      }
    ]
  }
}
```

---

## Audit Logging

```typescript
// functions/src/auth/auditLog.ts
interface AuthEvent {
  type: 'login' | 'logout' | 'signup' | 'password_change' | 'password_reset' | 
        'account_locked' | 'account_deleted' | 'session_revoked';
  userId: string;
  email: string;
  ip: string;
  userAgent: string;
  success: boolean;
  failureReason?: string;
  metadata?: Record<string, any>;
}

export async function logAuthEvent(event: AuthEvent): Promise<void> {
  const db = admin.firestore();
  
  await db.collection('_auditLogs').add({
    ...event,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    category: 'auth',
  });
  
  // Also log to Cloud Logging for long-term retention
  console.log(JSON.stringify({
    severity: event.success ? 'INFO' : 'WARNING',
    message: `Auth event: ${event.type}`,
    ...event,
  }));
}
```
