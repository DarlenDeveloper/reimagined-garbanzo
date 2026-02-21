/ads/{adId}
  - storeId
  - storeName
  - images: [url1, url2, url3] (1-3 landscape images)
  - budget: number (in dollars)
  - totalViews: number (budget × 1024)
  - viewsRemaining: number (decreases with each view)
  - status: "draft" | "pending_payment" | "active" | "completed"
  - clicks: number
  - storeVisits: number
  - createdAt
  - activatedAt
  - completedAt
  
/adViews/{viewId}
  - adId
  - userId
  - viewedAt
  - date (for daily unique tracking)
