import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { AdminUsersService, AdminUser } from "../services/admin-users.service";

export const useAdminUsers = () => {
  return useQuery({
    queryKey: ['admin-users'],
    queryFn: () => AdminUsersService.getAdminUsers(),
  });
};

export const useAdminUser = (adminId: string) => {
  return useQuery({
    queryKey: ['admin-user', adminId],
    queryFn: () => AdminUsersService.getAdminUser(adminId),
    enabled: !!adminId,
  });
};

export const useUpdateAdminUser = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: ({ adminId, data }: { adminId: string; data: Partial<AdminUser> }) =>
      AdminUsersService.updateAdminUser(adminId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
    },
  });
};
