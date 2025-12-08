import * as React from "react"
import { cn } from "@/lib/utils"

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          // Shopify-style input with proper depth and focus states
          "flex h-9 w-full rounded-lg border border-[#C9CCCF] bg-white px-3 py-2 text-sm text-[#1B4332]",
          "placeholder:text-[#8C9A8F]",
          "shadow-[inset_0_1px_2px_rgba(0,0,0,0.05)]",
          "focus:outline-none focus:border-[#1B4332] focus:ring-1 focus:ring-[#1B4332] focus:shadow-[0_0_0_1px_#1B4332]",
          "hover:border-[#8C9A8F]",
          "disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-[#F7F7F7]",
          "transition-all duration-150",
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = "Input"

export { Input }
