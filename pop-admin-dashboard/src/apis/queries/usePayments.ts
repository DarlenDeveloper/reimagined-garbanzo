import { useQuery } from "@tanstack/react-query";
import { PaymentsService } from "../services/payments.service";
import { PaginationParams } from "../services/firestore.service";

export const usePayments = (pagination: PaginationParams) => {
  return useQuery({
    queryKey: ['payments', pagination.pageIndex, pagination.pageSize],
    queryFn: () => PaymentsService.getPayments(pagination),
  });
};

export const usePaymentStats = () => {
  return useQuery({
    queryKey: ['payments', 'stats'],
    queryFn: () => PaymentsService.getPaymentStats(),
  });
};
