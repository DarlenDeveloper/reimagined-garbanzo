import { ColumnDef } from "@tanstack/react-table";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { DataTableColumnHeader } from "@components/data-table/data-table-column-header";
import { Copy, Eye } from "lucide-react";
import { toast } from "sonner";
import { useNavigate } from "react-router-dom";

export type User = {
  id: string;
  uid: string;
  name: string;
  email: string;
  phone: string;
  userType: "Buyer" | "Seller" | "Courier";
  status: "Active" | "Suspended" | "Banned";
  createdAt: string;
  lastActive: string;
};

export const columns: ColumnDef<User>[] = [
  {
    accessorKey: "name",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="User" />
    ),
    cell: ({ row }) => {
      return (
        <div className="flex flex-col">
          <span className="font-medium">{row.getValue("name")}</span>
          <span className="text-xs text-muted-foreground">{row.original.email}</span>
        </div>
      );
    },
  },
  {
    accessorKey: "uid",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="User ID" />
    ),
    cell: ({ row }) => {
      const uid = row.getValue("uid") as string;
      return (
        <div className="flex items-center gap-2">
          <code className="text-xs bg-muted px-2 py-1 rounded">
            {uid.substring(0, 12)}...
          </code>
          <Button
            variant="ghost"
            size="icon"
            className="h-6 w-6"
            onClick={() => {
              navigator.clipboard.writeText(uid);
              toast.success("User ID copied to clipboard");
            }}
          >
            <Copy className="h-3 w-3" />
          </Button>
        </div>
      );
    },
  },
  {
    accessorKey: "phone",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Phone" />
    ),
  },
  {
    accessorKey: "userType",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Type" />
    ),
    cell: ({ row }) => {
      const type = row.getValue("userType") as string;
      const variant = 
        type === "Buyer" ? "default" :
        type === "Seller" ? "secondary" :
        "outline";
      
      return <Badge variant={variant}>{type}</Badge>;
    },
  },
  {
    accessorKey: "status",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Status" />
    ),
    cell: ({ row }) => {
      const status = row.getValue("status") as string;
      const variant = 
        status === "Active" ? "default" :
        status === "Suspended" ? "destructive" :
        "outline";
      
      return <Badge variant={variant}>{status}</Badge>;
    },
  },
  {
    accessorKey: "lastActive",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Last Active" />
    ),
  },
  {
    id: "actions",
    cell: ({ row }) => {
      const navigate = useNavigate();
      return (
        <Button 
          variant="ghost" 
          size="sm"
          onClick={() => navigate(`/users/${row.original.id}`)}
        >
          <Eye className="h-4 w-4 mr-2" />
          View
        </Button>
      );
    },
  },
];
