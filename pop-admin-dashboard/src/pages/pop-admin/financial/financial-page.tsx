import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { DataTable } from "@components/data-table/data-table";
import { columns, FinancialRecord } from "./components/columns";
import { DollarSign, TrendingUp, Wallet, PieChart } from "lucide-react";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { useFinancialSummary, useFinancialRecords } from "@apis/queries/useFinancial";

export function FinancialPage() {
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  const { data: summary } = useFinancialSummary();
  const { data: records, isLoading } = useFinancialRecords();

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-bold">Financial Reports</h1>
        <p className="text-muted-foreground">Detailed financial analytics and revenue breakdown</p>
      </div>

      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">UGX {((summary?.totalRevenue || 0) / 1000000).toFixed(1)}M</div>
            <p className="text-xs text-muted-foreground">All platform orders</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Commission Earned</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">UGX {((summary?.totalCommission || 0) / 1000000).toFixed(1)}M</div>
            <p className="text-xs text-muted-foreground">{summary?.totalRevenue ? ((summary.totalCommission / summary.totalRevenue) * 100).toFixed(1) : 0}% of total revenue</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Payouts</CardTitle>
            <Wallet className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">UGX {((summary?.totalPayouts || 0) / 1000000).toFixed(1)}M</div>
            <p className="text-xs text-muted-foreground">To sellers & couriers</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Net Profit</CardTitle>
            <PieChart className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">UGX {((summary?.netProfit || 0) / 1000000).toFixed(1)}M</div>
            <p className="text-xs text-muted-foreground">Commission - Payouts</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Daily Financial Summary</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            data={records || []}
            columns={columns}
            manualPagination={false}
            paginationState={paginationState}
            onPaginationChange={setPaginationState}
            rowCount={records?.length || 0}
            loading={isLoading}
          />
        </CardContent>
      </Card>
    </div>
  );
}
