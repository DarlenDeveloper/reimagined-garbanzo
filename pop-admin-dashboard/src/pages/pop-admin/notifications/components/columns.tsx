import { ColumnDef } from "@tanstack/react-table";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { Eye } from "lucide-react";

export type Notification = {
  id: string;
  recipientType: "user" | "store" | "courier";
  recipientId: string;
  recipientName: string;
  type: "new_order" | "payment_received" | "delivery_update" | "message" | "low_stock" | "delivery_request";
  title: string;
  body: string;
  read: boolean;
  sentAt: string;
  deliveryStatus: "sent" | "delivered" | "failed";
};

export const columns: ColumnDef<Notification>[] = [
  {
    accessorKey: "recipientType",
    header: "Recipient Type",
    cell: ({ row }) => (
      <Badge variant="outline">{row.original.recipientType}</Badge>
    ),
  },
  {
    accessorKey: "recipientName",
    header: "Recipient",
  },
  {
    accessorKey: "type",
    header: "Type",
    cell: ({ row }) => (
      <Badge variant="secondary">{row.original.type.replace("_", " ")}</Badge>
    ),
  },
  {
    accessorKey: "title",
    header: "Title",
    cell: ({ row }) => <span className="font-medium">{row.original.title}</span>,
  },
  {
    accessorKey: "body",
    header: "Message",
    cell: ({ row }) => (
      <div className="max-w-md truncate">{row.original.body}</div>
    ),
  },
  {
    accessorKey: "read",
    header: "Read",
    cell: ({ row }) =>
      row.original.read ? (
        <span className="text-green-500">✓</span>
      ) : (
        <span className="text-muted-foreground">✗</span>
      ),
  },
  {
    accessorKey: "deliveryStatus",
    header: "Status",
    cell: ({ row }) => {
      const status = row.original.deliveryStatus;
      const variant =
        status === "delivered"
          ? "default"
          : status === "failed"
          ? "destructive"
          : "secondary";
      return <Badge variant={variant}>{status}</Badge>;
    },
  },
  {
    accessorKey: "sentAt",
    header: "Sent At",
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <Button variant="ghost" size="sm">
        <Eye className="h-4 w-4" />
      </Button>
    ),
  },
];
