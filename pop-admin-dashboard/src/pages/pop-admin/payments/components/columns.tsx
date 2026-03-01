import { ColumnDef } from "@tanstack/react-table";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { DataTableColumnHeader } from "@components/data-table/data-table-column-header";
import { Eye } from "lucide-react";

export type Payment = {
  id: string;
  txRef: string;
  orderNumber: string;
  buyerName: string;
  buyerPhone: string;
  amount: number;
  currency: string;
  paymentMethod: string;
  network: string | null;
  status: string;
  createdAt: string;
  flwRef: string;
};

export const columns: ColumnDef<Payment>[] = [
  {
    accessorKey: "txRef",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Transaction" />,
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-medium">{row.getValue("txRef")}</span>
        <span className="text-xs text-muted-foreground">FLW: {row.original.flwRef}</span>
      </div>
    ),
  },
  {
    accessorKey: "buyerName",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Buyer" />,
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-medium">{row.getValue("buyerName")}</span>
        <span className="text-xs text-muted-foreground">{row.original.buyerPhone}</span>
      </div>
    ),
  },
  {
    accessorKey: "orderNumber",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Order" />,
  },
  {
    accessorKey: "amount",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Amount" />,
    cell: ({ row }) => {
      const amount = (row.getValue("amount") as number) || 0;
      const currency = row.original.currency || 'UGX';
      return <span className="font-medium">{currency} {amount.toLocaleString()}</span>;
    },
  },
  {
    accessorKey: "paymentMethod",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Method" />,
    cell: ({ row }) => {
      const method = row.getValue("paymentMethod") as string;
      const network = row.original.network;
      return (
        <div className="flex gap-1">
          <Badge variant={method === "card" ? "default" : "secondary"}>
            {method === "card" ? "Card" : "Mobile Money"}
          </Badge>
          {network && <Badge variant="outline">{network}</Badge>}
        </div>
      );
    },
  },
  {
    accessorKey: "status",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Status" />,
    cell: ({ row }) => {
      const status = row.getValue("status") as string;
      const variant = status === "paid" ? "default" : status === "pending" ? "secondary" : "destructive";
      return <Badge variant={variant}>{status}</Badge>;
    },
  },
  {
    accessorKey: "createdAt",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Date" />,
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
