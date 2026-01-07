# Purl Platform - Security Overview

## Introduction

This document outlines security measures, potential vulnerabilities, and mitigations for the Purl platform (seller and buyer apps).

---

## Security Layers

| Layer | Technology | Purpose |
|-------|------------|---------|
| Authentication | Firebase Auth | Identity verification |
| Authorization | Firestore Rules + RBAC | Access control |
| Transport | HTTPS/TLS | Data in transit encryption |
| Storage | Firestore/Cloud Storage | Data at rest encryption |
| Rate Limiting | Cloud Functions + Firebase App Check | Abuse prevention |
| Input Validation | Client + Server | Injection prevention |
| Monitoring | Cloud Logging + Alerting | Threat detection |

---

## Threat Model

### 1. Authentication Threats

| Threat | Risk | Mitigation |
|--------|------|------------|
| Brute force login | High | Rate limiting, account lockout |
| Credential stuffing | High | Rate limiting, breach detection |
| Session hijacking | Medium | Secure token storage, HTTPS only |
| Weak passwords | Medium | Password strength requirements |
| Phishing | Medium | Email verification, user education |
| OAuth token theft | Low | Short-lived tokens, secure storage |

### 2. Authorization Threats

| Threat | Risk | Mitigation |
|--------|------|------------|
| IDOR (Insecure Direct Object Reference) | High | Firestore rules validate ownership |
| Privilege escalation | High | Server-side role validation |
| RBAC bypass | Medium | Cloud Functions enforce permissions |
| Cross-tenant data access | Critical | Strict vendor isolation in rules |

### 3. Data Threats

| Threat | Risk | Mitigation |
|--------|------|------------|
| Data exfiltration | High | Query limits, rate limiting |
| SQL/NoSQL injection | Medium | Parameterized queries, input validation |
| XSS (Cross-Site Scripting) | Medium | Input sanitization, CSP headers |
| Data tampering | Medium | Server-side validation |
| PII exposure | High | Field-level access control |

### 4. API/Infrastructure Threats

| Threat | Risk | Mitigation |
|--------|------|------------|
| DDoS | High | Firebase App Check, Cloud Armor |
| API abuse | High | Rate limiting, quotas |
| Replay attacks | Medium | Nonces, timestamps |
| Man-in-the-middle | Medium | Certificate pinning, HTTPS |

---

## Documents in This Folder

| Document | Purpose |
|----------|---------|
| [RATE_LIMITING.md](./RATE_LIMITING.md) | Rate limiting strategies |
| [FIRESTORE_RULES.md](./FIRESTORE_RULES.md) | Complete security rules |
| [INPUT_VALIDATION.md](./INPUT_VALIDATION.md) | Validation requirements |
| [AUTH_SECURITY.md](./AUTH_SECURITY.md) | Authentication hardening |
| [DATA_PROTECTION.md](./DATA_PROTECTION.md) | PII handling, encryption |
| [INCIDENT_RESPONSE.md](./INCIDENT_RESPONSE.md) | Security incident procedures |

---

## Quick Reference: Security Checklist

### Authentication
- [ ] Email verification required before full access
- [ ] Password minimum 8 chars, 1 uppercase, 1 number
- [ ] Account lockout after 5 failed attempts
- [ ] Rate limit login attempts (10/min per IP)
- [ ] Secure password reset flow
- [ ] Re-authentication for sensitive actions

### Authorization
- [ ] All Firestore rules deny by default
- [ ] RBAC enforced server-side (Cloud Functions)
- [ ] Vendor data isolated by vendorId
- [ ] No client-side role trust

### Data
- [ ] Input validation on client AND server
- [ ] Sanitize all user-generated content
- [ ] No sensitive data in logs
- [ ] PII encrypted at rest
- [ ] Query result limits enforced

### Infrastructure
- [ ] Firebase App Check enabled
- [ ] HTTPS only (no HTTP)
- [ ] API keys restricted by app/domain
- [ ] Cloud Function rate limits
- [ ] Monitoring and alerting active
