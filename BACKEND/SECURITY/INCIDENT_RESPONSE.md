# Security Incident Response

## Incident Classification

| Severity | Description | Response Time | Examples |
|----------|-------------|---------------|----------|
| **Critical** | Active breach, data exfiltration | Immediate (< 15 min) | Database dump, admin compromise |
| **High** | Potential breach, system compromise | < 1 hour | Brute force success, suspicious admin activity |
| **Medium** | Security weakness exploited | < 4 hours | Rate limit bypass, minor data exposure |
| **Low** | Attempted attack, no success | < 24 hours | Failed login attempts, scanning |

---

## Detection & Alerting

### Automated Alerts

```typescript
// functions/src/security/alerts.ts
import * as functions from 'firebase-functions';

interface SecurityAlert {
  severity: 'critical' | 'high' | 'medium' | 'low';
  type: string;
  description: string;
  metadata: Record<string, any>;
  timestamp: number;
}

export async function sendSecurityAlert(alert: SecurityAlert): Promise<void> {
  const db = admin.firestore();
  
  // Log to Firestore
  await db.collection('_securityAlerts').add({
    ...alert,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    status: 'open',
  });
  
  // Log to Cloud Logging (for Cloud Monitoring alerts)
  console.error(JSON.stringify({
    severity: alert.severity.toUpperCase(),
    message: `SECURITY ALERT: ${alert.type}`,
    ...alert,
  }));
  
  // Send immediate notification for critical/high
  if (['critical', 'high'].includes(alert.severity)) {
    await sendUrgentNotification(alert);
  }
}

async function sendUrgentNotification(alert: SecurityAlert): Promise<void> {
  // Send to Slack/PagerDuty/Email
  // Implementation depends on your alerting setup
  
  // Example: Send email via SendGrid
  await sendEmail({
    to: process.env.SECURITY_TEAM_EMAIL!,
    subject: `[${alert.severity.toUpperCase()}] Security Alert: ${alert.type}`,
    body: `
      Type: ${alert.type}
      Severity: ${alert.severity}
      Description: ${alert.description}
      Time: ${new Date(alert.timestamp).toISOString()}
      
      Metadata:
      ${JSON.stringify(alert.metadata, null, 2)}
    `,
  });
}
```

### Alert Triggers

```typescript
// functions/src/security/triggers.ts

// 1. Multiple failed logins from same IP
export const detectBruteForce = functions.firestore
  .document('_rateLimits/{docId}')
  .onUpdate(async (change, context) => {
    const data = change.after.data();
    const docId = context.params.docId;
    
    if (!docId.startsWith('login:ip:')) return;
    
    const recentFailures = (data.attempts || [])
      .filter((a: any) => !a.success && a.timestamp > Date.now() - 60 * 60 * 1000);
    
    if (recentFailures.length >= 50) {
      await sendSecurityAlert({
        severity: 'high',
        type: 'BRUTE_FORCE_DETECTED',
        description: `${recentFailures.length} failed login attempts from single IP in 1 hour`,
        metadata: { ip: docId.replace('login:ip:', ''), attempts: recentFailures.length },
        timestamp: Date.now(),
      });
    }
  });

// 2. Unusual data access patterns
export const detectDataExfiltration = functions.firestore
  .document('_auditLogs/{logId}')
  .onCreate(async (snapshot) => {
    const log = snapshot.data();
    
    // Check for bulk reads
    if (log.action === 'list' && log.resultCount > 1000) {
      await sendSecurityAlert({
        severity: 'medium',
        type: 'BULK_DATA_ACCESS',
        description: `User accessed ${log.resultCount} records in single query`,
        metadata: { userId: log.userId, collection: log.collection, count: log.resultCount },
        timestamp: Date.now(),
      });
    }
  });

// 3. Admin role changes
export const detectPrivilegeEscalation = functions.firestore
  .document('vendors/{vendorId}/members/{memberId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    if (before.role !== after.role) {
      const severity = after.role === 'owner' ? 'high' : 'medium';
      
      await sendSecurityAlert({
        severity,
        type: 'ROLE_CHANGE',
        description: `User role changed from ${before.role} to ${after.role}`,
        metadata: {
          vendorId: context.params.vendorId,
          memberId: context.params.memberId,
          userId: after.userId,
          oldRole: before.role,
          newRole: after.role,
        },
        timestamp: Date.now(),
      });
    }
  });

// 4. Suspicious payment activity
export const detectPaymentAnomaly = functions.firestore
  .document('vendors/{vendorId}/orders/{orderId}')
  .onCreate(async (snapshot, context) => {
    const order = snapshot.data();
    
    // Check for unusually large orders
    if (order.total > 10000) { // $10,000+
      await sendSecurityAlert({
        severity: 'medium',
        type: 'LARGE_ORDER',
        description: `Unusually large order: $${order.total}`,
        metadata: {
          vendorId: context.params.vendorId,
          orderId: context.params.orderId,
          total: order.total,
          buyerId: order.buyerId,
        },
        timestamp: Date.now(),
      });
    }
  });
```

---

## Response Procedures

### Critical Incident Response

```
1. IMMEDIATE (0-15 minutes)
   □ Acknowledge alert
   □ Assess scope of breach
   □ Activate incident response team
   □ Begin containment

2. CONTAINMENT (15-60 minutes)
   □ Disable compromised accounts
   □ Revoke suspicious sessions
   □ Block malicious IPs
   □ Isolate affected systems if needed

3. INVESTIGATION (1-4 hours)
   □ Collect logs and evidence
   □ Identify attack vector
   □ Determine data exposure
   □ Document timeline

4. REMEDIATION (4-24 hours)
   □ Patch vulnerability
   □ Reset affected credentials
   □ Restore from backup if needed
   □ Verify fix effectiveness

5. RECOVERY (24-72 hours)
   □ Gradually restore services
   □ Monitor for recurrence
   □ Notify affected users (if required)
   □ Report to authorities (if required)

6. POST-INCIDENT (1-2 weeks)
   □ Complete incident report
   □ Conduct post-mortem
   □ Update security measures
   □ Train team on lessons learned
```

### Account Compromise Response

```typescript
// functions/src/security/accountCompromise.ts
export async function handleCompromisedAccount(userId: string): Promise<void> {
  const db = admin.firestore();
  
  // 1. Revoke all sessions
  await admin.auth().revokeRefreshTokens(userId);
  
  // 2. Delete all session documents
  const sessions = await db.collection('users').doc(userId).collection('sessions').get();
  const batch = db.batch();
  sessions.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  
  // 3. Force password reset
  const user = await admin.auth().getUser(userId);
  if (user.email) {
    await admin.auth().generatePasswordResetLink(user.email);
    // Send notification email about forced reset
  }
  
  // 4. Temporarily disable account
  await admin.auth().updateUser(userId, { disabled: true });
  
  // 5. Log incident
  await db.collection('_securityIncidents').add({
    type: 'ACCOUNT_COMPROMISE',
    userId,
    actions: ['sessions_revoked', 'password_reset_sent', 'account_disabled'],
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    status: 'contained',
  });
  
  // 6. Alert security team
  await sendSecurityAlert({
    severity: 'high',
    type: 'ACCOUNT_COMPROMISE_CONTAINED',
    description: `Compromised account ${userId} has been contained`,
    metadata: { userId, email: user.email },
    timestamp: Date.now(),
  });
}
```

### IP Blocking

```typescript
// functions/src/security/ipBlocking.ts
export async function blockIP(ip: string, reason: string, duration: number): Promise<void> {
  const db = admin.firestore();
  
  await db.collection('_blockedIPs').doc(ip).set({
    ip,
    reason,
    blockedAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + duration),
    blockedBy: 'system',
  });
}

// Check in middleware
export async function isIPBlocked(ip: string): Promise<boolean> {
  const db = admin.firestore();
  const doc = await db.collection('_blockedIPs').doc(ip).get();
  
  if (!doc.exists) return false;
  
  const data = doc.data()!;
  if (data.expiresAt.toDate() < new Date()) {
    // Expired, remove block
    await doc.ref.delete();
    return false;
  }
  
  return true;
}
```

---

## Communication Templates

### User Notification (Data Breach)

```
Subject: Important Security Notice - Action Required

Dear [User Name],

We are writing to inform you of a security incident that may have affected your account.

What Happened:
[Brief description of incident]

What Information Was Involved:
[List of potentially exposed data]

What We Are Doing:
- We have secured the affected systems
- We are conducting a thorough investigation
- We have notified relevant authorities

What You Should Do:
1. Change your password immediately
2. Review your recent account activity
3. Enable two-factor authentication if not already enabled
4. Be cautious of phishing emails

If you notice any suspicious activity, please contact us immediately at security@purl.com.

We sincerely apologize for any inconvenience this may cause.

The Purl Security Team
```

### Internal Incident Report Template

```markdown
# Security Incident Report

## Summary
- **Incident ID**: INC-2024-001
- **Date Detected**: 2024-01-15 14:32 UTC
- **Date Resolved**: 2024-01-15 18:45 UTC
- **Severity**: High
- **Status**: Resolved

## Timeline
| Time | Event |
|------|-------|
| 14:32 | Alert triggered: Brute force detected |
| 14:35 | On-call engineer acknowledged |
| 14:40 | Initial assessment complete |
| 15:00 | Attacker IP blocked |
| 15:30 | Affected accounts identified (3) |
| 16:00 | Accounts secured, passwords reset |
| 18:45 | Investigation complete, incident closed |

## Impact
- 3 user accounts temporarily compromised
- No data exfiltration confirmed
- No financial impact

## Root Cause
Weak passwords on affected accounts combined with lack of rate limiting on legacy endpoint.

## Remediation
1. Deployed rate limiting to all auth endpoints
2. Forced password reset for affected users
3. Added password strength requirements

## Lessons Learned
- Need to audit all endpoints for rate limiting
- Consider mandatory 2FA for vendor accounts

## Action Items
- [ ] Audit all API endpoints (Owner: Security Team, Due: 2024-01-22)
- [ ] Implement 2FA requirement (Owner: Dev Team, Due: 2024-02-01)
```

---

## Contacts

| Role | Contact | Escalation |
|------|---------|------------|
| On-Call Engineer | PagerDuty rotation | Auto-escalate after 15 min |
| Security Lead | [email] | For High/Critical |
| CTO | [email] | For Critical only |
| Legal | [email] | For data breaches |
| PR | [email] | For public incidents |

---

## Tools & Access

### Investigation Tools

- **Cloud Logging**: `console.cloud.google.com/logs`
- **Firestore Console**: `console.firebase.google.com`
- **Firebase Auth**: User management
- **Cloud Monitoring**: Metrics and alerts

### Emergency Access

```bash
# Emergency admin access (break-glass)
gcloud auth login --update-adc
firebase use purl-platform-prod

# Disable user account
firebase auth:disable <userId>

# Export logs
gcloud logging read "severity>=WARNING" --limit=1000 --format=json > incident_logs.json
```
