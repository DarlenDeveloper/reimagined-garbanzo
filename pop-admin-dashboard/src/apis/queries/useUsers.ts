import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { UsersService } from "../services/users.service";
import { PaginationParams } from "../services/firestore.service";

export const useUsers = (pagination: PaginationParams) => {
  return useQuery({
    queryKey: ['users', pagination.pageIndex, pagination.pageSize],
    queryFn: () => UsersService.getUsers(pagination),
  });
};

export const useUser = (userId: string) => {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => UsersService.getUser(userId),
    enabled: !!userId,
  });
};

export const useUserStats = () => {
  return useQuery({
    queryKey: ['users', 'stats'],
    queryFn: () => UsersService.getUserStats(),
  });
};

export const useUpdateUserStatus = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: ({ userId, status }: { userId: string; status: 'Active' | 'Suspended' }) =>
      UsersService.updateUserStatus(userId, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });
};
