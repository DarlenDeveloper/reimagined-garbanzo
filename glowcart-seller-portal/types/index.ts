// Vendor Types
export interface Vendor {
  vendorId: string
  email: string
  storeName: string
  description?: string
  logoUrl?: string
  bannerUrl?: string
  contactEmail?: string
  phoneNumber?: string
  businessType?: string
  subscriptionTier: "free" | "premium"
  status: "active" | "inactive"
  createdAt: string
}

// Product Types
export interface Product {
  productId: string
  vendorId: string
  name: string
  description?: string
  price: number
  currency: string
  categoryId?: string
  images: string[]
  variants: ProductVariant[]
  sku?: string
  status: "active" | "inactive" | "out_of_stock"
  createdAt: string
  updatedAt: string
}

export interface ProductVariant {
  variantId: string
  productId: string
  name: string
  sku?: string
  priceAdjustment: number
}

// Inventory Types
export interface InventoryItem {
  productId: string
  productName: string
  variantId?: string
  quantity: number
  lowStockAlert: boolean
  threshold: number
  updatedAt: string
}

// Order Types
export type OrderStatus = "pending" | "processing" | "in_transit" | "delivered" | "cancelled"

export interface Order {
  orderId: string
  vendorId: string
  buyerId: string
  items: OrderItem[]
  totalAmount: number
  currency: string
  status: OrderStatus
  deliveryAddress: Address
  createdAt: string
  updatedAt: string
}

export interface OrderItem {
  productId: string
  productName: string
  quantity: number
  price: number
  variantId?: string
}

export interface Address {
  streetAddress: string
  city: string
  state?: string
  postalCode?: string
  country: string
}

export interface OrderEvent {
  eventId: string
  orderId: string
  eventType: string
  description: string
  createdAt: string
}

// Transaction Types
export interface Transaction {
  transactionId: string
  orderId: string
  vendorId: string
  grossAmount: number
  commission: number
  netAmount: number
  currency: string
  status: string
  processedAt: string
}

// Analytics Types
export interface DashboardMetrics {
  totalSales: number
  orderCount: number
  revenue: number
  commission: number
  netEarnings: number
  period: string
  topProducts: TopProduct[]
  salesTrend: DataPoint[]
}

export interface TopProduct {
  productId: string
  productName: string
  sales: number
  revenue: number
}

export interface DataPoint {
  date: string
  value: number
}

// Notification Types
export interface Notification {
  notificationId: string
  vendorId: string
  type: string
  title: string
  message: string
  readAt?: string
  createdAt: string
}


// Delivery Types
export interface Delivery {
  deliveryId: string
  orderId: string
  deliveryProvider: "uber" | "manual"
  deliveryProviderId?: string
  pickupAddress: Address
  dropoffAddress: Address
  status: "pending" | "assigned" | "picked_up" | "in_transit" | "delivered" | "failed"
  estimatedPickupTime?: string
  actualPickupTime?: string
  estimatedDeliveryTime?: string
  actualDeliveryTime?: string
  trackingUrl?: string
  driverName?: string
  driverPhone?: string
  createdAt: string
  updatedAt: string
}

// Shipment Types
export interface Shipment {
  shipmentId: string
  orderId: string
  shippingProvider: "skynet" | "other"
  trackingNumber: string
  shippingLabelUrl?: string
  status: "pending" | "label_created" | "picked_up" | "in_transit" | "out_for_delivery" | "delivered" | "returned"
  weight?: number
  dimensions?: {
    length: number
    width: number
    height: number
  }
  shippedAt?: string
  deliveredAt?: string
  createdAt: string
  updatedAt: string
}

// User Role Types
export type UserRole = "owner" | "admin" | "manager" | "staff"

export interface User {
  userId: string
  vendorId: string
  email: string
  name: string
  role: UserRole
  permissions: string[]
  status: "active" | "inactive"
  lastLogin?: string
  createdAt: string
}


// Social Post Types
export interface SocialPost {
  postId: string
  vendorId: string
  content: string
  mediaUrl?: string
  mediaType: "text" | "image" | "video"
  likes: number
  comments: number
  shares: number
  views: number
  expiresAt: string
  createdAt: string
}

export interface Follower {
  id: string
  name: string
  email: string
  followedAt: string
}

// Product Specifications Types
export interface ProductSpecification {
  category: string
  specs: SpecificationItem[]
}

export interface SpecificationItem {
  label: string
  value: string
}

// ============================================
// CATEGORY-SPECIFIC SPECIFICATION TEMPLATES
// ============================================

// CLOTHING & APPAREL
export interface ClothingSpecs {
  brand: string
  size: string[]
  color: string[]
  material: string
  fit: string // Slim, Regular, Loose, Oversized
  gender: string // Men, Women, Unisex, Kids
  season: string // Spring, Summer, Fall, Winter, All-season
  neckline?: string // V-neck, Crew, Collar, etc.
  sleeveLength?: string // Short, Long, 3/4, Sleeveless
  pattern?: string // Solid, Striped, Plaid, Floral, etc.
  closure?: string // Button, Zipper, Pull-on, etc.
  pockets?: string
  careInstructions: string
  countryOfOrigin: string
}

export interface FootwearSpecs {
  brand: string
  size: string[]
  width: string // Narrow, Standard, Wide, Extra Wide
  color: string[]
  material: string // Leather, Canvas, Synthetic, etc.
  soleMaterial: string
  heelHeight?: string
  closure: string // Lace-up, Slip-on, Velcro, Buckle
  style: string // Sneakers, Boots, Sandals, Heels, etc.
  gender: string
  waterproof: boolean
  archSupport?: string
}

// ELECTRONICS
export interface ElectronicsSpecs {
  brand: string
  model: string
  screenSize?: string
  resolution?: string
  displayType?: string // LCD, OLED, AMOLED, etc.
  processor?: string
  ram?: string
  storage?: string
  battery?: string
  batteryLife?: string
  chargingType?: string
  connectivity: string[]
  ports?: string[]
  operatingSystem?: string
  weight?: string
  dimensions?: string
  color?: string
  warranty: string
}

export interface TVSpecs {
  brand: string
  model: string
  screenSize: string // 32", 43", 55", 65", 75", 85"
  resolution: string // HD, Full HD, 4K UHD, 8K
  displayType: string // LED, QLED, OLED, Mini-LED
  refreshRate: string // 60Hz, 120Hz, 144Hz
  hdr: string[] // HDR10, HDR10+, Dolby Vision, HLG
  smartTV: boolean
  operatingSystem?: string // WebOS, Tizen, Android TV, Roku, Fire TV
  processor?: string
  speakers: string
  audioFeatures?: string[] // Dolby Atmos, DTS:X
  hdmiPorts: number
  usbPorts: number
  wifi: string
  bluetooth: string
  voiceAssistant?: string[]
  wallMountable: boolean
  vesaPattern?: string
  dimensions: string
  weight: string
  energyRating?: string
  warranty: string
}

export interface SmartphoneSpecs {
  brand: string
  model: string
  screenSize: string
  resolution: string
  displayType: string
  refreshRate: string
  processor: string
  ram: string
  storage: string[]
  expandableStorage: boolean
  rearCamera: string
  frontCamera: string
  videoRecording: string
  battery: string
  chargingSpeed: string
  wirelessCharging: boolean
  operatingSystem: string
  simType: string // Single, Dual, eSIM
  network: string // 4G, 5G
  biometrics: string[] // Fingerprint, Face ID
  waterResistance?: string
  dimensions: string
  weight: string
  colors: string[]
  warranty: string
}

export interface LaptopSpecs {
  brand: string
  model: string
  screenSize: string
  resolution: string
  displayType: string
  refreshRate?: string
  touchscreen: boolean
  processor: string
  processorGen: string
  ram: string
  ramType: string
  maxRam?: string
  storage: string
  storageType: string // SSD, HDD, Hybrid
  graphics: string
  graphicsMemory?: string
  operatingSystem: string
  battery: string
  batteryLife: string
  chargingWattage: string
  webcam: string
  speakers: string
  keyboard: string // Backlit, Mechanical, etc.
  ports: string[]
  wifi: string
  bluetooth: string
  weight: string
  dimensions: string
  color: string
  warranty: string
}

// VEHICLES
export interface VehicleSpecs {
  make: string
  model: string
  year: number
  trim?: string
  bodyType: string // Sedan, SUV, Truck, Coupe, etc.
  engine: string
  displacement?: string
  horsepower: string
  torque: string
  transmission: string // Automatic, Manual, CVT, DCT
  drivetrain: string // FWD, RWD, AWD, 4WD
  fuelType: string // Gasoline, Diesel, Hybrid, Electric
  fuelEconomy?: string
  range?: string // For EVs
  batteryCapacity?: string // For EVs
  chargingTime?: string // For EVs
  seatingCapacity: number
  doors: number
  exteriorColor: string
  interiorColor: string
  interiorMaterial?: string
  mileage: string
  condition: string // New, Used, Certified Pre-Owned
  vin?: string
  features?: string[]
  safetyFeatures?: string[]
  warranty?: string
}

export interface MotorcycleSpecs {
  make: string
  model: string
  year: number
  type: string // Sport, Cruiser, Touring, Adventure, etc.
  engine: string
  displacement: string
  horsepower: string
  torque: string
  transmission: string
  fuelCapacity: string
  fuelEconomy?: string
  seatHeight: string
  weight: string
  brakes: string
  suspension: string
  tires: string
  color: string
  mileage?: string
  condition: string
  warranty?: string
}

// FURNITURE
export interface FurnitureSpecs {
  brand?: string
  type: string // Sofa, Chair, Table, Bed, etc.
  style: string // Modern, Traditional, Industrial, etc.
  material: string
  frameMaterial?: string
  upholsteryMaterial?: string
  color: string
  dimensions: string // L x W x H
  weight: string
  weightCapacity?: string
  seatingCapacity?: number
  assemblyRequired: boolean
  assemblyTime?: string
  indoorOutdoor: string
  careInstructions: string
  warranty: string
}

export interface MattressSpecs {
  brand: string
  type: string // Memory Foam, Innerspring, Hybrid, Latex
  size: string // Twin, Full, Queen, King, Cal King
  thickness: string
  firmness: string // Soft, Medium, Firm
  layers?: string[]
  coolingTechnology?: string
  motionIsolation?: string
  edgeSupport?: string
  certifications?: string[] // CertiPUR-US, OEKO-TEX, etc.
  trialPeriod?: string
  warranty: string
}

// BEAUTY & PERSONAL CARE
export interface BeautyProductSpecs {
  brand: string
  productType: string
  skinType?: string[] // Oily, Dry, Combination, Sensitive, Normal
  concerns?: string[] // Acne, Aging, Hydration, etc.
  ingredients: string[]
  keyIngredients?: string[]
  size: string
  texture?: string
  scent?: string
  spf?: string
  coverage?: string // For makeup
  finish?: string // Matte, Dewy, Satin
  shade?: string
  crueltyFree: boolean
  vegan?: boolean
  organic?: boolean
  expirationPeriod?: string
  usage: string
  warnings?: string[]
}

// FOOD & BEVERAGES
export interface FoodProductSpecs {
  brand: string
  productType: string
  weight: string
  servingSize: string
  servingsPerContainer: number
  calories: string
  protein?: string
  carbohydrates?: string
  sugar?: string
  fat?: string
  saturatedFat?: string
  fiber?: string
  sodium?: string
  ingredients: string[]
  allergens?: string[]
  dietaryInfo?: string[] // Gluten-free, Vegan, Kosher, Halal, etc.
  organic: boolean
  nonGMO?: boolean
  countryOfOrigin: string
  storageInstructions: string
  shelfLife?: string
  expirationDate?: string
}

// SPORTS & FITNESS
export interface SportsEquipmentSpecs {
  brand: string
  sport: string
  type: string
  material: string
  size?: string
  weight?: string
  color: string
  skillLevel?: string // Beginner, Intermediate, Advanced, Pro
  gender?: string
  ageGroup?: string
  features?: string[]
  certifications?: string[]
  warranty: string
}

export interface FitnessEquipmentSpecs {
  brand: string
  type: string // Treadmill, Bike, Weights, etc.
  maxUserWeight: string
  dimensions: string
  weight: string
  foldable?: boolean
  resistance?: string
  programs?: number
  display?: string
  connectivity?: string[]
  heartRateMonitor?: boolean
  assembly: string
  warranty: string
}

// HOME APPLIANCES
export interface ApplianceSpecs {
  brand: string
  model: string
  type: string
  capacity?: string
  power: string
  voltage: string
  dimensions: string
  weight: string
  color: string
  energyRating?: string
  noiseLevel?: string
  features: string[]
  controls: string
  warranty: string
  certifications?: string[]
}

// JEWELRY & WATCHES
export interface JewelrySpecs {
  brand?: string
  type: string // Ring, Necklace, Bracelet, Earrings
  material: string // Gold, Silver, Platinum, etc.
  purity?: string // 14K, 18K, 925 Sterling, etc.
  gemstone?: string
  gemstoneWeight?: string
  gemstoneClarity?: string
  gemstoneCut?: string
  gemstoneColor?: string
  totalWeight: string
  dimensions?: string
  chainLength?: string
  ringSize?: string
  closure?: string
  style: string
  occasion?: string
  giftBox: boolean
  certification?: string
}

export interface WatchSpecs {
  brand: string
  model: string
  movement: string // Quartz, Automatic, Mechanical
  caseMaterial: string
  caseSize: string
  caseThickness: string
  dialColor: string
  strapMaterial: string
  strapWidth?: string
  crystal: string // Sapphire, Mineral, etc.
  waterResistance: string
  features: string[]
  complications?: string[] // Chronograph, Date, Moon phase, etc.
  luminous: boolean
  warranty: string
}

// BOOKS & MEDIA
export interface BookSpecs {
  title: string
  author: string
  publisher: string
  publicationDate: string
  isbn: string
  format: string // Hardcover, Paperback, eBook, Audiobook
  pages?: number
  language: string
  genre: string[]
  dimensions?: string
  weight?: string
  edition?: string
  series?: string
  ageRange?: string
}

// TOYS & GAMES
export interface ToySpecs {
  brand: string
  name: string
  type: string
  ageRange: string
  material: string
  dimensions?: string
  weight?: string
  batteryRequired: boolean
  batteryType?: string
  batteryIncluded?: boolean
  numberOfPlayers?: string
  playTime?: string
  educational?: boolean
  skills?: string[]
  safetyWarnings: string[]
  certifications?: string[]
}

// PET SUPPLIES
export interface PetProductSpecs {
  brand: string
  productType: string
  petType: string[] // Dog, Cat, Bird, Fish, etc.
  size?: string
  weight?: string
  material?: string
  flavor?: string // For food/treats
  lifeStage?: string // Puppy, Adult, Senior
  breedSize?: string // Small, Medium, Large
  ingredients?: string[]
  nutritionalInfo?: string
  feedingGuidelines?: string
  warranty?: string
}

// GARDEN & OUTDOOR
export interface GardenProductSpecs {
  brand?: string
  type: string
  material: string
  dimensions: string
  weight?: string
  color?: string
  weatherResistant: boolean
  uvResistant?: boolean
  capacity?: string
  assembly?: string
  indoorOutdoor: string
  warranty?: string
}

// TOOLS & HARDWARE
export interface ToolSpecs {
  brand: string
  type: string
  powerSource: string // Manual, Corded, Cordless
  voltage?: string
  batteryType?: string
  batteryIncluded?: boolean
  power?: string
  speed?: string
  material: string
  dimensions: string
  weight: string
  features: string[]
  accessories?: string[]
  warranty: string
}
