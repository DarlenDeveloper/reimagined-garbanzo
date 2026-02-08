# Cloud Functions Deployment Guide

## Quick Start for East Africa Optimization

### 1. Initialize Firebase Functions
```bash
cd functions
npm install
```

### 2. Update firebase.json
```json
{
  "functions": {
    "source": "functions",
    "runtime": "nodejs18",
    "region": "europe-west1"
  }
}
```

### 3. Deploy to europe-west1 (Optimal for Uganda/Kenya)
```bash
# Deploy all functions
firebase deploy --only functions --region europe-west1

# Or deploy specific function
firebase deploy --only functions:sendNotification --region europe-west1
```

### 4. Verify Deployment
```bash
firebase functions:list
```

Expected output:
```
✔ sendNotification(europe-west1)
```

---

## Expected Latency

- **Uganda → europe-west1:** 150-250ms
- **Kenya → europe-west1:** 120-200ms
- **Total notification delivery:** 200-400ms ✅

---

## Monitoring

```bash
# View logs
firebase functions:log --only sendNotification

# View errors
firebase functions:log --only sendNotification --only-errors
```

---

*Deploy to europe-west1 for best East Africa performance!*
