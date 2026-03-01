import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { DIDsService } from "../services/dids.service";

export const useDIDs = () => {
  return useQuery({
    queryKey: ['dids'],
    queryFn: () => DIDsService.getAllDIDs(),
  });
};

export const useAvailableDIDs = () => {
  return useQuery({
    queryKey: ['dids', 'available'],
    queryFn: () => DIDsService.getAvailableDIDs(),
  });
};

export const useAssignDID = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: ({ didId, storeId, storeName }: { didId: string; storeId: string; storeName: string }) =>
      DIDsService.assignDID(didId, storeId, storeName),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dids'] });
    },
  });
};

export const useUnassignDID = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: (didId: string) => DIDsService.unassignDID(didId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dids'] });
    },
  });
};
