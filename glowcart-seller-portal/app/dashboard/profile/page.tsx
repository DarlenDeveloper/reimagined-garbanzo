"use client"

import { useState } from "react"
import { useAuth } from "@/lib/auth-context"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { 
  Store, Mail, Phone, Globe, CreditCard, Bell, Shield, Users, 
  Truck, Package, FileText, ChevronRight, Upload, Check, 
  Building, MapPin, Clock, DollarSign, Percent, Languages,
  Smartphone, Lock, Key, Eye, EyeOff, AlertTriangle
} from "lucide-react"

const settingsSections = [
  { id: "store", name: "Store details", icon: Store },
  { id: "plan", name: "Plan", icon: CreditCard },
  { id: "billing", name: "Billing", icon: FileText },
  { id: "users", name: "Users and permissions", icon: Users },
  { id: "payments", name: "Payments", icon: DollarSign },
  { id: "checkout", name: "Checkout", icon: Package },
  { id: "shipping", name: "Shipping and delivery", icon: Truck },
  { id: "taxes", name: "Taxes and duties", icon: Percent },
  { id: "locations", name: "Locations", icon: MapPin },
  { id: "notifications", name: "Notifications", icon: Bell },
  { id: "languages", name: "Languages", icon: Languages },
  { id: "policies", name: "Policies", icon: FileText },
  { id: "apps", name: "Apps and sales channels", icon: Smartphone },
  { id: "security", name: "Security", icon: Shield },
]

export default function SettingsPage() {
  const { vendor } = useAuth()
  const [activeSection, setActiveSection] = useState("store")
  const [showPassword, setShowPassword] = useState(false)

  if (!vendor) return null

  return (
    <div className="flex gap-6 min-h-[calc(100vh-8rem)]">
      {/* Settings Sidebar */}
      <div className="w-64 flex-shrink-0">
        <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden sticky top-6">
          <div className="p-4 border-b border-[#E8E0D5]">
            <h2 className="font-semibold text-[#1B4332]">Settings</h2>
          </div>
          <nav className="p-2">
            {settingsSections.map((section) => (
              <button
                key={section.id}
                onClick={() => setActiveSection(section.id)}
                className={`w-full flex items-center space-x-3 px-3 py-2 rounded-lg text-sm transition-colors ${
                  activeSection === section.id
                    ? "bg-[#1B4332] text-white"
                    : "text-[#1B4332] hover:bg-[#F5F0E8]"
                }`}
              >
                <section.icon className={`h-4 w-4 ${activeSection === section.id ? "text-white" : "text-[#4F8A6D]"}`} />
                <span>{section.name}</span>
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 space-y-6">
        {/* Store Details Section */}
        {activeSection === "store" && (
          <>
            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Store details</h3>
                <p className="text-sm text-[#8C9A8F] mt-1">Basic information about your store</p>
              </div>
              <div className="p-6 space-y-6">
                {/* Store Logo & Banner */}
                <div className="flex items-start space-x-6">
                  <div>
                    <p className="text-sm font-medium text-[#1B4332] mb-2">Store logo</p>
                    <div className="h-24 w-24 rounded-xl bg-[#1B4332] flex items-center justify-center text-white text-3xl font-bold">
                      {vendor.storeName.charAt(0)}
                    </div>
                    <Button variant="outline" size="sm" className="mt-2">
                      <Upload className="h-3.5 w-3.5 mr-1" />
                      Upload
                    </Button>
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium text-[#1B4332] mb-2">Store banner</p>
                    <div className="h-24 rounded-xl bg-gradient-to-r from-[#1B4332] to-[#2D5A45] flex items-center justify-center">
                      <span className="text-white/60 text-sm">1200 x 300 recommended</span>
                    </div>
                    <Button variant="outline" size="sm" className="mt-2">
                      <Upload className="h-3.5 w-3.5 mr-1" />
                      Upload banner
                    </Button>
                  </div>
                </div>

                {/* Store Name */}
                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">Store name</label>
                    <Input defaultValue={vendor.storeName} className="bg-white border-[#E8E0D5]" />
                  </div>
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">Legal business name</label>
                    <Input defaultValue="Glow Electronics LLC" className="bg-white border-[#E8E0D5]" />
                  </div>
                </div>

                {/* Contact Info */}
                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">Store contact email</label>
                    <Input type="email" defaultValue={vendor.contactEmail || "contact@glowelectronics.com"} className="bg-white border-[#E8E0D5]" />
                  </div>
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">Store phone</label>
                    <Input type="tel" defaultValue={vendor.phoneNumber || "+1 (555) 123-4567"} className="bg-white border-[#E8E0D5]" />
                  </div>
                </div>

                {/* Industry */}
                <div>
                  <label className="text-sm font-medium text-[#1B4332] block mb-2">Store industry</label>
                  <select className="w-full h-10 px-3 rounded-xl border border-[#E8E0D5] bg-white text-[#1B4332] text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4332]/20">
                    <option>Electronics</option>
                    <option>Fashion</option>
                    <option>Home & Garden</option>
                    <option>Health & Beauty</option>
                    <option>Food & Beverage</option>
                    <option>Other</option>
                  </select>
                </div>

                {/* Description */}
                <div>
                  <label className="text-sm font-medium text-[#1B4332] block mb-2">Store description</label>
                  <textarea 
                    defaultValue={vendor.description || "Premium electronics and accessories for the modern lifestyle."}
                    className="w-full min-h-[100px] px-3 py-2 rounded-xl border border-[#E8E0D5] bg-white text-[#1B4332] text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4332]/20"
                  />
                </div>
              </div>
              <div className="px-6 py-4 bg-[#FAF8F5] border-t border-[#E8E0D5] flex justify-end">
                <Button>Save</Button>
              </div>
            </div>

            {/* Store Address */}
            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Store address</h3>
                <p className="text-sm text-[#8C9A8F] mt-1">This address will appear on your invoices</p>
              </div>
              <div className="p-6 space-y-4">
                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">Country/Region</label>
                    <select className="w-full h-10 px-3 rounded-xl border border-[#E8E0D5] bg-white text-[#1B4332] text-sm">
                      <option>United States</option>
                      <option>Canada</option>
                      <option>United Kingdom</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">State/Province</label>
                    <Input defaultValue="California" className="bg-white border-[#E8E0D5]" />
                  </div>
                </div>
                <div>
                  <label className="text-sm font-medium text-[#1B4332] block mb-2">Address</label>
                  <Input defaultValue="123 Commerce Street" className="bg-white border-[#E8E0D5]" />
                </div>
                <div className="grid grid-cols-3 gap-6">
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">City</label>
                    <Input defaultValue="San Francisco" className="bg-white border-[#E8E0D5]" />
                  </div>
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">ZIP code</label>
                    <Input defaultValue="94102" className="bg-white border-[#E8E0D5]" />
                  </div>
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">Phone</label>
                    <Input defaultValue="+1 (555) 123-4567" className="bg-white border-[#E8E0D5]" />
                  </div>
                </div>
              </div>
              <div className="px-6 py-4 bg-[#FAF8F5] border-t border-[#E8E0D5] flex justify-end">
                <Button>Save</Button>
              </div>
            </div>

            {/* Store Currency */}
            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Store currency</h3>
                <p className="text-sm text-[#8C9A8F] mt-1">The currency your products are sold in</p>
              </div>
              <div className="p-6">
                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">Store currency</label>
                    <select className="w-full h-10 px-3 rounded-xl border border-[#E8E0D5] bg-white text-[#1B4332] text-sm">
                      <option>USD - US Dollar</option>
                      <option>EUR - Euro</option>
                      <option>GBP - British Pound</option>
                      <option>CAD - Canadian Dollar</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">Currency format</label>
                    <select className="w-full h-10 px-3 rounded-xl border border-[#E8E0D5] bg-white text-[#1B4332] text-sm">
                      <option>$1,234.56</option>
                      <option>1,234.56 USD</option>
                      <option>USD 1,234.56</option>
                    </select>
                  </div>
                </div>
              </div>
              <div className="px-6 py-4 bg-[#FAF8F5] border-t border-[#E8E0D5] flex justify-end">
                <Button>Save</Button>
              </div>
            </div>
          </>
        )}

        {/* Plan Section */}
        {activeSection === "plan" && (
          <>
            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Current plan</h3>
              </div>
              <div className="p-6">
                <div className="flex items-center justify-between p-4 bg-[#F5F0E8] rounded-xl">
                  <div>
                    <div className="flex items-center space-x-2">
                      <span className="text-lg font-semibold text-[#1B4332]">
                        {vendor.subscriptionTier === "premium" ? "Premium" : "Free"} Plan
                      </span>
                      <span className="px-2 py-0.5 bg-[#D1E7DD] text-[#1B4332] text-xs font-medium rounded-full">Active</span>
                    </div>
                    <p className="text-sm text-[#8C9A8F] mt-1">3% commission on all transactions</p>
                  </div>
                  {vendor.subscriptionTier === "free" && (
                    <Button>Upgrade plan</Button>
                  )}
                </div>

                <div className="mt-6 grid grid-cols-2 gap-4">
                  <div className="p-4 border border-[#E8E0D5] rounded-xl">
                    <h4 className="font-medium text-[#1B4332]">Free Plan</h4>
                    <p className="text-2xl font-bold text-[#1B4332] mt-2">$0<span className="text-sm font-normal text-[#8C9A8F]">/month</span></p>
                    <ul className="mt-4 space-y-2 text-sm text-[#1B4332]">
                      <li className="flex items-center"><Check className="h-4 w-4 text-[#1B4332] mr-2" />Unlimited products</li>
                      <li className="flex items-center"><Check className="h-4 w-4 text-[#1B4332] mr-2" />Order management</li>
                      <li className="flex items-center"><Check className="h-4 w-4 text-[#1B4332] mr-2" />Basic analytics</li>
                      <li className="flex items-center"><Check className="h-4 w-4 text-[#1B4332] mr-2" />3% transaction fee</li>
                    </ul>
                  </div>
                  <div className="p-4 border-2 border-[#1B4332] rounded-xl relative">
                    <span className="absolute -top-3 left-4 px-2 py-0.5 bg-[#1B4332] text-white text-xs font-medium rounded-full">Recommended</span>
                    <h4 className="font-medium text-[#1B4332]">Premium Plan</h4>
                    <p className="text-2xl font-bold text-[#1B4332] mt-2">$29<span className="text-sm font-normal text-[#8C9A8F]">/month</span></p>
                    <ul className="mt-4 space-y-2 text-sm text-[#1B4332]">
                      <li className="flex items-center"><Check className="h-4 w-4 text-[#1B4332] mr-2" />Everything in Free</li>
                      <li className="flex items-center"><Check className="h-4 w-4 text-[#1B4332] mr-2" />AI customer service</li>
                      <li className="flex items-center"><Check className="h-4 w-4 text-[#1B4332] mr-2" />Advanced analytics</li>
                      <li className="flex items-center"><Check className="h-4 w-4 text-[#1B4332] mr-2" />Priority support</li>
                    </ul>
                    <Button className="w-full mt-4">Upgrade to Premium</Button>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}

        {/* Billing Section */}
        {activeSection === "billing" && (
          <>
            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Billing information</h3>
              </div>
              <div className="p-6 space-y-6">
                <div className="flex items-center justify-between p-4 bg-[#F5F0E8] rounded-xl">
                  <div className="flex items-center space-x-4">
                    <div className="h-12 w-12 rounded-xl bg-white flex items-center justify-center">
                      <CreditCard className="h-6 w-6 text-[#1B4332]" />
                    </div>
                    <div>
                      <p className="font-medium text-[#1B4332]">Visa ending in 4242</p>
                      <p className="text-sm text-[#8C9A8F]">Expires 12/2025</p>
                    </div>
                  </div>
                  <Button variant="outline" size="sm">Update</Button>
                </div>

                <div>
                  <h4 className="font-medium text-[#1B4332] mb-4">Billing history</h4>
                  <div className="border border-[#E8E0D5] rounded-xl overflow-hidden">
                    <table className="w-full">
                      <thead className="bg-[#F5F0E8]">
                        <tr>
                          <th className="px-4 py-3 text-left text-xs font-medium text-[#8C9A8F] uppercase">Date</th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-[#8C9A8F] uppercase">Description</th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-[#8C9A8F] uppercase">Amount</th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-[#8C9A8F] uppercase">Status</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-[#E8E0D5]">
                        <tr>
                          <td className="px-4 py-3 text-sm text-[#1B4332]">Dec 1, 2024</td>
                          <td className="px-4 py-3 text-sm text-[#1B4332]">Commission - November</td>
                          <td className="px-4 py-3 text-sm text-[#1B4332]">$52.80</td>
                          <td className="px-4 py-3"><span className="px-2 py-1 bg-[#D1E7DD] text-[#1B4332] text-xs rounded-full">Paid</span></td>
                        </tr>
                        <tr>
                          <td className="px-4 py-3 text-sm text-[#1B4332]">Nov 1, 2024</td>
                          <td className="px-4 py-3 text-sm text-[#1B4332]">Commission - October</td>
                          <td className="px-4 py-3 text-sm text-[#1B4332]">$48.30</td>
                          <td className="px-4 py-3"><span className="px-2 py-1 bg-[#D1E7DD] text-[#1B4332] text-xs rounded-full">Paid</span></td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}

        {/* Users Section */}
        {activeSection === "users" && (
          <>
            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5] flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-semibold text-[#1B4332]">Users and permissions</h3>
                  <p className="text-sm text-[#8C9A8F] mt-1">Manage who has access to your store</p>
                </div>
                <Button>Add staff</Button>
              </div>
              <div className="divide-y divide-[#E8E0D5]">
                {[
                  { name: "Sarah Johnson", email: "sarah@glowelectronics.com", role: "Owner", status: "Active" },
                  { name: "Michael Chen", email: "michael@glowelectronics.com", role: "Admin", status: "Active" },
                  { name: "Emily Rodriguez", email: "emily@glowelectronics.com", role: "Manager", status: "Active" },
                ].map((user, idx) => (
                  <div key={idx} className="flex items-center justify-between px-6 py-4 hover:bg-[#FAF8F5]">
                    <div className="flex items-center space-x-4">
                      <div className="h-10 w-10 rounded-full bg-[#1B4332] flex items-center justify-center text-white font-medium">
                        {user.name.charAt(0)}
                      </div>
                      <div>
                        <p className="font-medium text-[#1B4332]">{user.name}</p>
                        <p className="text-sm text-[#8C9A8F]">{user.email}</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-4">
                      <span className="px-2 py-1 bg-[#F5F0E8] text-[#1B4332] text-xs font-medium rounded-full">{user.role}</span>
                      <ChevronRight className="h-4 w-4 text-[#8C9A8F]" />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}

        {/* Payments Section */}
        {activeSection === "payments" && (
          <>
            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Payment providers</h3>
                <p className="text-sm text-[#8C9A8F] mt-1">Accept payments from customers</p>
              </div>
              <div className="p-6 space-y-4">
                <div className="flex items-center justify-between p-4 border border-[#E8E0D5] rounded-xl">
                  <div className="flex items-center space-x-4">
                    <div className="h-12 w-12 rounded-xl bg-[#F5F0E8] flex items-center justify-center">
                      <CreditCard className="h-6 w-6 text-[#1B4332]" />
                    </div>
                    <div>
                      <p className="font-medium text-[#1B4332]">Chipper Cash</p>
                      <p className="text-sm text-[#8C9A8F]">Accept mobile money and card payments</p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="px-2 py-1 bg-[#D1E7DD] text-[#1B4332] text-xs font-medium rounded-full">Connected</span>
                    <Button variant="outline" size="sm">Manage</Button>
                  </div>
                </div>

                <div className="p-4 border border-dashed border-[#E8E0D5] rounded-xl text-center">
                  <p className="text-sm text-[#8C9A8F]">Add another payment provider</p>
                  <Button variant="outline" size="sm" className="mt-2">Add provider</Button>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Payout settings</h3>
              </div>
              <div className="p-6 space-y-4">
                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">Payout schedule</label>
                    <select className="w-full h-10 px-3 rounded-xl border border-[#E8E0D5] bg-white text-[#1B4332] text-sm">
                      <option>Weekly</option>
                      <option>Bi-weekly</option>
                      <option>Monthly</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-sm font-medium text-[#1B4332] block mb-2">Minimum payout</label>
                    <Input defaultValue="$50.00" className="bg-white border-[#E8E0D5]" />
                  </div>
                </div>
              </div>
              <div className="px-6 py-4 bg-[#FAF8F5] border-t border-[#E8E0D5] flex justify-end">
                <Button>Save</Button>
              </div>
            </div>
          </>
        )}

        {/* Notifications Section */}
        {activeSection === "notifications" && (
          <>
            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Notification preferences</h3>
                <p className="text-sm text-[#8C9A8F] mt-1">Choose how you want to be notified</p>
              </div>
              <div className="divide-y divide-[#E8E0D5]">
                {[
                  { title: "New orders", desc: "Get notified when you receive a new order", email: true, push: true },
                  { title: "Order updates", desc: "Updates on order status changes", email: true, push: false },
                  { title: "Low stock alerts", desc: "When inventory falls below threshold", email: true, push: true },
                  { title: "Customer messages", desc: "New messages from customers", email: false, push: true },
                  { title: "Payout notifications", desc: "When payouts are processed", email: true, push: false },
                  { title: "Marketing tips", desc: "Tips to grow your business", email: false, push: false },
                ].map((item, idx) => (
                  <div key={idx} className="flex items-center justify-between px-6 py-4">
                    <div>
                      <p className="font-medium text-[#1B4332]">{item.title}</p>
                      <p className="text-sm text-[#8C9A8F]">{item.desc}</p>
                    </div>
                    <div className="flex items-center space-x-6">
                      <label className="flex items-center space-x-2 cursor-pointer">
                        <input type="checkbox" defaultChecked={item.email} className="h-4 w-4 rounded border-[#E8E0D5] text-[#1B4332]" />
                        <span className="text-sm text-[#8C9A8F]">Email</span>
                      </label>
                      <label className="flex items-center space-x-2 cursor-pointer">
                        <input type="checkbox" defaultChecked={item.push} className="h-4 w-4 rounded border-[#E8E0D5] text-[#1B4332]" />
                        <span className="text-sm text-[#8C9A8F]">Push</span>
                      </label>
                    </div>
                  </div>
                ))}
              </div>
              <div className="px-6 py-4 bg-[#FAF8F5] border-t border-[#E8E0D5] flex justify-end">
                <Button>Save preferences</Button>
              </div>
            </div>
          </>
        )}

        {/* Security Section */}
        {activeSection === "security" && (
          <>
            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Account security</h3>
              </div>
              <div className="p-6 space-y-6">
                {/* Email */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <div className="h-10 w-10 rounded-xl bg-[#F5F0E8] flex items-center justify-center">
                      <Mail className="h-5 w-5 text-[#1B4332]" />
                    </div>
                    <div>
                      <p className="font-medium text-[#1B4332]">Email address</p>
                      <p className="text-sm text-[#8C9A8F]">{vendor.email}</p>
                    </div>
                  </div>
                  <Button variant="outline" size="sm">Change</Button>
                </div>

                {/* Password */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <div className="h-10 w-10 rounded-xl bg-[#F5F0E8] flex items-center justify-center">
                      <Lock className="h-5 w-5 text-[#1B4332]" />
                    </div>
                    <div>
                      <p className="font-medium text-[#1B4332]">Password</p>
                      <p className="text-sm text-[#8C9A8F]">Last changed 30 days ago</p>
                    </div>
                  </div>
                  <Button variant="outline" size="sm">Change</Button>
                </div>

                {/* 2FA */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <div className="h-10 w-10 rounded-xl bg-[#F5F0E8] flex items-center justify-center">
                      <Key className="h-5 w-5 text-[#1B4332]" />
                    </div>
                    <div>
                      <p className="font-medium text-[#1B4332]">Two-factor authentication</p>
                      <p className="text-sm text-[#8C9A8F]">Add an extra layer of security</p>
                    </div>
                  </div>
                  <Button variant="outline" size="sm">Enable</Button>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Active sessions</h3>
              </div>
              <div className="divide-y divide-[#E8E0D5]">
                {[
                  { device: "Chrome on MacOS", location: "San Francisco, CA", current: true, time: "Now" },
                  { device: "Safari on iPhone", location: "San Francisco, CA", current: false, time: "2 hours ago" },
                ].map((session, idx) => (
                  <div key={idx} className="flex items-center justify-between px-6 py-4">
                    <div className="flex items-center space-x-4">
                      <div className="h-10 w-10 rounded-xl bg-[#F5F0E8] flex items-center justify-center">
                        <Globe className="h-5 w-5 text-[#1B4332]" />
                      </div>
                      <div>
                        <div className="flex items-center space-x-2">
                          <p className="font-medium text-[#1B4332]">{session.device}</p>
                          {session.current && <span className="px-2 py-0.5 bg-[#D1E7DD] text-[#1B4332] text-xs rounded-full">Current</span>}
                        </div>
                        <p className="text-sm text-[#8C9A8F]">{session.location} • {session.time}</p>
                      </div>
                    </div>
                    {!session.current && <Button variant="outline" size="sm">Revoke</Button>}
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-white rounded-xl border border-[#FEE2E2] overflow-hidden">
              <div className="p-6">
                <div className="flex items-start space-x-4">
                  <div className="h-10 w-10 rounded-xl bg-[#FEE2E2] flex items-center justify-center">
                    <AlertTriangle className="h-5 w-5 text-[#991B1B]" />
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold text-[#991B1B]">Danger zone</h3>
                    <p className="text-sm text-[#8C9A8F] mt-1">Permanently delete your store and all of its data</p>
                    <Button variant="outline" size="sm" className="mt-4 text-[#991B1B] border-[#991B1B] hover:bg-[#FEE2E2]">
                      Delete store
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}

        {/* Shipping Section */}
        {activeSection === "shipping" && (
          <>
            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Shipping providers</h3>
                <p className="text-sm text-[#8C9A8F] mt-1">Manage your shipping integrations</p>
              </div>
              <div className="p-6 space-y-4">
                <div className="flex items-center justify-between p-4 border border-[#E8E0D5] rounded-xl">
                  <div className="flex items-center space-x-4">
                    <div className="h-12 w-12 rounded-xl bg-[#F5F0E8] flex items-center justify-center">
                      <Truck className="h-6 w-6 text-[#1B4332]" />
                    </div>
                    <div>
                      <p className="font-medium text-[#1B4332]">Skynet Shipping</p>
                      <p className="text-sm text-[#8C9A8F]">International and domestic shipping</p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="px-2 py-1 bg-[#D1E7DD] text-[#1B4332] text-xs font-medium rounded-full">Connected</span>
                    <Button variant="outline" size="sm">Manage</Button>
                  </div>
                </div>

                <div className="flex items-center justify-between p-4 border border-[#E8E0D5] rounded-xl">
                  <div className="flex items-center space-x-4">
                    <div className="h-12 w-12 rounded-xl bg-[#F5F0E8] flex items-center justify-center">
                      <Package className="h-6 w-6 text-[#1B4332]" />
                    </div>
                    <div>
                      <p className="font-medium text-[#1B4332]">Uber Delivery</p>
                      <p className="text-sm text-[#8C9A8F]">Same-day local delivery</p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="px-2 py-1 bg-[#D1E7DD] text-[#1B4332] text-xs font-medium rounded-full">Connected</span>
                    <Button variant="outline" size="sm">Manage</Button>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl border border-[#E8E0D5] overflow-hidden">
              <div className="p-6 border-b border-[#E8E0D5]">
                <h3 className="text-lg font-semibold text-[#1B4332]">Shipping rates</h3>
              </div>
              <div className="p-6">
                <div className="border border-[#E8E0D5] rounded-xl overflow-hidden">
                  <table className="w-full">
                    <thead className="bg-[#F5F0E8]">
                      <tr>
                        <th className="px-4 py-3 text-left text-xs font-medium text-[#8C9A8F] uppercase">Zone</th>
                        <th className="px-4 py-3 text-left text-xs font-medium text-[#8C9A8F] uppercase">Rate name</th>
                        <th className="px-4 py-3 text-left text-xs font-medium text-[#8C9A8F] uppercase">Condition</th>
                        <th className="px-4 py-3 text-left text-xs font-medium text-[#8C9A8F] uppercase">Price</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[#E8E0D5]">
                      <tr>
                        <td className="px-4 py-3 text-sm text-[#1B4332]">Domestic</td>
                        <td className="px-4 py-3 text-sm text-[#1B4332]">Standard</td>
                        <td className="px-4 py-3 text-sm text-[#8C9A8F]">All orders</td>
                        <td className="px-4 py-3 text-sm text-[#1B4332]">$5.99</td>
                      </tr>
                      <tr>
                        <td className="px-4 py-3 text-sm text-[#1B4332]">Domestic</td>
                        <td className="px-4 py-3 text-sm text-[#1B4332]">Express</td>
                        <td className="px-4 py-3 text-sm text-[#8C9A8F]">All orders</td>
                        <td className="px-4 py-3 text-sm text-[#1B4332]">$12.99</td>
                      </tr>
                      <tr>
                        <td className="px-4 py-3 text-sm text-[#1B4332]">International</td>
                        <td className="px-4 py-3 text-sm text-[#1B4332]">Standard</td>
                        <td className="px-4 py-3 text-sm text-[#8C9A8F]">All orders</td>
                        <td className="px-4 py-3 text-sm text-[#1B4332]">$24.99</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
                <Button variant="outline" size="sm" className="mt-4">Add shipping rate</Button>
              </div>
            </div>
          </>
        )}

        {/* Default content for other sections */}
        {!["store", "plan", "billing", "users", "payments", "notifications", "security", "shipping"].includes(activeSection) && (
          <div className="bg-white rounded-xl border border-[#E8E0D5] p-12 text-center">
            <div className="h-16 w-16 rounded-full bg-[#F5F0E8] flex items-center justify-center mx-auto mb-4">
              {settingsSections.find(s => s.id === activeSection)?.icon && (
                <span className="text-[#1B4332]">
                  {(() => {
                    const Icon = settingsSections.find(s => s.id === activeSection)?.icon
                    return Icon ? <Icon className="h-8 w-8" /> : null
                  })()}
                </span>
              )}
            </div>
            <h3 className="text-lg font-semibold text-[#1B4332] mb-2">
              {settingsSections.find(s => s.id === activeSection)?.name}
            </h3>
            <p className="text-sm text-[#8C9A8F]">This section is coming soon</p>
          </div>
        )}
      </div>
    </div>
  )
}
