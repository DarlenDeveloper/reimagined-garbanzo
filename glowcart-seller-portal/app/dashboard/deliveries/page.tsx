"use client"

import { useState } from "react"
import { Truck, MapPin, Phone, User, ExternalLink, RefreshCw, Search, ChevronDown, ChevronRight, Filter, ArrowUpDown, MoreHorizontal, Clock } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { DUMMY_DELIVERIES } from "@/lib/dummy-data"
import { formatDateTime } from "@/lib/utils"
import { Delivery } from "@/types"

type DeliveryStatus = Delivery["status"]

export default function DeliveriesPage() {
  const [deliveries] = useState<Delivery[]>(DUMMY_DELIVERIES)
  const [searchQuery, setSearchQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState<DeliveryStatus | "all">("all")
  const [expandedRows, setExpandedRows] = useState<Set<string>>(new Set())
  const [selectedRows, setSelectedRows] = useState<Set<string>>(new Set())

  const filteredDeliveries = deliveries.filter((delivery) => {
    const matchesSearch = delivery.deliveryId.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          delivery.orderId.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesStatus = statusFilter === "all" || delivery.status === statusFilter
    return matchesSearch && matchesStatus
  })

  const toggleRow = (deliveryId: string) => {
    const newExpanded = new Set(expandedRows)
    if (newExpanded.has(deliveryId)) {
      newExpanded.delete(deliveryId)
    } else {
      newExpanded.add(deliveryId)
    }
    setExpandedRows(newExpanded)
  }

  const toggleSelect = (deliveryId: string) => {
    const newSelected = new Set(selectedRows)
    if (newSelected.has(deliveryId)) {
      newSelected.delete(deliveryId)
    } else {
      newSelected.add(deliveryId)
    }
    setSelectedRows(newSelected)
  }

  const toggleSelectAll = () => {
    if (selectedRows.size === filteredDeliveries.length) {
      setSelectedRows(new Set())
    } else {
      setSelectedRows(new Set(filteredDeliveries.map(d => d.deliveryId)))
    }
  }

  const getStatusBadge = (status: DeliveryStatus) => {
    const styles = {
      pending: "bg-[#FEF3C7] text-[#92400E]",
      assigned: "bg-[#DBEAFE] text-[#1E40AF]",
      picked_up: "bg-[#E8E0D5] text-[#1B4332]",
      in_transit: "bg-[#DBEAFE] text-[#1E40AF]",
      delivered: "bg-[#D1E7DD] text-[#1B4332]",
      failed: "bg-[#FEE2E2] text-[#991B1B]",
    }
    return styles[status]
  }

  const metrics = {
    pending: deliveries.filter(d => d.status === "pending").length,
    inTransit: deliveries.filter(d => ["picked_up", "in_transit", "assigned"].includes(d.status)).length,
    delivered: deliveries.filter(d => d.status === "delivered").length,
    failed: deliveries.filter(d => d.status === "failed").length,
  }

  const statusTabs = [
    { key: "all", label: "All" },
    { key: "pending", label: "Pending" },
    { key: "in_transit", label: "In Transit" },
    { key: "delivered", label: "Delivered" },
    { key: "failed", label: "Failed" },
  ]

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <h1 className="text-xl font-semibold text-[#1B4332]">Deliveries</h1>
          <ChevronDown className="h-4 w-4 text-[#8C9A8F]" />
        </div>
        <div className="flex items-center space-x-2">
          <Button variant="outline" size="sm">Export</Button>
          <Button size="sm">
            <RefreshCw className="h-4 w-4 mr-1" />
            Refresh Status
          </Button>
        </div>
      </div>

      {/* Metrics Cards */}
      <div className="grid grid-cols-5 gap-4">
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs text-[#8C9A8F]">Today</span>
            <ChevronDown className="h-3 w-3 text-[#8C9A8F]" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Pending</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.pending}</p>
          <p className="text-xs text-[#92400E]">Awaiting pickup</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">In Transit</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.inTransit}</p>
          <p className="text-xs text-[#1E40AF]">On the way</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Delivered</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.delivered}</p>
          <p className="text-xs text-[#1B4332]">Completed</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Failed</p>
          <p className="text-2xl font-bold text-[#991B1B]">{metrics.failed}</p>
          <p className="text-xs text-[#991B1B]">Need attention</p>
        </div>
      </div>

      {/* Status Tabs */}
      <div className="flex items-center space-x-1 border-b border-[#E8E0D5]">
        {statusTabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setStatusFilter(tab.key as DeliveryStatus | "all")}
            className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
              statusFilter === tab.key
                ? "border-[#1B4332] text-[#1B4332]"
                : "border-transparent text-[#8C9A8F] hover:text-[#1B4332]"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Search and Filters */}
      <div className="flex items-center space-x-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
          <Input
            placeholder="Search deliveries..."
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

      {/* Deliveries Table */}
      <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
        {/* Table Header */}
        <div className="grid grid-cols-[40px_120px_120px_150px_120px_120px_100px_50px] gap-4 px-4 py-3 bg-[#F5F0E8] border-b border-[#E8E0D5] text-xs font-medium text-[#8C9A8F] uppercase tracking-wide">
          <div className="flex items-center">
            <input
              type="checkbox"
              checked={selectedRows.size === filteredDeliveries.length && filteredDeliveries.length > 0}
              onChange={toggleSelectAll}
              className="h-4 w-4 rounded border-[#E8E0D5] text-[#1B4332] focus:ring-[#1B4332]"
            />
          </div>
          <div className="flex items-center space-x-1">
            <span>Delivery</span>
            <ArrowUpDown className="h-3 w-3" />
          </div>
          <div>Order</div>
          <div>Provider</div>
          <div>Status</div>
          <div>Est. Delivery</div>
          <div>Driver</div>
          <div></div>
        </div>

        {/* Table Body */}
        <div className="divide-y divide-[#E8E0D5]">
          {filteredDeliveries.map((delivery) => (
            <div key={delivery.deliveryId}>
              {/* Main Row */}
              <div 
                className={`grid grid-cols-[40px_120px_120px_150px_120px_120px_100px_50px] gap-4 px-4 py-3 items-center hover:bg-[#FAF8F5] transition-colors cursor-pointer ${
                  selectedRows.has(delivery.deliveryId) ? "bg-[#E8F5EE]" : ""
                }`}
              >
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    checked={selectedRows.has(delivery.deliveryId)}
                    onChange={() => toggleSelect(delivery.deliveryId)}
                    className="h-4 w-4 rounded border-[#E8E0D5] text-[#1B4332] focus:ring-[#1B4332]"
                  />
                </div>

                {/* Delivery ID */}
                <div 
                  className="flex items-center space-x-1 cursor-pointer"
                  onClick={() => toggleRow(delivery.deliveryId)}
                >
                  {expandedRows.has(delivery.deliveryId) ? (
                    <ChevronDown className="h-4 w-4 text-[#8C9A8F]" />
                  ) : (
                    <ChevronRight className="h-4 w-4 text-[#8C9A8F]" />
                  )}
                  <span className="text-sm font-medium text-[#1B4332]">#{delivery.deliveryId.slice(-5)}</span>
                </div>

                {/* Order ID */}
                <div className="text-sm text-[#1B4332]">
                  #{delivery.orderId.slice(-4)}
                </div>

                {/* Provider */}
                <div className="flex items-center space-x-2">
                  <Truck className="h-4 w-4 text-[#8C9A8F]" />
                  <span className="text-sm text-[#1B4332] capitalize">{delivery.deliveryProvider}</span>
                </div>

                {/* Status */}
                <div>
                  <span className={`inline-flex items-center px-2 py-1 text-xs font-medium rounded-full ${getStatusBadge(delivery.status)}`}>
                    <span className="w-1.5 h-1.5 rounded-full bg-current mr-1.5"></span>
                    {delivery.status.replace("_", " ")}
                  </span>
                </div>

                {/* Est. Delivery */}
                <div className="text-sm text-[#8C9A8F]">
                  {delivery.estimatedDeliveryTime ? new Date(delivery.estimatedDeliveryTime).toLocaleDateString() : "—"}
                </div>

                {/* Driver */}
                <div className="text-sm text-[#1B4332]">
                  {delivery.driverName || "—"}
                </div>

                {/* Actions */}
                <div>
                  <button className="p-1.5 rounded-lg hover:bg-[#E8E0D5] transition-colors">
                    <MoreHorizontal className="h-4 w-4 text-[#8C9A8F]" />
                  </button>
                </div>
              </div>

              {/* Expanded Details */}
              {expandedRows.has(delivery.deliveryId) && (
                <div className="px-4 py-4 bg-[#FAF8F5] border-t border-[#E8E0D5]">
                  <div className="ml-[40px] grid grid-cols-3 gap-6">
                    {/* Addresses */}
                    <div className="space-y-4">
                      <div className="p-3 border border-[#E8E0D5] rounded-lg bg-white">
                        <div className="flex items-center space-x-2 mb-2">
                          <MapPin className="h-4 w-4 text-[#1B4332]" />
                          <span className="text-xs font-medium text-[#8C9A8F] uppercase">Pickup Address</span>
                        </div>
                        <p className="text-sm text-[#1B4332]">
                          {delivery.pickupAddress.streetAddress}<br />
                          {delivery.pickupAddress.city}, {delivery.pickupAddress.state} {delivery.pickupAddress.postalCode}
                        </p>
                      </div>
                      <div className="p-3 border border-[#E8E0D5] rounded-lg bg-white">
                        <div className="flex items-center space-x-2 mb-2">
                          <MapPin className="h-4 w-4 text-[#4F8A6D]" />
                          <span className="text-xs font-medium text-[#8C9A8F] uppercase">Dropoff Address</span>
                        </div>
                        <p className="text-sm text-[#1B4332]">
                          {delivery.dropoffAddress.streetAddress}<br />
                          {delivery.dropoffAddress.city}, {delivery.dropoffAddress.state} {delivery.dropoffAddress.postalCode}
                        </p>
                      </div>
                    </div>

                    {/* Timeline */}
                    <div>
                      <h4 className="text-xs font-medium text-[#8C9A8F] uppercase mb-3">Timeline</h4>
                      <div className="space-y-3 text-sm">
                        <div className="flex items-center justify-between">
                          <span className="text-[#8C9A8F]">Est. Pickup</span>
                          <span className="text-[#1B4332]">{delivery.estimatedPickupTime ? formatDateTime(delivery.estimatedPickupTime) : "—"}</span>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-[#8C9A8F]">Est. Delivery</span>
                          <span className="text-[#1B4332]">{delivery.estimatedDeliveryTime ? formatDateTime(delivery.estimatedDeliveryTime) : "—"}</span>
                        </div>
                        {delivery.actualPickupTime && (
                          <div className="flex items-center justify-between">
                            <span className="text-[#8C9A8F]">Actual Pickup</span>
                            <span className="text-[#1B4332]">{formatDateTime(delivery.actualPickupTime)}</span>
                          </div>
                        )}
                        {delivery.actualDeliveryTime && (
                          <div className="flex items-center justify-between">
                            <span className="text-[#8C9A8F]">Actual Delivery</span>
                            <span className="text-[#1B4332]">{formatDateTime(delivery.actualDeliveryTime)}</span>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Actions */}
                    <div>
                      <h4 className="text-xs font-medium text-[#8C9A8F] uppercase mb-3">Actions</h4>
                      {delivery.driverName && (
                        <div className="p-3 bg-white border border-[#E8E0D5] rounded-lg mb-3">
                          <div className="flex items-center space-x-3">
                            <div className="h-8 w-8 rounded-full bg-[#1B4332] flex items-center justify-center text-white text-sm font-medium">
                              {delivery.driverName.charAt(0)}
                            </div>
                            <div>
                              <p className="text-sm font-medium text-[#1B4332]">{delivery.driverName}</p>
                              {delivery.driverPhone && (
                                <p className="text-xs text-[#8C9A8F]">{delivery.driverPhone}</p>
                              )}
                            </div>
                          </div>
                        </div>
                      )}
                      <div className="flex flex-wrap gap-2">
                        {delivery.trackingUrl && (
                          <Button variant="outline" size="sm">
                            <ExternalLink className="h-3.5 w-3.5 mr-1" />
                            Track
                          </Button>
                        )}
                        {delivery.status === "pending" && (
                          <Button size="sm">Request Pickup</Button>
                        )}
                        {delivery.status === "failed" && (
                          <Button size="sm">Retry</Button>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Empty State */}
        {filteredDeliveries.length === 0 && (
          <div className="py-12 text-center">
            <Truck className="h-12 w-12 text-[#E8E0D5] mx-auto mb-4" />
            <p className="text-[#8C9A8F]">No deliveries found.</p>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="flex items-center justify-between text-sm text-[#8C9A8F]">
        <span>{filteredDeliveries.length} deliveries</span>
        {selectedRows.size > 0 && (
          <span>{selectedRows.size} selected</span>
        )}
      </div>
    </div>
  )
}
