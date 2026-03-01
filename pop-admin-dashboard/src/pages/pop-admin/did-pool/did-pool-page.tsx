import { DataTable } from "@components/data-table/data-table";
import PageTitle from "@components/commons/page-title";
import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { Phone, CheckCircle, XCircle, Plus } from "lucide-react";
import { Button } from "@components/ui/button";
import { columns } from "./components/columns";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { useDIDs } from "@apis/queries/useDIDs";

export function DIDPoolPage() {
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  const { data: didsData, isLoading: didsLoading } = useDIDs();

  const totalDIDs = didsData?.length || 0;
  const assignedDIDs = didsData?.filter(d => d.assigned).length || 0;
  const availableDIDs = totalDIDs - assignedDIDs;

  const stats = [
    { title: "Total DIDs", value: totalDIDs.toString(), icon: Phone, description: "In pool" },
    { title: "Assigned", value: assignedDIDs.toString(), icon: CheckCircle, description: `${totalDIDs ? Math.round((assignedDIDs / totalDIDs) * 100) : 0}% utilization` },
    { title: "Available", value: availableDIDs.toString(), icon: XCircle, description: `${totalDIDs ? Math.round((availableDIDs / totalDIDs) * 100) : 0}% available` },
    { title: "Active Subscriptions", value: assignedDIDs.toString(), icon: Phone, description: "AI service active" },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <PageTitle title="DID Pool Management" desc="Manage phone numbers for AI customer service" />
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Add DID
        </Button>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{stat.title}</CardTitle>
              <stat.icon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stat.value}</div>
              <p className="text-xs text-muted-foreground">{stat.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All DIDs</CardTitle>
        </CardHeader>
        <CardContent>
          <DataTable
            data={didsData || []}
            columns={columns}
            manualPagination={false}
            paginationState={paginationState}
            onPaginationChange={setPaginationState}
            rowCount={totalDIDs}
            loading={didsLoading}
          />
        </CardContent>
      </Card>
    </div>
  );
}
