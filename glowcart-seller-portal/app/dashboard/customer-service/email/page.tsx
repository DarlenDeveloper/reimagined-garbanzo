"use client"

import { useState } from "react"
import { Mail, Inbox, Send, Archive, Trash2, Search, Star, Paperclip, MoreHorizontal, Reply, Forward } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

const DUMMY_EMAILS = [
  { id: "email-1", from: "john@example.com", name: "John Smith", subject: "Question about order #5678", preview: "Hi, I wanted to ask about the delivery time for my recent order...", status: "unread", starred: true, hasAttachment: false, date: "10:30 AM" },
  { id: "email-2", from: "sarah@example.com", name: "Sarah Johnson", subject: "Return request", preview: "I would like to return the item I purchased last week because...", status: "unread", starred: false, hasAttachment: true, date: "9:15 AM" },
  { id: "email-3", from: "mike@example.com", name: "Mike Brown", subject: "Re: Product inquiry", preview: "Thank you for your quick response! I'll go ahead and place the order...", status: "read", starred: false, hasAttachment: false, date: "Yesterday" },
  { id: "email-4", from: "emily@example.com", name: "Emily Davis", subject: "Bulk order inquiry", preview: "We're interested in placing a bulk order for our company. Could you...", status: "read", starred: true, hasAttachment: true, date: "Yesterday" },
  { id: "email-5", from: "chris@example.com", name: "Chris Wilson", subject: "Feedback on recent purchase", preview: "I just received my order and wanted to share my feedback...", status: "replied", starred: false, hasAttachment: false, date: "Dec 5" },
]

export default function EmailPage() {
  const [searchQuery, setSearchQuery] = useState("")
  const [filter, setFilter] = useState<"all" | "unread" | "starred" | "replied">("all")
  const [selectedEmails, setSelectedEmails] = useState<Set<string>>(new Set())

  const filteredEmails = DUMMY_EMAILS.filter((email) => {
    const matchesSearch = email.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          email.subject.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesFilter = filter === "all" || 
                          (filter === "unread" && email.status === "unread") ||
                          (filter === "starred" && email.starred) ||
                          (filter === "replied" && email.status === "replied")
    return matchesSearch && matchesFilter
  })

  const toggleSelect = (id: string) => {
    const newSelected = new Set(selectedEmails)
    if (newSelected.has(id)) {
      newSelected.delete(id)
    } else {
      newSelected.add(id)
    }
    setSelectedEmails(newSelected)
  }

  const metrics = {
    total: DUMMY_EMAILS.length,
    unread: DUMMY_EMAILS.filter(e => e.status === "unread").length,
    starred: DUMMY_EMAILS.filter(e => e.starred).length,
    replied: DUMMY_EMAILS.filter(e => e.status === "replied").length,
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-[#1B4332]">Email</h1>
          <p className="text-sm text-[#8C9A8F]">Manage customer emails</p>
        </div>
        <Button>
          <Mail className="h-4 w-4 mr-2" />
          Compose
        </Button>
      </div>

      {/* Metrics */}
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <div className="flex items-center space-x-2 mb-1">
            <Inbox className="h-4 w-4 text-[#8C9A8F]" />
            <p className="text-xs text-[#8C9A8F]">Inbox</p>
          </div>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.total}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <div className="flex items-center space-x-2 mb-1">
            <Mail className="h-4 w-4 text-[#8C9A8F]" />
            <p className="text-xs text-[#8C9A8F]">Unread</p>
          </div>
          <p className="text-2xl font-bold text-[#92400E]">{metrics.unread}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <div className="flex items-center space-x-2 mb-1">
            <Star className="h-4 w-4 text-[#8C9A8F]" />
            <p className="text-xs text-[#8C9A8F]">Starred</p>
          </div>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.starred}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-4">
          <div className="flex items-center space-x-2 mb-1">
            <Send className="h-4 w-4 text-[#8C9A8F]" />
            <p className="text-xs text-[#8C9A8F]">Replied</p>
          </div>
          <p className="text-2xl font-bold text-[#1B4332]">{metrics.replied}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center space-x-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
          <Input
            placeholder="Search emails..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 bg-white border-[#E8E0D5]"
          />
        </div>
        <div className="flex space-x-1">
          {(["all", "unread", "starred", "replied"] as const).map((f) => (
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
        {selectedEmails.size > 0 && (
          <div className="flex space-x-1 ml-4 border-l border-[#E8E0D5] pl-4">
            <Button variant="outline" size="sm">
              <Archive className="h-4 w-4" />
            </Button>
            <Button variant="outline" size="sm">
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
        )}
      </div>

      {/* Email List */}
      <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
        <div className="divide-y divide-[#E8E0D5]">
          {filteredEmails.map((email) => (
            <div 
              key={email.id} 
              className={`flex items-center px-4 py-3 hover:bg-[#FAF8F5] transition-colors cursor-pointer ${email.status === "unread" ? "bg-[#FAF8F5]" : ""}`}
            >
              <input
                type="checkbox"
                checked={selectedEmails.has(email.id)}
                onChange={() => toggleSelect(email.id)}
                className="h-4 w-4 rounded border-[#E8E0D5] text-[#1B4332] focus:ring-[#1B4332] mr-3"
              />
              <button className="mr-3">
                <Star className={`h-4 w-4 ${email.starred ? "fill-[#F59E0B] text-[#F59E0B]" : "text-[#E8E0D5]"}`} />
              </button>
              <div className="flex-1 min-w-0 grid grid-cols-[200px_1fr_80px] gap-4 items-center">
                <div className="flex items-center space-x-2">
                  <span className={`text-sm truncate ${email.status === "unread" ? "font-semibold text-[#1B4332]" : "text-[#1B4332]"}`}>
                    {email.name}
                  </span>
                </div>
                <div className="flex items-center space-x-2 min-w-0">
                  <span className={`text-sm truncate ${email.status === "unread" ? "font-semibold text-[#1B4332]" : "text-[#1B4332]"}`}>
                    {email.subject}
                  </span>
                  <span className="text-sm text-[#8C9A8F] truncate">— {email.preview}</span>
                  {email.hasAttachment && <Paperclip className="h-3.5 w-3.5 text-[#8C9A8F] flex-shrink-0" />}
                </div>
                <span className="text-xs text-[#8C9A8F] text-right">{email.date}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
