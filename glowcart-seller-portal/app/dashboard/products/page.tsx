"use client"

import { useState } from "react"
import { Plus, Search, ChevronDown, ChevronRight, Filter, ArrowUpDown, MoreHorizontal, Edit, Trash2, Copy } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { DUMMY_PRODUCTS, DUMMY_INVENTORY } from "@/lib/dummy-data"
import { formatCurrency } from "@/lib/utils"
import { Product } from "@/types"

export default function ProductsPage() {
  const [products] = useState<Product[]>(DUMMY_PRODUCTS)
  const [searchQuery, setSearchQuery] = useState("")
  const [expandedRows, setExpandedRows] = useState<Set<string>>(new Set())
  const [selectedRows, setSelectedRows] = useState<Set<string>>(new Set())

  const filteredProducts = products.filter((product) =>
    product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    product.sku?.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const toggleRow = (productId: string) => {
    const newExpanded = new Set(expandedRows)
    if (newExpanded.has(productId)) {
      newExpanded.delete(productId)
    } else {
      newExpanded.add(productId)
    }
    setExpandedRows(newExpanded)
  }

  const toggleSelect = (productId: string) => {
    const newSelected = new Set(selectedRows)
    if (newSelected.has(productId)) {
      newSelected.delete(productId)
    } else {
      newSelected.add(productId)
    }
    setSelectedRows(newSelected)
  }

  const toggleSelectAll = () => {
    if (selectedRows.size === filteredProducts.length) {
      setSelectedRows(new Set())
    } else {
      setSelectedRows(new Set(filteredProducts.map(p => p.productId)))
    }
  }

  const getStatusBadge = (status: string) => {
    const styles = {
      active: "bg-[#D1E7DD] text-[#1B4332]",
      inactive: "bg-[#E8E0D5] text-[#8C9A8F]",
      out_of_stock: "bg-[#FEE2E2] text-[#991B1B]",
    }
    return styles[status as keyof typeof styles] || styles.inactive
  }

  const getInventoryForProduct = (productId: string) => {
    const inv = DUMMY_INVENTORY.find(i => i.productId === productId)
    return inv ? `${inv.quantity} in stock` : "—"
  }

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <h1 className="text-xl font-semibold text-[#1B4332]">Products</h1>
          <ChevronDown className="h-4 w-4 text-[#8C9A8F]" />
        </div>
        <div className="flex items-center space-x-2">
          <Button variant="outline" size="sm">Export</Button>
          <Button variant="outline" size="sm">Import</Button>
          <Button size="sm">
            <Plus className="h-4 w-4 mr-1" />
            Add product
          </Button>
        </div>
      </div>

      {/* Search and Filters Bar */}
      <div className="bg-white rounded-xl border border-[#E8E0D5] p-3">
        <div className="flex items-center space-x-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
            <Input
              placeholder="Search items"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 bg-[#F5F0E8] border-0"
            />
          </div>
          <Button variant="outline" size="sm">
            <Filter className="h-4 w-4 mr-1" />
            Filters
          </Button>
          <Button variant="outline" size="sm">
            <ArrowUpDown className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Products Table */}
      <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
        {/* Table Header */}
        <div className="grid grid-cols-[40px_60px_1fr_120px_100px_120px_50px] gap-4 px-4 py-3 bg-[#F5F0E8] border-b border-[#E8E0D5] text-xs font-medium text-[#8C9A8F] uppercase tracking-wide">
          <div className="flex items-center">
            <input
              type="checkbox"
              checked={selectedRows.size === filteredProducts.length && filteredProducts.length > 0}
              onChange={toggleSelectAll}
              className="h-4 w-4 rounded border-[#E8E0D5] text-[#1B4332] focus:ring-[#1B4332]"
            />
          </div>
          <div></div>
          <div className="flex items-center space-x-1">
            <span>Product</span>
            <ArrowUpDown className="h-3 w-3" />
          </div>
          <div>Status</div>
          <div>Price</div>
          <div>Inventory</div>
          <div></div>
        </div>

        {/* Table Body */}
        <div className="divide-y divide-[#E8E0D5]">
          {filteredProducts.map((product) => (
            <div key={product.productId}>
              {/* Main Row */}
              <div 
                className={`grid grid-cols-[40px_60px_1fr_120px_100px_120px_50px] gap-4 px-4 py-3 items-center hover:bg-[#FAF8F5] transition-colors cursor-pointer ${
                  selectedRows.has(product.productId) ? "bg-[#E8F5EE]" : ""
                }`}
              >
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    checked={selectedRows.has(product.productId)}
                    onChange={() => toggleSelect(product.productId)}
                    className="h-4 w-4 rounded border-[#E8E0D5] text-[#1B4332] focus:ring-[#1B4332]"
                  />
                </div>
                
                {/* Product Image */}
                <div 
                  className="h-10 w-10 rounded-lg bg-[#F5F0E8] flex items-center justify-center cursor-pointer"
                  onClick={() => toggleRow(product.productId)}
                >
                  <span className="text-lg">📦</span>
                </div>

                {/* Product Name & SKU */}
                <div 
                  className="min-w-0 cursor-pointer"
                  onClick={() => toggleRow(product.productId)}
                >
                  <div className="flex items-center space-x-2">
                    {expandedRows.has(product.productId) ? (
                      <ChevronDown className="h-4 w-4 text-[#8C9A8F] flex-shrink-0" />
                    ) : (
                      <ChevronRight className="h-4 w-4 text-[#8C9A8F] flex-shrink-0" />
                    )}
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-[#1B4332] truncate">{product.name}</p>
                      <p className="text-xs text-[#8C9A8F]">{product.sku || "—"}</p>
                    </div>
                  </div>
                </div>

                {/* Status */}
                <div>
                  <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getStatusBadge(product.status)}`}>
                    {product.status === "out_of_stock" ? "Out of stock" : product.status.charAt(0).toUpperCase() + product.status.slice(1)}
                  </span>
                </div>

                {/* Price */}
                <div className="text-sm text-[#1B4332]">
                  {formatCurrency(product.price)}
                </div>

                {/* Inventory */}
                <div className="text-sm text-[#8C9A8F]">
                  {getInventoryForProduct(product.productId)}
                </div>

                {/* Actions */}
                <div>
                  <button className="p-1.5 rounded-lg hover:bg-[#E8E0D5] transition-colors">
                    <MoreHorizontal className="h-4 w-4 text-[#8C9A8F]" />
                  </button>
                </div>
              </div>

              {/* Expanded Details */}
              {expandedRows.has(product.productId) && (
                <div className="px-4 py-4 bg-[#FAF8F5] border-t border-[#E8E0D5]">
                  <div className="ml-[100px] grid grid-cols-3 gap-6">
                    <div>
                      <h4 className="text-xs font-medium text-[#8C9A8F] uppercase mb-2">Description</h4>
                      <p className="text-sm text-[#1B4332]">{product.description || "No description"}</p>
                    </div>
                    <div>
                      <h4 className="text-xs font-medium text-[#8C9A8F] uppercase mb-2">Details</h4>
                      <div className="space-y-1 text-sm">
                        <p><span className="text-[#8C9A8F]">SKU:</span> <span className="text-[#1B4332]">{product.sku || "—"}</span></p>
                        <p><span className="text-[#8C9A8F]">Category:</span> <span className="text-[#1B4332]">{product.categoryId || "—"}</span></p>
                        <p><span className="text-[#8C9A8F]">Created:</span> <span className="text-[#1B4332]">{new Date(product.createdAt).toLocaleDateString()}</span></p>
                      </div>
                    </div>
                    <div>
                      <h4 className="text-xs font-medium text-[#8C9A8F] uppercase mb-2">Actions</h4>
                      <div className="flex space-x-2">
                        <Button variant="outline" size="sm">
                          <Edit className="h-3.5 w-3.5 mr-1" />
                          Edit
                        </Button>
                        <Button variant="outline" size="sm">
                          <Copy className="h-3.5 w-3.5 mr-1" />
                          Duplicate
                        </Button>
                        <Button variant="outline" size="sm" className="text-[#991B1B] hover:bg-[#FEE2E2]">
                          <Trash2 className="h-3.5 w-3.5 mr-1" />
                          Delete
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
        {filteredProducts.length === 0 && (
          <div className="py-12 text-center">
            <p className="text-[#8C9A8F]">No products found matching your search.</p>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="flex items-center justify-between text-sm text-[#8C9A8F]">
        <span>{filteredProducts.length} products</span>
        {selectedRows.size > 0 && (
          <span>{selectedRows.size} selected</span>
        )}
      </div>
    </div>
  )
}
