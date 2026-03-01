import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { DataTable } from "@components/data-table/data-table";
import { columns, Store } from "./components/columns";
import { Store as StoreIcon, CheckCircle, Sparkles, TrendingUp } from "lucide-react";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { useStores, useStoreStats } from "@apis/queries/useStores";

export function StoresPage() {
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  const { data: storesData, isLoading: storesLoading } = useStores(paginationState);
  const { data: statsData } = useStoreStats();

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-bold">Stores</h1>
        <p className="text-muted-foreground">Manage all stores on the platform</p>
      </div>

      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Stores</CardTitle>
            <StoreIcon className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{(statsData?.total || 0).toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">All registered stores</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Verified Stores</CardTitle>
            <CheckCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{(statsData?.verified || 0).toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">{statsData?.total ? Math.round((statsData.verified / statsData.total) * 100) : 0}% of total</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">AI Service Active</CardTitle>
            <Sparkles className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{(statsData?.withAI || 0).toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">{statsData?.total ? Math.round((statsData.withAI / statsData.total) * 100) : 0}% of total</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Premium Stores</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{(statsData?.premium || 0).toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">{statsData?.total ? Math.round((statsData.premium / statsData.total) * 100) : 0}% of total</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Stores</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            data={storesData?.data || []}
            columns={columns}
            manualPagination={true}
            paginationState={paginationState}
            onPaginationChange={setPaginationState}
            rowCount={storesData?.total || 0}
            loading={storesLoading}
          />
        </CardContent>
      </Card>
    </div>
  );
}
