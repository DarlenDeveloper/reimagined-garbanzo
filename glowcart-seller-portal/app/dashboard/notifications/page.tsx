"use client"

import { useState } from "react"
import { Bell, Package, DollarSign, AlertTriangle, CheckCircle, ChevronDown, ChevronUp, Check } from "lucide-react"
import { Button } from "@/components/ui/button"
import { DUMMY_NOTIFICATIONS } from "@/lib/dummy-data"
import { formatDateTime } from "@/lib/utils"
import { Notification } from "@/types"

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>(DUMMY_NOTIFICATIONS)
  const [expandedId, setExpandedId] = useState<string | null>(null)

  const unreadCount = notifications.filter((n) => !n.readAt).length

  const getNotificationIcon = (type: string) => {
    const iconClass = "h-4 w-4"
    switch (type) {
      case "new_order":
        return <Bell className={`${iconClass} text-[#3B82F6]`} />
      case "low_stock":
        return <AlertTriangle className={`${iconClass} text-[#F59E0B]`} />
      case "out_of_stock":
        return <Package className={`${iconClass} text-[#EF4444]`} />
      case "payout":
        return <DollarSign className={`${iconClass} text-[#22C55E]`} />
      default:
        return <Bell className={`${iconClass} text-[#8C9A8F]`} />
    }
  }

  const getNotificationBg = (type: string, isUnread: boolean) => {
    if (!isUnread) return "bg-white"
    switch (type) {
      case "new_order":
        return "bg-[#EFF6FF]"
      case "low_stock":
        return "bg-[#FFFBEB]"
      case "out_of_stock":
        return "bg-[#FEF2F2]"
      case "payout":
        return "bg-[#F0FDF4]"
      default:
        return "bg-[#F5F0E8]"
    }
  }

  const markAsRead = (notificationId: string) => {
    setNotifications((prev) =>
      prev.map((n) =>
        n.notificationId === notificationId
          ? { ...n, readAt: new Date().toISOString() }
          : n
      )
    )
  }

  const markAllAsRead = () => {
    setNotifications((prev) =>
      prev.map((n) => ({ ...n, readAt: n.readAt || new Date().toISOString() }))
    )
  }

  const toggleExpand = (id: string) => {
    setExpandedId(expandedId === id ? null : id)
  }

  const getTimeAgo = (dateString: string) => {
    const now = new Date()
    const date = new Date(dateString)
    const diff = now.getTime() - date.getTime()
    const hours = Math.floor(diff / (1000 * 60 * 60))
    const days = Math.floor(hours / 24)
    
    if (days > 0) return `${days}d ago`
    if (hours > 0) return `${hours}h ago`
    return "Just now"
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-[#1B4332]">Notifications</h1>
          <p className="text-sm text-[#8C9A8F]">
            {unreadCount > 0 ? `${unreadCount} unread` : "All caught up!"}
          </p>
        </div>
        {unreadCount > 0 && (
          <Button variant="outline" size="sm" onClick={markAllAsRead}>
            <Check className="h-3 w-3 mr-1" />
            Mark all read
          </Button>
        )}
      </div>

      {/* Quick Stats */}
      <div className="flex items-center space-x-3">
        <div className="flex items-center space-x-1.5 px-3 py-1.5 bg-white rounded-full border border-[#E8E0D5]">
          <span className="h-2 w-2 rounded-full bg-[#3B82F6]"></span>
          <span className="text-xs text-[#1B4332]">Orders</span>
          <span className="text-xs font-medium text-[#1B4332]">{notifications.filter(n => n.type === "new_order").length}</span>
        </div>
        <div className="flex items-center space-x-1.5 px-3 py-1.5 bg-white rounded-full border border-[#E8E0D5]">
          <span className="h-2 w-2 rounded-full bg-[#F59E0B]"></span>
          <span className="text-xs text-[#1B4332]">Alerts</span>
          <span className="text-xs font-medium text-[#1B4332]">{notifications.filter(n => n.type === "low_stock" || n.type === "out_of_stock").length}</span>
        </div>
        <div className="flex items-center space-x-1.5 px-3 py-1.5 bg-white rounded-full border border-[#E8E0D5]">
          <span className="h-2 w-2 rounded-full bg-[#22C55E]"></span>
          <span className="text-xs text-[#1B4332]">Payouts</span>
          <span className="text-xs font-medium text-[#1B4332]">{notifications.filter(n => n.type === "payout").length}</span>
        </div>
      </div>

      {/* Notifications List - Compact */}
      <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden divide-y divide-[#E8E0D5]">
        {notifications.map((notification) => {
          const isExpanded = expandedId === notification.notificationId
          const isUnread = !notification.readAt
          
          return (
            <div
              key={notification.notificationId}
              className={`transition-all ${getNotificationBg(notification.type, isUnread)}`}
            >
              {/* Compact Row */}
              <div 
                className="flex items-center px-4 py-2.5 cursor-pointer hover:bg-[#FAF8F5] transition-colors"
                onClick={() => toggleExpand(notification.notificationId)}
              >
                {/* Unread Indicator */}
                <div className="w-2 mr-3">
                  {isUnread && <span className="block h-2 w-2 rounded-full bg-[#1B4332]"></span>}
                </div>
                
                {/* Icon */}
                <div className="mr-3">
                  {getNotificationIcon(notification.type)}
                </div>
                
                {/* Title */}
                <div className="flex-1 min-w-0">
                  <p className={`text-sm truncate ${isUnread ? "font-medium text-[#1B4332]" : "text-[#1B4332]"}`}>
                    {notification.title}
                  </p>
                </div>
                
                {/* Time */}
                <span className="text-[10px] text-[#8C9A8F] mx-3">
                  {getTimeAgo(notification.createdAt)}
                </span>
                
                {/* Expand Icon */}
                {isExpanded ? (
                  <ChevronUp className="h-4 w-4 text-[#8C9A8F]" />
                ) : (
                  <ChevronDown className="h-4 w-4 text-[#8C9A8F]" />
                )}
              </div>
              
              {/* Expanded Content */}
              {isExpanded && (
                <div className="px-4 pb-3 pt-1 ml-9">
                  <p className="text-sm text-[#8C9A8F] mb-2">{notification.message}</p>
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] text-[#8C9A8F]">
                      {formatDateTime(notification.createdAt)}
                    </span>
                    {isUnread && (
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          markAsRead(notification.notificationId)
                        }}
                        className="flex items-center space-x-1 text-xs text-[#1B4332] hover:underline"
                      >
                        <CheckCircle className="h-3 w-3" />
                        <span>Mark as read</span>
                      </button>
                    )}
                  </div>
                </div>
              )}
            </div>
          )
        })}
      </div>

      {notifications.length === 0 && (
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-12 text-center">
          <Bell className="h-10 w-10 text-[#E8E0D5] mx-auto mb-3" />
          <p className="text-[#8C9A8F]">No notifications yet</p>
        </div>
      )}
    </div>
  )
}
