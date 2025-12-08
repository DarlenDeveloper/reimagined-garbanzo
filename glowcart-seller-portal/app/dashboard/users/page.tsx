"use client"

import { useState } from "react"
import { UserPlus, Search, Edit, Trash2, Shield, Mail, Calendar } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { DUMMY_USERS } from "@/lib/dummy-data"
import { formatDateTime } from "@/lib/utils"
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
      owner: "bg-purple-100 text-purple-700 border-purple-200",
      admin: "bg-blue-100 text-blue-700 border-blue-200",
      manager: "bg-green-100 text-green-700 border-green-200",
      staff: "bg-gray-100 text-gray-700 border-gray-200",
    }
    return styles[role]
  }

  const getStatusBadge = (status: User["status"]) => {
    return status === "active"
      ? "bg-green-100 text-green-700"
      : "bg-red-100 text-red-700"
  }

  const getRolePermissions = (role: UserRole) => {
    const permissions = {
      owner: "Full access to all features",
      admin: "Manage products, orders, inventory, analytics, and users",
      manager: "Manage products, orders, inventory, and view analytics",
      staff: "Manage orders and view products",
    }
    return permissions[role]
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">User Management</h1>
          <p className="text-gray-500 mt-1">Manage team members and their permissions</p>
        </div>
        <Button>
          <UserPlus className="h-4 w-4 mr-2" />
          Add User
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium text-gray-600">Total Users</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">{users.length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium text-gray-600">Active</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold text-green-600">
              {users.filter((u) => u.status === "active").length}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium text-gray-600">Admins</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">
              {users.filter((u) => ["owner", "admin"].includes(u.role)).length}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium text-gray-600">Staff</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">
              {users.filter((u) => ["manager", "staff"].includes(u.role)).length}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Search */}
      <Card>
        <CardContent className="pt-6">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <Input
              placeholder="Search by name, email, or role..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>
        </CardContent>
      </Card>

      {/* Role Information */}
      <Card className="bg-blue-50 border-blue-200">
        <CardContent className="pt-6">
          <div className="flex items-start space-x-3">
            <Shield className="h-5 w-5 text-blue-600 mt-0.5" />
            <div>
              <h3 className="font-semibold text-blue-900">Role Permissions</h3>
              <div className="mt-2 space-y-1 text-sm text-blue-700">
                <p><strong>Owner:</strong> Full access to all features including billing and settings</p>
                <p><strong>Admin:</strong> Can manage products, orders, inventory, analytics, and users</p>
                <p><strong>Manager:</strong> Can manage products, orders, inventory, and view analytics</p>
                <p><strong>Staff:</strong> Can manage orders and view products</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Users List */}
      <div className="space-y-4">
        {filteredUsers.map((user) => (
          <Card key={user.userId}>
            <CardContent className="p-6">
              <div className="flex items-start justify-between">
                <div className="flex items-start space-x-4 flex-1">
                  {/* Avatar */}
                  <div className="h-12 w-12 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-semibold text-lg">
                    {user.name.split(" ").map((n) => n[0]).join("")}
                  </div>

                  {/* User Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center space-x-3 mb-2">
                      <h3 className="font-semibold text-lg">{user.name}</h3>
                      <span className={`px-3 py-1 text-xs rounded-full border ${getRoleBadge(user.role)}`}>
                        {user.role}
                      </span>
                      <span className={`px-2 py-1 text-xs rounded-full ${getStatusBadge(user.status)}`}>
                        {user.status}
                      </span>
                    </div>

                    <div className="space-y-2">
                      <div className="flex items-center space-x-2 text-sm text-gray-600">
                        <Mail className="h-4 w-4" />
                        <span>{user.email}</span>
                      </div>

                      <div className="flex items-center space-x-2 text-sm text-gray-600">
                        <Shield className="h-4 w-4" />
                        <span>{getRolePermissions(user.role)}</span>
                      </div>

                      <div className="flex items-center space-x-4 text-xs text-gray-500">
                        <div className="flex items-center space-x-1">
                          <Calendar className="h-3 w-3" />
                          <span>Joined: {formatDateTime(user.createdAt)}</span>
                        </div>
                        {user.lastLogin && (
                          <div className="flex items-center space-x-1">
                            <span>Last login: {formatDateTime(user.lastLogin)}</span>
                          </div>
                        )}
                      </div>

                      {/* Permissions */}
                      <div className="pt-2">
                        <p className="text-xs text-gray-500 mb-1">Permissions:</p>
                        <div className="flex flex-wrap gap-1">
                          {user.permissions.map((permission) => (
                            <span
                              key={permission}
                              className="px-2 py-0.5 text-xs bg-gray-100 text-gray-600 rounded"
                            >
                              {permission.replace("_", " ")}
                            </span>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center space-x-2 ml-4">
                  <Button variant="outline" size="sm">
                    <Edit className="h-4 w-4" />
                  </Button>
                  {user.role !== "owner" && (
                    <Button variant="destructive" size="sm">
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {filteredUsers.length === 0 && (
        <Card>
          <CardContent className="py-12 text-center">
            <p className="text-gray-500">No users found matching your search.</p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
