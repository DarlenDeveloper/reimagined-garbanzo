import { useQuery } from "@tanstack/react-query";
import { OrdersService } from "../services/orders.service";
import { PaginationParams } from "../services/firestore.service";

export const useOrders = (pagination: PaginationParams) => {
  return useQuery({
    queryKey: ['orders', pagination.pageIndex, pagination.pageSize],
    queryFn: () => OrdersService.getOrders(pagination),
  });
};

export const useOrder = (orderId: string) => {
  return useQuery({
    queryKey: ['order', orderId],
    queryFn: () => OrdersService.getOrder(orderId),
    enabled: !!orderId,
  });
};

export const useOrderStats = () => {
  return useQuery({
    queryKey: ['orders', 'stats'],
    queryFn: () => OrdersService.getOrderStats(),
  });
};
