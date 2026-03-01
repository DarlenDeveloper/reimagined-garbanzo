import { useQuery } from "@tanstack/react-query";
import { FinancialService } from "../services/financial.service";

export const useFinancialRecords = () => {
  return useQuery({
    queryKey: ['financial', 'records'],
    queryFn: () => FinancialService.getFinancialRecords(),
  });
};

export const useFinancialSummary = () => {
  return useQuery({
    queryKey: ['financial', 'summary'],
    queryFn: () => FinancialService.getFinancialSummary(),
  });
};
