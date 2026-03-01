import { useQuery } from "@tanstack/react-query";
import { NotificationsService } from "../services/notifications.service";
import { PaginationParams } from "../services/firestore.service";

export const useNotifications = (pagination: PaginationParams) => {
  return useQuery({
    queryKey: ['notifications', pagination.pageIndex, pagination.pageSize],
    queryFn: () => NotificationsService.getNotifications(pagination),
  });
};

export const useNotificationStats = () => {
  return useQuery({
    queryKey: ['notifications', 'stats'],
    queryFn: () => NotificationsService.getNotificationStats(),
  });
};
