import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@components/ui/tabs";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, Truck, Package, DollarSign, MapPin, Ban, CheckCircle } from "lucide-react";
import { DataTable } from "@components/data-table/data-table";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { ColumnDef } from "@tanstack/react-table";

const mockCourier = {
  id: "1",
  uid: "courier123",
  fullName: "David Okello",
  email: "david@example.com",
  phone: "+256 700 111 222",
  status: "verified",
  verified: true,
  isOnline: true,
  vehicleType: "motorcycle",
  vehicleName: "Honda CB150",
  plateNumber: "UAM 123A",
  rating: 4.8,
  totalDeliveries: 234,
  totalEarnings: 5600000,
  createdAt: "2026-01-10",
  idNumber: "CM1234567890",
  nextOfKin: {
    name: "Sarah Okello",
    phone: "+256 700 222 333",
    nin: "CM0987654321"
  }
};

const deliveriesColumns: ColumnDef<any>[] = [
  { accessorKey: "orderNumber", header: "Order #" },
  { accessorKey: "storeName", header: "Store" },
  { accessorKey: "buyerName", header: "Customer" },
  { 
    accessorKey: "deliveryFee", 
    header: "Fee",
    cell: ({ row }) => `UGX ${row.original.deliveryFee.toLocaleString()}`
  },
  { 
    accessorKey: "status", 
    header: "Status",
    cell: ({ row }) => <Badge>{row.original.status}</Badge>
  },
  { accessorKey: "deliveredAt", header: "Delivered" },
];

const mockDeliveries = [
  { id: "1", orderNumber: "ORD-20260301-1234", storeName: "Fashion Hub", buyerName: "Jane Smith", deliveryFee: 5000, status: "delivered", deliveredAt: "2026-03-01 14:30" },
  { id: "2", orderNumber: "ORD-20260301-5678", storeName: "Tech Store", buyerName: "John Doe", deliveryFee: 7000, status: "delivered", deliveredAt: "2026-03-01 16:45" },
];

const earningsColumns: ColumnDef<any>[] = [
  { accessorKey: "date", header: "Date" },
  { accessorKey: "deliveries", header: "Deliveries" },
  { 
    accessorKey: "earnings", 
    header: "Earnings",
    cell: ({ row }) => `UGX ${row.original.earnings.toLocaleString()}`
  },
];

const mockEarnings = [
  { id: "1", date: "2026-03-01", deliveries: 12, earnings: 84000 },
  { id: "2", date: "2026-02-28", deliveries: 15, earnings: 105000 },
];

export function CourierDetailPage() {
  const { courierId } = useParams();
  const navigate = useNavigate();
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" onClick={() => navigate("/couriers")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back to Couriers
        </Button>
      </div>

      {/* Courier Header */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-4">
                <div className="h-20 w-20 rounded-full bg-primary/10 flex items-center justify-center">
                  <Truck className="h-10 w-10 text-primary" />
                </div>
                <div>
                  <h1 className="text-3xl font-bold">{mockCourier.fullName}</h1>
                  <p className="text-muted-foreground">{mockCourier.email}</p>
                  <p className="text-muted-foreground">{mockCourier.phone}</p>
                </div>
              </div>

              <div className="grid grid-cols-4 gap-4 mt-6">
                <div>
                  <p className="text-sm text-muted-foreground">Status</p>
                  <Badge className="mt-1">{mockCourier.status}</Badge>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Online Status</p>
                  <p className="text-lg font-semibold flex items-center gap-2 mt-1">
                    {mockCourier.isOnline ? (
                      <>
                        <span className="h-2 w-2 rounded-full bg-green-500"></span>
                        Online
                      </>
                    ) : (
                      "Offline"
                    )}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Rating</p>
                  <p className="text-lg font-semibold mt-1">⭐ {mockCourier.rating}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Joined</p>
                  <p className="text-lg font-semibold mt-1">{mockCourier.createdAt}</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 mt-4">
                <div className="p-4 bg-muted rounded-lg">
                  <h3 className="font-semibold mb-2">Vehicle Information</h3>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Type:</span>
                      <span className="font-medium">{mockCourier.vehicleType === "motorcycle" ? "🏍️ Motorcycle" : "🚗 Car"}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Model:</span>
                      <span className="font-medium">{mockCourier.vehicleName}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Plate:</span>
                      <span className="font-medium">{mockCourier.plateNumber}</span>
                    </div>
                  </div>
                </div>

                <div className="p-4 bg-muted rounded-lg">
                  <h3 className="font-semibold mb-2">Next of Kin</h3>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Name:</span>
                      <span className="font-medium">{mockCourier.nextOfKin.name}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Phone:</span>
                      <span className="font-medium">{mockCourier.nextOfKin.phone}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">NIN:</span>
                      <span className="font-medium">{mockCourier.nextOfKin.nin}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="flex flex-col gap-2">
              {mockCourier.status === "verified" && (
                <Button variant="destructive" size="sm">
                  <Ban className="h-4 w-4 mr-2" />
                  Suspend
                </Button>
              )}
              {mockCourier.status === "suspended" && (
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
            <CardTitle className="text-sm font-medium">Total Deliveries</CardTitle>
            <Package className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{mockCourier.totalDeliveries}</div>
            <p className="text-xs text-muted-foreground">All time</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Earnings</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">UGX {mockCourier.totalEarnings.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">All time</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg per Delivery</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">UGX {Math.round(mockCourier.totalEarnings / mockCourier.totalDeliveries).toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">Average earnings</p>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs defaultValue="deliveries" className="w-full">
        <TabsList>
          <TabsTrigger value="deliveries">
            <Package className="h-4 w-4 mr-2" />
            Deliveries
          </TabsTrigger>
          <TabsTrigger value="earnings">
            <DollarSign className="h-4 w-4 mr-2" />
            Earnings
          </TabsTrigger>
        </TabsList>

        <TabsContent value="deliveries">
          <Card>
            <CardHeader>
              <CardTitle>Delivery History ({mockDeliveries.length})</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={mockDeliveries}
                columns={deliveriesColumns}
                manualPagination={true}
                paginationState={paginationState}
                onPaginationChange={setPaginationState}
                rowCount={mockDeliveries.length}
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="earnings">
          <Card>
            <CardHeader>
              <CardTitle>Daily Earnings</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={mockEarnings}
                columns={earningsColumns}
                manualPagination={true}
                paginationState={paginationState}
                onPaginationChange={setPaginationState}
                rowCount={mockEarnings.length}
              />
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
