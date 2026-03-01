import { ColumnDef } from "@tanstack/react-table";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { DataTableColumnHeader } from "@components/data-table/data-table-column-header";
import { Eye, CheckCircle, XCircle } from "lucide-react";
import { useModal } from "@saimin/react-modal-manager";
import { ViewCourierDocumentsModal } from "./view-documents-modal";

export type CourierVerification = {
  id: string;
  courierName: string;
  fullName: string;
  email: string;
  phone: string;
  vehicleType: string;
  vehicleName: string;
  plateNumber: string;
  submittedAt: string;
  documents: string;
  status: string;
};

export const columns: ColumnDef<CourierVerification>[] = [
  {
    accessorKey: "fullName",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Courier" />,
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-medium">{row.getValue("fullName")}</span>
        <span className="text-xs text-muted-foreground">{row.original.vehicleType}</span>
      </div>
    ),
  },
  {
    accessorKey: "email",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Contact" />,
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="text-sm">{row.getValue("email")}</span>
        <span className="text-xs text-muted-foreground">{row.original.phone}</span>
      </div>
    ),
  },
  {
    accessorKey: "submittedAt",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Submitted" />,
  },
  {
    accessorKey: "documents",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Documents" />,
    cell: ({ row }) => {
      const docs = row.getValue("documents") as string;
      const variant = docs === "complete" ? "default" : "destructive";
      return <Badge variant={variant}>{docs}</Badge>;
    },
  },
  {
    id: "actions",
    cell: ({ row }) => {
      const { open } = useModal();
      
      return (
        <div className="flex gap-2">
          <Button 
            variant="ghost" 
            size="sm"
            onClick={() => {
              open("view-courier-documents", {
                content: <ViewCourierDocumentsModal verification={{
                  ...row.original,
                  courierName: row.original.fullName,
                  vehicleName: row.original.vehicleName || "Honda CB150",
                  plateNumber: row.original.plateNumber || "UAM 123A",
                }} />,
                animationType: "zoom",
                hideOnClickBackDrop: false,
              });
            }}
          >
            <Eye className="h-4 w-4 mr-2" />
            View Docs
          </Button>
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
    },
  },
];
