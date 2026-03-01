import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { CouriersService } from "../services/couriers.service";
import { PaginationParams } from "../services/firestore.service";

export const useCouriers = (pagination: PaginationParams) => {
  return useQuery({
    queryKey: ['couriers', pagination.pageIndex, pagination.pageSize],
    queryFn: () => CouriersService.getCouriers(pagination),
  });
};

export const useCourier = (courierId: string) => {
  return useQuery({
    queryKey: ['courier', courierId],
    queryFn: () => CouriersService.getCourier(courierId),
    enabled: !!courierId,
  });
};

export const useCourierStats = () => {
  return useQuery({
    queryKey: ['couriers', 'stats'],
    queryFn: () => CouriersService.getCourierStats(),
  });
};

export const usePendingCourierVerifications = () => {
  return useQuery({
    queryKey: ['couriers', 'pending-verifications'],
    queryFn: () => CouriersService.getPendingVerifications(),
  });
};

export const useUpdateCourierVerification = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: ({ courierId, status }: { courierId: string; status: 'verified' | 'rejected' }) =>
      CouriersService.updateVerificationStatus(courierId, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['couriers'] });
    },
  });
};
