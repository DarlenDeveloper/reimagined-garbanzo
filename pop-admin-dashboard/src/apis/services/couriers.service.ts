import { orderBy } from "firebase/firestore";
import { FirestoreService, PaginationParams } from "./firestore.service";

export interface Courier {
  id: string;
  name: string;
  email: string;
  phone: string;
  vehicleType: string;
  status: 'Active' | 'Inactive' | 'Suspended';
  isOnline?: boolean;
  rating?: number;
  deliveriesCompleted?: number;
  verificationStatus?: 'pending' | 'verified' | 'rejected';
  createdAt: string;
}

export const CouriersService = {
  async getCouriers(pagination: PaginationParams) {
    const result = await FirestoreService.getPaginatedCollection<any>(
      'couriers',
      pagination,
      [orderBy('createdAt', 'desc')]
    );
    
    // Map and provide defaults for missing fields
    const mappedData = result.data.map(courier => ({
      ...courier,
      name: courier.name || courier.fullName || courier.displayName || 'Unknown',
      email: courier.email || '',
      phone: courier.phone || courier.phoneNumber || '',
      vehicleType: courier.vehicleType || courier.vehicle || 'Unknown',
      status: courier.status === 'active' ? 'Active' : courier.status === 'inactive' ? 'Inactive' : courier.status || 'Inactive',
      isOnline: courier.isOnline || courier.online || false,
      rating: courier.rating || courier.averageRating || 0,
      deliveriesCompleted: courier.deliveriesCompleted || courier.completedDeliveries || 0,
      verificationStatus: courier.verificationStatus || courier.status || 'pending',
    }));
    
    return {
      ...result,
      data: mappedData,
    };
  },

  async getCourier(courierId: string) {
    return FirestoreService.getDocument<Courier>('couriers', courierId);
  },

  async getCourierStats() {
    const couriers = await FirestoreService.getAllDocuments<any>('couriers');
    const total = couriers.length;
    return {
      total,
      active: couriers.filter(c => c.status === 'Active' || c.status === 'active').length,
      online: couriers.filter(c => c.isOnline || c.online).length,
      avgRating: total > 0 ? couriers.reduce((sum, c) => sum + (c.rating || c.averageRating || 0), 0) / total : 0,
    };
  },

  async getPendingVerifications() {
    // Get all couriers and filter in memory to avoid composite index requirement
    const allCouriers = await FirestoreService.getAllDocuments<any>('couriers');
    
    // Filter for pending verifications - be more lenient
    const pendingCouriers = allCouriers.filter(courier => {
      return (
        courier.verificationStatus === 'pending' ||
        courier.status === 'pending' ||
        (!courier.isVerified && !courier.verified)
      );
    });
    
    // Sort by creation date (newest first)
    pendingCouriers.sort((a, b) => {
      const dateA = a.createdAt?.seconds || 0;
      const dateB = b.createdAt?.seconds || 0;
      return dateB - dateA;
    });
    
    // Map with defaults
    return pendingCouriers.map(courier => ({
      ...courier,
      name: courier.name || courier.fullName || courier.displayName || 'Unknown',
      email: courier.email || '',
      phone: courier.phone || courier.phoneNumber || '',
      vehicleType: courier.vehicleType || courier.vehicle || 'Unknown',
      status: 'Inactive',
      isOnline: false,
      rating: courier.rating || courier.averageRating || 0,
      deliveriesCompleted: courier.deliveriesCompleted || courier.completedDeliveries || 0,
      verificationStatus: 'pending',
    }));
  },

  async updateVerificationStatus(courierId: string, status: 'verified' | 'rejected') {
    return FirestoreService.updateDocument('couriers', courierId, {
      verificationStatus: status,
      status: status === 'verified' ? 'Active' : 'Inactive',
    });
  },
};
