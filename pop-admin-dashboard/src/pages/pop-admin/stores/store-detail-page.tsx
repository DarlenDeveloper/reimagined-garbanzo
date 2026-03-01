import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@components/ui/tabs";
import { Badge } from "@components/ui/badge";
import { Button } from "@components/ui/button";
import { useParams, useNavigate } from "react-router-dom";
import { 
  ArrowLeft, Store as StoreIcon, Package, Image, Tag, 
  Megaphone, MessageSquare, Eye, DollarSign, Phone 
} from "lucide-react";
import { DataTable } from "@components/data-table/data-table";
import { useState } from "react";
import { PaginationState } from "@tanstack/react-table";
import { ColumnDef } from "@tanstack/react-table";

// Mock store data
const mockStore = {
  id: "1",
  name: "Fashion Hub",
  slug: "fashion-hub",
  category: "Fashion",
  description: "Your one-stop shop for trendy fashion items",
  logoUrl: "https://via.placeholder.com/150",
  bannerUrl: "https://via.placeholder.com/800x200",
  ownerId: "user123",
  ownerName: "John Doe",
  ownerEmail: "john@example.com",
  ownerPhone: "+256 700 123 456",
  isVerified: true,
  verificationStatus: "verified",
  hasAIService: true,
  aiPhoneNumber: "+256 205 479 710",
  rating: 4.8,
  reviewCount: 234,
  productCount: 245,
  followerCount: 1520,
  subscription: "premium",
  address: "Kampala, Uganda",
  createdAt: "2026-01-15",
};

// Products columns
const productsColumns: ColumnDef<any>[] = [
  { accessorKey: "name", header: "Product Name" },
  { accessorKey: "category", header: "Category" },
  { 
    accessorKey: "price", 
    header: "Price",
    cell: ({ row }) => `UGX ${row.original.price.toLocaleString()}`
  },
  { accessorKey: "stock", header: "Stock" },
  { 
    accessorKey: "status", 
    header: "Status",
    cell: ({ row }) => <Badge>{row.original.status}</Badge>
  },
];

const mockProducts = [
  { id: "1", name: "Cotton T-Shirt", category: "Clothing", price: 25000, stock: 45, status: "active" },
  { id: "2", name: "Denim Jeans", category: "Clothing", price: 65000, stock: 23, status: "active" },
];

// Posts columns
const postsColumns: ColumnDef<any>[] = [
  { 
    accessorKey: "content", 
    header: "Content",
    cell: ({ row }) => <div className="max-w-md truncate">{row.original.content}</div>
  },
  { 
    accessorKey: "postType", 
    header: "Type",
    cell: ({ row }) => <Badge variant="outline">{row.original.postType}</Badge>
  },
  { accessorKey: "likes", header: "Likes" },
  { accessorKey: "comments", header: "Comments" },
  { accessorKey: "createdAt", header: "Posted" },
];

const mockPosts = [
  { id: "1", content: "🔥 Flash Sale Alert! Get 50% off on all summer collection.", postType: "promo", likes: 234, comments: 45, createdAt: "2026-03-01" },
];

// Orders columns
const ordersColumns: ColumnDef<any>[] = [
  { accessorKey: "orderNumber", header: "Order #" },
  { accessorKey: "customerName", header: "Customer" },
  { 
    accessorKey: "total", 
    header: "Total",
    cell: ({ row }) => `UGX ${row.original.total.toLocaleString()}`
  },
  { 
    accessorKey: "status", 
    header: "Status",
    cell: ({ row }) => <Badge>{row.original.status}</Badge>
  },
  { accessorKey: "createdAt", header: "Date" },
];

const mockOrders = [
  { id: "1", orderNumber: "ORD-20260301-1234", customerName: "Jane Smith", total: 284000, status: "delivered", createdAt: "2026-03-01" },
];

// Discounts columns
const discountsColumns: ColumnDef<any>[] = [
  { accessorKey: "code", header: "Code" },
  { accessorKey: "type", header: "Type" },
  { 
    accessorKey: "value", 
    header: "Value",
    cell: ({ row }) => row.original.type === "percentage" ? `${row.original.value}%` : `UGX ${row.original.value}`
  },
  { 
    accessorKey: "usageCount", 
    header: "Usage",
    cell: ({ row }) => `${row.original.usageCount} / ${row.original.usageLimit}`
  },
  { 
    accessorKey: "status", 
    header: "Status",
    cell: ({ row }) => <Badge>{row.original.status}</Badge>
  },
];

const mockDiscounts = [
  { id: "1", code: "SAVE20", type: "percentage", value: 20, usageCount: 45, usageLimit: 100, status: "active" },
];

// Ads columns
const adsColumns: ColumnDef<any>[] = [
  { accessorKey: "title", header: "Ad Title" },
  { 
    accessorKey: "status", 
    header: "Status",
    cell: ({ row }) => <Badge>{row.original.status}</Badge>
  },
  { accessorKey: "totalViews", header: "Views" },
  { accessorKey: "clickCount", header: "Clicks" },
  { 
    accessorKey: "budget", 
    header: "Budget",
    cell: ({ row }) => `UGX ${row.original.budget.toLocaleString()}`
  },
];

const mockAds = [
  { id: "1", title: "Summer Sale - 50% Off", status: "active", totalViews: 15000, clickCount: 450, budget: 200000 },
];

// Conversations columns
const conversationsColumns: ColumnDef<any>[] = [
  { accessorKey: "userName", header: "Customer" },
  { 
    accessorKey: "lastMessage", 
    header: "Last Message",
    cell: ({ row }) => <div className="max-w-md truncate">{row.original.lastMessage}</div>
  },
  { accessorKey: "totalMessages", header: "Messages" },
  { accessorKey: "lastMessageTime", header: "Last Activity" },
];

const mockConversations = [
  { id: "1", userName: "John Doe", lastMessage: "Is this item still available?", totalMessages: 15, lastMessageTime: "2026-03-01 14:30" },
];

// Visitors columns
const visitorsColumns: ColumnDef<any>[] = [
  { accessorKey: "userName", header: "Visitor" },
  { accessorKey: "visitCount", header: "Visits" },
  { accessorKey: "pagesViewed", header: "Pages" },
  { 
    accessorKey: "hasOrdered", 
    header: "Converted",
    cell: ({ row }) => row.original.hasOrdered ? <span className="text-green-500">✓ Yes</span> : <span className="text-muted-foreground">No</span>
  },
  { accessorKey: "lastVisitDate", header: "Last Visit" },
];

const mockVisitors = [
  { id: "1", userName: "John Doe", visitCount: 5, pagesViewed: 12, hasOrdered: true, lastVisitDate: "2026-03-01" },
];

export function StoreDetailPage() {
  const { storeId } = useParams();
  const navigate = useNavigate();
  const [paginationState, setPaginationState] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 10,
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" onClick={() => navigate("/stores")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back to Stores
        </Button>
      </div>

      {/* Store Header */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-start gap-6">
            <img 
              src={mockStore.logoUrl} 
              alt={mockStore.name}
              className="w-24 h-24 rounded-lg object-cover"
            />
            <div className="flex-1">
              <div className="flex items-start justify-between">
                <div>
                  <h1 className="text-3xl font-bold">{mockStore.name}</h1>
                  <p className="text-muted-foreground">@{mockStore.slug}</p>
                  <p className="mt-2">{mockStore.description}</p>
                </div>
                <div className="flex gap-2">
                  <Badge variant={mockStore.verificationStatus === "verified" ? "default" : "secondary"}>
                    {mockStore.verificationStatus}
                  </Badge>
                  <Badge variant={mockStore.subscription === "premium" ? "default" : "outline"}>
                    {mockStore.subscription}
                  </Badge>
                </div>
              </div>
              
              <div className="grid grid-cols-4 gap-4 mt-4">
                <div>
                  <p className="text-sm text-muted-foreground">Rating</p>
                  <p className="text-lg font-semibold">⭐ {mockStore.rating} ({mockStore.reviewCount})</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Products</p>
                  <p className="text-lg font-semibold">{mockStore.productCount}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Followers</p>
                  <p className="text-lg font-semibold">{mockStore.followerCount}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Joined</p>
                  <p className="text-lg font-semibold">{mockStore.createdAt}</p>
                </div>
              </div>

              <div className="mt-4 p-4 bg-muted rounded-lg">
                <h3 className="font-semibold mb-2">Owner Information</h3>
                <div className="grid grid-cols-3 gap-4 text-sm">
                  <div>
                    <p className="text-muted-foreground">Name</p>
                    <p>{mockStore.ownerName}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Email</p>
                    <p>{mockStore.ownerEmail}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Phone</p>
                    <p>{mockStore.ownerPhone}</p>
                  </div>
                </div>
              </div>

              {mockStore.hasAIService && (
                <div className="mt-4 p-4 bg-primary/10 rounded-lg flex items-center gap-2">
                  <Phone className="h-5 w-5 text-primary" />
                  <div>
                    <p className="font-semibold">AI Customer Service Active</p>
                    <p className="text-sm text-muted-foreground">Phone: {mockStore.aiPhoneNumber}</p>
                  </div>
                </div>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Tabs for different sections */}
      <Tabs defaultValue="products" className="w-full">
        <TabsList className="grid w-full grid-cols-7">
          <TabsTrigger value="products">
            <Package className="h-4 w-4 mr-2" />
            Products
          </TabsTrigger>
          <TabsTrigger value="posts">
            <Image className="h-4 w-4 mr-2" />
            Posts
          </TabsTrigger>
          <TabsTrigger value="orders">
            <DollarSign className="h-4 w-4 mr-2" />
            Orders
          </TabsTrigger>
          <TabsTrigger value="discounts">
            <Tag className="h-4 w-4 mr-2" />
            Discounts
          </TabsTrigger>
          <TabsTrigger value="ads">
            <Megaphone className="h-4 w-4 mr-2" />
            Ads
          </TabsTrigger>
          <TabsTrigger value="conversations">
            <MessageSquare className="h-4 w-4 mr-2" />
            Messages
          </TabsTrigger>
          <TabsTrigger value="visitors">
            <Eye className="h-4 w-4 mr-2" />
            Visitors
          </TabsTrigger>
        </TabsList>

        <TabsContent value="products">
          <Card>
            <CardHeader>
              <CardTitle>Products ({mockProducts.length})</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={mockProducts}
                columns={productsColumns}
                manualPagination={true}
                paginationState={paginationState}
                onPaginationChange={setPaginationState}
                rowCount={mockProducts.length}
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="posts">
          <Card>
            <CardHeader>
              <CardTitle>Posts & Stories ({mockPosts.length})</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={mockPosts}
                columns={postsColumns}
                manualPagination={true}
                paginationState={paginationState}
                onPaginationChange={setPaginationState}
                rowCount={mockPosts.length}
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="orders">
          <Card>
            <CardHeader>
              <CardTitle>Orders ({mockOrders.length})</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={mockOrders}
                columns={ordersColumns}
                manualPagination={true}
                paginationState={paginationState}
                onPaginationChange={setPaginationState}
                rowCount={mockOrders.length}
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="discounts">
          <Card>
            <CardHeader>
              <CardTitle>Discount Codes ({mockDiscounts.length})</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={mockDiscounts}
                columns={discountsColumns}
                manualPagination={true}
                paginationState={paginationState}
                onPaginationChange={setPaginationState}
                rowCount={mockDiscounts.length}
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="ads">
          <Card>
            <CardHeader>
              <CardTitle>Ad Campaigns ({mockAds.length})</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={mockAds}
                columns={adsColumns}
                manualPagination={true}
                paginationState={paginationState}
                onPaginationChange={setPaginationState}
                rowCount={mockAds.length}
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="conversations">
          <Card>
            <CardHeader>
              <CardTitle>Customer Conversations ({mockConversations.length})</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={mockConversations}
                columns={conversationsColumns}
                manualPagination={true}
                paginationState={paginationState}
                onPaginationChange={setPaginationState}
                rowCount={mockConversations.length}
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="visitors">
          <Card>
            <CardHeader>
              <CardTitle>Store Visitors ({mockVisitors.length})</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                data={mockVisitors}
                columns={visitorsColumns}
                manualPagination={true}
                paginationState={paginationState}
                onPaginationChange={setPaginationState}
                rowCount={mockVisitors.length}
              />
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
