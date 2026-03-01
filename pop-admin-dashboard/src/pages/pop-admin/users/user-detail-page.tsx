import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@components/ui/tabs";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, User as UserIcon, ShoppingCart, Store, Ban, CheckCircle } from "lucide-react";
import { DataTable } from "@components/data-table/data-table";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { ColumnDef } from "@tanstack/react-table";

const mockUser = {
  id: "1",
  uid: "abc123def456ghi789",
  name: "John Doe",
  email: "john@example.com",
  phone: "+256 700 123 456",
  userType: "Buyer",
  status: "Active",
  createdAt: "2024-01-15",
  lastActive: "2026-03-01",
  location: "Kampala, Uganda",
  interests: ["Fashion", "Electronics", "Home & Garden"],
};

const ordersColumns: ColumnDef<any>[] = [
  { accessorKey: "orderNumber", header: "Order #" },
  { accessorKey: "storeName", header: "Store" },
  { 
    accessorKey: "total", 
    header: "Total",
    cell: ({ row }) => `UGX ${row.original.total.toLocaleString()}`
  },
  { 
    accessorKey: "status", 
    header: "Status",
    cell: ({ row }) => <Badge>{row.original.status}</Badge>
  },
  { accessorKey: "createdAt", header: "Date" },
];

const mockOrders = [
  { id: "1", orderNumber: "ORD-20260301-1234", storeName: "Fashion Hub", total: 284000, status: "delivered", createdAt: "2026-03-01" },
  { id: "2", orderNumber: "ORD-20260228-5678", storeName: "Tech Store", total: 156000, status: "delivered", createdAt: "2026-02-28" },
];

const storesColumns: ColumnDef<any>[] = [
  { accessorKey: "name", header: "Store Name" },
  { accessorKey: "category", header: "Category" },
  { 
    accessorKey: "verificationStatus", 
    header: "Status",
    cell: ({ row }) => <Badge>{row.original.verificationStatus}</Badge>
  },
  { accessorKey: "productCount", header: "Products" },
  { accessorKey: "createdAt", header: "Created" },
];

const mockStores = [
  { id: "1", name: "Fashion Hub", category: "Fashion", verificationStatus: "verified", productCount: 245, createdAt: "2026-01-15" },
];

export function UserDetailPage() {
  const { userId } = useParams();
  const navigate = useNavigate();
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" onClick={() => navigate("/users")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back to Users
        </Button>
      </div>

      {/* User Header */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-4">
                <div className="h-20 w-20 rounded-full bg-primary/10 flex items-center justify-center">
                  <UserIcon className="h-10 w-10 text-primary" />
                </div>
                <div>
                  <h1 className="text-3xl font-bold">{mockUser.name}</h1>
                  <p className="text-muted-foreground">{mockUser.email}</p>
                  <p className="text-muted-foreground">{mockUser.phone}</p>
                </div>
              </div>

              <div className="grid grid-cols-4 gap-4 mt-6">
                <div>
                  <p className="text-sm text-muted-foreground">User Type</p>
                  <Badge className="mt-1">{mockUser.userType}</Badge>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Status</p>
                  <Badge className="mt-1" variant={mockUser.status === "Active" ? "default" : "destructive"}>
                    {mockUser.status}
                  </Badge>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Joined</p>
                  <p className="text-lg font-semibold mt-1">{mockUser.createdAt}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Last Active</p>
                  <p className="text-lg font-semibold mt-1">{mockUser.lastActive}</p>
                </div>
              </div>

              <div className="mt-4 p-4 bg-muted rounded-lg">
                <h3 className="font-semibold mb-2">User Information</h3>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <p className="text-muted-foreground">User ID</p>
                    <code className="text-xs bg-background px-2 py-1 rounded">{mockUser.uid}</code>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Location</p>
                    <p>{mockUser.location}</p>
                  </div>
                </div>
                <div className="mt-3">
                  <p className="text-muted-foreground mb-2">Interests</p>
                  <div className="flex flex-wrap gap-2">
                    {mockUser.interests.map((interest) => (
                      <Badge key={interest} variant="outline">{interest}</Badge>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            <div className="flex flex-col gap-2">
              {mockUser.status === "Active" && (
                <Button variant="destructive" size="sm">
                  <Ban className="h-4 w-4 mr-2" />
                  Suspend
                </Button>
              )}
              {mockUser.status === "Suspended" && (
                <Button variant="default" size="sm">
                  <CheckCircle className="h-4 w-4 mr-2" />
                  Activate
                </Button>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Orders</CardTitle>
            <ShoppingCart className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{mockOrders.length}</div>
            <p className="text-xs text-muted-foreground">All time</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Spent</CardTitle>
            <ShoppingCart className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              UGX {mockOrders.reduce((sum, order) => sum + order.total, 0).toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground">All time</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Stores Owned</CardTitle>
            <Store className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{mockUser.userType === "Seller" ? mockStores.length : 0}</div>
            <p className="text-xs text-muted-foreground">Active stores</p>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs defaultValue="orders" className="w-full">
        <TabsList>
          <TabsTrigger value="orders">
            <ShoppingCart className="h-4 w-4 mr-2" />
            Orders
          </TabsTrigger>
          {mockUser.userType === "Seller" && (
            <TabsTrigger value="stores">
              <Store className="h-4 w-4 mr-2" />
              Stores
            </TabsTrigger>
          )}
        </TabsList>

        <TabsContent value="orders">
          <Card>
            <CardHeader>
              <CardTitle>Order History ({mockOrders.length})</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={mockOrders}
                columns={ordersColumns}
                manualPagination={true}
                paginationState={paginationState}
                onPaginationChange={setPaginationState}
                rowCount={mockOrders.length}
              />
            </CardContent>
          </Card>
        </TabsContent>

        {mockUser.userType === "Seller" && (
          <TabsContent value="stores">
            <Card>
              <CardHeader>
                <CardTitle>Owned Stores ({mockStores.length})</CardTitle>
              </CardHeader>
              <CardContent>
                <DataTable
                  data={mockStores}
                  columns={storesColumns}
                  manualPagination={true}
                  paginationState={paginationState}
                  onPaginationChange={setPaginationState}
                  rowCount={mockStores.length}
                />
              </CardContent>
            </Card>
          </TabsContent>
        )}
      </Tabs>
    </div>
  );
}
