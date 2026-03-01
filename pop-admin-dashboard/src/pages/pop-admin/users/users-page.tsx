import { DataTable } from "@components/data-table/data-table";
import PageTitle from "@components/commons/page-title";
import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { Users as UsersIcon, Store, Truck } from "lucide-react";
import { columns } from "./components/columns";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { useUsers, useUserStats } from "@apis/queries/useUsers";

export function UsersPage() {
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  const { data: usersData, isLoading: usersLoading } = useUsers(paginationState);
  const { data: statsData, isLoading: statsLoading } = useUserStats();

  const stats = [
    {
      title: "Total Users",
      value: (statsData?.total || 0).toLocaleString(),
      icon: UsersIcon,
      description: "All registered users",
    },
    {
      title: "Buyers",
      value: (statsData?.buyers || 0).toLocaleString(),
      icon: UsersIcon,
      description: `${statsData?.total ? Math.round((statsData.buyers / statsData.total) * 100) : 0}% of total`,
    },
    {
      title: "Sellers",
      value: (statsData?.sellers || 0).toLocaleString(),
      icon: Store,
      description: `${statsData?.total ? Math.round((statsData.sellers / statsData.total) * 100) : 0}% of total`,
    },
    {
      title: "Couriers",
      value: (statsData?.couriers || 0).toLocaleString(),
      icon: Truck,
      description: `${statsData?.total ? Math.round((statsData.couriers / statsData.total) * 100) : 0}% of total`,
    },
  ];

  return (
    <div className="space-y-4">
      <PageTitle 
        title="User Management" 
        desc="Manage all platform users - buyers, sellers, and couriers"
      />

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{stat.title}</CardTitle>
              <stat.icon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stat.value}</div>
              <p className="text-xs text-muted-foreground">{stat.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Users Table */}
      <Card>
        <CardHeader>
          <CardTitle>All Users</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            data={usersData?.data || []}
            columns={columns}
            manualPagination={true}
            paginationState={paginationState}
            onPaginationChange={setPaginationState}
            rowCount={usersData?.total || 0}
            loading={usersLoading}
          />
        </CardContent>
      </Card>
    </div>
  );
}
