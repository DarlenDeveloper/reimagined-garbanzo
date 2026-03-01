import { ColumnDef } from "@tanstack/react-table";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { Eye, Edit, Trash2 } from "lucide-react";

export type AdminUser = {
  id: string;
  uid: string;
  name: string;
  email: string;
  role: "super_admin" | "accountant" | "customer_service" | "analyst";
  permissions: string[];
  createdAt: string;
  lastLogin: string;
  status: "active" | "inactive";
};

const roleColors = {
  super_admin: "default",
  accountant: "secondary",
  customer_service: "outline",
  analyst: "outline",
} as const;

const roleLabels = {
  super_admin: "Super Admin",
  accountant: "Accountant",
  customer_service: "Customer Service",
  analyst: "Analyst",
};

export const columns: ColumnDef<AdminUser>[] = [
  {
    accessorKey: "name",
    header: "Name",
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-medium">{row.original.name}</span>
        <span className="text-xs text-muted-foreground">{row.original.email}</span>
      </div>
    ),
  },
  {
    accessorKey: "role",
    header: "Role",
    cell: ({ row }) => (
      <Badge variant={roleColors[row.original.role]}>
        {roleLabels[row.original.role]}
      </Badge>
    ),
  },
  {
    accessorKey: "permissions",
    header: "Permissions",
    cell: ({ row }) => (
      <div className="flex flex-wrap gap-1">
        {row.original.permissions.slice(0, 2).map((perm) => (
          <Badge key={perm} variant="outline" className="text-xs">
            {perm}
          </Badge>
        ))}
        {row.original.permissions.length > 2 && (
          <Badge variant="outline" className="text-xs">
            +{row.original.permissions.length - 2}
          </Badge>
        )}
      </div>
    ),
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => (
      <Badge variant={row.original.status === "active" ? "default" : "secondary"}>
        {row.original.status}
      </Badge>
    ),
  },
  {
    accessorKey: "lastLogin",
    header: "Last Login",
  },
  {
    accessorKey: "createdAt",
    header: "Created",
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <div className="flex gap-1">
        <Button variant="ghost" size="sm">
          <Eye className="h-4 w-4" />
        </Button>
        <Button variant="ghost" size="sm">
          <Edit className="h-4 w-4" />
        </Button>
        {row.original.role !== "super_admin" && (
          <Button variant="ghost" size="sm">
            <Trash2 className="h-4 w-4 text-red-500" />
          </Button>
        )}
      </div>
    ),
  },
];
