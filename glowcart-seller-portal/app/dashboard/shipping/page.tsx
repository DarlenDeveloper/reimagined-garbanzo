"use client"

import { useState } from "react"
import { Package, Download, Search, Plus, ExternalLink, ChevronDown, ChevronRight, Filter, ArrowUpDown, MoreHorizontal, Printer, Copy } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { DUMMY_SHIPMENTS } from "@/lib/dummy-data"
import { formatDateTime } from "@/lib/utils"
import { Shipment } from "@/types"

type ShipmentStatus = Shipment["status"]

export default function ShippingPage() {
  const [shipments] = useState<Shipment[]>(DUMMY_SHIPMENTS)
  const [searchQuery, setSearchQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState<ShipmentStatus | "all">("all")
  const [expandedRows, setExpandedRows] = useState<Set<string>>(new Set())
  const [selectedRows, setSelectedRows] = useState<Set<string>>(new Set())

  const filteredShipments = shipments.filter((shipment) => {
    const matchesSearch = shipment.trackingNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          shipment.orderId.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesStatus = statusFilter === "all" || shipment.status === statusFilter
    return matchesSearch && matchesStatus
  })

  const toggleRow = (shipmentId: string) => {
    const newExpanded = new Set(expandedRows)
    if (newExpanded.has(shipmentId)) {
      newExpanded.delete(shipmentId)
    } else {
      newExpanded.add(shipmentId)
    }
    setExpandedRows(newExpanded)
  }

  const toggleSelect = (shipmentId: string) => {
    const newSelected = new Set(selectedRows)
    if (newSelected.has(shipmentId)) {
      newSelected.delete(shipmentId)
    } else {
      newSelected.add(shipmentId)
    }
    setSelectedRows(newSelected)
  }

  const toggleSelectAll = () => {
    if (selectedRows.size === filteredShipments.length) {
      setSelectedRows(new Set())
    } else {
      setSelectedRows(new Set(filteredShipments.map(s => s.shipmentId)))
    }
  }

  const getStatusBadge = (status: ShipmentStatus) => {
    const styles = {
      pending: "bg-[#E8E0D5] text-[#1B4332]",
      label_created: "bg-[#DBEAFE] text-[#1E40AF]",
      picked_up: "bg-[#E8E0D5] text-[#1B4332]",
      in_transit: "bg-[#DBEAFE] text-[#1E40AF]",
      out_for_delivery: "bg-[#FEF3C7] text-[#92400E]",
      delivered: "bg-[#D1E7DD] text-[#1B4332]",
      returned: "bg-[#FEE2E2] text-[#991B1B]",
    }
    return styles[status]
  }

  const metrics = {
    pending: shipments.filter(s => s.status === "pending" || s.status === "label_created").length,
    inTransit: shipments.filter(s => ["picked_up", "in_transit", "out_for_delivery"].includes(s.status)).length,
    delivered: shipments.filter(s => s.status === "delivered").length,
    returned: shipments.filter(s => s.status === "returned").length,
  }

  const statusTabs = [
    { key: "all", label: "All" },
    { key: "pending", label: "Pending" },
    { key: "label_created", label: "Label Created" },
    { key: "in_transit", label: "In Transit" },
    { key: "delivered", label: "Delivered" },
  ]

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <h1 className="text-xl font-semibold text-[#1B4332]">Shipping</h1>
          <ChevronDown className="h-4 w-4 text-[#8C9A8F]" />
        </div>
        <div className="flex items-center space-x-2">
          <Button variant="outline" size="sm">Export</Button>
          <Button variant="outline" size="sm">Print Labels</Button>
          <Button size="sm">
            <Plus className="h-4 w-4 mr-1" />
            Create Shipment
          </Button>
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
          <p className="text-xs text-[#8C9A8F] mb-1">Pending</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.pending}</p>
          <p className="text-xs text-[#8C9A8F]">Awaiting shipment</p>
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
          <p className="text-xs text-[#8C9A8F] mb-1">Returned</p>
          <p className="text-2xl font-bold text-[#991B1B]">{metrics.returned}</p>
          <p className="text-xs text-[#991B1B]">Need attention</p>
        </div>
      </div>

      {/* Status Tabs */}
      <div className="flex items-center space-x-1 border-b border-[#E8E0D5]">
        {statusTabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setStatusFilter(tab.key as ShipmentStatus | "all")}
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
            placeholder="Search by tracking number or order ID..."
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

      {/* Shipments Table */}
      <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
        {/* Table Header */}
        <div className="grid grid-cols-[40px_120px_180px_100px_80px_120px_100px_50px] gap-4 px-4 py-3 bg-[#F5F0E8] border-b border-[#E8E0D5] text-xs font-medium text-[#8C9A8F] uppercase tracking-wide">
          <div className="flex items-center">
            <input
              type="checkbox"
              checked={selectedRows.size === filteredShipments.length && filteredShipments.length > 0}
              onChange={toggleSelectAll}
              className="h-4 w-4 rounded border-[#E8E0D5] text-[#1B4332] focus:ring-[#1B4332]"
            />
          </div>
          <div className="flex items-center space-x-1">
            <span>Order</span>
            <ArrowUpDown className="h-3 w-3" />
          </div>
          <div>Tracking Number</div>
          <div>Provider</div>
          <div>Weight</div>
          <div>Status</div>
          <div>Created</div>
          <div></div>
        </div>

        {/* Table Body */}
        <div className="divide-y divide-[#E8E0D5]">
          {filteredShipments.map((shipment) => (
            <div key={shipment.shipmentId}>
              {/* Main Row */}
              <div 
                className={`grid grid-cols-[40px_120px_180px_100px_80px_120px_100px_50px] gap-4 px-4 py-3 items-center hover:bg-[#FAF8F5] transition-colors cursor-pointer ${
                  selectedRows.has(shipment.shipmentId) ? "bg-[#E8F5EE]" : ""
                }`}
              >
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    checked={selectedRows.has(shipment.shipmentId)}
                    onChange={() => toggleSelect(shipment.shipmentId)}
                    className="h-4 w-4 rounded border-[#E8E0D5] text-[#1B4332] focus:ring-[#1B4332]"
                  />
                </div>

                {/* Order ID */}
                <div 
                  className="flex items-center space-x-1 cursor-pointer"
                  onClick={() => toggleRow(shipment.shipmentId)}
                >
                  {expandedRows.has(shipment.shipmentId) ? (
                    <ChevronDown className="h-4 w-4 text-[#8C9A8F]" />
                  ) : (
                    <ChevronRight className="h-4 w-4 text-[#8C9A8F]" />
                  )}
                  <span className="text-sm font-medium text-[#1B4332]">#{shipment.orderId.slice(-4)}</span>
                </div>

                {/* Tracking Number */}
                <div className="flex items-center space-x-2">
                  <Package className="h-4 w-4 text-[#8C9A8F]" />
                  <span className="text-sm font-mono text-[#1B4332]">{shipment.trackingNumber}</span>
                </div>

                {/* Provider */}
                <div className="text-sm text-[#1B4332] capitalize">
                  {shipment.shippingProvider}
                </div>

                {/* Weight */}
                <div className="text-sm text-[#8C9A8F]">
                  {shipment.weight ? `${shipment.weight} kg` : "—"}
                </div>

                {/* Status */}
                <div>
                  <span className={`inline-flex items-center px-2 py-1 text-xs font-medium rounded-full ${getStatusBadge(shipment.status)}`}>
                    <span className="w-1.5 h-1.5 rounded-full bg-current mr-1.5"></span>
                    {shipment.status.replace(/_/g, " ")}
                  </span>
                </div>

                {/* Created */}
                <div className="text-sm text-[#8C9A8F]">
                  {new Date(shipment.createdAt).toLocaleDateString()}
                </div>

                {/* Actions */}
                <div>
                  <button className="p-1.5 rounded-lg hover:bg-[#E8E0D5] transition-colors">
                    <MoreHorizontal className="h-4 w-4 text-[#8C9A8F]" />
                  </button>
                </div>
              </div>

              {/* Expanded Details */}
              {expandedRows.has(shipment.shipmentId) && (
                <div className="px-4 py-4 bg-[#FAF8F5] border-t border-[#E8E0D5]">
                  <div className="ml-[40px] grid grid-cols-3 gap-6">
                    {/* Shipment Details */}
                    <div>
                      <h4 className="text-xs font-medium text-[#8C9A8F] uppercase mb-3">Shipment Details</h4>
                      <div className="space-y-2 text-sm">
                        <div className="flex items-center justify-between">
                          <span className="text-[#8C9A8F]">Shipment ID</span>
                          <span className="text-[#1B4332] font-mono">{shipment.shipmentId}</span>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-[#8C9A8F]">Provider</span>
                          <span className="text-[#1B4332] capitalize">{shipment.shippingProvider}</span>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-[#8C9A8F]">Weight</span>
                          <span className="text-[#1B4332]">{shipment.weight ? `${shipment.weight} kg` : "—"}</span>
                        </div>
                        {shipment.dimensions && (
                          <div className="flex items-center justify-between">
                            <span className="text-[#8C9A8F]">Dimensions</span>
                            <span className="text-[#1B4332]">
                              {shipment.dimensions.length} × {shipment.dimensions.width} × {shipment.dimensions.height} cm
                            </span>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Timeline */}
                    <div>
                      <h4 className="text-xs font-medium text-[#8C9A8F] uppercase mb-3">Timeline</h4>
                      <div className="space-y-2 text-sm">
                        <div className="flex items-center justify-between">
                          <span className="text-[#8C9A8F]">Created</span>
                          <span className="text-[#1B4332]">{formatDateTime(shipment.createdAt)}</span>
                        </div>
                        {shipment.shippedAt && (
                          <div className="flex items-center justify-between">
                            <span className="text-[#8C9A8F]">Shipped</span>
                            <span className="text-[#1B4332]">{formatDateTime(shipment.shippedAt)}</span>
                          </div>
                        )}
                        {shipment.deliveredAt && (
                          <div className="flex items-center justify-between">
                            <span className="text-[#8C9A8F]">Delivered</span>
                            <span className="text-[#1B4332]">{formatDateTime(shipment.deliveredAt)}</span>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Actions */}
                    <div>
                      <h4 className="text-xs font-medium text-[#8C9A8F] uppercase mb-3">Actions</h4>
                      <div className="flex flex-wrap gap-2">
                        {shipment.shippingLabelUrl && (
                          <>
                            <Button variant="outline" size="sm">
                              <Download className="h-3.5 w-3.5 mr-1" />
                              Download Label
                            </Button>
                            <Button variant="outline" size="sm">
                              <Printer className="h-3.5 w-3.5 mr-1" />
                              Print
                            </Button>
                          </>
                        )}
                        <Button variant="outline" size="sm">
                          <Copy className="h-3.5 w-3.5 mr-1" />
                          Copy Tracking
                        </Button>
                        <Button variant="outline" size="sm">
                          <ExternalLink className="h-3.5 w-3.5 mr-1" />
                          Track
                        </Button>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Empty State */}
        {filteredShipments.length === 0 && (
          <div className="py-12 text-center">
            <Package className="h-12 w-12 text-[#E8E0D5] mx-auto mb-4" />
            <p className="text-[#8C9A8F]">No shipments found.</p>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="flex items-center justify-between text-sm text-[#8C9A8F]">
        <span>{filteredShipments.length} shipments</span>
        {selectedRows.size > 0 && (
          <span>{selectedRows.size} selected</span>
        )}
      </div>
    </div>
  )
}
