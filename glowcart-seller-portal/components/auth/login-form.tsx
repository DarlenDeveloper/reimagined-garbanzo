"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import { useAuth } from "@/lib/auth-context"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Mail, Lock } from "lucide-react"
import Image from "next/image"

export function LoginForm() {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [isLoading, setIsLoading] = useState(false)
  const { login } = useAuth()
  const router = useRouter()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)

    try {
      await login(email, password)
      router.push("/dashboard")
    } catch (error) {
      console.error("Login failed:", error)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="w-full max-w-md">
      {/* Logo */}
      <div className="text-center mb-8">
        <div className="inline-flex items-center justify-center mb-5">
          {/* Floating logo with glow effect */}
          <div className="relative group">
            {/* Ambient glow */}
            <div className="absolute inset-0 bg-gradient-to-b from-[#1B4332]/20 to-[#4F8A6D]/10 rounded-3xl blur-2xl scale-150 opacity-60"></div>
            {/* Logo container with glass morphism */}
            <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-white via-white to-[#F5F0E8] p-1 shadow-[0_20px_50px_rgba(27,67,50,0.15),0_8px_20px_rgba(27,67,50,0.1)]">
              <div className="rounded-xl bg-white p-3">
                <Image 
                  src="/LOGO.PNG" 
                  alt="GLOWCART" 
                  width={80} 
                  height={80}
                  className="object-contain drop-shadow-sm"
                  priority
                />
              </div>
            </div>
            {/* Subtle shine effect */}
            <div className="absolute inset-0 rounded-2xl bg-gradient-to-tr from-transparent via-white/20 to-transparent pointer-events-none"></div>
          </div>
        </div>
        <h1 className="text-2xl font-bold text-[#1B4332] tracking-tight">GLOWCART</h1>
        <p className="text-[#4F8A6D] mt-1 text-sm font-medium">Seller Portal</p>
      </div>

      {/* Card */}
      <div className="bg-white rounded-3xl shadow-xl p-8 border border-[#E8E0D5]">
        <div className="text-center mb-6">
          <h2 className="text-xl font-semibold text-[#1B4332]">Welcome back!</h2>
          <p className="text-sm text-[#4F8A6D] mt-1">Sign in to your account</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          <div className="space-y-2">
            <label htmlFor="email" className="text-sm font-medium text-[#1B4332]">
              Email
            </label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
              <Input
                id="email"
                type="email"
                placeholder="seller@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="pl-11"
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <label htmlFor="password" className="text-sm font-medium text-[#1B4332]">
              Password
            </label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="pl-11"
                required
              />
            </div>
          </div>

          <div className="flex items-center justify-between text-sm">
            <label className="flex items-center space-x-2 cursor-pointer">
              <input type="checkbox" className="rounded border-[#E8E0D5] text-[#1B4332] focus:ring-[#1B4332]" />
              <span className="text-[#4F8A6D]">Remember me</span>
            </label>
            <a href="#" className="text-[#1B4332] hover:text-[#2D5A45] font-medium">
              Forgot password?
            </a>
          </div>

          <Button
            type="submit"
            className="w-full h-11"
            disabled={isLoading}
          >
            {isLoading ? (
              <div className="flex items-center space-x-2">
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent"></div>
                <span>Signing in...</span>
              </div>
            ) : (
              "Sign In"
            )}
          </Button>
        </form>

        <div className="mt-6 text-center">
          <p className="text-sm text-[#4F8A6D]">
            Don&apos;t have an account?{" "}
            <Link href="/signup" className="text-[#1B4332] hover:text-[#2D5A45] font-medium">
              Sign up
            </Link>
          </p>
        </div>

        <div className="mt-6 pt-6 border-t border-[#E8E0D5]">
          <p className="text-xs text-center text-[#8C9A8F]">
            Demo: Use any email and password to login
          </p>
        </div>
      </div>
    </div>
  )
}
