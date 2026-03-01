import { ColumnDef } from "@tanstack/react-table";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { Eye, Ban, CheckCircle } from "lucide-react";
import { useNavigate } from "react-router-dom";

export type Courier = {
  id: string;
  uid: string;
  fullName: string;
  email: string;
  phone: string;
  status: "pending_verification" | "verified" | "suspended";
  verified: boolean;
  isOnline: boolean;
  vehicleType: "motorcycle" | "car";
  rating: number;
  totalDeliveries: number;
  totalEarnings: number;
  createdAt: string;
};

export const columns: ColumnDef<Courier>[] = [
  {
    accessorKey: "fullName",
    header: "Name",
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-medium">{row.original.fullName}</span>
        <span className="text-xs text-muted-foreground">{row.original.email}</span>
      </div>
    ),
  },
  {
    accessorKey: "phone",
    header: "Phone",
  },
  {
    accessorKey: "vehicleType",
    header: "Vehicle",
    cell: ({ row }) => (
      <Badge variant="outline">
        {row.original.vehicleType === "motorcycle" ? "🏍️ Motorcycle" : "🚗 Car"}
      </Badge>
    ),
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => {
      const status = row.original.status;
      const variant =
        status === "verified"
          ? "default"
          : status === "suspended"
          ? "destructive"
          : "secondary";
      return <Badge variant={variant}>{status.replace("_", " ")}</Badge>;
    },
  },
  {
    accessorKey: "isOnline",
    header: "Online",
    cell: ({ row }) =>
      row.original.isOnline ? (
        <span className="flex items-center gap-1 text-green-500">
          <span className="h-2 w-2 rounded-full bg-green-500"></span> Online
        </span>
      ) : (
        <span className="text-muted-foreground">Offline</span>
      ),
  },
  {
    accessorKey: "rating",
    header: "Rating",
    cell: ({ row }) => `⭐ ${row.original.rating.toFixed(1)}`,
  },
  {
    accessorKey: "totalDeliveries",
    header: "Deliveries",
  },
  {
    accessorKey: "totalEarnings",
    header: "Earnings",
    cell: ({ row }) => `UGX ${row.original.totalEarnings.toLocaleString()}`,
  },
  {
    accessorKey: "createdAt",
    header: "Joined",
  },
  {
    id: "actions",
    cell: ({ row }) => {
      const navigate = useNavigate();
      return (
        <Button 
          variant="ghost" 
          size="sm"
          onClick={() => navigate(`/couriers/${row.original.id}`)}
        >
          <Eye className="h-4 w-4 mr-1" />
          View
        </Button>
      );
    },
  },
];
