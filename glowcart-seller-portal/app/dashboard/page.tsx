"use client"

import { Eye, Users, ShoppingCart, TrendingUp, TrendingDown, MoreVertical } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { DUMMY_METRICS, DUMMY_ORDERS } from "@/lib/dummy-data"
import { formatCurrency } from "@/lib/utils"

export default function DashboardPage() {
  const metrics = DUMMY_METRICS
  const recentOrders = DUMMY_ORDERS.slice(0, 4)

  return (
    <div className="space-y-6">
      {/* Top Stats Row */}
      <div className="grid gap-4 md:grid-cols-3">
        {/* Views Card */}
        <Card className="bg-white rounded-2xl border-0 shadow-sm card-hover">
          <CardContent className="p-5">
            <div className="flex items-start justify-between">
              <div className="p-3 rounded-xl bg-[#D1E7DD]">
                <Eye className="h-5 w-5 text-[#1B4332]" />
              </div>
              <button className="text-[#8C9A8F] hover:text-[#1B4332]">
                <MoreVertical className="h-5 w-5" />
              </button>
            </div>
            <div className="mt-4">
              <p className="text-sm text-[#4F8A6D]">Views</p>
              <div className="flex items-baseline space-x-2 mt-1">
                <span className="text-2xl font-bold text-[#1B4332]">1,696</span>
                <span className="text-sm font-medium text-[#1B4332] flex items-center">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  +45%
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Visits Card */}
        <Card className="bg-white rounded-2xl border-0 shadow-sm card-hover">
          <CardContent className="p-5">
            <div className="flex items-start justify-between">
              <div className="p-3 rounded-xl bg-[#F3D9EC]">
                <Users className="h-5 w-5 text-[#4A1942]" />
              </div>
              <button className="text-[#8C9A8F] hover:text-[#1B4332]">
                <MoreVertical className="h-5 w-5" />
              </button>
            </div>
            <div className="mt-4">
              <p className="text-sm text-[#4F8A6D]">Visits</p>
              <div className="flex items-baseline space-x-2 mt-1">
                <span className="text-2xl font-bold text-[#1B4332]">3,490</span>
                <span className="text-sm font-medium text-[#1B4332] flex items-center">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  +32%
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Orders Card */}
        <Card className="bg-white rounded-2xl border-0 shadow-sm card-hover">
          <CardContent className="p-5">
            <div className="flex items-start justify-between">
              <div className="p-3 rounded-xl bg-[#E8E0D5]">
                <ShoppingCart className="h-5 w-5 text-[#1B4332]" />
              </div>
              <button className="text-[#8C9A8F] hover:text-[#1B4332]">
                <MoreVertical className="h-5 w-5" />
              </button>
            </div>
            <div className="mt-4">
              <p className="text-sm text-[#4F8A6D]">Orders</p>
              <div className="flex items-baseline space-x-2 mt-1">
                <span className="text-2xl font-bold text-[#1B4332]">{metrics.orderCount}</span>
                <span className="text-sm font-medium text-[#1B4332] flex items-center">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  +24%
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Stats Bar + Last Orders */}
      <div className="grid gap-6 lg:grid-cols-3">
        {/* Gradient Stats Bar */}
        <div className="lg:col-span-2">
          <div className="rounded-2xl p-6 bg-gradient-to-r from-[#D1E7DD] via-[#F5F0E8] to-[#F3D9EC]">
            <div className="grid grid-cols-3 gap-6">
              {/* Income */}
              <div className="flex items-center space-x-4">
                <div className="relative">
                  <svg className="w-16 h-16 transform -rotate-90">
                    <circle cx="32" cy="32" r="28" stroke="#E8E0D5" strokeWidth="4" fill="none" />
                    <circle cx="32" cy="32" r="28" stroke="#1B4332" strokeWidth="4" fill="none" 
                      strokeDasharray="176" strokeDashoffset="62" strokeLinecap="round" />
                  </svg>
                  <span className="absolute inset-0 flex items-center justify-center text-xs font-semibold text-[#1B4332]">65%</span>
                </div>
                <div>
                  <p className="text-sm text-[#4F8A6D]">Income</p>
                  <p className="text-xs text-[#8C9A8F]">Today</p>
                  <p className="text-xl font-bold text-[#1B4332]">{formatCurrency(metrics.netEarnings)}</p>
                </div>
              </div>

              {/* Sales */}
              <div className="flex items-center space-x-4">
                <div className="relative">
                  <svg className="w-16 h-16 transform -rotate-90">
                    <circle cx="32" cy="32" r="28" stroke="#E8E0D5" strokeWidth="4" fill="none" />
                    <circle cx="32" cy="32" r="28" stroke="#4A1942" strokeWidth="4" fill="none" 
                      strokeDasharray="176" strokeDashoffset="106" strokeLinecap="round" />
                  </svg>
                  <span className="absolute inset-0 flex items-center justify-center text-xs font-semibold text-[#4A1942]">40%</span>
                </div>
                <div>
                  <div className="flex items-center space-x-1">
                    <p className="text-sm text-[#4F8A6D]">Sales</p>
                    <TrendingDown className="h-3 w-3 text-[#4A1942]" />
                  </div>
                  <p className="text-xs text-[#8C9A8F]">Per hour</p>
                  <p className="text-xl font-bold text-[#1B4332]">{formatCurrency(metrics.totalSales / 24)}</p>
                </div>
              </div>

              {/* Visits */}
              <div className="flex items-center space-x-4">
                <div className="relative">
                  <svg className="w-16 h-16 transform -rotate-90">
                    <circle cx="32" cy="32" r="28" stroke="#E8E0D5" strokeWidth="4" fill="none" />
                    <circle cx="32" cy="32" r="28" stroke="#2D5A45" strokeWidth="4" fill="none" 
                      strokeDasharray="176" strokeDashoffset="44" strokeLinecap="round" />
                  </svg>
                  <span className="absolute inset-0 flex items-center justify-center text-xs font-semibold text-[#2D5A45]">75%</span>
                </div>
                <div>
                  <div className="flex items-center space-x-1">
                    <p className="text-sm text-[#4F8A6D]">Visits</p>
                    <TrendingUp className="h-3 w-3 text-[#1B4332]" />
                  </div>
                  <p className="text-xs text-[#8C9A8F]">Total today</p>
                  <p className="text-xl font-bold text-[#1B4332]">2,600</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Last Orders */}
        <Card className="bg-white rounded-2xl border-0 shadow-sm">
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg font-semibold">Last orders</CardTitle>
              <button className="text-sm text-[#4A1942] hover:text-[#6B2D5C] font-medium">View all</button>
            </div>
          </CardHeader>
          <CardContent className="pt-0">
            <div className="space-y-4">
              {recentOrders.map((order) => (
                <div key={order.orderId} className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <div className="h-10 w-10 rounded-full bg-gradient-to-br from-[#1B4332] to-[#4A1942] flex items-center justify-center text-white font-semibold text-sm">
                      {order.orderId.slice(-1)}
                    </div>
                    <div>
                      <p className="font-medium text-sm text-[#1B4332]">Customer {order.orderId.slice(-1)}</p>
                      <p className="text-xs text-[#8C9A8F]">items: {order.items.reduce((sum, i) => sum + i.quantity, 0)}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-sm text-[#1B4332]">{formatCurrency(order.totalAmount)}</p>
                    <span className={`text-xs font-medium ${
                      order.status === "delivered" ? "text-[#1B4332]" :
                      order.status === "processing" ? "text-[#4A1942]" :
                      order.status === "pending" ? "text-[#BFB09D]" :
                      "text-[#8C9A8F]"
                    }`}>
                      {order.status === "delivered" ? "Complete" :
                       order.status === "processing" ? "Processing" :
                       order.status === "pending" ? "Pending" :
                       order.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Bottom Section */}
      <div className="grid gap-6 lg:grid-cols-3">
        {/* Products Sold Chart */}
        <Card className="bg-white rounded-2xl border-0 shadow-sm">
          <CardHeader>
            <CardTitle className="text-lg font-semibold">Products sold</CardTitle>
            <p className="text-sm text-[#8C9A8F]">{metrics.topProducts.reduce((sum, p) => sum + p.sales, 0)} Products</p>
          </CardHeader>
          <CardContent>
            <div className="flex items-end justify-between h-40 px-2">
              {["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((day, i) => {
                const heights = [40, 60, 80, 100, 70, 120, 90]
                return (
                  <div key={day} className="flex flex-col items-center space-y-2">
                    <div 
                      className={`w-8 rounded-lg ${i === 5 ? 'bg-[#1B4332]' : 'bg-[#D4C9B9]'}`}
                      style={{ height: `${heights[i]}px` }}
                    />
                    <span className="text-xs text-[#8C9A8F]">{day.toLowerCase()}</span>
                  </div>
                )
              })}
            </div>
          </CardContent>
        </Card>

        {/* Sold Today */}
        <Card className="bg-white rounded-2xl border-0 shadow-sm">
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg font-semibold">Sold today</CardTitle>
              <button className="text-sm text-[#4A1942] hover:text-[#6B2D5C] font-medium">View all</button>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {metrics.topProducts.map((product) => (
                <div key={product.productId} className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <div className="h-12 w-12 rounded-xl bg-[#F5F0E8] flex items-center justify-center">
                      <span className="text-lg">📦</span>
                    </div>
                    <div>
                      <p className="font-medium text-sm text-[#1B4332]">{product.productName.split(" ").slice(0, 2).join(" ")}</p>
                      <p className="text-xs text-[#8C9A8F]">items: {product.sales}</p>
                    </div>
                  </div>
                  <p className="font-semibold text-sm text-[#1B4332]">{formatCurrency(product.revenue)}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Revenue Breakdown */}
        <Card className="bg-white rounded-2xl border-0 shadow-sm">
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg font-semibold">Revenue breakdown</CardTitle>
              <select className="text-sm text-[#8C9A8F] bg-transparent border-0 focus:ring-0">
                <option>Weekly</option>
                <option>Monthly</option>
              </select>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-sm text-[#4F8A6D]">Gross Sales</span>
                <span className="font-semibold text-[#1B4332]">{formatCurrency(metrics.totalSales)}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-[#4F8A6D]">Commission (3%)</span>
                <span className="font-semibold text-[#4A1942]">-{formatCurrency(metrics.commission)}</span>
              </div>
              <div className="border-t border-[#E8E0D5] pt-4">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-[#1B4332]">Net Earnings</span>
                  <span className="font-bold text-lg text-[#1B4332]">{formatCurrency(metrics.netEarnings)}</span>
                </div>
              </div>
              <div className="pt-2">
                <div className="flex items-center space-x-3 text-xs">
                  <span className="flex items-center"><span className="h-2 w-2 rounded-full bg-[#1B4332] mr-1"></span>Products</span>
                  <span className="flex items-center"><span className="h-2 w-2 rounded-full bg-[#4A1942] mr-1"></span>Services</span>
                  <span className="flex items-center"><span className="h-2 w-2 rounded-full bg-[#D4C9B9] mr-1"></span>Other</span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
