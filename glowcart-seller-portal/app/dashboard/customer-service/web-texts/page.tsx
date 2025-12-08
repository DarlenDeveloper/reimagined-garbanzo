"use client"

import { useState } from "react"
import { Globe, MessageSquare, Search, Filter, MoreHorizontal, Reply, Eye, Clock } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

const DUMMY_WEB_TEXTS = [
  { id: "wt-1", customer: "Alice Cooper", message: "Hi, I have a question about my order #1234", status: "unread", source: "Website Chat", date: "2 min ago" },
  { id: "wt-2", customer: "Bob Martinez", message: "When will my package arrive?", status: "read", source: "Contact Form", date: "15 min ago" },
  { id: "wt-3", customer: "Carol White", message: "I'd like to return an item please", status: "replied", source: "Website Chat", date: "1 hour ago" },
  { id: "wt-4", customer: "David Lee", message: "Do you have this product in blue?", status: "unread", source: "Website Chat", date: "2 hours ago" },
  { id: "wt-5", customer: "Eva Green", message: "Thanks for the quick response!", status: "replied", source: "Contact Form", date: "Yesterday" },
]

export default function WebTextsPage() {
  const [searchQuery, setSearchQuery] = useState("")
  const [filter, setFilter] = useState<"all" | "unread" | "read" | "replied">("all")

  const filteredTexts = DUMMY_WEB_TEXTS.filter((text) => {
    const matchesSearch = text.customer.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          text.message.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesFilter = filter === "all" || text.status === filter
    return matchesSearch && matchesFilter
  })

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "unread": return "bg-[#FEF3C7] text-[#92400E]"
      case "read": return "bg-[#E8E0D5] text-[#1B4332]"
      case "replied": return "bg-[#D1E7DD] text-[#1B4332]"
      default: return "bg-[#E8E0D5] text-[#8C9A8F]"
    }
  }

  const metrics = {
    total: DUMMY_WEB_TEXTS.length,
    unread: DUMMY_WEB_TEXTS.filter(t => t.status === "unread").length,
    read: DUMMY_WEB_TEXTS.filter(t => t.status === "read").length,
    replied: DUMMY_WEB_TEXTS.filter(t => t.status === "replied").length,
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-[#1B4332]">Web Texts</h1>
          <p className="text-sm text-[#8C9A8F]">Messages from website visitors</p>
        </div>
        <Button>
          <MessageSquare className="h-4 w-4 mr-2" />
          New Message
        </Button>
      </div>

      {/* Metrics */}
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Total Messages</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.total}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Unread</p>
          <p className="text-2xl font-bold text-[#92400E]">{metrics.unread}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Read</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.read}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Replied</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.replied}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center space-x-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
          <Input
            placeholder="Search messages..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 bg-white border-[#E8E0D5]"
          />
        </div>
        <div className="flex space-x-1">
          {(["all", "unread", "read", "replied"] as const).map((f) => (
            <Button
              key={f}
              variant={filter === f ? "default" : "outline"}
              size="sm"
              onClick={() => setFilter(f)}
            >
              {f.charAt(0).toUpperCase() + f.slice(1)}
            </Button>
          ))}
        </div>
      </div>

      {/* Messages List */}
      <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
        <div className="divide-y divide-[#E8E0D5]">
          {filteredTexts.map((text) => (
            <div key={text.id} className={`flex items-start justify-between px-4 py-4 hover:bg-[#FAF8F5] transition-colors ${text.status === "unread" ? "bg-[#FAF8F5]" : ""}`}>
              <div className="flex items-start space-x-4">
                <div className="h-10 w-10 rounded-full bg-[#F5F0E8] flex items-center justify-center flex-shrink-0">
                  <Globe className="h-4 w-4 text-[#1B4332]" />
                </div>
                <div className="min-w-0">
                  <div className="flex items-center space-x-2 mb-1">
                    <p className="text-sm font-medium text-[#1B4332]">{text.customer}</p>
                    <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${getStatusBadge(text.status)}`}>
                      {text.status}
                    </span>
                  </div>
                  <p className="text-sm text-[#1B4332] line-clamp-1">{text.message}</p>
                  <div className="flex items-center space-x-3 mt-1 text-xs text-[#8C9A8F]">
                    <span>{text.source}</span>
                    <span>•</span>
                    <span>{text.date}</span>
                  </div>
                </div>
              </div>
              <div className="flex items-center space-x-2 flex-shrink-0">
                <Button variant="outline" size="sm">
                  <Reply className="h-3.5 w-3.5 mr-1" />
                  Reply
                </Button>
                <Button variant="ghost" size="icon" className="h-8 w-8">
                  <MoreHorizontal className="h-4 w-4" />
                </Button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
