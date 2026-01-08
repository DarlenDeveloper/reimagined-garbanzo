# Product Category Taxonomy - Detailed Product-Specific Attributes

## Overview

This document defines the complete product taxonomy for Purl marketplace. Each **product type** (not just category) has its own specific attributes to enable precise filtering and dynamic form generation.

**Structure:** Category → Subcategory → Product Type → Specific Attributes

---

## 1. APPAREL & FASHION

### 1.1 Clothing

#### T-Shirts & Tops
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size | select | XS, S, M, L, XL, XXL, XXXL | Yes |
| Color | multi-select | Color palette | Yes |
| Brand | autocomplete | Nike, Adidas, H&M, Zara, Uniqlo, etc. | Yes |
| Gender | select | Men, Women, Unisex | Yes |
| Sleeve Length | select | Sleeveless, Short Sleeve, Long Sleeve, 3/4 Sleeve | Yes |
| Neckline | select | Crew Neck, V-Neck, Polo, Henley, Scoop | No |
| Material | multi-select | Cotton, Polyester, Linen, Blend | No |
| Fit | select | Slim, Regular, Oversized, Relaxed | No |

#### Jeans & Pants
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Waist Size | select | 26, 28, 30, 32, 34, 36, 38, 40, 42 | Yes |
| Length | select | 28, 30, 32, 34, 36 (inches) | Yes |
| Color | select | Blue, Black, Gray, White, Khaki, Navy | Yes |
| Brand | autocomplete | Levi's, Wrangler, Diesel, G-Star, etc. | Yes |
| Gender | select | Men, Women, Unisex | Yes |
| Fit | select | Skinny, Slim, Straight, Bootcut, Relaxed, Wide Leg | Yes |
| Rise | select | Low Rise, Mid Rise, High Rise | No |
| Material | select | Denim, Chino, Corduroy, Linen | No |

#### Dresses
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size | select | XS, S, M, L, XL, XXL | Yes |
| Color | multi-select | Color palette | Yes |
| Brand | autocomplete | Zara, H&M, ASOS, etc. | Yes |
| Length | select | Mini, Midi, Maxi, Knee-Length | Yes |
| Style | select | Casual, Formal, Cocktail, Evening, Maxi, Bodycon, A-Line, Wrap | Yes |
| Occasion | select | Everyday, Work, Party, Wedding, Beach | No |
| Sleeve Type | select | Sleeveless, Short, Long, Off-Shoulder, Spaghetti Strap | No |
| Neckline | select | V-Neck, Round, Square, Halter, Sweetheart | No |
| Material | select | Cotton, Silk, Chiffon, Satin, Polyester | No |

#### Suits & Blazers
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size | select | 36, 38, 40, 42, 44, 46, 48, 50 (chest) | Yes |
| Color | select | Black, Navy, Gray, Charcoal, Brown, Beige | Yes |
| Brand | autocomplete | Hugo Boss, Zara, H&M, etc. | Yes |
| Gender | select | Men, Women | Yes |
| Type | select | Single-Breasted, Double-Breasted, Tuxedo | Yes |
| Fit | select | Slim, Regular, Classic | Yes |
| Material | select | Wool, Polyester, Linen, Cotton Blend | No |
| Pieces | select | Jacket Only, 2-Piece (Jacket+Pants), 3-Piece (Jacket+Pants+Vest) | No |

#### Activewear & Sportswear
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size | select | XS, S, M, L, XL, XXL | Yes |
| Color | multi-select | Color palette | Yes |
| Brand | autocomplete | Nike, Adidas, Under Armour, Puma, Lululemon | Yes |
| Gender | select | Men, Women, Unisex | Yes |
| Type | select | Leggings, Sports Bra, Tank Top, Shorts, Track Pants, Hoodie | Yes |
| Sport | select | Running, Yoga, Gym, Football, Basketball, Tennis, General | No |
| Material | select | Polyester, Spandex, Nylon, Moisture-Wicking | No |

#### Outerwear (Jackets & Coats)
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size | select | XS, S, M, L, XL, XXL, XXXL | Yes |
| Color | select | Black, Navy, Brown, Olive, Beige, Gray | Yes |
| Brand | autocomplete | North Face, Columbia, Patagonia, etc. | Yes |
| Gender | select | Men, Women, Unisex | Yes |
| Type | select | Bomber, Denim Jacket, Leather Jacket, Parka, Trench Coat, Puffer, Windbreaker | Yes |
| Material | select | Leather, Denim, Nylon, Polyester, Wool, Down | No |
| Weather | select | Waterproof, Water-Resistant, Insulated, Lightweight | No |

### 1.2 Shoes

#### Sneakers
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size (US) | select | 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10, 10.5, 11, 11.5, 12, 13, 14, 15 | Yes |
| Size (EU) | select | 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50 | No |
| Color | multi-select | Color palette | Yes |
| Brand | autocomplete | Nike, Adidas, Jordan, New Balance, Puma, Converse, Vans, Reebok | Yes |
| Gender | select | Men, Women, Unisex, Kids | Yes |
| Style | select | Low-Top, Mid-Top, High-Top | Yes |
| Type | select | Running, Basketball, Casual, Skateboarding, Training | No |
| Width | select | Narrow, Standard, Wide | No |

#### Boots
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size (US) | select | 4-15 (with half sizes) | Yes |
| Color | select | Black, Brown, Tan, Gray, Burgundy | Yes |
| Brand | autocomplete | Timberland, Dr. Martens, Red Wing, Clarks, etc. | Yes |
| Gender | select | Men, Women, Unisex | Yes |
| Type | select | Ankle Boots, Chelsea, Combat, Hiking, Work Boots, Cowboy, Knee-High | Yes |
| Material | select | Leather, Suede, Synthetic, Rubber | Yes |
| Heel Height | select | Flat, Low (1-2"), Medium (2-3"), High (3"+) | No |

#### Sandals & Flip-Flops
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size (US) | select | 4-15 | Yes |
| Color | multi-select | Color palette | Yes |
| Brand | autocomplete | Birkenstock, Teva, Havaianas, Crocs, etc. | Yes |
| Gender | select | Men, Women, Unisex | Yes |
| Type | select | Flip-Flops, Slides, Gladiator, Sport Sandals, Wedge | Yes |
| Material | select | Leather, Rubber, Synthetic, Cork | No |

#### Formal Shoes
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size (US) | select | 5-15 | Yes |
| Color | select | Black, Brown, Tan, Burgundy, Navy | Yes |
| Brand | autocomplete | Allen Edmonds, Cole Haan, Clarks, etc. | Yes |
| Gender | select | Men, Women | Yes |
| Type | select | Oxford, Derby, Loafer, Monk Strap, Brogue, Pump, Stiletto | Yes |
| Material | select | Leather, Patent Leather, Suede | Yes |
| Width | select | Narrow, Standard, Wide | No |

#### Heels
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size (US) | select | 4-12 | Yes |
| Color | multi-select | Color palette | Yes |
| Brand | autocomplete | Steve Madden, Aldo, Nine West, etc. | Yes |
| Heel Height | select | Kitten (1-2"), Low (2-3"), Medium (3-4"), High (4"+) | Yes |
| Heel Type | select | Stiletto, Block, Wedge, Cone, Platform | Yes |
| Style | select | Pump, Sandal, Mule, Slingback, Ankle Strap | Yes |
| Material | select | Leather, Suede, Satin, Patent, Synthetic | No |

### 1.3 Jewelry & Accessories

#### Watches
**Conditions:** New, Used, Refurbished, Collectible
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | autocomplete | Rolex, Omega, Seiko, Casio, Apple, Samsung, Fossil, etc. | Yes |
| Type | select | Analog, Digital, Smart Watch, Chronograph, Dive Watch | Yes |
| Gender | select | Men, Women, Unisex | Yes |
| Case Material | select | Stainless Steel, Gold, Titanium, Ceramic, Plastic | Yes |
| Band Material | select | Leather, Metal, Rubber, Silicone, Nylon | Yes |
| Case Size | select | Under 36mm, 36-40mm, 40-44mm, 44mm+ | No |
| Movement | select | Automatic, Quartz, Mechanical, Solar | No |
| Water Resistance | select | None, 30m, 50m, 100m, 200m+ | No |

#### Rings
**Conditions:** New, Used, Collectible
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Ring Size | select | 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10, 10.5, 11, 12, 13 | Yes |
| Metal | select | Gold (10K, 14K, 18K, 24K), White Gold, Rose Gold, Platinum, Sterling Silver, Stainless Steel, Titanium | Yes |
| Type | select | Engagement, Wedding Band, Fashion, Signet, Stackable, Statement | Yes |
| Gender | select | Men, Women, Unisex | Yes |
| Gemstone | select | Diamond, Ruby, Sapphire, Emerald, Pearl, Cubic Zirconia, None | No |
| Carat Weight | number | 0.1 - 10+ | No (if gemstone) |
| Certification | text | GIA, AGS, IGI, etc. | No |

#### Necklaces & Pendants
**Conditions:** New, Used, Collectible
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Metal | select | Gold, White Gold, Rose Gold, Sterling Silver, Platinum, Stainless Steel | Yes |
| Length | select | Choker (14-16"), Princess (17-19"), Matinee (20-24"), Opera (28-36"), Rope (36"+) | Yes |
| Type | select | Chain, Pendant, Locket, Choker, Statement, Layered | Yes |
| Gender | select | Men, Women, Unisex | Yes |
| Gemstone | select | Diamond, Pearl, Sapphire, Ruby, None | No |
| Chain Style | select | Cable, Box, Rope, Snake, Figaro, Curb | No |

#### Earrings
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Metal | select | Gold, White Gold, Rose Gold, Sterling Silver, Platinum | Yes |
| Type | select | Stud, Hoop, Drop, Dangle, Huggie, Chandelier, Ear Cuff | Yes |
| Gemstone | select | Diamond, Pearl, Sapphire, Ruby, Cubic Zirconia, None | No |
| Closure | select | Push Back, Screw Back, Lever Back, Hook, Clip-On | No |

#### Bracelets
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Metal | select | Gold, White Gold, Rose Gold, Sterling Silver, Leather, Beaded | Yes |
| Type | select | Bangle, Cuff, Chain, Tennis, Charm, Wrap | Yes |
| Length | select | 6", 6.5", 7", 7.5", 8", Adjustable | Yes |
| Gender | select | Men, Women, Unisex | Yes |
| Gemstone | select | Diamond, Pearl, None | No |

---

## 2. ELECTRONICS & TECHNOLOGY

### 2.1 Cell Phones

#### Smartphones
**Conditions:** New, Used, Refurbished
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Apple, Samsung, Google, OnePlus, Xiaomi, Huawei, Oppo, Vivo, Motorola, Nokia | Yes |
| Model | text | iPhone 15 Pro Max, Galaxy S24 Ultra, Pixel 8 Pro, etc. | Yes |
| Storage | select | 32GB, 64GB, 128GB, 256GB, 512GB, 1TB | Yes |
| RAM | select | 4GB, 6GB, 8GB, 12GB, 16GB | No |
| Color | select | Black, White, Silver, Gold, Blue, Green, Purple, Red | Yes |
| Carrier Lock | select | Unlocked, Safaricom, Airtel, MTN, Telkom | Yes |
| Screen Size | select | Under 6", 6.0-6.4", 6.5-6.9", 7"+ | No |
| Battery Health | select | 100%, 90-99%, 80-89%, Below 80% | No (Used only) |
| Includes | multi-select | Original Box, Charger, Cable, Earphones, Case | No |

#### Feature Phones
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Nokia, Samsung, Tecno, Itel, Infinix | Yes |
| Model | text | | Yes |
| SIM Type | select | Single SIM, Dual SIM | Yes |
| Color | select | Black, Blue, Red, Gold | Yes |
| Battery Capacity | text | mAh | No |

#### Phone Accessories
**Conditions:** New
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Case, Screen Protector, Charger, Cable, Earphones, Power Bank, Car Mount, Wireless Charger | Yes |
| Compatible Brand | select | Apple, Samsung, Universal, etc. | Yes |
| Compatible Model | text | iPhone 15, Galaxy S24, etc. | No |
| Color | select | Color palette | No |
| Material | select | Silicone, Leather, Plastic, Tempered Glass, TPU | No |

### 2.2 Computers

#### Laptops
**Conditions:** New, Used, Refurbished
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Apple, Dell, HP, Lenovo, Asus, Acer, Microsoft, MSI, Razer | Yes |
| Model | text | MacBook Pro 14", ThinkPad X1, XPS 15, etc. | Yes |
| Processor Brand | select | Intel, AMD, Apple Silicon | Yes |
| Processor Model | select | i3, i5, i7, i9, Ryzen 3, Ryzen 5, Ryzen 7, Ryzen 9, M1, M2, M3, M3 Pro, M3 Max | Yes |
| RAM | select | 4GB, 8GB, 16GB, 32GB, 64GB, 128GB | Yes |
| Storage Type | select | SSD, HDD, SSD + HDD | Yes |
| Storage Size | select | 128GB, 256GB, 512GB, 1TB, 2TB | Yes |
| Screen Size | select | 11", 13", 14", 15", 16", 17" | Yes |
| Screen Resolution | select | HD (1366x768), FHD (1920x1080), 2K, 4K, Retina | No |
| GPU | select | Integrated, NVIDIA GTX, NVIDIA RTX, AMD Radeon | No |
| GPU Model | text | RTX 4060, RTX 4070, etc. | No |
| Operating System | select | Windows 11, Windows 10, macOS, Chrome OS, Linux | No |
| Battery Health | select | Excellent, Good, Fair | No (Used only) |
| Condition Notes | text | Scratches, dents, etc. | No |

#### Desktop Computers
**Conditions:** New, Used, Refurbished
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Apple, Dell, HP, Lenovo, Custom Built | Yes |
| Type | select | Tower, All-in-One, Mini PC, Workstation | Yes |
| Processor Brand | select | Intel, AMD, Apple Silicon | Yes |
| Processor Model | select | i3, i5, i7, i9, Ryzen 3, 5, 7, 9, M1, M2 | Yes |
| RAM | select | 4GB, 8GB, 16GB, 32GB, 64GB, 128GB | Yes |
| Storage Type | select | SSD, HDD, SSD + HDD | Yes |
| Storage Size | select | 256GB, 512GB, 1TB, 2TB, 4TB+ | Yes |
| GPU | select | Integrated, NVIDIA GTX, NVIDIA RTX, AMD Radeon | No |
| GPU Model | text | | No |
| Operating System | select | Windows 11, Windows 10, macOS, Linux | No |
| Includes Monitor | boolean | Yes/No | No |

#### Tablets
**Conditions:** New, Used, Refurbished
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Apple, Samsung, Microsoft, Lenovo, Amazon, Huawei | Yes |
| Model | text | iPad Pro 12.9", Galaxy Tab S9, Surface Pro 9, etc. | Yes |
| Storage | select | 32GB, 64GB, 128GB, 256GB, 512GB, 1TB | Yes |
| Screen Size | select | 7-8", 9-10", 11-12", 12"+ | Yes |
| Connectivity | select | WiFi Only, WiFi + Cellular | Yes |
| Color | select | Space Gray, Silver, Gold, Black, etc. | Yes |
| Includes | multi-select | Stylus/Pencil, Keyboard, Case, Original Box | No |

#### Computer Accessories
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Monitor, Keyboard, Mouse, Webcam, Headset, Docking Station, External Drive, USB Hub | Yes |
| Brand | autocomplete | Logitech, Razer, Dell, LG, Samsung, etc. | Yes |
| Connectivity | multi-select | USB, USB-C, Bluetooth, Wireless, HDMI | Yes |
| Compatible With | multi-select | Windows, Mac, Linux | No |

### 2.3 TVs & Home Entertainment

#### Televisions
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Samsung, LG, Sony, TCL, Hisense, Vizio | Yes |
| Screen Size | select | 32", 40", 43", 50", 55", 65", 75", 85"+ | Yes |
| Display Technology | select | LED, QLED, OLED, Mini-LED, LCD | Yes |
| Resolution | select | HD (720p), Full HD (1080p), 4K UHD, 8K | Yes |
| Smart TV | boolean | Yes/No | Yes |
| Smart Platform | select | Tizen, webOS, Google TV, Roku, Fire TV, Android TV | No |
| Refresh Rate | select | 60Hz, 120Hz, 144Hz | No |
| HDR Support | multi-select | HDR10, HDR10+, Dolby Vision, HLG | No |
| Ports | multi-select | HDMI 2.1, HDMI 2.0, USB, Ethernet, Optical | No |

#### Speakers & Sound Systems
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Bose, Sonos, JBL, Sony, Samsung, LG, Harman Kardon | Yes |
| Type | select | Soundbar, Bookshelf, Tower, Portable Bluetooth, Smart Speaker, Subwoofer | Yes |
| Connectivity | multi-select | Bluetooth, WiFi, AUX, Optical, HDMI ARC | Yes |
| Channels | select | 2.0, 2.1, 3.1, 5.1, 7.1, Atmos | No |
| Power Output | text | Watts | No |
| Voice Assistant | select | Alexa, Google Assistant, Siri, None | No |

#### Headphones & Earbuds
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Apple, Sony, Bose, Samsung, JBL, Beats, Sennheiser, Audio-Technica | Yes |
| Type | select | Over-Ear, On-Ear, In-Ear, True Wireless | Yes |
| Connectivity | select | Wired, Bluetooth, Both | Yes |
| Noise Cancellation | select | Active (ANC), Passive, None | Yes |
| Color | select | Black, White, Silver, Blue, Red | Yes |
| Battery Life | text | Hours | No |
| Microphone | boolean | Yes/No | No |
| Foldable | boolean | Yes/No | No |

#### Gaming Consoles
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Sony, Microsoft, Nintendo | Yes |
| Console | select | PlayStation 5, PlayStation 5 Digital, PlayStation 4, PlayStation 4 Pro, Xbox Series X, Xbox Series S, Xbox One, Nintendo Switch, Nintendo Switch OLED, Nintendo Switch Lite | Yes |
| Storage | select | 500GB, 825GB, 1TB, 2TB | No |
| Color | select | Black, White, Special Edition | Yes |
| Includes | multi-select | Controller, Games, Original Box, HDMI Cable | No |
| Controller Count | select | 1, 2, 3, 4 | No |

### 2.4 Cameras & Photography

#### DSLR Cameras
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Canon, Nikon, Sony, Pentax | Yes |
| Model | text | Canon EOS 5D Mark IV, Nikon D850, etc. | Yes |
| Sensor Type | select | Full Frame, APS-C, Micro 4/3 | Yes |
| Megapixels | select | Under 20MP, 20-30MP, 30-45MP, 45MP+ | Yes |
| Lens Mount | select | Canon EF, Canon RF, Nikon F, Nikon Z, Sony A, Sony E | Yes |
| Video Resolution | select | 1080p, 4K, 8K | No |
| Shutter Count | number | Approximate count | No (Used only) |
| Includes | multi-select | Body Only, Kit Lens, Battery, Charger, Bag, Memory Card | No |

#### Mirrorless Cameras
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Sony, Canon, Nikon, Fujifilm, Panasonic, Olympus | Yes |
| Model | text | Sony A7 IV, Canon R6, etc. | Yes |
| Sensor Type | select | Full Frame, APS-C, Micro 4/3 | Yes |
| Megapixels | select | Under 20MP, 20-30MP, 30-45MP, 45MP+ | Yes |
| Lens Mount | select | Sony E, Canon RF, Nikon Z, Fuji X, Micro 4/3 | Yes |
| Video Resolution | select | 1080p, 4K, 6K, 8K | No |
| IBIS | boolean | Yes/No | No |
| Includes | multi-select | Body Only, Kit Lens, Battery, Charger | No |

#### Camera Lenses
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | Canon, Nikon, Sony, Sigma, Tamron, Zeiss, Fujifilm | Yes |
| Mount | select | Canon EF, Canon RF, Nikon F, Nikon Z, Sony E, Sony A, Fuji X, Micro 4/3 | Yes |
| Focal Length | text | 24mm, 50mm, 24-70mm, 70-200mm, etc. | Yes |
| Aperture | text | f/1.4, f/1.8, f/2.8, f/4, etc. | Yes |
| Type | select | Prime, Zoom, Macro, Telephoto, Wide Angle, Fisheye | Yes |
| Image Stabilization | boolean | Yes/No | No |
| Autofocus | boolean | Yes/No | No |
| Filter Size | text | mm | No |

#### Action Cameras & Drones
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Brand | select | GoPro, DJI, Insta360, Sony | Yes |
| Model | text | GoPro Hero 12, DJI Mavic 3, etc. | Yes |
| Type | select | Action Camera, Drone, 360 Camera | Yes |
| Video Resolution | select | 1080p, 4K, 5.3K, 8K | Yes |
| Waterproof | boolean | Yes/No | No |
| Flight Time | text | Minutes (drones only) | No |
| Includes | multi-select | Batteries, Memory Card, Case, Mounts, Controller | No |

---

## 3. AUTOMOTIVE

### 3.1 Vehicles

#### Cars
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Make | select | Toyota, Honda, Nissan, BMW, Mercedes-Benz, Audi, Volkswagen, Ford, Mazda, Subaru, Hyundai, Kia, Mitsubishi, Suzuki, Land Rover, Jeep, Porsche, Lexus | Yes |
| Model | text | Corolla, Civic, 3 Series, C-Class, etc. | Yes |
| Year | select | 1990-2026 | Yes |
| Mileage | number | Kilometers | Yes |
| Fuel Type | select | Petrol, Diesel, Hybrid, Plug-in Hybrid, Electric | Yes |
| Transmission | select | Automatic, Manual, CVT, DCT | Yes |
| Body Type | select | Sedan, SUV, Hatchback, Coupe, Convertible, Wagon, Pickup, Van, Crossover | Yes |
| Engine Size | text | e.g., 1.8L, 2.0L, 3.0L | Yes |
| Drive Type | select | FWD, RWD, AWD, 4WD | No |
| Color (Exterior) | select | Color palette | Yes |
| Color (Interior) | select | Black, Beige, Brown, Gray, Red | No |
| Seats | select | 2, 4, 5, 7, 8+ | No |
| Condition | select | Excellent, Very Good, Good, Fair | Yes |
| Service History | select | Full, Partial, None | No |
| Previous Owners | select | 1, 2, 3, 4+ | No |
| Features | multi-select | Sunroof, Leather Seats, Navigation, Backup Camera, Bluetooth, Heated Seats, Cruise Control, Parking Sensors | No |
| Registration | select | Kenyan, Foreign (Duty Paid), Foreign (Duty Not Paid) | Yes |

#### Motorcycles
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Make | select | Honda, Yamaha, Kawasaki, Suzuki, BMW, Harley-Davidson, KTM, Ducati, Bajaj, TVS | Yes |
| Model | text | | Yes |
| Year | select | 1990-2026 | Yes |
| Mileage | number | Kilometers | Yes |
| Engine Size | text | cc (e.g., 150cc, 650cc, 1000cc) | Yes |
| Type | select | Sport, Cruiser, Touring, Adventure, Naked, Scooter, Dirt Bike, Cafe Racer | Yes |
| Color | select | Color palette | Yes |
| Condition | select | Excellent, Very Good, Good, Fair | Yes |

#### Trucks & Commercial
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Make | select | Toyota, Isuzu, Mitsubishi, Hino, Mercedes-Benz, MAN, Scania, Volvo | Yes |
| Model | text | | Yes |
| Year | select | 1990-2026 | Yes |
| Mileage | number | Kilometers | Yes |
| Type | select | Pickup, Light Truck, Medium Truck, Heavy Truck, Trailer, Bus | Yes |
| Payload Capacity | text | Tons | Yes |
| Fuel Type | select | Diesel, Petrol | Yes |
| Transmission | select | Manual, Automatic | Yes |
| Condition | select | Excellent, Very Good, Good, Fair | Yes |

### 3.2 Auto Parts & Accessories

#### Engine Parts
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Part Type | select | Air Filter, Oil Filter, Spark Plugs, Timing Belt, Water Pump, Alternator, Starter Motor, Fuel Pump, Radiator, Turbocharger | Yes |
| Compatible Makes | multi-select | Toyota, Honda, Nissan, BMW, etc. | Yes |
| Compatible Models | text | Corolla, Civic, etc. | No |
| Compatible Years | text | e.g., 2015-2020 | Yes |
| OEM/Aftermarket | select | OEM (Original), Aftermarket, Refurbished | Yes |
| Brand | text | | No |
| Part Number | text | | No |

#### Tires & Wheels
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Tire, Wheel/Rim, Tire + Wheel Set | Yes |
| Tire Size | text | e.g., 205/55R16, 225/45R17 | Yes (if tire) |
| Wheel Size | select | 14", 15", 16", 17", 18", 19", 20", 21", 22" | Yes (if wheel) |
| Brand | autocomplete | Michelin, Bridgestone, Goodyear, Continental, Pirelli, etc. | Yes |
| Season | select | All-Season, Summer, Winter, All-Terrain | No |
| Tread Depth | select | New, 80%+, 60-80%, 40-60%, Below 40% | No (Used only) |
| Bolt Pattern | text | e.g., 5x114.3, 5x120 | No |
| Quantity | select | 1, 2, 4 | Yes |

#### Car Electronics
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Head Unit, Speakers, Amplifier, Subwoofer, Dash Cam, GPS Navigator, Reverse Camera, Car Alarm | Yes |
| Brand | autocomplete | Pioneer, Sony, JBL, Kenwood, Alpine, etc. | Yes |
| Screen Size | select | 7", 9", 10" (for head units) | No |
| Features | multi-select | Bluetooth, Apple CarPlay, Android Auto, GPS, USB, AUX | No |

---

## 4. HOME & LIVING

### 4.1 Furniture

#### Sofas & Couches
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | 2-Seater, 3-Seater, L-Shaped, Sectional, Sofa Bed, Recliner, Loveseat | Yes |
| Material | select | Leather, Fabric, Velvet, Microfiber, Faux Leather | Yes |
| Color | select | Color palette | Yes |
| Brand | text | | No |
| Dimensions | object | Length x Width x Height (cm) | Yes |
| Seating Capacity | select | 2, 3, 4, 5, 6+ | Yes |
| Features | multi-select | Reclining, Storage, Convertible, USB Ports | No |
| Assembly | select | Assembled, Requires Assembly | Yes |

#### Beds & Mattresses
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Bed Frame, Mattress, Bed + Mattress Set, Bunk Bed, Sofa Bed | Yes |
| Size | select | Single (3x6), Double (4x6), Queen (5x6), King (6x6), Super King (6x7) | Yes |
| Material (Frame) | select | Wood, Metal, Upholstered, Leather | No |
| Mattress Type | select | Spring, Memory Foam, Latex, Hybrid, Orthopedic | No |
| Firmness | select | Soft, Medium, Firm, Extra Firm | No |
| Color | select | Color palette | Yes |
| Features | multi-select | Storage Drawers, Headboard, Footboard, Adjustable | No |
| Assembly | select | Assembled, Requires Assembly | Yes |

#### Tables
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Dining Table, Coffee Table, Side Table, Console Table, Desk, Outdoor Table | Yes |
| Shape | select | Rectangle, Round, Square, Oval | Yes |
| Material | select | Wood, Glass, Metal, Marble, MDF | Yes |
| Seating Capacity | select | 2, 4, 6, 8, 10+ (dining tables) | No |
| Color | select | Color palette | Yes |
| Dimensions | object | Length x Width x Height (cm) | Yes |
| Extendable | boolean | Yes/No | No |
| Assembly | select | Assembled, Requires Assembly | Yes |

#### Chairs
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Dining Chair, Office Chair, Accent Chair, Bar Stool, Recliner, Gaming Chair, Outdoor Chair | Yes |
| Material | select | Wood, Metal, Plastic, Fabric, Leather, Mesh | Yes |
| Color | select | Color palette | Yes |
| Quantity | select | 1, 2, 4, 6, 8 | Yes |
| Features | multi-select | Armrests, Swivel, Adjustable Height, Wheels, Lumbar Support | No |
| Assembly | select | Assembled, Requires Assembly | Yes |

#### Storage & Organization
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Wardrobe, Dresser, Bookshelf, TV Stand, Cabinet, Shoe Rack, Storage Box | Yes |
| Material | select | Wood, Metal, Plastic, MDF, Fabric | Yes |
| Color | select | Color palette | Yes |
| Dimensions | object | Length x Width x Height (cm) | Yes |
| Number of Shelves/Drawers | number | | No |
| Assembly | select | Assembled, Requires Assembly | Yes |

### 4.2 Home Appliances

#### Kitchen Appliances
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Refrigerator, Microwave, Blender, Toaster, Coffee Maker, Air Fryer, Electric Kettle, Food Processor, Mixer, Rice Cooker, Pressure Cooker | Yes |
| Brand | autocomplete | Samsung, LG, Philips, Kenwood, Breville, Ninja, etc. | Yes |
| Capacity | text | Liters, Cups, etc. | No |
| Power | text | Watts | No |
| Color | select | White, Black, Silver, Stainless Steel, Red | Yes |
| Features | multi-select | Digital Display, Timer, Multiple Speeds, Dishwasher Safe | No |
| Warranty | select | None, 6 Months, 1 Year, 2 Years | No |

#### Major Appliances
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Refrigerator, Washing Machine, Dryer, Dishwasher, Oven/Range, Air Conditioner, Water Heater | Yes |
| Brand | select | Samsung, LG, Whirlpool, Bosch, Miele, Haier, Hisense | Yes |
| Capacity | text | Liters, kg, BTU | Yes |
| Energy Rating | select | A+++, A++, A+, A, B, C, D | No |
| Color | select | White, Black, Silver, Stainless Steel | Yes |
| Type (Specific) | select | Top Load, Front Load (washers); Side-by-Side, French Door (fridges); Split, Window (AC) | Yes |
| Dimensions | object | Width x Depth x Height (cm) | Yes |
| Features | multi-select | Inverter, Smart/WiFi, Ice Maker, Steam, Quick Wash | No |
| Warranty | select | None, 1 Year, 2 Years, 5 Years | No |

#### Cleaning Appliances
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Vacuum Cleaner, Robot Vacuum, Steam Mop, Carpet Cleaner, Pressure Washer | Yes |
| Brand | autocomplete | Dyson, iRobot, Shark, Bissell, Karcher, etc. | Yes |
| Power Source | select | Corded, Cordless, Battery | Yes |
| Bag Type | select | Bagless, Bagged | No |
| Features | multi-select | HEPA Filter, Wet/Dry, Self-Emptying, App Control | No |

### 4.3 Home Decor

#### Lighting
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Ceiling Light, Pendant, Chandelier, Floor Lamp, Table Lamp, Wall Sconce, LED Strip | Yes |
| Style | select | Modern, Traditional, Industrial, Minimalist, Bohemian | Yes |
| Material | select | Metal, Glass, Fabric, Wood, Crystal | Yes |
| Color | select | Color palette | Yes |
| Bulb Type | select | LED, Incandescent, Halogen, Smart Bulb | No |
| Dimmable | boolean | Yes/No | No |
| Dimensions | text | Height x Width (cm) | No |

#### Rugs & Carpets
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Area Rug, Runner, Round Rug, Outdoor Rug, Doormat | Yes |
| Size | select | 2x3ft, 3x5ft, 4x6ft, 5x7ft, 6x9ft, 8x10ft, 9x12ft, Custom | Yes |
| Material | select | Wool, Cotton, Synthetic, Jute, Silk, Polypropylene | Yes |
| Style | select | Modern, Traditional, Persian, Moroccan, Shag, Geometric | Yes |
| Color | multi-select | Color palette | Yes |
| Pile Height | select | Low, Medium, High | No |

#### Wall Art & Decor
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Canvas Print, Framed Art, Poster, Wall Decal, Mirror, Clock, Tapestry | Yes |
| Style | select | Abstract, Modern, Traditional, Minimalist, Photography, Typography | Yes |
| Size | select | Small (Under 12"), Medium (12-24"), Large (24-36"), Extra Large (36"+) | Yes |
| Frame | select | Framed, Unframed, Gallery Wrapped | No |
| Color Theme | multi-select | Color palette | No |

---

## 5. BEAUTY & PERSONAL CARE

### 5.1 Skincare
**Conditions:** New Only
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Product Type | select | Cleanser, Moisturizer, Serum, Toner, Sunscreen, Eye Cream, Face Mask, Exfoliator, Face Oil | Yes |
| Brand | autocomplete | CeraVe, The Ordinary, La Roche-Posay, Neutrogena, Olay, etc. | Yes |
| Skin Type | multi-select | Oily, Dry, Combination, Sensitive, Normal, All Skin Types | Yes |
| Skin Concern | multi-select | Acne, Anti-Aging, Hydration, Brightening, Dark Spots, Pores, Redness | No |
| Size | text | ml, oz | Yes |
| Key Ingredients | multi-select | Hyaluronic Acid, Retinol, Vitamin C, Niacinamide, Salicylic Acid, AHA/BHA, SPF | No |
| Expiry Date | date | | Yes |

### 5.2 Makeup
**Conditions:** New Only
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Product Type | select | Foundation, Concealer, Powder, Blush, Bronzer, Highlighter, Lipstick, Lip Gloss, Mascara, Eyeliner, Eyeshadow, Brow Products, Setting Spray | Yes |
| Brand | autocomplete | MAC, Fenty Beauty, Maybelline, L'Oreal, NYX, Charlotte Tilbury, etc. | Yes |
| Shade | text | | Yes |
| Finish | select | Matte, Dewy, Satin, Shimmer, Glitter, Natural | No |
| Coverage | select | Sheer, Light, Medium, Full | No |
| Size | text | ml, g, oz | Yes |
| Skin Type | multi-select | Oily, Dry, Combination, All | No |
| Expiry Date | date | | Yes |

### 5.3 Haircare
**Conditions:** New Only
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Product Type | select | Shampoo, Conditioner, Hair Mask, Hair Oil, Styling Gel, Mousse, Hair Spray, Heat Protectant, Leave-In Conditioner, Hair Serum | Yes |
| Brand | autocomplete | Olaplex, Kerastase, Pantene, TRESemmé, Cantu, etc. | Yes |
| Hair Type | multi-select | Straight, Wavy, Curly, Coily, All Hair Types | Yes |
| Hair Concern | multi-select | Dry/Damaged, Oily, Color-Treated, Frizzy, Thinning, Dandruff | No |
| Size | text | ml, oz | Yes |
| Expiry Date | date | | Yes |

### 5.4 Fragrances
**Conditions:** New, Used (Partial)
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Eau de Parfum, Eau de Toilette, Cologne, Body Mist, Perfume Oil | Yes |
| Brand | autocomplete | Chanel, Dior, Tom Ford, Versace, Gucci, Jo Malone, etc. | Yes |
| Gender | select | Men, Women, Unisex | Yes |
| Size | select | 30ml, 50ml, 75ml, 100ml, 150ml, 200ml | Yes |
| Scent Family | select | Floral, Woody, Fresh, Oriental, Citrus, Aquatic, Gourmand | No |
| Fill Level | select | Full, 90%+, 75-90%, 50-75%, Below 50% | No (Used only) |
| Includes Box | boolean | Yes/No | No |

### 5.5 Personal Care Tools
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Hair Dryer, Flat Iron, Curling Iron, Electric Shaver, Trimmer, Electric Toothbrush, Facial Cleansing Device, LED Mask | Yes |
| Brand | autocomplete | Dyson, GHD, BaByliss, Philips, Braun, Oral-B, Foreo, etc. | Yes |
| Power Source | select | Corded, Cordless, Battery | Yes |
| Color | select | Color palette | Yes |
| Features | multi-select | Heat Settings, Ionic, Ceramic, Titanium, Waterproof | No |
| Warranty | select | None, 6 Months, 1 Year, 2 Years | No |

---

## 6. BABY & KIDS

### 6.1 Baby Gear
**Conditions:** New Only
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Stroller, Car Seat, Baby Carrier, High Chair, Playpen, Baby Swing, Bouncer, Walker | Yes |
| Brand | autocomplete | Graco, Chicco, Baby Jogger, UPPAbaby, Ergobaby, etc. | Yes |
| Age Range | select | 0-6 months, 6-12 months, 1-2 years, 2-4 years | Yes |
| Weight Limit | text | kg | No |
| Color | select | Color palette | Yes |
| Features | multi-select | Foldable, Reclining, Adjustable, Travel System Compatible | No |
| Safety Certification | text | | No |

### 6.2 Baby Clothing
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size | select | Preemie, Newborn, 0-3M, 3-6M, 6-9M, 9-12M, 12-18M, 18-24M, 2T, 3T, 4T, 5T | Yes |
| Type | select | Onesie, Romper, Sleepwear, Outfit Set, Dress, Pants, Top, Jacket | Yes |
| Gender | select | Boy, Girl, Unisex | Yes |
| Color | multi-select | Color palette | Yes |
| Material | select | Cotton, Organic Cotton, Polyester, Fleece | No |
| Brand | text | | No |
| Season | select | Summer, Winter, All Season | No |

### 6.3 Kids Clothing (2-14 years)
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Size | select | 2T, 3T, 4T, 5, 6, 7, 8, 10, 12, 14 | Yes |
| Type | select | T-Shirt, Pants, Shorts, Dress, Skirt, Jacket, Uniform, Swimwear | Yes |
| Gender | select | Boy, Girl, Unisex | Yes |
| Color | multi-select | Color palette | Yes |
| Brand | text | | No |
| Material | select | Cotton, Polyester, Denim, Fleece | No |

### 6.4 Toys & Games
**Conditions:** New
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Action Figures, Dolls, Building Blocks, Educational, Puzzles, Board Games, Outdoor Toys, Remote Control, Stuffed Animals, Arts & Crafts | Yes |
| Brand | autocomplete | LEGO, Mattel, Hasbro, Fisher-Price, Melissa & Doug, etc. | Yes |
| Age Range | select | 0-2 years, 3-5 years, 6-8 years, 9-12 years, 13+ years | Yes |
| Gender | select | Boys, Girls, Unisex | No |
| Number of Pieces | number | (for building sets, puzzles) | No |
| Battery Required | boolean | Yes/No | No |
| Educational Focus | multi-select | STEM, Motor Skills, Creativity, Language, Math | No |

### 6.5 Baby Feeding
**Conditions:** New Only
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Bottles, Nipples, Breast Pump, Formula, Baby Food, Bibs, Sippy Cups, Utensils, Sterilizer | Yes |
| Brand | autocomplete | Philips Avent, Dr. Brown's, Medela, Tommee Tippee, etc. | Yes |
| Age Range | select | 0-3 months, 3-6 months, 6-12 months, 12+ months | Yes |
| Material | select | Plastic, Glass, Silicone, Stainless Steel | No |
| BPA Free | boolean | Yes/No | No |
| Quantity | number | | No |
| Expiry Date | date | (for food/formula) | No |

---

## 7. SPORTS & OUTDOORS

### 7.1 Fitness Equipment
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Treadmill, Exercise Bike, Elliptical, Rowing Machine, Weight Bench, Dumbbells, Kettlebells, Resistance Bands, Yoga Mat, Pull-Up Bar | Yes |
| Brand | autocomplete | NordicTrack, Peloton, Bowflex, Rogue, etc. | Yes |
| Weight Capacity | text | kg | No |
| Dimensions | object | Length x Width x Height (cm) | No |
| Foldable | boolean | Yes/No | No |
| Features | multi-select | Digital Display, Heart Rate Monitor, Bluetooth, App Compatible | No |
| Condition | select | Like New, Good, Fair | No |

### 7.2 Sports Equipment by Sport

#### Football/Soccer
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Ball, Boots, Shin Guards, Gloves, Goal, Jersey, Shorts | Yes |
| Brand | autocomplete | Nike, Adidas, Puma, Under Armour | Yes |
| Size | select | 3, 4, 5 (balls); Youth, Adult (gear); S-XXL (apparel) | Yes |
| Position | select | Goalkeeper, Outfield (for gloves) | No |

#### Basketball
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Ball, Shoes, Hoop, Jersey, Shorts | Yes |
| Brand | autocomplete | Spalding, Wilson, Nike, Jordan | Yes |
| Size | select | 5, 6, 7 (balls); Shoe sizes; S-XXL (apparel) | Yes |
| Indoor/Outdoor | select | Indoor, Outdoor, Both | No |

#### Tennis & Racquet Sports
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Racquet, Balls, Shoes, Bag, Strings, Grip | Yes |
| Brand | autocomplete | Wilson, Babolat, Head, Yonex | Yes |
| Grip Size | select | 4, 4 1/8, 4 1/4, 4 3/8, 4 1/2, 4 5/8 | No |
| Head Size | select | Midsize, Mid-Plus, Oversize | No |
| String Pattern | text | e.g., 16x19 | No |

#### Golf
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Clubs, Balls, Bag, Gloves, Shoes, Rangefinder, Cart | Yes |
| Brand | autocomplete | Titleist, Callaway, TaylorMade, Ping, Cobra | Yes |
| Club Type | select | Driver, Woods, Irons, Wedges, Putter, Full Set | No |
| Flex | select | Regular, Stiff, Senior, Ladies | No |
| Hand | select | Right, Left | Yes |
| Shaft Material | select | Steel, Graphite | No |

#### Cycling
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Bicycle, Helmet, Jersey, Shorts, Gloves, Shoes, Lights, Lock, Pump | Yes |
| Bike Type | select | Road, Mountain, Hybrid, BMX, Electric, Kids | No |
| Brand | autocomplete | Trek, Giant, Specialized, Cannondale, etc. | Yes |
| Frame Size | select | XS, S, M, L, XL (or cm) | No |
| Wheel Size | select | 20", 24", 26", 27.5", 29", 700c | No |
| Gears | select | Single Speed, 7-Speed, 21-Speed, 24-Speed, 27-Speed | No |
| Frame Material | select | Aluminum, Carbon, Steel | No |

### 7.3 Outdoor & Camping
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Tent, Sleeping Bag, Backpack, Camping Chair, Cooler, Lantern, Stove, Hiking Boots, Trekking Poles | Yes |
| Brand | autocomplete | The North Face, Columbia, Osprey, REI, etc. | Yes |
| Capacity | text | Person (tents), Liters (backpacks) | No |
| Season Rating | select | 2-Season, 3-Season, 4-Season | No |
| Weight | text | kg | No |
| Waterproof | boolean | Yes/No | No |
| Color | select | Color palette | Yes |

---

## 8. BOOKS, MEDIA & ENTERTAINMENT

### 8.1 Books
**Conditions:** New, Used, Collectible
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Format | select | Hardcover, Paperback, eBook Code | Yes |
| Genre | select | Fiction, Non-Fiction, Mystery, Romance, Sci-Fi, Fantasy, Biography, Self-Help, Business, Children's, Educational, Comics/Manga | Yes |
| Language | select | English, Swahili, French, Arabic, Other | Yes |
| Author | text | | Yes |
| Title | text | | Yes |
| ISBN | text | | No |
| Publisher | text | | No |
| Year Published | number | | No |
| Condition | select | Like New, Very Good, Good, Acceptable | Yes |
| Edition | text | 1st Edition, etc. | No |

### 8.2 Video Games
**Conditions:** New, Used, Collectible
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Platform | select | PlayStation 5, PlayStation 4, Xbox Series X/S, Xbox One, Nintendo Switch, PC | Yes |
| Title | text | | Yes |
| Genre | select | Action, Adventure, RPG, Sports, Racing, Shooter, Strategy, Puzzle, Fighting, Simulation | Yes |
| Rating | select | E (Everyone), E10+, T (Teen), M (Mature) | No |
| Format | select | Physical Disc, Digital Code | Yes |
| Region | select | All Regions, Region 1, Region 2, Region Free | No |
| Includes | multi-select | Original Case, Manual, DLC Codes | No |

### 8.3 Music & Vinyl
**Conditions:** New, Used, Collectible
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Format | select | Vinyl LP, CD, Cassette, Digital Download Code | Yes |
| Genre | select | Pop, Rock, Hip-Hop, R&B, Electronic, Jazz, Classical, Country, Afrobeats, Gospel | Yes |
| Artist | text | | Yes |
| Album Title | text | | Yes |
| Condition | select | Mint, Near Mint, Very Good, Good, Fair | Yes |
| Speed | select | 33 RPM, 45 RPM, 78 RPM (vinyl only) | No |
| Special Edition | boolean | Yes/No | No |

### 8.4 Movies & TV Shows
**Conditions:** New, Used
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Format | select | Blu-ray, 4K UHD, DVD, Digital Code | Yes |
| Genre | select | Action, Comedy, Drama, Horror, Sci-Fi, Documentary, Animation, Romance | Yes |
| Title | text | | Yes |
| Rating | select | G, PG, PG-13, R, NC-17 | No |
| Region | select | Region A, Region B, Region Free | No |
| Edition | select | Standard, Special Edition, Collector's, Steelbook | No |

---

## 9. ART & COLLECTIBLES

### 9.1 Fine Art
**Conditions:** New, Collectible
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Painting, Sculpture, Print, Photography, Mixed Media, Digital Art | Yes |
| Medium | select | Oil, Acrylic, Watercolor, Charcoal, Pastel, Bronze, Marble, Digital | Yes |
| Style | select | Abstract, Contemporary, Modern, Impressionist, Realist, Pop Art, Minimalist, Traditional African | Yes |
| Artist | text | | Yes |
| Title | text | | No |
| Year Created | number | | No |
| Dimensions | object | Width x Height (cm) | Yes |
| Framed | boolean | Yes/No | Yes |
| Signed | boolean | Yes/No | No |
| Certificate of Authenticity | boolean | Yes/No | No |
| Edition | text | e.g., 1/50, Open Edition | No |

### 9.2 Antiques
**Conditions:** Collectible
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Furniture, Ceramics, Glassware, Silverware, Clocks, Textiles, Jewelry, Books, Maps | Yes |
| Era/Period | select | Victorian, Art Deco, Art Nouveau, Mid-Century Modern, Colonial, Pre-Colonial African | Yes |
| Origin | text | Country/Region | Yes |
| Age | text | Approximate years | Yes |
| Material | text | | No |
| Condition | select | Excellent, Very Good, Good, Fair, Restoration Needed | Yes |
| Provenance | text | History of ownership | No |
| Dimensions | object | | No |

### 9.3 Coins & Currency
**Conditions:** Collectible
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Coin, Paper Currency, Token, Medal | Yes |
| Country | text | | Yes |
| Year | number | | Yes |
| Denomination | text | | Yes |
| Metal/Material | select | Gold, Silver, Copper, Bronze, Nickel, Paper | Yes |
| Grade | select | MS70, MS69, MS65, AU, XF, VF, F, VG, G, AG, Poor | No |
| Certification | select | PCGS, NGC, Uncertified | No |
| Mint Mark | text | | No |

### 9.4 Trading Cards
**Conditions:** New, Collectible
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Category | select | Sports, Pokemon, Yu-Gi-Oh, Magic: The Gathering, Other TCG | Yes |
| Sport/Game | text | | Yes |
| Player/Character | text | | Yes |
| Year | number | | Yes |
| Brand/Set | text | Topps, Panini, etc. | Yes |
| Card Number | text | | No |
| Grade | select | PSA 10, PSA 9, BGS 10, Raw/Ungraded | No |
| Condition | select | Mint, Near Mint, Excellent, Good | Yes |
| Autographed | boolean | Yes/No | No |
| Serial Numbered | text | e.g., /100 | No |

---

## 10. GROCERY & FOOD

### 10.1 Packaged Foods
**Conditions:** New Only
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Snacks, Cereals, Pasta, Rice, Canned Goods, Sauces, Condiments, Baking, Spices | Yes |
| Brand | text | | Yes |
| Dietary | multi-select | Vegan, Vegetarian, Gluten-Free, Halal, Kosher, Organic, Sugar-Free, Keto | No |
| Weight/Volume | text | g, kg, ml, L | Yes |
| Expiry Date | date | | Yes |
| Country of Origin | text | | No |

### 10.2 Beverages
**Conditions:** New Only
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Water, Soft Drinks, Juice, Tea, Coffee, Energy Drinks, Alcohol | Yes |
| Brand | text | | Yes |
| Volume | text | ml, L | Yes |
| Pack Size | select | Single, 6-Pack, 12-Pack, 24-Pack, Case | Yes |
| Dietary | multi-select | Sugar-Free, Diet, Organic, Caffeine-Free | No |
| Alcohol Content | text | % (if applicable) | No |
| Expiry Date | date | | Yes |

### 10.3 Fresh & Frozen
**Conditions:** New Only
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Meat, Poultry, Seafood, Dairy, Fruits, Vegetables, Frozen Meals, Ice Cream | Yes |
| Storage | select | Fresh (Refrigerated), Frozen | Yes |
| Weight | text | g, kg | Yes |
| Organic | boolean | Yes/No | No |
| Expiry Date | date | | Yes |
| Halal Certified | boolean | Yes/No | No |

---

## 11. SERVICES & DIGITAL GOODS

### 11.1 Gift Cards
**Conditions:** New Only
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Store Gift Card, Restaurant, Entertainment, Gaming, General Purpose | Yes |
| Brand/Store | text | | Yes |
| Value | number | KES | Yes |
| Delivery | select | Physical Card, Email/Digital | Yes |
| Expiry Date | date | | No |

### 11.2 Digital Products
**Conditions:** New Only
| Attribute | Type | Options | Required |
|-----------|------|---------|----------|
| Type | select | Software License, Game Key, Subscription, eBook, Course, Template, Music/Audio | Yes |
| Platform | select | Windows, Mac, iOS, Android, Cross-Platform | No |
| Delivery | select | Email, Download Link, Account Transfer | Yes |
| Duration | select | Lifetime, 1 Month, 3 Months, 6 Months, 1 Year | No |
| Region | select | Global, Kenya, Africa, Specific Region | No |

---

## COMMON FIELDS (All Products)

These fields apply to EVERY product regardless of category:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | text | Yes | Product title (max 200 chars) |
| description | text | Yes | Detailed description (max 5000 chars) |
| price | number | Yes | Price in KES |
| compareAtPrice | number | No | Original price (for showing discounts) |
| images | array | Yes | 1-10 product images |
| condition | select | Yes | Based on category-allowed conditions |
| stock | number | Yes | Available quantity |
| sku | text | No | Seller's internal SKU |
| tags | array | No | Search keywords (max 10) |
| isActive | boolean | Yes | Whether product is visible |
| category | string | Yes | Category path (e.g., "electronics/smartphones") |
| attributes | map | Yes | Category-specific attributes |

---

## COLOR PALETTE

Standard colors available for selection across all categories:

**Neutrals:** Black, White, Gray, Silver, Beige, Cream, Ivory, Charcoal

**Primary:** Red, Blue, Yellow

**Secondary:** Green, Orange, Purple, Pink

**Fashion:** Navy, Burgundy, Olive, Tan, Brown, Khaki, Maroon, Teal, Coral, Mint

**Metallic:** Gold, Rose Gold, Bronze, Copper

**Special:** Multi-color, Patterned, Clear/Transparent

---

## IMPLEMENTATION NOTES

### Dynamic Form Generation (Seller App)

```dart
// Pseudocode for dynamic form
1. User selects Category (e.g., "Electronics")
2. Show Subcategories (e.g., "Cell Phones", "Computers", "TVs")
3. User selects Subcategory (e.g., "Cell Phones")
4. Show Product Types (e.g., "Smartphones", "Feature Phones", "Accessories")
5. User selects Product Type (e.g., "Smartphones")
6. Load attribute schema for "Smartphones"
7. Generate form fields dynamically:
   - Required fields shown first with * indicator
   - Optional fields in collapsible section
   - Field types: select, multi-select, text, number, date, boolean
8. Show only allowed Conditions for this product type
9. Show common fields (name, price, description, images)
```

### Filter Generation (Buyer App)

```dart
// When buyer browses "Electronics > Cell Phones > Smartphones"
1. Load attribute schema for Smartphones
2. Generate filter chips/dropdowns:
   - Brand: [Apple, Samsung, Google, ...]
   - Storage: [64GB, 128GB, 256GB, ...]
   - Carrier: [Unlocked, Safaricom, ...]
   - Condition: [New, Used, Refurbished]
   - Price Range: [Min] - [Max]
3. Apply filters to Firestore query
```

### Firestore Document Structure

```json
{
  "id": "prod_abc123",
  "storeId": "store_xyz",
  "name": "iPhone 15 Pro Max 256GB",
  "description": "Brand new, sealed in box...",
  "price": 189999,
  "compareAtPrice": 199999,
  "category": "electronics/cell_phones/smartphones",
  "condition": "new",
  "attributes": {
    "brand": "Apple",
    "model": "iPhone 15 Pro Max",
    "storage": "256GB",
    "ram": "8GB",
    "color": "Natural Titanium",
    "carrierLock": "Unlocked",
    "screenSize": "6.5-6.9\"",
    "includes": ["Original Box", "Charger", "Cable"]
  },
  "images": ["url1", "url2", "url3"],
  "stock": 5,
  "isActive": true,
  "createdAt": "2026-01-08T10:00:00Z",
  "updatedAt": "2026-01-08T10:00:00Z"
}
```

### Category Path Convention

Format: `{main_category}/{subcategory}/{product_type}`

Examples:
- `apparel/clothing/tshirts`
- `apparel/shoes/sneakers`
- `electronics/cell_phones/smartphones`
- `electronics/computers/laptops`
- `automotive/vehicles/cars`
- `home/furniture/sofas`
- `beauty/skincare`
- `baby/toys`

---

## NEXT STEPS

1. ✅ Category Taxonomy defined (this document)
2. ⏳ Create design.md with technical implementation details
3. ⏳ Create tasks.md with implementation checklist
4. ⏳ Implement in Seller App (product forms)
5. ⏳ Implement in Buyer App (filters & search)
