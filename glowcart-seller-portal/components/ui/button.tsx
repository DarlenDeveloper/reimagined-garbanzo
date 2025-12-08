import * as React from "react"
import { cn } from "@/lib/utils"

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "default" | "outline" | "ghost" | "destructive" | "secondary" | "plain"
  size?: "default" | "sm" | "lg" | "icon" | "slim"
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = "default", size = "default", ...props }, ref) => {
    return (
      <button
        className={cn(
          // Base styles - Shopify-like with depth and tactile feel
          "inline-flex items-center justify-center font-semibold transition-all duration-150 cursor-pointer select-none",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-1",
          "disabled:pointer-events-none disabled:opacity-50 disabled:cursor-not-allowed",
          "active:scale-[0.98]",
          {
            // Primary - Dark green with gradient and shadow for depth
            "bg-[#1B4332] text-white rounded-lg shadow-[0_1px_0_0_rgba(0,0,0,0.1),inset_0_1px_0_0_rgba(255,255,255,0.1)] hover:bg-[#163728] active:bg-[#122D21] active:shadow-[inset_0_2px_4px_rgba(0,0,0,0.2)] focus-visible:ring-[#1B4332] border border-[#163728]": 
              variant === "default",
            
            // Outline - White with border and subtle shadow
            "bg-white text-[#1B4332] rounded-lg border border-[#C9CCCF] shadow-[0_1px_0_0_rgba(0,0,0,0.05)] hover:bg-[#F7F7F7] hover:border-[#BABFC4] active:bg-[#F0F0F0] active:shadow-[inset_0_2px_4px_rgba(0,0,0,0.1)] focus-visible:ring-[#1B4332]": 
              variant === "outline",
            
            // Ghost - No background, subtle hover
            "text-[#1B4332] rounded-lg hover:bg-[#F5F0E8] active:bg-[#E8E0D5] focus-visible:ring-[#1B4332]": 
              variant === "ghost",
            
            // Destructive - Red with depth
            "bg-[#D72C0D] text-white rounded-lg shadow-[0_1px_0_0_rgba(0,0,0,0.1),inset_0_1px_0_0_rgba(255,255,255,0.1)] hover:bg-[#BC2200] active:bg-[#A21B00] active:shadow-[inset_0_2px_4px_rgba(0,0,0,0.2)] focus-visible:ring-[#D72C0D] border border-[#BC2200]": 
              variant === "destructive",
            
            // Secondary - Beige background
            "bg-[#F5F0E8] text-[#1B4332] rounded-lg border border-[#E8E0D5] shadow-[0_1px_0_0_rgba(0,0,0,0.05)] hover:bg-[#EDE7DD] active:bg-[#E5DDD1] active:shadow-[inset_0_1px_2px_rgba(0,0,0,0.1)] focus-visible:ring-[#1B4332]": 
              variant === "secondary",
            
            // Plain - Text only, like Shopify's plain buttons
            "text-[#1B4332] underline-offset-2 hover:underline focus-visible:ring-[#1B4332] p-0 h-auto": 
              variant === "plain",
          },
          {
            // Size variants
            "h-9 px-4 py-2 text-sm gap-1.5": size === "default",
            "h-7 px-3 text-xs gap-1": size === "sm",
            "h-11 px-5 text-sm gap-2": size === "lg",
            "h-9 w-9 p-0": size === "icon",
            "h-7 px-2 text-xs": size === "slim",
          },
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button }
