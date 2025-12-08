"use client"

import React, { createContext, useContext, useState, useEffect } from "react"
import { Vendor } from "@/types"

interface AuthContextType {
  vendor: Vendor | null
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<void>
  signup: (data: SignupData) => Promise<void>
  logout: () => void
  isLoading: boolean
}

interface SignupData {
  storeName: string
  email: string
  password: string
  phoneNumber: string
  businessType: string
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

// Dummy vendor data
const DUMMY_VENDOR: Vendor = {
  vendorId: "vendor-123",
  email: "seller@glowcart.com",
  storeName: "Glow Electronics",
  description: "Premium electronics and gadgets",
  logoUrl: "/placeholder-logo.png",
  bannerUrl: "/placeholder-banner.png",
  contactEmail: "contact@glowelectronics.com",
  phoneNumber: "+1234567890",
  businessType: "Electronics",
  subscriptionTier: "premium",
  status: "active",
  createdAt: new Date().toISOString(),
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [vendor, setVendor] = useState<Vendor | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    // Check if user is already logged in (from localStorage)
    const storedVendor = localStorage.getItem("glowcart_vendor")
    if (storedVendor) {
      setVendor(JSON.parse(storedVendor))
    }
    setIsLoading(false)
  }, [])

  const login = async (email: string, password: string) => {
    // Dummy login - accepts any email/password
    setIsLoading(true)
    
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // Store vendor data
    localStorage.setItem("glowcart_vendor", JSON.stringify(DUMMY_VENDOR))
    setVendor(DUMMY_VENDOR)
    setIsLoading(false)
  }

  const signup = async (data: SignupData) => {
    // Dummy signup - creates a new vendor
    setIsLoading(true)
    
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    const newVendor: Vendor = {
      ...DUMMY_VENDOR,
      vendorId: `vendor-${Date.now()}`,
      email: data.email,
      storeName: data.storeName,
      phoneNumber: data.phoneNumber,
      businessType: data.businessType,
      subscriptionTier: "free",
      createdAt: new Date().toISOString(),
    }
    
    // Store vendor data
    localStorage.setItem("glowcart_vendor", JSON.stringify(newVendor))
    setVendor(newVendor)
    setIsLoading(false)
  }

  const logout = () => {
    localStorage.removeItem("glowcart_vendor")
    setVendor(null)
  }

  return (
    <AuthContext.Provider
      value={{
        vendor,
        isAuthenticated: !!vendor,
        login,
        signup,
        logout,
        isLoading,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider")
  }
  return context
}
