"use client"

import { useState } from "react"
import { UserPlus, Search, Edit, Trash2, Shield, Mail, Calendar, MoreHorizontal } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { DUMMY_USERS } from "@/lib/dummy-data"
import { User, UserRole } from "@/types"

export default function UsersPage() {
  const [users] = useState<User[]>(DUMMY_USERS)
  const [searchQuery, setSearchQuery] = useState("")

  const filteredUsers = users.filter((user) =>
    user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    user.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
    user.role.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const getRoleBadge = (role: UserRole) => {
    const styles = {
      owner: "bg-[#E8D5F5] text-[#6B21A8]",
      admin: "bg-[#DBEAFE] text-[#1D4ED8]",
      manager: "bg-[#D1E7DD] text-[#1B4332]",
      staff: "bg-[#F5F0E8] text-[#8C9A8F]",
    }
    return styles[role]
  }

  const getStatusDot = (status: User["status"]) => {
    return status === "active" ? "bg-[#22C55E]" : "bg-[#EF4444]"
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("en-US", { month: "short", day: "numeric" })
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-[#1B4332]">Users</h1>
          <p className="text-sm text-[#8C9A8F]">{users.length} team members</p>
        </div>
        <Button size="sm">
          <UserPlus className="h-4 w-4 mr-1" />
          Add User
        </Button>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-4 gap-3">
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-3">
          <p className="text-xs text-[#8C9A8F]">Total</p>
          <p className="text-xl font-bold text-[#1B4332]">{users.length}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-3">
          <p className="text-xs text-[#8C9A8F]">Active</p>
          <p className="text-xl font-bold text-[#22C55E]">{users.filter((u) => u.status === "active").length}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-3">
          <p className="text-xs text-[#8C9A8F]">Admins</p>
          <p className="text-xl font-bold text-[#1B4332]">{users.filter((u) => ["owner", "admin"].includes(u.role)).length}</p>
        </div>
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-3">
          <p className="text-xs text-[#8C9A8F]">Staff</p>
          <p className="text-xl font-bold text-[#1B4332]">{users.filter((u) => ["manager", "staff"].includes(u.role)).length}</p>
        </div>
      </div>

      {/* Search */}
      <div className="bg-white rounded-xl border border-[#E8E0D5] p-3">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
          <Input
            placeholder="Search users..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 bg-[#F5F0E8] border-0"
          />
        </div>
      </div>

      {/* Users Grid */}
      <div className="grid grid-cols-3 gap-4">
        {filteredUsers.map((user) => (
          <div key={user.userId} className="bg-white rounded-xl border border-[#E8E0D5] p-4 hover:shadow-md transition-shadow">
            {/* Header */}
            <div className="flex items-start justify-between mb-3">
              <div className="flex items-center space-x-3">
                <div className="relative">
                  <div className="h-10 w-10 rounded-full bg-[#1B4332] flex items-center justify-center text-white font-medium text-sm">
                    {user.name.split(" ").map((n) => n[0]).join("")}
                  </div>
                  <span className={`absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-white ${getStatusDot(user.status)}`}></span>
                </div>
                <div>
                  <p className="font-medium text-[#1B4332] text-sm">{user.name}</p>
                  <span className={`inline-block px-2 py-0.5 text-[10px] font-medium rounded-full ${getRoleBadge(user.role)}`}>
                    {user.role}
                  </span>
                </div>
              </div>
              <button className="p-1 rounded-lg hover:bg-[#F5F0E8] transition-colors">
                <MoreHorizontal className="h-4 w-4 text-[#8C9A8F]" />
              </button>
            </div>

            {/* Email */}
            <div className="flex items-center space-x-2 text-xs text-[#8C9A8F] mb-3">
              <Mail className="h-3 w-3" />
              <span className="truncate">{user.email}</span>
            </div>

            {/* Permissions */}
            <div className="mb-3">
              <div className="flex flex-wrap gap-1">
                {user.permissions.slice(0, 3).map((permission) => (
                  <span
                    key={permission}
                    className="px-1.5 py-0.5 text-[10px] bg-[#F5F0E8] text-[#8C9A8F] rounded"
                  >
                    {permission.replace("_", " ")}
                  </span>
                ))}
                {user.permissions.length > 3 && (
                  <span className="px-1.5 py-0.5 text-[10px] bg-[#F5F0E8] text-[#8C9A8F] rounded">
                    +{user.permissions.length - 3}
                  </span>
                )}
              </div>
            </div>

            {/* Footer */}
            <div className="flex items-center justify-between pt-3 border-t border-[#E8E0D5]">
              <div className="flex items-center space-x-1 text-[10px] text-[#8C9A8F]">
                <Calendar className="h-3 w-3" />
                <span>Joined {formatDate(user.createdAt)}</span>
              </div>
              <div className="flex items-center space-x-1">
                <button className="p-1.5 rounded-lg hover:bg-[#F5F0E8] transition-colors">
                  <Edit className="h-3 w-3 text-[#8C9A8F]" />
                </button>
                {user.role !== "owner" && (
                  <button className="p-1.5 rounded-lg hover:bg-[#FEE2E2] transition-colors">
                    <Trash2 className="h-3 w-3 text-[#991B1B]" />
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {filteredUsers.length === 0 && (
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-12 text-center">
          <p className="text-[#8C9A8F]">No users found matching your search.</p>
        </div>
      )}
    </div>
  )
}
