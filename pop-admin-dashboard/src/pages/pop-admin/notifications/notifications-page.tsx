import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { DataTable } from "@components/data-table/data-table";
import { columns, Notification } from "./components/columns";
import { Bell, Send, CheckCircle, XCircle } from "lucide-react";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { useNotifications, useNotificationStats } from "@apis/queries/useNotifications";

export function NotificationsPage() {
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  const { data: notificationsData, isLoading: notificationsLoading } = useNotifications(paginationState);
  const { data: statsData } = useNotificationStats();

  const deliveryRate = statsData?.total ? ((statsData.delivered / statsData.total) * 100).toFixed(1) : "0.0";
  const readRate = statsData?.delivered ? ((statsData.read / statsData.delivered) * 100).toFixed(1) : "0.0";

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-bold">Notifications</h1>
        <p className="text-muted-foreground">Monitor notification delivery across the platform</p>
      </div>

      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Sent</CardTitle>
            <Send className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{((statsData?.total || 0) / 1000).toFixed(1)}K</div>
            <p className="text-xs text-muted-foreground">All notifications</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Delivered</CardTitle>
            <CheckCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{((statsData?.delivered || 0) / 1000).toFixed(1)}K</div>
            <p className="text-xs text-muted-foreground">{deliveryRate}% success rate</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending</CardTitle>
            <XCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{statsData?.pending || 0}</div>
            <p className="text-xs text-muted-foreground">Awaiting delivery</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Read Rate</CardTitle>
            <Bell className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{readRate}%</div>
            <p className="text-xs text-muted-foreground">User engagement</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Notification Logs</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            data={notificationsData?.data || []}
            columns={columns}
            manualPagination={true}
            paginationState={paginationState}
            onPaginationChange={setPaginationState}
            rowCount={notificationsData?.total || 0}
            loading={notificationsLoading}
          />
        </CardContent>
      </Card>
    </div>
  );
}
