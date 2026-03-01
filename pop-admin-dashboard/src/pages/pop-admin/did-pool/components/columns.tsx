import { ColumnDef } from "@tanstack/react-table";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { DataTableColumnHeader } from "@components/data-table/data-table-column-header";
import { Unlink, Link } from "lucide-react";

export type DID = {
  id: string;
  phoneNumber: string;
  assigned: boolean;
  storeName: string | null;
  storeId: string | null;
  assignedAt: string | null;
  createdAt: string;
};

export const columns: ColumnDef<DID>[] = [
  {
    accessorKey: "phoneNumber",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Phone Number" />,
    cell: ({ row }) => <span className="font-mono font-medium">{row.getValue("phoneNumber")}</span>,
  },
  {
    accessorKey: "assigned",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Status" />,
    cell: ({ row }) => {
      const assigned = row.getValue("assigned") as boolean;
      return (
        <Badge variant={assigned ? "default" : "outline"}>
          {assigned ? "Assigned" : "Available"}
        </Badge>
      );
    },
  },
  {
    accessorKey: "storeName",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Assigned To" />,
    cell: ({ row }) => {
      const storeName = row.getValue("storeName") as string | null;
      return storeName ? (
        <span className="font-medium">{storeName}</span>
      ) : (
        <span className="text-muted-foreground">-</span>
      );
    },
  },
  {
    accessorKey: "assignedAt",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Assigned Date" />,
    cell: ({ row }) => {
      const date = row.getValue("assignedAt") as string | null;
      return date ? date : <span className="text-muted-foreground">-</span>;
    },
  },
  {
    accessorKey: "createdAt",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Created" />,
  },
  {
    id: "actions",
    cell: ({ row }) => {
      const assigned = row.original.assigned;
      return (
        <Button variant="ghost" size="sm">
          {assigned ? (
            <>
              <Unlink className="h-4 w-4 mr-2" />
              Unassign
            </>
          ) : (
            <>
              <Link className="h-4 w-4 mr-2" />
              Assign
            </>
          )}
        </Button>
      );
    },
  },
];
