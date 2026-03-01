import { orderBy } from "firebase/firestore";
import { FirestoreService, PaginationParams } from "./firestore.service";

export interface Notification {
  id: string;
  title: string;
  message: string;
  type: string;
  recipientType: string;
  recipientCount: number;
  deliveredCount: number;
  readCount: number;
  status: string;
  createdAt: string;
}

export const NotificationsService = {
  async getNotifications(pagination: PaginationParams) {
    const result = await FirestoreService.getPaginatedCollection<any>(
      'notifications',
      pagination,
      [orderBy('createdAt', 'desc')]
    );
    
    // Map and provide defaults
    const mappedData = result.data.map(notif => ({
      ...notif,
      title: notif.title || 'Notification',
      message: notif.message || notif.body || '',
      type: notif.type || 'general',
      recipientType: notif.recipientType || notif.audience || 'all',
      recipientCount: notif.recipientCount || notif.recipients?.length || 0,
      deliveredCount: notif.deliveredCount || notif.delivered || 0,
      readCount: notif.readCount || notif.read || 0,
      status: notif.status || 'sent',
    }));
    
    return {
      ...result,
      data: mappedData,
    };
  },

  async getNotificationStats() {
    const notifications = await FirestoreService.getAllDocuments<any>('notifications');
    return {
      total: notifications.length,
      delivered: notifications.reduce((sum, n) => sum + (n.deliveredCount || n.delivered || 0), 0),
      read: notifications.reduce((sum, n) => sum + (n.readCount || n.read || 0), 0),
      pending: notifications.filter(n => n.status === 'pending' || n.status === 'queued').length,
    };
  },
};
