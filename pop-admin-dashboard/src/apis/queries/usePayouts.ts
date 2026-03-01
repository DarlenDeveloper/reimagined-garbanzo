import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { PayoutsService } from "../services/payouts.service";
import { PaginationParams } from "../services/firestore.service";

export const usePayouts = (pagination: PaginationParams, type?: 'store' | 'courier') => {
  return useQuery({
    queryKey: ['payouts', type, pagination.pageIndex, pagination.pageSize],
    queryFn: () => PayoutsService.getPayouts(pagination, type),
  });
};

export const usePayoutStats = (type?: 'store' | 'courier') => {
  return useQuery({
    queryKey: ['payouts', 'stats', type],
    queryFn: () => PayoutsService.getPayoutStats(type),
  });
};

export const useUpdatePayoutStatus = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: ({ payoutId, status }: { payoutId: string; status: 'processing' | 'completed' | 'failed' }) =>
      PayoutsService.updatePayoutStatus(payoutId, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['payouts'] });
    },
  });
};
