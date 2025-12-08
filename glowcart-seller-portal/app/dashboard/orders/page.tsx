"use client"

import { useState } from "react"
import { Search, ChevronDown, ChevronRight, Filter, ArrowUpDown, MoreHorizontal, Eye, Check, X, Truck, MessageSquare, FileText } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { DUMMY_ORDERS } from "@/lib/dummy-data"
import { formatCurrency, formatDateTime } from "@/lib/utils"
import { Order, OrderStatus } from "@/types"

export default function OrdersPage() {
  const [orders] = useState<Order[]>(DUMMY_ORDERS)
  const [searchQuery, setSearchQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState<OrderStatus | "all">("all")
  const [expandedRows, setExpandedRows] = useState<Set<string>>(new Set())
  const [selectedRows, setSelectedRows] = useState<Set<string>>(new Set())

  const filteredOrders = orders.filter((order) => {
    const matchesSearch = order.orderId.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesStatus = statusFilter === "all" || order.status === statusFilter
    return matchesSearch && matchesStatus
  })

  const toggleRow = (orderId: string) => {
    const newExpanded = new Set(expandedRows)
    if (newExpanded.has(orderId)) {
      newExpanded.delete(orderId)
    } else {
      newExpanded.add(orderId)
    }
    setExpandedRows(newExpanded)
  }

  const toggleSelect = (orderId: string) => {
    const newSelected = new Set(selectedRows)
    if (newSelected.has(orderId)) {
      newSelected.delete(orderId)
    } else {
      newSelected.add(orderId)
    }
    setSelectedRows(newSelected)
  }

  const toggleSelectAll = () => {
    if (selectedRows.size === filteredOrders.length) {
      setSelectedRows(new Set())
    } else {
      setSelectedRows(new Set(filteredOrders.map(o => o.orderId)))
    }
  }

  const getStatusBadge = (status: OrderStatus) => {
    const styles = {
      pending: "bg-[#FEF3C7] text-[#92400E]",
      processing: "bg-[#DBEAFE] text-[#1E40AF]",
      in_transit: "bg-[#E8E0D5] text-[#1B4332]",
      delivered: "bg-[#D1E7DD] text-[#1B4332]",
      cancelled: "bg-[#FEE2E2] text-[#991B1B]",
    }
    return styles[status]
  }

  const getPaymentStatus = () => {
    return { label: "Paid", style: "bg-[#E8E0D5] text-[#1B4332]" }
  }

  const getFulfillmentStatus = (status: OrderStatus) => {
    const styles = {
      pending: { label: "Unfulfilled", style: "bg-[#FEF3C7] text-[#92400E]" },
      processing: { label: "Unfulfilled", style: "bg-[#FEF3C7] text-[#92400E]" },
      in_transit: { label: "In transit", style: "bg-[#DBEAFE] text-[#1E40AF]" },
      delivered: { label: "Fulfilled", style: "bg-[#D1E7DD] text-[#1B4332]" },
      cancelled: { label: "Cancelled", style: "bg-[#FEE2E2] text-[#991B1B]" },
    }
    return styles[status]
  }

  // Calculate metrics
  const metrics = {
    total: orders.length,
    pending: orders.filter(o => o.status === "pending").length,
    processing: orders.filter(o => o.status === "processing").length,
    delivered: orders.filter(o => o.status === "delivered").length,
  }

  const statusTabs = [
    { key: "all", label: "All" },
    { key: "pending", label: "Unfulfilled" },
    { key: "processing", label: "Open" },
    { key: "delivered", label: "Closed" },
  ]

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <h1 className="text-xl font-semibold text-[#1B4332]">Orders: All locations</h1>
          <ChevronDown className="h-4 w-4 text-[#8C9A8F]" />
        </div>
        <div className="flex items-center space-x-2">
          <Button variant="outline" size="sm">Export</Button>
          <Button variant="outline" size="sm">More actions</Button>
          <Button size="sm">Create order</Button>
        </div>
      </div>

      {/* Metrics Cards */}
      <div className="grid grid-cols-5 gap-4">
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs text-[#8C9A8F]">30 days</span>
            <ChevronDown className="h-3 w-3 text-[#8C9A8F]" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Orders</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.total}</p>
          <p className="text-xs text-[#4F8A6D]">↑ 45%</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Ordered items</p>
          <p className="text-2xl font-bold text-[#1B4332]">{orders.reduce((acc, o) => acc + o.items.length, 0)}</p>
          <p className="text-xs text-[#4F8A6D]">↑ 28%</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Fulfilled orders</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.delivered}</p>
          <p className="text-xs text-[#4F8A6D]">↑ 11%</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Delivered orders</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.delivered}</p>
          <p className="text-xs text-[#4F8A6D]">↑ 45%</p>
        </div>
      </div>

      {/* Status Tabs */}
      <div className="flex items-center space-x-1 border-b border-[#E8E0D5]">
        {statusTabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setStatusFilter(tab.key as OrderStatus | "all")}
            className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
              statusFilter === tab.key
                ? "border-[#1B4332] text-[#1B4332]"
                : "border-transparent text-[#8C9A8F] hover:text-[#1B4332]"
            }`}
          >
            {tab.label}
          </button>
        ))}
        <button className="px-4 py-2 text-sm text-[#8C9A8F] hover:text-[#1B4332]">+</button>
      </div>

      {/* Search and Filters */}
      <div className="flex items-center space-x-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
          <Input
            placeholder="Search orders"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 bg-white border-[#E8E0D5]"
          />
        </div>
        <Button variant="outline" size="sm">
          <Filter className="h-4 w-4" />
        </Button>
        <Button variant="outline" size="sm">
          <ArrowUpDown className="h-4 w-4" />
        </Button>
      </div>

      {/* Orders Table */}
      <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
        {/* Table Header */}
        <div className="grid grid-cols-[40px_100px_150px_150px_100px_120px_130px_80px] gap-4 px-4 py-3 bg-[#F5F0E8] border-b border-[#E8E0D5] text-xs font-medium text-[#8C9A8F] uppercase tracking-wide">
          <div className="flex items-center">
            <input
              type="checkbox"
              checked={selectedRows.size === filteredOrders.length && filteredOrders.length > 0}
              onChange={toggleSelectAll}
              className="h-4 w-4 rounded border-[#E8E0D5] text-[#1B4332] focus:ring-[#1B4332]"
            />
          </div>
          <div className="flex items-center space-x-1">
            <span>Order</span>
            <ArrowUpDown className="h-3 w-3" />
          </div>
          <div>Date</div>
          <div>Customer</div>
          <div>Total</div>
          <div>Payment</div>
          <div>Fulfillment</div>
          <div>Items</div>
        </div>

        {/* Table Body */}
        <div className="divide-y divide-[#E8E0D5]">
          {filteredOrders.map((order) => {
            const payment = getPaymentStatus()
            const fulfillment = getFulfillmentStatus(order.status)
            
            return (
              <div key={order.orderId}>
                {/* Main Row */}
                <div 
                  className={`grid grid-cols-[40px_100px_150px_150px_100px_120px_130px_80px] gap-4 px-4 py-3 items-center hover:bg-[#FAF8F5] transition-colors cursor-pointer ${
                    selectedRows.has(order.orderId) ? "bg-[#E8F5EE]" : ""
                  }`}
                >
                  <div className="flex items-center">
                    <input
                      type="checkbox"
                      checked={selectedRows.has(order.orderId)}
                      onChange={() => toggleSelect(order.orderId)}
                      className="h-4 w-4 rounded border-[#E8E0D5] text-[#1B4332] focus:ring-[#1B4332]"
                    />
                  </div>

                  {/* Order ID */}
                  <div 
                    className="flex items-center space-x-1 cursor-pointer"
                    onClick={() => toggleRow(order.orderId)}
                  >
                    {expandedRows.has(order.orderId) ? (
                      <ChevronDown className="h-4 w-4 text-[#8C9A8F]" />
                    ) : (
                      <ChevronRight className="h-4 w-4 text-[#8C9A8F]" />
                    )}
                    <span className="text-sm font-medium text-[#1B4332]">#{order.orderId.slice(-4)}</span>
                    <MessageSquare className="h-3 w-3 text-[#8C9A8F]" />
                  </div>

                  {/* Date */}
                  <div className="text-sm text-[#1B4332]">
                    {formatDateTime(order.createdAt)}
                  </div>

                  {/* Customer */}
                  <div className="text-sm text-[#1B4332]">
                    Customer #{order.buyerId.slice(-1)}
                  </div>

                  {/* Total */}
                  <div className="text-sm font-medium text-[#1B4332]">
                    {formatCurrency(order.totalAmount)}
                  </div>

                  {/* Payment Status */}
                  <div>
                    <span className={`inline-flex items-center px-2 py-1 text-xs font-medium rounded-full ${payment.style}`}>
                      <span className="w-1.5 h-1.5 rounded-full bg-current mr-1.5"></span>
                      {payment.label}
                    </span>
                  </div>

                  {/* Fulfillment Status */}
                  <div>
                    <span className={`inline-flex items-center px-2 py-1 text-xs font-medium rounded-full ${fulfillment.style}`}>
                      <span className="w-1.5 h-1.5 rounded-full bg-current mr-1.5"></span>
                      {fulfillment.label}
                    </span>
                  </div>

                  {/* Items */}
                  <div className="text-sm text-[#8C9A8F]">
                    {order.items.length} item{order.items.length > 1 ? "s" : ""}
                  </div>
                </div>

                {/* Expanded Details */}
                {expandedRows.has(order.orderId) && (
                  <div className="px-4 py-4 bg-[#FAF8F5] border-t border-[#E8E0D5]">
                    <div className="ml-[40px] grid grid-cols-3 gap-6">
                      {/* Items */}
                      <div>
                        <h4 className="text-xs font-medium text-[#8C9A8F] uppercase mb-3">Order Items</h4>
                        <div className="space-y-2">
                          {order.items.map((item, idx) => (
                            <div key={idx} className="flex items-center justify-between text-sm">
                              <div className="flex items-center space-x-2">
                                <div className="h-8 w-8 rounded bg-[#E8E0D5] flex items-center justify-center text-xs">📦</div>
                                <div>
                                  <p className="text-[#1B4332]">{item.productName}</p>
                                  <p className="text-xs text-[#8C9A8F]">Qty: {item.quantity}</p>
                                </div>
                              </div>
                              <span className="font-medium text-[#1B4332]">{formatCurrency(item.price * item.quantity)}</span>
                            </div>
                          ))}
                        </div>
                      </div>

                      {/* Delivery Address */}
                      <div>
                        <h4 className="text-xs font-medium text-[#8C9A8F] uppercase mb-3">Delivery Address</h4>
                        <div className="text-sm text-[#1B4332] space-y-1">
                          <p>{order.deliveryAddress.streetAddress}</p>
                          <p>{order.deliveryAddress.city}, {order.deliveryAddress.state}</p>
                          <p>{order.deliveryAddress.postalCode}, {order.deliveryAddress.country}</p>
                        </div>
                      </div>

                      {/* Actions */}
                      <div>
                        <h4 className="text-xs font-medium text-[#8C9A8F] uppercase mb-3">Actions</h4>
                        <div className="flex flex-wrap gap-2">
                          <Button variant="outline" size="sm">
                            <Eye className="h-3.5 w-3.5 mr-1" />
                            View
                          </Button>
                          <Button variant="outline" size="sm">
                            <FileText className="h-3.5 w-3.5 mr-1" />
                            Invoice
                          </Button>
                          {order.status === "pending" && (
                            <>
                              <Button size="sm">
                                <Check className="h-3.5 w-3.5 mr-1" />
                                Accept
                              </Button>
                              <Button variant="outline" size="sm" className="text-[#991B1B] hover:bg-[#FEE2E2]">
                                <X className="h-3.5 w-3.5 mr-1" />
                                Reject
                              </Button>
                            </>
                          )}
                          {order.status === "processing" && (
                            <Button size="sm">
                              <Truck className="h-3.5 w-3.5 mr-1" />
                              Ship
                            </Button>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )
          })}
        </div>

        {/* Empty State */}
        {filteredOrders.length === 0 && (
          <div className="py-12 text-center">
            <p className="text-[#8C9A8F]">No orders found matching your criteria.</p>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="flex items-center justify-between text-sm text-[#8C9A8F]">
        <span>{filteredOrders.length} orders</span>
        {selectedRows.size > 0 && (
          <span>{selectedRows.size} selected</span>
        )}
      </div>
    </div>
  )
}
