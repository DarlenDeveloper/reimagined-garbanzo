import { orderBy } from "firebase/firestore";
import { FirestoreService } from "./firestore.service";

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: 'super_admin' | 'accountant' | 'customer_service' | 'analyst';
  permissions: string[];
  status: 'active' | 'inactive';
  lastLogin?: string;
  createdAt: string;
}

export const AdminUsersService = {
  async getAdminUsers() {
    return FirestoreService.getAllDocuments<AdminUser>(
      'admins',
      [orderBy('createdAt', 'desc')]
    );
  },

  async getAdminUser(adminId: string) {
    return FirestoreService.getDocument<AdminUser>('admins', adminId);
  },

  async updateAdminUser(adminId: string, data: Partial<AdminUser>) {
    return FirestoreService.updateDocument('admins', adminId, data);
  },
};
