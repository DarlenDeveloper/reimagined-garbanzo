"use client"

import { DollarSign, TrendingUp, ShoppingCart, Percent } from "lucide-react"
import { MetricsCard } from "@/components/dashboard/metrics-card"
import { SalesChart } from "@/components/dashboard/sales-chart"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { DUMMY_METRICS } from "@/lib/dummy-data"
import { formatCurrency } from "@/lib/utils"

export default function AnalyticsPage() {
  const metrics = DUMMY_METRICS

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Analytics</h1>
          <p className="text-gray-500 mt-1">Detailed insights into your store performance</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline">Export CSV</Button>
          <Button variant="outline">Export PDF</Button>
        </div>
      </div>

      {/* Metrics Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <MetricsCard
          title="Total Revenue"
          value={formatCurrency(metrics.revenue)}
          subtitle={metrics.period}
          icon={DollarSign}
          trend={{ value: "12.5%", isPositive: true }}
        />
        <MetricsCard
          title="Total Orders"
          value={metrics.orderCount.toString()}
          subtitle={metrics.period}
          icon={ShoppingCart}
          trend={{ value: "8.2%", isPositive: true }}
        />
        <MetricsCard
          title="Net Earnings"
          value={formatCurrency(metrics.netEarnings)}
          subtitle="After commission"
          icon={TrendingUp}
          trend={{ value: "15.3%", isPositive: true }}
        />
        <MetricsCard
          title="Platform Commission"
          value={formatCurrency(metrics.commission)}
          subtitle="3% of total sales"
          icon={Percent}
        />
      </div>

      {/* Sales Trend Chart */}
      <SalesChart data={metrics.salesTrend} />

      {/* Two Column Layout */}
      <div className="grid gap-6 md:grid-cols-2">
        {/* Top Products by Revenue */}
        <Card>
          <CardHeader>
            <CardTitle>Top Products by Revenue</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {metrics.topProducts.map((product, index) => (
                <div key={product.productId} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      <div className="flex h-8 w-8 items-center justify-center rounded-full bg-blue-100 text-blue-600 font-semibold text-sm">
                        {index + 1}
                      </div>
                      <div>
                        <p className="font-medium text-sm">{product.productName}</p>
                        <p className="text-xs text-gray-500">{product.sales} units sold</p>
                      </div>
                    </div>
                    <p className="font-semibold">{formatCurrency(product.revenue)}</p>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-blue-600 h-2 rounded-full"
                      style={{
                        width: `${(product.revenue / metrics.topProducts[0].revenue) * 100}%`,
                      }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Revenue Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle>Revenue Breakdown</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center justify-between py-3 border-b">
                <div>
                  <p className="font-medium">Gross Sales</p>
                  <p className="text-xs text-gray-500">Total sales before commission</p>
                </div>
                <p className="text-lg font-bold">{formatCurrency(metrics.totalSales)}</p>
              </div>
              <div className="flex items-center justify-between py-3 border-b">
                <div>
                  <p className="font-medium">Platform Commission</p>
                  <p className="text-xs text-gray-500">3% of gross sales</p>
                </div>
                <p className="text-lg font-bold text-red-600">-{formatCurrency(metrics.commission)}</p>
              </div>
              <div className="flex items-center justify-between py-3 bg-green-50 rounded-lg px-4">
                <div>
                  <p className="font-medium text-green-900">Net Earnings</p>
                  <p className="text-xs text-green-700">Amount you receive</p>
                </div>
                <p className="text-xl font-bold text-green-900">{formatCurrency(metrics.netEarnings)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Additional Metrics */}
      <div className="grid gap-6 md:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle className="text-sm">Average Order Value</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">{formatCurrency(metrics.totalSales / metrics.orderCount)}</p>
            <p className="text-xs text-gray-500 mt-1">Per order</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-sm">Total Products Sold</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">
              {metrics.topProducts.reduce((sum, p) => sum + p.sales, 0)}
            </p>
            <p className="text-xs text-gray-500 mt-1">Units</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-sm">Commission Rate</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">3.00%</p>
            <p className="text-xs text-gray-500 mt-1">Platform fee</p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
