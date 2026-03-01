import { ColumnDef } from "@tanstack/react-table";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { DataTableColumnHeader } from "@components/data-table/data-table-column-header";
import { CheckCircle, XCircle } from "lucide-react";

export type StorePayout = {
  id: string;
  storeName: string;
  ownerName: string;
  amount: number;
  method: string;
  accountDetails: string;
  status: string;
  requestedAt: string;
};

export const storeColumns: ColumnDef<StorePayout>[] = [
  {
    accessorKey: "storeName",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Store" />,
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-medium">{row.getValue("storeName")}</span>
        <span className="text-xs text-muted-foreground">{row.original.ownerName}</span>
      </div>
    ),
  },
  {
    accessorKey: "amount",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Amount" />,
    cell: ({ row }) => {
      const amount = row.getValue("amount") as number;
      return <span className="font-medium">UGX {amount.toLocaleString()}</span>;
    },
  },
  {
    accessorKey: "method",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Method" />,
    cell: ({ row }) => {
      const method = row.getValue("method") as string;
      return <Badge variant="outline">{method === "mobile_money" ? "Mobile Money" : "Bank Transfer"}</Badge>;
    },
  },
  {
    accessorKey: "accountDetails",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Account" />,
  },
  {
    accessorKey: "status",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Status" />,
    cell: ({ row }) => {
      const status = row.getValue("status") as string;
      const variant = 
        status === "completed" ? "default" :
        status === "processing" ? "secondary" :
        status === "pending" ? "outline" :
        "destructive";
      return <Badge variant={variant}>{status}</Badge>;
    },
  },
  {
    accessorKey: "requestedAt",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Requested" />,
  },
  {
    id: "actions",
    cell: ({ row }) => {
      const status = row.original.status;
      if (status === "pending") {
        return (
          <div className="flex gap-2">
            <Button variant="ghost" size="sm" className="text-green-600">
              <CheckCircle className="h-4 w-4 mr-2" />
              Approve
            </Button>
            <Button variant="ghost" size="sm" className="text-red-600">
              <XCircle className="h-4 w-4 mr-2" />
              Reject
            </Button>
          </div>
        );
      }
      return null;
    },
  },
];
