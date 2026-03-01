import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { DataTable } from "@components/data-table/data-table";
import { columns, AdminUser } from "./components/columns";
import { Shield, Users, UserPlus, Activity } from "lucide-react";
import { Button } from "@components/ui/button";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { useAdminUsers } from "@apis/queries/useAdminUsers";

export function AdminUsersPage() {
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  const { data: adminUsers, isLoading } = useAdminUsers();

  const activeAdmins = adminUsers?.filter(a => a.status === 'active').length || 0;
  const superAdmins = adminUsers?.filter(a => a.role === 'super_admin').length || 0;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Admin Users</h1>
          <p className="text-muted-foreground">Manage admin users and their permissions</p>
        </div>
        <Button>
          <UserPlus className="mr-2 h-4 w-4" />
          Add Admin User
        </Button>
      </div>

      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Admins</CardTitle>
            <Shield className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{adminUsers?.length || 0}</div>
            <p className="text-xs text-muted-foreground">Across all roles</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Super Admins</CardTitle>
            <Shield className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{superAdmins}</div>
            <p className="text-xs text-muted-foreground">Full access</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Users</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{activeAdmins}</div>
            <p className="text-xs text-muted-foreground">{adminUsers?.length ? Math.round((activeAdmins / adminUsers.length) * 100) : 0}% active</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Today</CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{activeAdmins}</div>
            <p className="text-xs text-muted-foreground">Currently working</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Admin Users</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            data={adminUsers || []}
            columns={columns}
            manualPagination={false}
            paginationState={paginationState}
            onPaginationChange={setPaginationState}
            rowCount={adminUsers?.length || 0}
            loading={isLoading}
          />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Role Permissions</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="rounded-lg border p-4">
              <h3 className="font-semibold mb-2">Super Admin</h3>
              <p className="text-sm text-muted-foreground mb-2">Full access to all features and settings</p>
              <div className="flex flex-wrap gap-2">
                <span className="text-xs bg-primary/10 text-primary px-2 py-1 rounded">All Permissions</span>
              </div>
            </div>

            <div className="rounded-lg border p-4">
              <h3 className="font-semibold mb-2">Accountant</h3>
              <p className="text-sm text-muted-foreground mb-2">Manage payments, payouts, and financial reports</p>
              <div className="flex flex-wrap gap-2">
                <span className="text-xs bg-secondary px-2 py-1 rounded">Payments</span>
                <span className="text-xs bg-secondary px-2 py-1 rounded">Payouts</span>
                <span className="text-xs bg-secondary px-2 py-1 rounded">Financial Reports</span>
                <span className="text-xs bg-secondary px-2 py-1 rounded">Orders (Read)</span>
              </div>
            </div>

            <div className="rounded-lg border p-4">
              <h3 className="font-semibold mb-2">Customer Service</h3>
              <p className="text-sm text-muted-foreground mb-2">Handle user issues, orders, and communications</p>
              <div className="flex flex-wrap gap-2">
                <span className="text-xs bg-secondary px-2 py-1 rounded">Users</span>
                <span className="text-xs bg-secondary px-2 py-1 rounded">Orders</span>
                <span className="text-xs bg-secondary px-2 py-1 rounded">Conversations</span>
                <span className="text-xs bg-secondary px-2 py-1 rounded">Notifications</span>
              </div>
            </div>

            <div className="rounded-lg border p-4">
              <h3 className="font-semibold mb-2">Analyst</h3>
              <p className="text-sm text-muted-foreground mb-2">Read-only access to analytics and reports</p>
              <div className="flex flex-wrap gap-2">
                <span className="text-xs bg-secondary px-2 py-1 rounded">Analytics (Read)</span>
                <span className="text-xs bg-secondary px-2 py-1 rounded">Visitors (Read)</span>
                <span className="text-xs bg-secondary px-2 py-1 rounded">Financial (Read)</span>
                <span className="text-xs bg-secondary px-2 py-1 rounded">Stores (Read)</span>
                <span className="text-xs bg-secondary px-2 py-1 rounded">Products (Read)</span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
