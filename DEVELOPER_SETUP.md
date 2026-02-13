# Developer Setup Guide

## Prerequisites
- Node.js 20+ installed
- Firebase CLI installed: `npm install -g firebase-tools`
- Git installed
- Access to the Firebase project

## Initial Setup

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd reimagined-garbanzo
```

### 2. Firebase Authentication
```bash
firebase login
```

### 3. Verify Firebase Project
```bash
firebase projects:list
```
Make sure you have access to the `purlstores` project.

### 4. Install Dependencies

#### Backend Functions
```bash
cd functions
npm install
cd ..
```

#### Buyer App (if working on it)
```bash
cd purl-stores-app\(buyer\)
flutter pub get
cd ..
```

#### Seller App (if working on it)
```bash
cd purl-admin-app\(seller\)
flutter pub get
cd ..
```

### 5. Build Functions (TypeScript)
```bash
cd functions
npm run build
cd ..
```

## Running Locally

### Firebase Emulators (Recommended for Development)
```bash
firebase emulators:start
```

### Deploy to Firebase
```bash
# Deploy everything
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy only firestore rules
firebase deploy --only firestore:rules

# Deploy only storage rules
firebase deploy --only storage:rules
```

## Important Notes

- **DO NOT commit** service account keys or credentials
- **DO NOT commit** `.env` files with secrets
- The project uses `africa-south1` region for functions
- Firebase project ID: `purlstores`

## Troubleshooting

### Functions won't build
```bash
cd functions
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Permission denied on Firebase
Make sure you're added to the Firebase project with appropriate permissions (Editor or Owner role).

### Flutter issues
```bash
flutter clean
flutter pub get
```

## Project Structure
- `/functions` - Cloud Functions (TypeScript)
- `/purl-stores-app(buyer)` - Buyer mobile app (Flutter)
- `/purl-admin-app(seller)` - Seller mobile app (Flutter)
- `/BACKEND` - Documentation and architecture
- `firestore.rules` - Firestore security rules
- `storage.rules` - Storage security rules

## Need Help?
Check the documentation in the `/BACKEND` folder for detailed architecture and implementation guides.
