"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import { useAuth } from "@/lib/auth-context"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Mail, Lock, Store, Phone, Building2, Eye, EyeOff, Check } from "lucide-react"
import Image from "next/image"

const businessTypes = [
  "Electronics",
  "Fashion & Apparel",
  "Home & Garden",
  "Health & Beauty",
  "Food & Beverages",
  "Sports & Outdoors",
  "Books & Media",
  "Toys & Games",
  "Automotive",
  "Other",
]

export function SignupForm() {
  const [formData, setFormData] = useState({
    storeName: "",
    email: "",
    password: "",
    confirmPassword: "",
    phoneNumber: "",
    businessType: "",
  })
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [agreedToTerms, setAgreedToTerms] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const { signup } = useAuth()
  const router = useRouter()

  const validateForm = () => {
    const newErrors: Record<string, string> = {}

    if (!formData.storeName.trim()) {
      newErrors.storeName = "Store name is required"
    }

    if (!formData.email.trim()) {
      newErrors.email = "Email is required"
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = "Please enter a valid email"
    }

    if (!formData.password) {
      newErrors.password = "Password is required"
    } else if (formData.password.length < 8) {
      newErrors.password = "Password must be at least 8 characters"
    }

    if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = "Passwords do not match"
    }

    if (!formData.phoneNumber.trim()) {
      newErrors.phoneNumber = "Phone number is required"
    }

    if (!formData.businessType) {
      newErrors.businessType = "Please select a business type"
    }

    if (!agreedToTerms) {
      newErrors.terms = "You must agree to the terms and conditions"
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!validateForm()) return

    setIsLoading(true)

    try {
      await signup({
        storeName: formData.storeName,
        email: formData.email,
        password: formData.password,
        phoneNumber: formData.phoneNumber,
        businessType: formData.businessType,
      })
      router.push("/dashboard")
    } catch (error) {
      console.error("Signup failed:", error)
      setErrors({ submit: "Failed to create account. Please try again." })
    } finally {
      setIsLoading(false)
    }
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: "" }))
    }
  }

  const passwordStrength = () => {
    const password = formData.password
    if (!password) return { strength: 0, label: "" }
    
    let strength = 0
    if (password.length >= 8) strength++
    if (/[A-Z]/.test(password)) strength++
    if (/[a-z]/.test(password)) strength++
    if (/[0-9]/.test(password)) strength++
    if (/[^A-Za-z0-9]/.test(password)) strength++

    const labels = ["", "Weak", "Fair", "Good", "Strong", "Very Strong"]
    const colors = ["", "bg-red-500", "bg-orange-500", "bg-yellow-500", "bg-green-500", "bg-[#1B4332]"]
    
    return { strength, label: labels[strength], color: colors[strength] }
  }

  const { strength, label, color } = passwordStrength()

  return (
    <div className="w-full max-w-lg">
      {/* Logo */}
      <div className="text-center mb-6">
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
          <h2 className="text-xl font-semibold text-[#1B4332]">Create your store</h2>
          <p className="text-sm text-[#4F8A6D] mt-1">Start selling on GLOWCART today</p>
        </div>

        {errors.submit && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-600">
            {errors.submit}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Store Name */}
          <div className="space-y-1.5">
            <label htmlFor="storeName" className="text-sm font-medium text-[#1B4332]">
              Store Name
            </label>
            <div className="relative">
              <Store className="absolute left-4 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
              <Input
                id="storeName"
                name="storeName"
                type="text"
                placeholder="Your Store Name"
                value={formData.storeName}
                onChange={handleChange}
                className={`pl-11 ${errors.storeName ? "border-red-500" : ""}`}
              />
            </div>
            {errors.storeName && <p className="text-xs text-red-500">{errors.storeName}</p>}
          </div>

          {/* Email */}
          <div className="space-y-1.5">
            <label htmlFor="email" className="text-sm font-medium text-[#1B4332]">
              Email
            </label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
              <Input
                id="email"
                name="email"
                type="email"
                placeholder="seller@example.com"
                value={formData.email}
                onChange={handleChange}
                className={`pl-11 ${errors.email ? "border-red-500" : ""}`}
              />
            </div>
            {errors.email && <p className="text-xs text-red-500">{errors.email}</p>}
          </div>

          {/* Phone Number */}
          <div className="space-y-1.5">
            <label htmlFor="phoneNumber" className="text-sm font-medium text-[#1B4332]">
              Phone Number
            </label>
            <div className="relative">
              <Phone className="absolute left-4 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
              <Input
                id="phoneNumber"
                name="phoneNumber"
                type="tel"
                placeholder="+1234567890"
                value={formData.phoneNumber}
                onChange={handleChange}
                className={`pl-11 ${errors.phoneNumber ? "border-red-500" : ""}`}
              />
            </div>
            {errors.phoneNumber && <p className="text-xs text-red-500">{errors.phoneNumber}</p>}
          </div>

          {/* Business Type */}
          <div className="space-y-1.5">
            <label htmlFor="businessType" className="text-sm font-medium text-[#1B4332]">
              Business Type
            </label>
            <div className="relative">
              <Building2 className="absolute left-4 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F] z-10" />
              <select
                id="businessType"
                name="businessType"
                value={formData.businessType}
                onChange={handleChange}
                className={`w-full h-10 pl-11 pr-10 rounded-lg border bg-white text-sm text-[#1B4332] focus:outline-none focus:ring-2 focus:ring-[#1B4332] focus:border-transparent ${
                  errors.businessType ? "border-red-500" : "border-[#E8E0D5]"
                }`}
              >
                <option value="">Select business type</option>
                {businessTypes.map(type => (
                  <option key={type} value={type}>{type}</option>
                ))}
              </select>
            </div>
            {errors.businessType && <p className="text-xs text-red-500">{errors.businessType}</p>}
          </div>

          {/* Password */}
          <div className="space-y-1.5">
            <label htmlFor="password" className="text-sm font-medium text-[#1B4332]">
              Password
            </label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
              <Input
                id="password"
                name="password"
                type={showPassword ? "text" : "password"}
                placeholder="••••••••"
                value={formData.password}
                onChange={handleChange}
                className={`pl-11 pr-11 ${errors.password ? "border-red-500" : ""}`}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 transform -translate-y-1/2 text-[#8C9A8F] hover:text-[#1B4332]"
              >
                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </div>
            {formData.password && (
              <div className="space-y-1">
                <div className="flex gap-1">
                  {[1, 2, 3, 4, 5].map(i => (
                    <div
                      key={i}
                      className={`h-1 flex-1 rounded-full ${i <= strength ? color : "bg-gray-200"}`}
                    />
                  ))}
                </div>
                <p className="text-xs text-[#8C9A8F]">{label}</p>
              </div>
            )}
            {errors.password && <p className="text-xs text-red-500">{errors.password}</p>}
          </div>

          {/* Confirm Password */}
          <div className="space-y-1.5">
            <label htmlFor="confirmPassword" className="text-sm font-medium text-[#1B4332]">
              Confirm Password
            </label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 transform -translate-y-1/2 h-4 w-4 text-[#8C9A8F]" />
              <Input
                id="confirmPassword"
                name="confirmPassword"
                type={showConfirmPassword ? "text" : "password"}
                placeholder="••••••••"
                value={formData.confirmPassword}
                onChange={handleChange}
                className={`pl-11 pr-11 ${errors.confirmPassword ? "border-red-500" : ""}`}
              />
              <button
                type="button"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                className="absolute right-4 top-1/2 transform -translate-y-1/2 text-[#8C9A8F] hover:text-[#1B4332]"
              >
                {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </div>
            {formData.confirmPassword && formData.password === formData.confirmPassword && (
              <p className="text-xs text-[#1B4332] flex items-center gap-1">
                <Check className="h-3 w-3" /> Passwords match
              </p>
            )}
            {errors.confirmPassword && <p className="text-xs text-red-500">{errors.confirmPassword}</p>}
          </div>

          {/* Terms */}
          <div className="space-y-1.5">
            <label className="flex items-start space-x-3 cursor-pointer">
              <input
                type="checkbox"
                checked={agreedToTerms}
                onChange={(e) => {
                  setAgreedToTerms(e.target.checked)
                  if (errors.terms) setErrors(prev => ({ ...prev, terms: "" }))
                }}
                className="mt-0.5 rounded border-[#E8E0D5] text-[#1B4332] focus:ring-[#1B4332]"
              />
              <span className="text-sm text-[#4F8A6D]">
                I agree to the{" "}
                <a href="#" className="text-[#1B4332] hover:underline font-medium">Terms of Service</a>
                {" "}and{" "}
                <a href="#" className="text-[#1B4332] hover:underline font-medium">Privacy Policy</a>
              </span>
            </label>
            {errors.terms && <p className="text-xs text-red-500">{errors.terms}</p>}
          </div>

          <Button
            type="submit"
            className="w-full h-11"
            disabled={isLoading}
          >
            {isLoading ? (
              <div className="flex items-center space-x-2">
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent"></div>
                <span>Creating account...</span>
              </div>
            ) : (
              "Create Account"
            )}
          </Button>
        </form>

        <div className="mt-6 text-center">
          <p className="text-sm text-[#4F8A6D]">
            Already have an account?{" "}
            <Link href="/" className="text-[#1B4332] hover:text-[#2D5A45] font-medium">
              Sign in
            </Link>
          </p>
        </div>

        <div className="mt-6 pt-6 border-t border-[#E8E0D5]">
          <div className="flex items-center justify-center space-x-4 text-xs text-[#8C9A8F]">
            <span className="flex items-center gap-1">
              <Check className="h-3 w-3 text-[#1B4332]" /> Free to start
            </span>
            <span className="flex items-center gap-1">
              <Check className="h-3 w-3 text-[#1B4332]" /> No credit card required
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}
