import { FirestoreService, PaginationParams } from "./firestore.service";

export interface User {
  id: string;
  uid?: string;
  name?: string;
  email?: string;
  phone?: string;
  userType: 'Buyer' | 'Seller' | 'Courier';
  status?: 'Active' | 'Suspended' | 'Inactive';
  createdAt?: any;
  lastActive?: any;
}

export const UsersService = {
  async getUsers(pagination: PaginationParams) {
    // Get buyers from users collection
    const buyers = await FirestoreService.getAllDocuments<any>('users');
    const buyerUsers: User[] = buyers.map(user => ({
      id: user.id,
      uid: user.uid || user.id,
      name: user.name || user.displayName || user.fullName || 'Unknown',
      email: user.email || '',
      phone: user.phone || user.phoneNumber || '',
      userType: 'Buyer' as const,
      status: user.status === 'active' ? 'Active' as const : user.status === 'suspended' ? 'Suspended' as const : 'Active' as const,
      createdAt: user.createdAt,
      lastActive: user.lastActive || user.lastLogin || user.createdAt,
    }));

    // Get sellers from stores collection
    const stores = await FirestoreService.getAllDocuments<any>('stores');
    const sellerUsers: User[] = stores.map(store => ({
      id: store.id,
      uid: store.ownerId || store.userId || store.id,
      name: store.name || store.ownerName || store.storeName || 'Unknown Store',
      email: store.email || store.ownerEmail || '',
      phone: store.phone || store.ownerPhone || store.phoneNumber || '',
      userType: 'Seller' as const,
      status: store.status === 'active' || store.isVerified ? 'Active' as const : 'Inactive' as const,
      createdAt: store.createdAt,
      lastActive: store.updatedAt || store.lastActive || store.createdAt,
    }));

    // Get couriers from couriers collection
    const couriers = await FirestoreService.getAllDocuments<any>('couriers');
    const courierUsers: User[] = couriers.map(courier => ({
      id: courier.id,
      uid: courier.uid || courier.id,
      name: courier.fullName || courier.name || courier.displayName || 'Unknown Courier',
      email: courier.email || '',
      phone: courier.phone || courier.phoneNumber || '',
      userType: 'Courier' as const,
      status: courier.status === 'active' ? 'Active' as const : courier.status === 'suspended' ? 'Suspended' as const : 'Inactive' as const,
      createdAt: courier.createdAt,
      lastActive: courier.lastActive || courier.lastLogin || courier.createdAt,
    }));

    // Combine all users
    const allUsers = [...buyerUsers, ...sellerUsers, ...courierUsers];
    
    // Sort by creation date (newest first)
    allUsers.sort((a, b) => {
      const dateA = a.createdAt?.seconds || 0;
      const dateB = b.createdAt?.seconds || 0;
      return dateB - dateA;
    });

    // Apply pagination
    const startIndex = pagination.pageIndex * pagination.pageSize;
    const endIndex = startIndex + pagination.pageSize;
    const paginatedUsers = allUsers.slice(startIndex, endIndex);

    return {
      data: paginatedUsers,
      total: allUsers.length,
      hasMore: endIndex < allUsers.length,
    };
  },

  async getUser(userId: string) {
    // Try to find in users collection first
    let user = await FirestoreService.getDocument<any>('users', userId);
    if (user) {
      return {
        ...user,
        userType: 'Buyer' as const,
      };
    }

    // Try stores collection
    user = await FirestoreService.getDocument<any>('stores', userId);
    if (user) {
      return {
        ...user,
        name: user.name || user.ownerName,
        userType: 'Seller' as const,
      };
    }

    // Try couriers collection
    user = await FirestoreService.getDocument<any>('couriers', userId);
    if (user) {
      return {
        ...user,
        name: user.fullName || user.name,
        userType: 'Courier' as const,
      };
    }

    return null;
  },

  async updateUserStatus(userId: string, status: 'Active' | 'Suspended') {
    // Try to update in all collections
    try {
      await FirestoreService.updateDocument('users', userId, { status });
    } catch (e) {
      try {
        await FirestoreService.updateDocument('stores', userId, { status });
      } catch (e) {
        await FirestoreService.updateDocument('couriers', userId, { status });
      }
    }
  },

  async getUserStats() {
    // Get all users
    const users = await FirestoreService.getAllDocuments<User>('users');
    
    // Get all stores (sellers)
    const stores = await FirestoreService.getAllDocuments<any>('stores');
    
    // Get all couriers
    const couriers = await FirestoreService.getAllDocuments<any>('couriers');
    
    // Total users = users collection (buyers) + stores (sellers) + couriers
    const totalUsers = users.length + stores.length + couriers.length;
    
    return {
      total: totalUsers,
      buyers: users.length, // users collection are buyers
      sellers: stores.length, // stores collection represents sellers
      couriers: couriers.length, // couriers collection
    };
  },
};
