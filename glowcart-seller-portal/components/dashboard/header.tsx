"use client"

import { Search, Bell, MessageSquare, Command } from "lucide-react"
import { useAuth } from "@/lib/auth-context"
import Image from "next/image"

export function Header() {
  const { vendor } = useAuth()

  return (
    <header className="h-14 bg-[#1B4332] px-4 flex items-center justify-between sticky top-0 z-10">
      {/* Logo - Left Side */}
      <div className="flex items-center space-x-3 w-60">
        <div className="relative">
          {/* Subtle glow behind logo */}
          <div className="absolute inset-0 bg-white/20 rounded-xl blur-md"></div>
          <div className="relative overflow-hidden rounded-xl bg-gradient-to-br from-white to-[#F5F0E8] p-0.5 shadow-[0_4px_12px_rgba(0,0,0,0.2)]">
            <div className="rounded-lg bg-white p-1.5">
              <Image 
                src="/LOGO.PNG" 
                alt="GLOWCART" 
                width={26} 
                height={26}
                className="object-contain"
              />
            </div>
          </div>
        </div>
        <span className="text-xl font-bold text-white tracking-tight">
          GLOWCART
        </span>
      </div>

      {/* Center Search Bar */}
      <div className="flex-1 flex justify-center">
        <div className="relative w-full max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
          <input
            type="text"
            placeholder="Search"
            className="w-full h-9 pl-10 pr-16 rounded-lg bg-[#2D5A45] border-0 text-sm text-white placeholder:text-[#8C9A8F] focus:outline-none focus:ring-2 focus:ring-white/20 transition-all"
          />
          <div className="absolute right-3 top-1/2 transform -translate-y-1/2 flex items-center space-x-1 text-[#8C9A8F]">
            <Command className="h-3 w-3" />
            <span className="text-xs">K</span>
          </div>
        </div>
      </div>

      {/* Right side */}
      <div className="flex items-center space-x-2">
        {/* Messages */}
        <button className="relative p-2 rounded-lg hover:bg-[#2D5A45] transition-colors">
          <MessageSquare className="h-5 w-5 text-white/80" />
        </button>

        {/* Notifications */}
        <button className="relative p-2 rounded-lg hover:bg-[#2D5A45] transition-colors">
          <Bell className="h-5 w-5 text-white/80" />
        </button>

        {/* Profile */}
        <button className="flex items-center space-x-2 ml-2 p-1 rounded-lg hover:bg-[#2D5A45] transition-colors">
          <span className="text-sm text-white/90 hidden md:block">
            {vendor?.storeName || "Glow Electronics"}
          </span>
          <div className="h-8 w-8 rounded-lg bg-[#F5F0E8] flex items-center justify-center text-[#1B4332] font-semibold text-sm">
            {vendor?.storeName?.charAt(0) || "G"}
          </div>
        </button>
      </div>
    </header>
  )
}
