"use client"

import { useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { cn } from "@/lib/utils"
import {
  LayoutDashboard,
  Package,
  ShoppingCart,
  Warehouse,
  BarChart3,
  CreditCard,
  Bell,
  LogOut,
  Truck,
  PackageSearch,
  Users,
  Settings,
  Sparkles,
  Headphones,
  Phone,
  Globe,
  Mail,
  MessageCircle,
  ChevronDown,
  ChevronRight,
} from "lucide-react"
import { useAuth } from "@/lib/auth-context"

const navigation = [
  { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { name: "Products", href: "/dashboard/products", icon: Package },
  { name: "Orders", href: "/dashboard/orders", icon: ShoppingCart },
  { name: "Inventory", href: "/dashboard/inventory", icon: Warehouse },
  { name: "Deliveries", href: "/dashboard/deliveries", icon: Truck },
  { name: "Shipping", href: "/dashboard/shipping", icon: PackageSearch },
  { name: "Analytics", href: "/dashboard/analytics", icon: BarChart3 },
  { name: "Payments", href: "/dashboard/payments", icon: CreditCard },
  { name: "Users", href: "/dashboard/users", icon: Users },
  { name: "Notifications", href: "/dashboard/notifications", icon: Bell },
]

const customerServiceItems = [
  { name: "Calls", href: "/dashboard/customer-service/calls", icon: Phone },
  { name: "Web Texts", href: "/dashboard/customer-service/web-texts", icon: Globe },
  { name: "Email", href: "/dashboard/customer-service/email", icon: Mail },
]

export function Sidebar() {
  const pathname = usePathname()
  const { logout } = useAuth()
  const [customerServiceOpen, setCustomerServiceOpen] = useState(
    pathname.startsWith("/dashboard/customer-service")
  )

  const isCustomerServiceActive = pathname.startsWith("/dashboard/customer-service")

  return (
    <div className="flex h-full w-64 flex-col bg-white border-r border-[#E8E0D5]">
      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 overflow-y-auto">
        <div className="space-y-1">
          {navigation.map((item) => {
            const isActive = pathname === item.href
            return (
              <Link
                key={item.name}
                href={item.href}
                className={cn(
                  "flex items-center space-x-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200",
                  isActive
                    ? "bg-[#1B4332] text-white"
                    : "text-[#1B4332] hover:bg-[#F5F0E8]"
                )}
              >
                <item.icon className={cn("h-5 w-5", isActive ? "text-white" : "text-[#4F8A6D]")} />
                <span>{item.name}</span>
              </Link>
            )
          })}

          {/* Customer Service Dropdown */}
          <div>
            <button
              onClick={() => setCustomerServiceOpen(!customerServiceOpen)}
              className={cn(
                "flex w-full items-center justify-between rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200",
                isCustomerServiceActive
                  ? "bg-[#1B4332] text-white"
                  : "text-[#1B4332] hover:bg-[#F5F0E8]"
              )}
            >
              <div className="flex items-center space-x-3">
                <Headphones className={cn("h-5 w-5", isCustomerServiceActive ? "text-white" : "text-[#4F8A6D]")} />
                <span>Customer Service</span>
              </div>
              {customerServiceOpen ? (
                <ChevronDown className={cn("h-4 w-4", isCustomerServiceActive ? "text-white" : "text-[#8C9A8F]")} />
              ) : (
                <ChevronRight className={cn("h-4 w-4", isCustomerServiceActive ? "text-white" : "text-[#8C9A8F]")} />
              )}
            </button>
            
            {customerServiceOpen && (
              <div className="ml-4 mt-1 space-y-1">
                {customerServiceItems.map((item) => {
                  const isActive = pathname === item.href
                  return (
                    <Link
                      key={item.name}
                      href={item.href}
                      className={cn(
                        "flex items-center space-x-3 rounded-xl px-3 py-2 text-sm font-medium transition-all duration-200",
                        isActive
                          ? "bg-[#1B4332] text-white"
                          : "text-[#1B4332] hover:bg-[#F5F0E8]"
                      )}
                    >
                      <item.icon className={cn("h-4 w-4", isActive ? "text-white" : "text-[#4F8A6D]")} />
                      <span>{item.name}</span>
                    </Link>
                  )
                })}
              </div>
            )}
          </div>

          {/* Chats */}
          <Link
            href="/dashboard/chats"
            className={cn(
              "flex items-center space-x-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200",
              pathname === "/dashboard/chats"
                ? "bg-[#1B4332] text-white"
                : "text-[#1B4332] hover:bg-[#F5F0E8]"
            )}
          >
            <MessageCircle className={cn("h-5 w-5", pathname === "/dashboard/chats" ? "text-white" : "text-[#4F8A6D]")} />
            <span>Chats</span>
          </Link>

          {/* Settings */}
          <Link
            href="/dashboard/profile"
            className={cn(
              "flex items-center space-x-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200",
              pathname === "/dashboard/profile"
                ? "bg-[#1B4332] text-white"
                : "text-[#1B4332] hover:bg-[#F5F0E8]"
            )}
          >
            <Settings className={cn("h-5 w-5", pathname === "/dashboard/profile" ? "text-white" : "text-[#4F8A6D]")} />
            <span>Settings</span>
          </Link>
        </div>
      </nav>

      {/* Upgrade Banner - No purple */}
      <div className="px-3 py-4">
        <div className="rounded-2xl bg-gradient-to-br from-[#1B4332] to-[#2D5A45] p-4 text-white">
          <div className="flex items-center space-x-2 mb-2">
            <Sparkles className="h-5 w-5" />
            <span className="font-semibold text-sm">Upgrade to Pro!</span>
          </div>
          <p className="text-xs text-white/80 mb-3">
            Get AI customer service and advanced analytics.
          </p>
          <button className="w-full py-2 px-4 bg-[#F5F0E8] text-[#1B4332] rounded-xl text-sm font-semibold hover:bg-white transition-colors">
            Upgrade
          </button>
        </div>
      </div>

      {/* Sign Out */}
      <div className="border-t border-[#E8E0D5] p-3">
        <button
          onClick={logout}
          className="flex w-full items-center space-x-3 rounded-xl px-3 py-2.5 text-sm font-medium text-[#1B4332] hover:bg-[#F5F0E8] transition-colors"
        >
          <LogOut className="h-5 w-5 text-[#4F8A6D]" />
          <span>Sign out</span>
        </button>
      </div>
    </div>
  )
}
