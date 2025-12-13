"use client"

import { useState } from "react"
import {
  Heart,
  MessageCircle,
  Plus,
  Image,
  Video,
  Clock,
  Sparkles,
  Eye,
  Grid3X3,
  Bookmark,
  Settings,
  MoreHorizontal,
  Send,
  MapPin,
  Link2,
  Crown,
  Play,
  BadgeCheck,
  ShoppingBag,
  Film,
  Star,
  Flame,
  Lightbulb,
  Package,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { useAuth } from "@/lib/auth-context"
import { DUMMY_SOCIAL_POSTS } from "@/lib/dummy-data"

const STORY_HIGHLIGHTS = [
  { id: "new", label: "New", isAdd: true, icon: Plus },
  { id: "1", label: "Products", icon: ShoppingBag },
  { id: "2", label: "Behind Scenes", icon: Film },
  { id: "3", label: "Reviews", icon: Star },
  { id: "4", label: "Sales", icon: Flame },
  { id: "5", label: "Tips", icon: Lightbulb },
]

export default function SocialsPage() {
  const { vendor } = useAuth()
  const [posts, setPosts] = useState(DUMMY_SOCIAL_POSTS)
  const [showCreatePost, setShowCreatePost] = useState(false)
  const [newPostContent, setNewPostContent] = useState("")
  const [likedPosts, setLikedPosts] = useState<Set<string>>(new Set())
  const isPremium = vendor?.subscriptionTier === "premium"

  const totalFollowers = 1247
  const totalFollowing = 89
  const totalPosts = posts.length

  const toggleLike = (postId: string) => {
    const newLiked = new Set(likedPosts)
    if (newLiked.has(postId)) {
      newLiked.delete(postId)
    } else {
      newLiked.add(postId)
    }
    setLikedPosts(newLiked)
  }

  const getExpiryTime = (expiresAt: string) => {
    const now = new Date()
    const expires = new Date(expiresAt)
    const diff = expires.getTime() - now.getTime()
    if (diff <= 0) return "Expired"
    const hours = Math.floor(diff / (1000 * 60 * 60))
    if (hours < 24) return `${hours}h`
    return `${Math.floor(hours / 24)}d`
  }

  const handleCreatePost = () => {
    if (!newPostContent.trim()) return
    const expiresIn = isPremium ? 7 : 1
    const newPost = {
      postId: `post-${Date.now()}`,
      vendorId: vendor?.vendorId || "vendor-123",
      content: newPostContent,
      mediaType: "text" as const,
      likes: 0,
      comments: 0,
      shares: 0,
      views: 0,
      expiresAt: new Date(Date.now() + expiresIn * 24 * 60 * 60 * 1000).toISOString(),
      createdAt: new Date().toISOString(),
    }
    setPosts([newPost, ...posts])
    setNewPostContent("")
    setShowCreatePost(false)
  }

  return (
    <div className="max-w-5xl mx-auto">
      {/* Profile Header */}
      <div className="bg-white rounded-2xl border border-[#E8E0D5] overflow-hidden mb-6">
        <div className="h-28 bg-gradient-to-r from-[#1B4332] via-[#2D5A45] to-[#1B4332] relative">
          {isPremium && (
            <div className="absolute top-3 right-3 flex items-center space-x-1 px-2 py-1 bg-white/20 backdrop-blur-sm rounded-full">
              <Crown className="h-3 w-3 text-[#FFD700]" />
              <span className="text-[10px] font-medium text-white">PRO</span>
            </div>
          )}
        </div>

        <div className="px-6 pb-5">
          <div className="flex items-end justify-between -mt-10 mb-3">
            <div className="relative">
              <div className="h-20 w-20 rounded-full border-4 border-white bg-[#1B4332] flex items-center justify-center text-white text-2xl font-bold shadow-lg">
                {vendor?.storeName?.charAt(0) || "G"}
              </div>
              <span className="absolute bottom-0.5 right-0.5 h-4 w-4 bg-[#22C55E] border-[3px] border-white rounded-full"></span>
            </div>
            <div className="flex items-center space-x-2">
              <Button variant="outline" size="sm" onClick={() => setShowCreatePost(true)}>
                <Plus className="h-4 w-4 mr-1" />
                Post
              </Button>
              <Button variant="outline" size="sm">
                <Settings className="h-4 w-4" />
              </Button>
            </div>
          </div>

          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center space-x-2 mb-1">
                <h1 className="text-lg font-bold text-[#1B4332]">
                  {vendor?.storeName || "Glow Electronics"}
                </h1>
                <BadgeCheck className="h-4 w-4 text-[#3B82F6]" />
              </div>
              <p className="text-xs text-[#8C9A8F] mb-2">@glowelectronics</p>
              <p className="text-sm text-[#1B4332] mb-2">
                Premium Electronics & Accessories. Quality products, exceptional service.
              </p>
              <div className="flex items-center space-x-3 text-xs text-[#8C9A8F]">
                <span className="flex items-center space-x-1">
                  <MapPin className="h-3 w-3" />
                  <span>San Francisco</span>
                </span>
                <a href="#" className="flex items-center space-x-1 text-[#3B82F6] hover:underline">
                  <Link2 className="h-3 w-3" />
                  <span>glowelectronics.com</span>
                </a>
              </div>
            </div>

            <div className="flex items-center space-x-6 text-center">
              <div>
                <p className="text-lg font-bold text-[#1B4332]">{totalPosts}</p>
                <p className="text-[10px] text-[#8C9A8F]">posts</p>
              </div>
              <div className="cursor-pointer hover:opacity-70">
                <p className="text-lg font-bold text-[#1B4332]">{totalFollowers.toLocaleString()}</p>
                <p className="text-[10px] text-[#8C9A8F]">followers</p>
              </div>
              <div className="cursor-pointer hover:opacity-70">
                <p className="text-lg font-bold text-[#1B4332]">{totalFollowing}</p>
                <p className="text-[10px] text-[#8C9A8F]">following</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Story Highlights */}
      <div className="flex items-center space-x-4 mb-6 overflow-x-auto pb-1">
        {STORY_HIGHLIGHTS.map((highlight) => {
          const Icon = highlight.icon
          return (
            <div key={highlight.id} className="flex flex-col items-center space-y-1 flex-shrink-0">
              <div
                className={`h-14 w-14 rounded-full flex items-center justify-center cursor-pointer transition-all hover:scale-105 ${
                  highlight.isAdd
                    ? "border-2 border-dashed border-[#8C9A8F] bg-white hover:border-[#1B4332]"
                    : "bg-gradient-to-br from-[#1B4332] to-[#2D5A45] p-0.5"
                }`}
              >
                {highlight.isAdd ? (
                  <Icon className="h-5 w-5 text-[#8C9A8F]" />
                ) : (
                  <div className="h-full w-full rounded-full bg-white flex items-center justify-center">
                    <Icon className="h-5 w-5 text-[#1B4332]" />
                  </div>
                )}
              </div>
              <span className="text-[10px] text-[#1B4332] font-medium">{highlight.label}</span>
            </div>
          )
        })}
      </div>

      {/* Section Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-2">
          <Grid3X3 className="h-4 w-4 text-[#1B4332]" />
          <span className="text-sm font-medium text-[#1B4332]">Posts</span>
        </div>
        <span className="text-xs text-[#8C9A8F]">{posts.length} posts</span>
      </div>

      {/* Posts Grid */}
      <div className="grid grid-cols-3 gap-1 rounded-xl overflow-hidden">
        {posts.map((post) => (
          <div
            key={post.postId}
            className="aspect-square bg-gradient-to-br from-[#1B4332] to-[#2D5A45] relative group cursor-pointer"
          >
            {/* Content */}
            <div className="absolute inset-0 flex items-center justify-center p-3">
              <p className="text-white text-xs text-center line-clamp-4 leading-relaxed">{post.content}</p>
            </div>

            {/* Hover Overlay */}
            <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
              <div className="flex items-center space-x-4">
                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    toggleLike(post.postId)
                  }}
                  className="flex items-center space-x-1 text-white"
                >
                  <Heart
                    className={`h-5 w-5 ${likedPosts.has(post.postId) ? "fill-white" : ""}`}
                  />
                  <span className="text-sm font-semibold">
                    {post.likes + (likedPosts.has(post.postId) ? 1 : 0)}
                  </span>
                </button>
                <div className="flex items-center space-x-1 text-white">
                  <MessageCircle className="h-5 w-5" />
                  <span className="text-sm font-semibold">{post.comments}</span>
                </div>
              </div>
            </div>

            {/* Video Indicator */}
            {post.mediaType === "video" && (
              <div className="absolute top-2 right-2">
                <Play className="h-4 w-4 text-white drop-shadow-lg" />
              </div>
            )}

            {/* Expiry Badge */}
            <div className="absolute bottom-1.5 left-1.5 flex items-center space-x-0.5 px-1.5 py-0.5 bg-black/50 rounded text-[9px] text-white">
              <Clock className="h-2.5 w-2.5" />
              <span>{getExpiryTime(post.expiresAt)}</span>
            </div>

            {/* Views */}
            <div className="absolute bottom-1.5 right-1.5 flex items-center space-x-0.5 px-1.5 py-0.5 bg-black/50 rounded text-[9px] text-white">
              <Eye className="h-2.5 w-2.5" />
              <span>{post.views}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Empty State */}
      {posts.length === 0 && (
        <div className="bg-white rounded-xl border border-[#E8E0D5] p-12 text-center">
          <div className="h-14 w-14 rounded-full bg-[#F5F0E8] flex items-center justify-center mx-auto mb-3">
            <Package className="h-7 w-7 text-[#8C9A8F]" />
          </div>
          <h3 className="font-semibold text-[#1B4332] mb-1">No posts yet</h3>
          <p className="text-sm text-[#8C9A8F] mb-4">Share updates with your followers</p>
          <Button size="sm" onClick={() => setShowCreatePost(true)}>
            <Plus className="h-4 w-4 mr-1" />
            Create Post
          </Button>
        </div>
      )}

      {/* Upgrade Banner */}
      {!isPremium && (
        <div className="mt-6 bg-gradient-to-r from-[#1B4332] to-[#2D5A45] rounded-xl p-4 text-white">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <Sparkles className="h-6 w-6" />
              <div>
                <p className="font-semibold text-sm">Upgrade to Pro</p>
                <p className="text-xs text-white/70">Posts visible for 7 days instead of 24h</p>
              </div>
            </div>
            <Button size="sm" className="bg-white text-[#1B4332] hover:bg-white/90">
              Upgrade
            </Button>
          </div>
        </div>
      )}

      {/* Create Post Modal */}
      {showCreatePost && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
          onClick={() => setShowCreatePost(false)}
        >
          <div
            className="bg-white rounded-2xl w-full max-w-md mx-4 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between px-4 py-3 border-b border-[#E8E0D5]">
              <button onClick={() => setShowCreatePost(false)} className="text-sm text-[#8C9A8F]">
                Cancel
              </button>
              <span className="font-semibold text-sm text-[#1B4332]">New Post</span>
              <button
                onClick={handleCreatePost}
                className="text-sm font-semibold text-[#3B82F6] disabled:opacity-50"
                disabled={!newPostContent.trim()}
              >
                Share
              </button>
            </div>
            <div className="p-4">
              <div className="flex items-start space-x-3">
                <div className="h-9 w-9 rounded-full bg-[#1B4332] flex items-center justify-center text-white font-medium text-sm">
                  {vendor?.storeName?.charAt(0) || "G"}
                </div>
                <textarea
                  value={newPostContent}
                  onChange={(e) => setNewPostContent(e.target.value)}
                  placeholder="What's new at your store?"
                  className="flex-1 min-h-[100px] text-sm text-[#1B4332] placeholder:text-[#8C9A8F] focus:outline-none resize-none"
                  autoFocus
                />
              </div>
            </div>
            <div className="flex items-center justify-between px-4 py-3 border-t border-[#E8E0D5] bg-[#FAF8F5]">
              <div className="flex items-center space-x-2">
                <button className="p-2 rounded-lg hover:bg-[#E8E0D5] transition-colors">
                  <Image className="h-4 w-4 text-[#1B4332]" />
                </button>
                <button className="p-2 rounded-lg hover:bg-[#E8E0D5] transition-colors">
                  <Video className="h-4 w-4 text-[#1B4332]" />
                </button>
              </div>
              <div className="flex items-center space-x-1.5 text-[10px] text-[#8C9A8F]">
                <Clock className="h-3 w-3" />
                <span>Expires {isPremium ? "7d" : "24h"}</span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
