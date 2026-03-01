import {
  Users,
  ShoppingCart,
  DollarSign,
  Store,
  Truck,
  Wallet,
  Phone,
  TrendingUp,
  Bell,
  FileText,
  Shield,
} from "lucide-react";

const menus = [
  {
    name: "Analytics",
    icon: <TrendingUp className="h-[18px] w-[18px]" />,
    route: "/analytics",
  },
  {
    name: "Users",
    icon: <Users className="h-[18px] w-[18px]" />,
    route: "/users",
  },
  {
    name: "Stores",
    icon: <Store className="h-[18px] w-[18px]" />,
    route: "/stores",
  },
  {
    name: "Couriers",
    icon: <Truck className="h-[18px] w-[18px]" />,
    route: "/couriers",
  },
  {
    name: "Orders",
    icon: <ShoppingCart className="h-[18px] w-[18px]" />,
    route: "/orders",
  },
  {
    name: "Payments",
    icon: <DollarSign className="h-[18px] w-[18px]" />,
    route: "/payments",
  },
  {
    name: "Verification",
    icon: <Store className="h-[18px] w-[18px]" />,
    route: "verification",
    childs: [
      {
        name: "Stores",
        icon: <Store className="h-[18px] w-[18px]" />,
        route: "/store-verification",
      },
      {
        name: "Couriers",
        icon: <Truck className="h-[18px] w-[18px]" />,
        route: "/courier-verification",
      },
    ],
  },
  {
    name: "Payouts",
    icon: <Wallet className="h-[18px] w-[18px]" />,
    route: "/payouts",
  },
  {
    name: "Notifications",
    icon: <Bell className="h-[18px] w-[18px]" />,
    route: "/notifications",
  },
  {
    name: "Financial Reports",
    icon: <FileText className="h-[18px] w-[18px]" />,
    route: "/financial",
  },
  {
    name: "DID Pool",
    icon: <Phone className="h-[18px] w-[18px]" />,
    route: "/did-pool",
  },
  {
    name: "Admin Users",
    icon: <Shield className="h-[18px] w-[18px]" />,
    route: "/admin-users",
  },
];

export default menus;
