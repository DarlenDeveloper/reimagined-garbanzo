# VAPI Credentials - POP Platform

**Date**: February 22, 2026  
**Status**: Active

---

## API Keys

### Private Key (Backend)
```
0b2ef112-f947-4a36-a520-083bc5902771
```
Use for: Cloud Functions API calls to VAPI

### Public Key (Frontend)
```
fc915f5b-fdb2-41fb-a601-c6ed2ea1072d
```
Use for: Flutter app (if needed)

---

## SIP Configuration

### SIP Credential ID
```
25718c8b-4388-4b59-ad0c-e2c7b8ea2147
```

### Sample Phone Number Response
```json
{
  "id": "cef8d16a-9890-4a25-9cff-a9f0bae9d761",
  "orgId": "1478f430-7a38-498d-9ac6-4d5f70d99fc8",
  "assistantId": "727ca903-42cc-4b76-ac68-8803b302f968",
  "number": "+256205479710",
  "createdAt": "2026-02-22T13:39:34.994Z",
  "updatedAt": "2026-02-22T13:41:00.083Z",
  "name": "DID 1",
  "credentialId": "25718c8b-4388-4b59-ad0c-e2c7b8ea2147",
  "provider": "byo-phone-number",
  "numberE164CheckEnabled": false,
  "status": "active",
  "providerResourceId": "240d2ce6-4783-43c7-9c81-89082109069c"
}
```

---

## Structured Output IDs

### CSAT (Customer Satisfaction)
```
01b9a819-68cb-41d6-b626-4426af1e89bb
```

### Call Summary
```
a356b2a9-fecc-49da-9220-85b5d315e2db
```

---

## Subscription Plan

### AI Customer Service Plan
- **Monthly Fee**: $20 USD
- **Included Minutes**: 100 minutes/month
- **Cost per Additional Minute**: $0.20 (internal, not displayed to users)
- **Target**: Stores expecting ~1 call per day
- **Overage Handling**: Block calls after 100 minutes or charge overage

---

## Firebase Configuration

### Project
- **Project ID**: `purlstores-za`
- **Region**: `africa-south1`

---

**Security Note**: Store Private Key in Firebase Secret Manager, not in code.
