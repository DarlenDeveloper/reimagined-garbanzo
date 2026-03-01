import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { StoresService } from "../services/stores.service";
import { PaginationParams } from "../services/firestore.service";

export const useStores = (pagination: PaginationParams) => {
  return useQuery({
    queryKey: ['stores', pagination.pageIndex, pagination.pageSize],
    queryFn: () => StoresService.getStores(pagination),
  });
};

export const useStore = (storeId: string) => {
  return useQuery({
    queryKey: ['store', storeId],
    queryFn: () => StoresService.getStore(storeId),
    enabled: !!storeId,
  });
};

export const useStoreStats = () => {
  return useQuery({
    queryKey: ['stores', 'stats'],
    queryFn: () => StoresService.getStoreStats(),
  });
};

export const usePendingStoreVerifications = () => {
  return useQuery({
    queryKey: ['stores', 'pending-verifications'],
    queryFn: () => StoresService.getPendingVerifications(),
  });
};

export const useUpdateStoreVerification = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: ({ storeId, status }: { storeId: string; status: 'verified' | 'rejected' }) =>
      StoresService.updateVerificationStatus(storeId, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stores'] });
    },
  });
};
