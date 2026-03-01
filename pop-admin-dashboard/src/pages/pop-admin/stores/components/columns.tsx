import { ColumnDef } from "@tanstack/react-table";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { Eye, CheckCircle, XCircle } from "lucide-react";
import { useNavigate } from "react-router-dom";

export type Store = {
  id: string;
  name: string;
  slug: string;
  category: string;
  ownerId: string;
  ownerName: string;
  isVerified: boolean;
  verificationStatus: "none" | "pending" | "verified" | "expired";
  hasAIService: boolean;
  rating: number;
  productCount: number;
  followerCount: number;
  subscription: "free" | "premium";
  createdAt: string;
};

export const columns: ColumnDef<Store>[] = [
  {
    accessorKey: "name",
    header: "Store Name",
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-medium">{row.original.name}</span>
        <span className="text-xs text-muted-foreground">@{row.original.slug}</span>
      </div>
    ),
  },
  {
    accessorKey: "category",
    header: "Category",
  },
  {
    accessorKey: "ownerName",
    header: "Owner",
  },
  {
    accessorKey: "verificationStatus",
    header: "Verification",
    cell: ({ row }) => {
      const status = row.original.verificationStatus;
      const variant =
        status === "verified"
          ? "default"
          : status === "pending"
          ? "secondary"
          : status === "expired"
          ? "destructive"
          : "outline";
      return <Badge variant={variant}>{status}</Badge>;
    },
  },
  {
    accessorKey: "hasAIService",
    header: "AI Service",
    cell: ({ row }) =>
      row.original.hasAIService ? (
        <CheckCircle className="h-4 w-4 text-green-500" />
      ) : (
        <XCircle className="h-4 w-4 text-gray-300" />
      ),
  },
  {
    accessorKey: "subscription",
    header: "Plan",
    cell: ({ row }) => (
      <Badge variant={row.original.subscription === "premium" ? "default" : "outline"}>
        {row.original.subscription}
      </Badge>
    ),
  },
  {
    accessorKey: "rating",
    header: "Rating",
    cell: ({ row }) => `⭐ ${(row.original.rating || 0).toFixed(1)}`,
  },
  {
    accessorKey: "productCount",
    header: "Products",
  },
  {
    accessorKey: "followerCount",
    header: "Followers",
  },
  {
    accessorKey: "createdAt",
    header: "Created",
  },
  {
    id: "actions",
    cell: ({ row }) => {
      const navigate = useNavigate();
      return (
        <Button 
          variant="ghost" 
          size="sm"
          onClick={() => navigate(`/stores/${row.original.id}`)}
        >
          <Eye className="h-4 w-4 mr-1" />
          View
        </Button>
      );
    },
  },
];
