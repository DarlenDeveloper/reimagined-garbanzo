import { ColumnDef } from "@tanstack/react-table";
import { DataTableColumnHeader } from "@components/data-table/data-table-column-header";

export type FinancialRecord = {
  id: string;
  date: string;
  totalRevenue: number;
  commission: number;
  payouts: number;
  netProfit: number;
  orderCount: number;
};

export const columns: ColumnDef<FinancialRecord>[] = [
  {
    accessorKey: "date",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Date" />,
  },
  {
    accessorKey: "orderCount",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Orders" />,
  },
  {
    accessorKey: "totalRevenue",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Revenue" />,
    cell: ({ row }) => {
      const amount = row.getValue("totalRevenue") as number;
      return <span className="font-medium">UGX {amount.toLocaleString()}</span>;
    },
  },
  {
    accessorKey: "commission",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Commission" />,
    cell: ({ row }) => {
      const amount = row.getValue("commission") as number;
      return <span className="font-medium text-orange-600">UGX {amount.toLocaleString()}</span>;
    },
  },
  {
    accessorKey: "payouts",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Payouts" />,
    cell: ({ row }) => {
      const amount = row.getValue("payouts") as number;
      return <span className="font-medium text-red-600">UGX {amount.toLocaleString()}</span>;
    },
  },
  {
    accessorKey: "netProfit",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Net Profit" />,
    cell: ({ row }) => {
      const amount = row.getValue("netProfit") as number;
      const isPositive = amount >= 0;
      return (
        <span className={`font-medium ${isPositive ? 'text-green-600' : 'text-red-600'}`}>
          UGX {amount.toLocaleString()}
        </span>
      );
    },
  },
];
