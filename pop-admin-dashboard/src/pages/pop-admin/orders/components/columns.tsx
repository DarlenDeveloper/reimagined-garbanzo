import { ColumnDef } from "@tanstack/react-table";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { DataTableColumnHeader } from "@components/data-table/data-table-column-header";
import { Eye } from "lucide-react";

export type Order = {
  id: string;
  orderNumber: string;
  customerName: string;
  customerPhone: string;
  storeName: string;
  items: number;
  total: number;
  commission: number;
  commissionRate: number;
  sellerPayout: number;
  paymentMethod: string;
  paymentStatus: string;
  status: string;
  createdAt: string;
};

export const columns: ColumnDef<Order>[] = [
  {
    accessorKey: "orderNumber",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Order #" />,
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-medium">{row.getValue("orderNumber")}</span>
        <span className="text-xs text-muted-foreground">{row.original.createdAt}</span>
      </div>
    ),
  },
  {
    accessorKey: "customerName",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Customer" />,
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-medium">{row.getValue("customerName")}</span>
        <span className="text-xs text-muted-foreground">{row.original.customerPhone}</span>
      </div>
    ),
  },
  {
    accessorKey: "storeName",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Store" />,
  },
  {
    accessorKey: "total",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Total" />,
    cell: ({ row }) => {
      const total = (row.getValue("total") as number) || 0;
      const items = row.original.items || 0;
      return (
        <div className="flex flex-col">
          <span className="font-medium">UGX {total.toLocaleString()}</span>
          <span className="text-xs text-muted-foreground">{items} items</span>
        </div>
      );
    },
  },
  {
    accessorKey: "commission",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Commission" />,
    cell: ({ row }) => {
      const commission = (row.getValue("commission") as number) || 0;
      const rate = row.original.commissionRate || 0;
      return (
        <div className="flex flex-col">
          <span className="font-medium text-orange-600">UGX {commission.toLocaleString()}</span>
          <span className="text-xs text-muted-foreground">{rate}%</span>
        </div>
      );
    },
  },
  {
    accessorKey: "sellerPayout",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Seller Payout" />,
    cell: ({ row }) => {
      const payout = (row.getValue("sellerPayout") as number) || 0;
      return <span className="font-medium text-green-600">UGX {payout.toLocaleString()}</span>;
    },
  },
  {
    accessorKey: "paymentStatus",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Payment" />,
    cell: ({ row }) => {
      const status = row.getValue("paymentStatus") as string;
      const variant = status === "paid" ? "default" : status === "pending" ? "secondary" : "destructive";
      return <Badge variant={variant}>{status}</Badge>;
    },
  },
  {
    accessorKey: "status",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Status" />,
    cell: ({ row }) => {
      const status = row.getValue("status") as string;
      const variant = 
        status === "delivered" ? "default" :
        status === "shipped" ? "secondary" :
        "outline";
      return <Badge variant={variant}>{status}</Badge>;
    },
  },
  {
    id: "actions",
    cell: () => (
      <Button variant="ghost" size="sm">
        <Eye className="h-4 w-4 mr-2" />
        View
      </Button>
    ),
  },
];
