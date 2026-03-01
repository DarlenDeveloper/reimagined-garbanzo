# Verification Pages Fixed

## Issue
Verification pages (Store Verification and Courier Verification) were showing empty tables.

## Root Cause
The queries were using Firestore's `where()` and `orderBy()` together, which requires a composite index. Without the index, the queries would fail silently.

## Solution
Changed the approach to:
1. Fetch all documents from the collection
2. Filter in memory (JavaScript)
3. Sort in memory
4. Return filtered results

This avoids the need for composite indexes while still providing the same functionality.

## Changes Made

### 1. Store Verification Service
**File**: `src/apis/services/stores.service.ts`

**Before**:
```typescript
async getPendingVerifications() {
  return FirestoreService.getAllDocuments<Store>(
    'stores',
    [where('verificationStatus', '==', 'pending'), orderBy('createdAt', 'desc')]
  );
}
```

**After**:
```typescript
async getPendingVerifications() {
  // Get all stores
  const allStores = await FirestoreService.getAllDocuments<any>('stores');
  
  // Filter for pending verifications
  const pendingStores = allStores.filter(store => 
    store.verificationStatus === 'pending' || 
    (!store.isVerified && !store.verified && store.status === 'pending')
  );
  
  // Sort by creation date (newest first)
  pendingStores.sort((a, b) => {
    const dateA = a.createdAt?.seconds || 0;
    const dateB = b.createdAt?.seconds || 0;
    return dateB - dateA;
  });
  
  // Map with defaults
  return pendingStores.map(store => ({ /* ... */ }));
}
```

### 2. Courier Verification Service
**File**: `src/apis/services/couriers.service.ts`

Applied the same pattern:
- Fetch all couriers
- Filter for pending verifications
- Sort in memory
- Map with default values

### 3. Payouts Service
**File**: `src/apis/services/payouts.service.ts`

Updated to avoid composite index requirement:
- Fetch all payouts
- Filter by type in memory
- Sort by requested date
- Apply pagination manually

### 4. Fixed DataTable Props
**Files**: 
- `src/pages/pop-admin/store-verification/store-verification-page.tsx`
- `src/pages/pop-admin/courier-verification/courier-verification-page.tsx`

Changed `isLoading` to `loading` to match DataTable component API.

## Benefits

1. **No Composite Index Required**: Works immediately without Firestore index configuration
2. **Flexible Filtering**: Can check multiple field variations for pending status
3. **Better Error Handling**: Provides default values for missing fields
4. **Performance**: For small datasets (typical for pending verifications), in-memory filtering is fast

## Filtering Logic

### Store Verification
A store is considered "pending" if:
- `verificationStatus === 'pending'`, OR
- Not verified AND status is 'pending'

### Courier Verification
A courier is considered "pending" if:
- `verificationStatus === 'pending'`, OR
- `status === 'pending'`, OR
- Not verified (neither `isVerified` nor `verified` is true)

## Testing

After refreshing the browser (Ctrl+Shift+R), verification pages should now show:
- ✅ Pending stores awaiting verification
- ✅ Pending couriers awaiting verification
- ✅ Correct stats (pending count, verified count, etc.)
- ✅ Approve/Reject buttons working
- ✅ No console errors

## Note on Performance

This approach works well for:
- Small to medium datasets (< 1000 documents)
- Infrequent queries
- Development/testing environments

For production with large datasets, consider:
- Creating composite indexes in Firestore
- Using Cloud Functions for aggregation
- Implementing server-side filtering
