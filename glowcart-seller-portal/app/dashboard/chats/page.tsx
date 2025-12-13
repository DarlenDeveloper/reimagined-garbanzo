"use client"

import { useState } from "react"
import { MessageCircle, Search, Send, Paperclip, Smile, MoreVertical, Phone, Video, User } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

const DUMMY_CONVERSATIONS = [
  { 
    id: "conv-1", 
    customer: "Alice Cooper", 
    avatar: "A",
    lastMessage: "Thanks for the help!", 
    time: "2 min ago", 
    unread: 2,
    online: true,
    messages: [
      { id: 1, sender: "customer", text: "Hi, I need help with my order", time: "10:30 AM" },
      { id: 2, sender: "agent", text: "Hello! I'd be happy to help. What's your order number?", time: "10:31 AM" },
      { id: 3, sender: "customer", text: "It's #12345", time: "10:32 AM" },
      { id: 4, sender: "agent", text: "I found your order. It's currently being processed and should ship tomorrow.", time: "10:33 AM" },
      { id: 5, sender: "customer", text: "Thanks for the help!", time: "10:34 AM" },
    ]
  },
  { 
    id: "conv-2", 
    customer: "Bob Martinez", 
    avatar: "B",
    lastMessage: "When will it arrive?", 
    time: "15 min ago", 
    unread: 1,
    online: true,
    messages: [
      { id: 1, sender: "customer", text: "Hi, I placed an order yesterday", time: "9:00 AM" },
      { id: 2, sender: "agent", text: "Hello Bob! How can I assist you today?", time: "9:05 AM" },
      { id: 3, sender: "customer", text: "When will it arrive?", time: "9:10 AM" },
    ]
  },
  { 
    id: "conv-3", 
    customer: "Carol White", 
    avatar: "C",
    lastMessage: "Perfect, thank you!", 
    time: "1 hour ago", 
    unread: 0,
    online: false,
    messages: [
      { id: 1, sender: "customer", text: "Do you have this in size M?", time: "8:00 AM" },
      { id: 2, sender: "agent", text: "Let me check our inventory for you.", time: "8:02 AM" },
      { id: 3, sender: "agent", text: "Yes, we have size M in stock!", time: "8:03 AM" },
      { id: 4, sender: "customer", text: "Perfect, thank you!", time: "8:05 AM" },
    ]
  },
  { 
    id: "conv-4", 
    customer: "David Lee", 
    avatar: "D",
    lastMessage: "I'll think about it", 
    time: "3 hours ago", 
    unread: 0,
    online: false,
    messages: []
  },
  { 
    id: "conv-5", 
    customer: "Eva Green", 
    avatar: "E",
    lastMessage: "Great service!", 
    time: "Yesterday", 
    unread: 0,
    online: false,
    messages: []
  },
]

export default function ChatsPage() {
  const [searchQuery, setSearchQuery] = useState("")
  const [selectedConversation, setSelectedConversation] = useState(DUMMY_CONVERSATIONS[0])
  const [newMessage, setNewMessage] = useState("")

  const filteredConversations = DUMMY_CONVERSATIONS.filter((conv) =>
    conv.customer.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const totalUnread = DUMMY_CONVERSATIONS.reduce((acc, conv) => acc + conv.unread, 0)

  return (
    <div className="h-[calc(100vh-8rem)]">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h1 className="text-xl font-semibold text-[#1B4332]">Chats</h1>
          <p className="text-sm text-[#8C9A8F]">{totalUnread} unread messages</p>
        </div>
      </div>

      {/* Chat Container */}
      <div className="flex h-[calc(100%-3rem)] bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
        {/* Conversations List */}
        <div className="w-80 border-r border-[#E8E0D5] flex flex-col">
          {/* Search */}
          <div className="p-3 border-b border-[#E8E0D5]">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
              <Input
                placeholder="Search conversations..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10 bg-[#F5F0E8] border-0"
              />
            </div>
          </div>

          {/* Conversation List */}
          <div className="flex-1 overflow-y-auto">
            {filteredConversations.map((conv) => (
              <button
                key={conv.id}
                onClick={() => setSelectedConversation(conv)}
                className={`w-full flex items-center space-x-3 px-4 py-3 hover:bg-[#FAF8F5] transition-colors text-left ${
                  selectedConversation.id === conv.id ? "bg-[#F5F0E8]" : ""
                }`}
              >
                <div className="relative">
                  <div className="h-10 w-10 rounded-full bg-[#1B4332] flex items-center justify-center text-white font-medium">
                    {conv.avatar}
                  </div>
                  {conv.online && (
                    <span className="absolute bottom-0 right-0 h-3 w-3 bg-[#22C55E] border-2 border-white rounded-full"></span>
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-[#1B4332] truncate">{conv.customer}</span>
                    <span className="text-xs text-[#8C9A8F]">{conv.time}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-[#8C9A8F] truncate">{conv.lastMessage}</span>
                    {conv.unread > 0 && (
                      <span className="h-4 min-w-4 px-1 rounded-full bg-[#1B4332] text-white text-[10px] flex items-center justify-center">
                        {conv.unread}
                      </span>
                    )}
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Chat Area */}
        <div className="flex-1 flex flex-col">
          {/* Chat Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-[#E8E0D5]">
            <div className="flex items-center space-x-3">
              <div className="relative">
                <div className="h-10 w-10 rounded-full bg-[#1B4332] flex items-center justify-center text-white font-medium">
                  {selectedConversation.avatar}
                </div>
                {selectedConversation.online && (
                  <span className="absolute bottom-0 right-0 h-3 w-3 bg-[#22C55E] border-2 border-white rounded-full"></span>
                )}
              </div>
              <div>
                <p className="text-sm font-medium text-[#1B4332]">{selectedConversation.customer}</p>
                <p className="text-xs text-[#8C9A8F]">{selectedConversation.online ? "Online" : "Offline"}</p>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <Button variant="ghost" size="icon">
                <Phone className="h-4 w-4 text-[#8C9A8F]" />
              </Button>
              <Button variant="ghost" size="icon">
                <Video className="h-4 w-4 text-[#8C9A8F]" />
              </Button>
              <Button variant="ghost" size="icon">
                <MoreVertical className="h-4 w-4 text-[#8C9A8F]" />
              </Button>
            </div>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-[#FAF8F5]">
            {selectedConversation.messages.map((message) => (
              <div
                key={message.id}
                className={`flex ${message.sender === "agent" ? "justify-end" : "justify-start"}`}
              >
                <div
                  className={`max-w-[70%] px-4 py-2 rounded-2xl ${
                    message.sender === "agent"
                      ? "bg-[#1B4332] text-white rounded-br-md"
                      : "bg-white text-[#1B4332] border border-[#E8E0D5] rounded-bl-md"
                  }`}
                >
                  <p className="text-sm">{message.text}</p>
                  <p className={`text-xs mt-1 ${message.sender === "agent" ? "text-white/70" : "text-[#8C9A8F]"}`}>
                    {message.time}
                  </p>
                </div>
              </div>
            ))}
          </div>

          {/* Message Input */}
          <div className="p-4 border-t border-[#E8E0D5]">
            <div className="flex items-center space-x-3">
              <Button variant="ghost" size="icon">
                <Paperclip className="h-4 w-4 text-[#8C9A8F]" />
              </Button>
              <div className="flex-1 relative">
                <Input
                  placeholder="Type a message..."
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  className="pr-10 bg-[#F5F0E8] border-0"
                />
                <button className="absolute right-3 top-1/2 transform -translate-y-1/2">
                  <Smile className="h-4 w-4 text-[#8C9A8F]" />
                </button>
              </div>
              <Button size="icon">
                <Send className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
