"use client"

import { useState } from "react"
import { Phone, PhoneIncoming, PhoneOutgoing, PhoneMissed, Clock, User, Search, Filter, MoreHorizontal, Play } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

const DUMMY_CALLS = [
  { id: "call-1", customer: "John Smith", phone: "+1 234 567 8901", type: "incoming", status: "completed", duration: "5:32", date: "Today, 2:30 PM" },
  { id: "call-2", customer: "Sarah Johnson", phone: "+1 234 567 8902", type: "outgoing", status: "completed", duration: "3:15", date: "Today, 11:45 AM" },
  { id: "call-3", customer: "Mike Brown", phone: "+1 234 567 8903", type: "missed", status: "missed", duration: "0:00", date: "Today, 9:20 AM" },
  { id: "call-4", customer: "Emily Davis", phone: "+1 234 567 8904", type: "incoming", status: "completed", duration: "8:47", date: "Yesterday, 4:15 PM" },
  { id: "call-5", customer: "Chris Wilson", phone: "+1 234 567 8905", type: "outgoing", status: "completed", duration: "2:08", date: "Yesterday, 10:30 AM" },
]

export default function CallsPage() {
  const [searchQuery, setSearchQuery] = useState("")
  const [filter, setFilter] = useState<"all" | "incoming" | "outgoing" | "missed">("all")

  const filteredCalls = DUMMY_CALLS.filter((call) => {
    const matchesSearch = call.customer.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesFilter = filter === "all" || call.type === filter
    return matchesSearch && matchesFilter
  })

  const getCallIcon = (type: string) => {
    switch (type) {
      case "incoming": return <PhoneIncoming className="h-4 w-4 text-[#1B4332]" />
      case "outgoing": return <PhoneOutgoing className="h-4 w-4 text-[#4F8A6D]" />
      case "missed": return <PhoneMissed className="h-4 w-4 text-[#991B1B]" />
      default: return <Phone className="h-4 w-4 text-[#8C9A8F]" />
    }
  }

  const metrics = {
    total: DUMMY_CALLS.length,
    incoming: DUMMY_CALLS.filter(c => c.type === "incoming").length,
    outgoing: DUMMY_CALLS.filter(c => c.type === "outgoing").length,
    missed: DUMMY_CALLS.filter(c => c.type === "missed").length,
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-[#1B4332]">Calls</h1>
          <p className="text-sm text-[#8C9A8F]">Manage customer phone calls</p>
        </div>
        <Button>
          <Phone className="h-4 w-4 mr-2" />
          New Call
        </Button>
      </div>

      {/* Metrics */}
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Total Calls</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.total}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Incoming</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.incoming}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Outgoing</p>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.outgoing}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <p className="text-xs text-[#8C9A8F] mb-1">Missed</p>
          <p className="text-2xl font-bold text-[#991B1B]">{metrics.missed}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center space-x-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
          <Input
            placeholder="Search calls..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 bg-white border-[#E8E0D5]"
          />
        </div>
        <div className="flex space-x-1">
          {(["all", "incoming", "outgoing", "missed"] as const).map((f) => (
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

      {/* Calls List */}
      <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
        <div className="divide-y divide-[#E8E0D5]">
          {filteredCalls.map((call) => (
            <div key={call.id} className="flex items-center justify-between px-4 py-3 hover:bg-[#FAF8F5] transition-colors">
              <div className="flex items-center space-x-4">
                <div className="h-10 w-10 rounded-full bg-[#F5F0E8] flex items-center justify-center">
                  {getCallIcon(call.type)}
                </div>
                <div>
                  <p className="text-sm font-medium text-[#1B4332]">{call.customer}</p>
                  <p className="text-xs text-[#8C9A8F]">{call.phone}</p>
                </div>
              </div>
              <div className="flex items-center space-x-6">
                <div className="text-right">
                  <p className="text-sm text-[#1B4332]">{call.date}</p>
                  <div className="flex items-center justify-end space-x-1 text-xs text-[#8C9A8F]">
                    <Clock className="h-3 w-3" />
                    <span>{call.duration}</span>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <Button variant="outline" size="icon" className="h-8 w-8">
                    <Play className="h-3.5 w-3.5" />
                  </Button>
                  <Button variant="ghost" size="icon" className="h-8 w-8">
                    <MoreHorizontal className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
