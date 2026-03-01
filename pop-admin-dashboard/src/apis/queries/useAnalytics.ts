import { useQuery } from "@tanstack/react-query";
import { AnalyticsService } from "../services/analytics.service";

export const useDashboardStats = () => {
  return useQuery({
    queryKey: ['analytics', 'dashboard'],
    queryFn: () => AnalyticsService.getDashboardStats(),
  });
};

export const useRevenueData = () => {
  return useQuery({
    queryKey: ['analytics', 'revenue'],
    queryFn: () => AnalyticsService.getRevenueData(),
  });
};
