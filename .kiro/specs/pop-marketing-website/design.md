# Design Document: POP Marketing Website

## Overview

The POP Marketing Website is a modern, high-performance static website built with Astro and Tailwind CSS. The design follows contemporary web trends including bento grid layouts, smooth animations, and gradient accents while strictly adhering to POP brand guidelines. The website serves as the primary web presence for the POP marketplace platform, converting visitors into app users through compelling design and clear calls-to-action.

## Architecture

### Technology Stack

- **Framework**: Astro 5.x (Static Site Generator)
- **Styling**: Tailwind CSS 4.x
- **Hosting**: Firebase Hosting (africa-south1 region)
- **Fonts**: Google Fonts (Poppins)
- **Build Tool**: Vite (via Astro)
- **Deployment**: Firebase CLI

### Architecture Decisions

**Why Astro?**
- Zero JavaScript by default (fast page loads)
- Excellent SEO with static HTML generation
- Component-based architecture (.astro files)
- Built-in image optimization
- Perfect for content-heavy marketing sites

**Why Tailwind CSS?**
- Utility-first approach for rapid development
- Easy to maintain brand consistency
- Excellent responsive design utilities
- Small bundle size with purging
- Matches modern design trends

**Why Firebase Hosting?**
- Already using Firebase for backend
- Unified billing and management
- Auto SSL certificates
- Global CDN with edge caching
- Custom domain support
- Same region as Cloud Functions (africa-south1)

## Components and Interfaces

### Page Components

#### Layout.astro
Base layout component wrapping all pages.

**Props:**
- `title: string` - Page title for SEO
- `description?: string` - Meta description (default provided)

**Responsibilities:**
- Load global CSS and fonts
- Set up HTML structure
- Include meta tags for SEO
- Provide slot for page content

#### Header.astro
Sticky navigation header component.

**Props:** None (uses static navigation links)

**Responsibilities:**
- Display POP logo (red square with "P")
- Render navigation links
- Display "Sign up" and "Start for free" buttons
- Sticky positioning on scroll
- Responsive collapse on mobile

#### Footer.astro
Site-wide footer component.

**Props:** None (uses static content)

**Responsibilities:**
- Display organized link columns
- Show copyright information
- Provide access to legal pages
- Display POP branding

### Page Routes

#### / (index.astro)
Homepage with hero section, features, and final CTA.

**Sections:**
1. Hero Section with bento grid
2. Features Section ("Why Choose POP?")
3. Final CTA Section

#### /seller (seller.astro)
Seller landing page.

**Sections:**
1. Hero with headline
2. Benefits grid (3 cards)
3. "Start Selling Today" steps
4. Download CTA section

#### /rider (rider.astro)
Rider landing page.

**Sections:**
1. Hero with headline
2. Benefits grid (3 cards)
3. "Ready to Start Earning?" CTA section

#### /about (about.astro)
About POP page.

**Sections:**
1. Introduction
2. Our Mission
3. How It Works (3 steps)
4. Why Choose POP? (bullet list)

#### /contact (contact.astro)
Contact information and form.

**Sections:**
1. Contact information cards
2. Contact form
3. Support hours

#### /privacy (privacy.astro)
Privacy policy legal document.

**Sections:**
1-10. Standard privacy policy sections

#### /terms (terms.astro)
Terms of service legal document.

**Sections:**
1-14. Standard terms sections

## Data Models

### Navigation Link
```typescript
interface NavLink {
  href: string;      // Route path (e.g., "/seller")
  label: string;     // Display text (e.g., "Sell on POP")
}
```

### Feature Card
```typescript
interface FeatureCard {
  icon: string;          // SVG path or icon identifier
  title: string;         // Feature title
  description: string;   // Feature description
}
```

### Contact Info
```typescript
interface ContactInfo {
  type: 'email' | 'phone' | 'location';
  icon: string;          // SVG icon
  label: string;         // Display label
  value: string;         // Contact value
  link?: string;         // Optional href
}
```

### Bento Card
```typescript
interface BentoCard {
  type: 'image' | 'badge' | 'transaction';
  content: string | BentoCardContent;
  className: string;     // Tailwind classes
  position: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right';
}

interface BentoCardContent {
  title?: string;
  subtitle?: string;
  amount?: string;
  date?: string;
  icon?: string;
  image?: string;
}
```

## Design System

### Color Palette

```css
/* Primary Brand Colors */
--pop-red: #fb2a0a;           /* Main brand color, accents */
--pop-dark-red: #e02509;      /* Hover states */
--pop-button-red: #b71000;    /* Buttons, CTAs */

/* Neutral Colors */
--pop-black: #000000;         /* Primary text */
--pop-white: #ffffff;         /* Backgrounds */

/* Gray Scale */
--gray-50: #FAFAFA;           /* Light backgrounds */
--gray-100: #F5F5F5;          /* Card backgrounds */
--gray-200: #EEEEEE;          /* Borders */
--gray-300: #E0E0E0;
--gray-400: #BDBDBD;
--gray-500: #9E9E9E;          /* Tertiary text */
--gray-600: #757575;          /* Secondary text */
--gray-700: #616161;          /* Navigation text */
--gray-800: #424242;
--gray-900: #212121;
```

### Typography Scale

```css
/* Font Family */
font-family: 'Poppins', sans-serif;

/* Font Sizes */
--text-xs: 12px;      /* Captions, metadata */
--text-sm: 13px;      /* Small text */
--text-base: 14px;    /* Secondary text */
--text-md: 15px;      /* Button text, nav links */
--text-lg: 16px;      /* Body text */
--text-xl: 20px;      /* Subheadings */
--text-2xl: 24px;     /* Section headings */
--text-3xl: 32px;     /* Large headings */
--text-4xl: 40px;     /* Page titles */
--text-5xl: 56px;     /* Hero headlines */

/* Font Weights */
--font-regular: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;

/* Line Heights */
--leading-tight: 1.1;    /* Large headings */
--leading-normal: 1.5;   /* Body text */
--leading-relaxed: 1.625; /* Comfortable reading */
```

### Spacing System

```css
/* Spacing Scale (4px base) */
--space-1: 4px;
--space-2: 8px;
--space-3: 12px;
--space-4: 16px;
--space-5: 20px;
--space-6: 24px;
--space-8: 32px;
--space-10: 40px;
--space-12: 48px;
--space-16: 64px;
--space-20: 80px;
```

### Border Radius

```css
/* Border Radius Scale */
--radius-sm: 8px;       /* Small elements */
--radius-md: 12px;      /* Standard cards */
--radius-lg: 16px;      /* Large cards */
--radius-xl: 24px;      /* Extra large cards */
--radius-2xl: 32px;     /* Bento grid cards */
--radius-3xl: 48px;     /* CTA sections */
--radius-full: 9999px;  /* Buttons, pills */
```

### Component Styles

#### Buttons

**Primary Button (CTA)**
```css
background: #b71000;
color: white;
padding: 14px 28px;
border-radius: 9999px;
font-size: 15px;
font-weight: 600;
transition: all 200ms;

hover:
  background: #e02509;
  transform: scale(1.05);
```

**Secondary Button (Outline)**
```css
background: transparent;
color: #000000;
border: 1px solid #E0E0E0;
padding: 14px 28px;
border-radius: 9999px;
font-size: 15px;
font-weight: 500;
```

**Text Button**
```css
background: transparent;
color: #fb2a0a;
padding: 12px 16px;
font-size: 14px;
font-weight: 500;
```

#### Cards

**Feature Card**
```css
background: white;
border: 1px solid #EEEEEE;
border-radius: 24px;
padding: 32px;
```

**Bento Grid Card**
```css
border-radius: 32px;
height: 250px;
overflow: hidden;
```

**Icon Container**
```css
width: 48px;
height: 48px;
background: rgba(251, 42, 10, 0.1);
border-radius: 16px;
display: flex;
align-items: center;
justify-content: center;
```

## Page Layouts

### Homepage Layout

```
┌─────────────────────────────────────────┐
│           Header (Sticky)                │
├─────────────────────────────────────────┤
│                                          │
│  Hero Section                            │
│  ┌──────────────┬──────────────────┐   │
│  │              │  ┌────┐  ┌────┐  │   │
│  │   Text       │  │ 1  │  │ 2  │  │   │
│  │   Content    │  └────┘  └────┘  │   │
│  │              │  ┌────┐  ┌────┐  │   │
│  │   CTA        │  │ 3  │  │ 4  │  │   │
│  │   Social     │  └────┘  └────┘  │   │
│  └──────────────┴──────────────────┘   │
│                                          │
├─────────────────────────────────────────┤
│                                          │
│  Features Section (3 cards)              │
│  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │  🛒  │  │  ⚡  │  │  🔒  │          │
│  └──────┘  └──────┘  └──────┘          │
│                                          │
├─────────────────────────────────────────┤
│                                          │
│  Final CTA Section (Red background)     │
│                                          │
├─────────────────────────────────────────┤
│           Footer                         │
└─────────────────────────────────────────┘
```

### Bento Grid Structure

```
┌─────────────┬─────────────┐
│             │             │
│  Shopping   │  Success    │
│  Cart       │  Badge      │
│  Image      │             │
│             │             │
├─────────────┼─────────────┤
│             │             │
│  R250       │  Store      │
│  Transaction│  Interior   │
│  Card       │  Image      │
│             │             │
└─────────────┴─────────────┘
```

## Hero Section Detailed Design

### Layout Structure

**Container:**
- Max width: 1280px (max-w-7xl)
- Padding: 32px horizontal on mobile, 64px on desktop
- Padding vertical: 80px
- Background: White

**Grid:**
- Two columns on desktop (1fr 1fr)
- Single column on mobile
- Gap: 64px
- Alignment: items-start (top-aligned)

### Left Column (Text Content)

**Label:**
- Text: "— TRY IT NOW!"
- Color: gray-500 (#9E9E9E)
- Font: Poppins Medium
- Size: 13px
- Margin bottom: 24px

**Headline:**
- Text: "Instant\nShopping with\nPOP\nMarketplace"
- Font: Poppins Bold (700)
- Size: 56px
- Line height: 1.1
- Color: Black
- Italic: "POP" and "Marketplace" words only
- Margin bottom: 24px

**Body Text:**
- Font: Poppins Regular (400)
- Size: 16px
- Line height: 1.625
- Color: gray-600 (#757575)
- Max width: 448px
- Margin bottom: 32px

**CTA Button:**
- Text: "Get app"
- Background: #b71000
- Color: White
- Padding: 14px 28px
- Border radius: 9999px (rounded-full)
- Font: Poppins SemiBold (600)
- Size: 15px
- Hover: background #e02509, scale 1.05

**Social Proof:**
- Three avatar circles (40px each)
- Overlap: -10px (negative space)
- Border: 2px white
- Gradient backgrounds: gray-300 to gray-600
- Star rating: 5 orange stars
- Rating number: "4.8" in bold
- Review count: "from 500+ reviews" in gray-500

### Right Column (Bento Grid)

**Grid Configuration:**
- Display: grid
- Columns: 2
- Rows: 2
- Gap: 16px
- Total height: 520px
- Hidden on mobile (lg:grid)

**Card 1 (Top Left) - Shopping Cart:**
- Type: Image card
- Height: 250px
- Border radius: 32px
- Background: gray-200
- Image: Shopping cart with groceries
- Object fit: cover

**Card 2 (Top Right) - Success Badge:**
- Type: Status card
- Height: 250px
- Border radius: 32px
- Background: Gradient from gray-100 to gray-200
- Content:
  - Red circle icon (48px) with white checkmark
  - "Successful" text (18px bold)
  - "Transaction" text (16px semibold)
  - "Date: Mar 25, 2024" (12px gray-500)
- Alignment: Center

**Card 3 (Bottom Left) - Transaction:**
- Type: Transaction card
- Height: 250px
- Border radius: 32px
- Background: Gradient from #b71000 to #e02509
- Text color: White
- Content:
  - Shopping bag emoji in circle (top)
  - "R250" amount (32px bold)
  - "Sent to Store" subtitle (12px white/70)
  - User avatar circle (bottom)
- Layout: Flex column, space-between

**Card 4 (Bottom Right) - Store Interior:**
- Type: Image card
- Height: 250px
- Border radius: 32px
- Background: gray-200
- Image: Store interior or payment scene
- Object fit: cover

## Header Design

### Structure

**Container:**
- Background: White
- Border bottom: 1px gray-100
- Height: 80px
- Position: Sticky top
- Z-index: 50

**Logo:**
- Red square background (#b71000)
- White "P" text
- Size: 48px x 48px
- Border radius: 12px (rounded-xl)

**Navigation Links:**
- Font: Poppins Medium (500)
- Size: 15px
- Color: gray-700
- Hover: button red (#b71000)
- Spacing: 32px between links
- Links: Home, Sell on POP, Become a Rider, About, Contact

**Right Actions:**
- "Sign up" text link (gray-700, hover red)
- "Start for free" button (button red, rounded-full)

## Footer Design

### Structure

**Container:**
- Background: gray-50
- Border top: 1px gray-200
- Padding: 48px vertical

**Grid:**
- Four columns on desktop
- Single column on mobile
- Gap: 32px

**Column 1 - Brand:**
- POP logo text (24px bold, red)
- Tagline (14px gray-600)

**Column 2 - For Buyers:**
- Heading (16px semibold)
- Links: Download App, Help Center

**Column 3 - For Partners:**
- Heading (16px semibold)
- Links: Sell on POP, Become a Rider

**Column 4 - Company:**
- Heading (16px semibold)
- Links: About, Contact, Privacy, Terms

**Copyright:**
- Border top: 1px gray-200
- Padding top: 32px
- Text: "© 2026 POP. All rights reserved."
- Centered, gray-600, 14px

## Features Section Design

### Structure

**Container:**
- Background: gray-50
- Padding: 80px vertical
- Max width: 1280px

**Heading:**
- Text: "Why Choose POP?"
- Font: Poppins Bold (700)
- Size: 40px
- Centered
- Margin bottom: 48px

**Grid:**
- Three columns on desktop
- Single column on mobile
- Gap: 32px

**Feature Card:**
- Background: White
- Border: 1px gray-200
- Border radius: 24px
- Padding: 32px

**Icon Container:**
- Size: 48px x 48px
- Background: rgba(251, 42, 10, 0.1)
- Border radius: 16px
- Icon: 24px, red color

**Title:**
- Font: Poppins SemiBold (600)
- Size: 20px
- Margin bottom: 8px

**Description:**
- Font: Poppins Regular (400)
- Size: 16px
- Color: gray-600
- Line height: 1.5

## Landing Pages Design

### Seller Page

**Hero:**
- Headline: "Grow Your Business with POP Seller"
- Subheadline: Commission and benefits
- Layout: Centered text

**Benefits Grid:**
- Three cards
- Icons: Money, Phone, Chart
- Red accent backgrounds

**Steps Section:**
- Numbered steps (1, 2, 3)
- Red circle numbers
- White background card
- Download buttons at bottom

### Rider Page

**Hero:**
- Headline: "Earn Money as a POP Rider"
- Subheadline: Flexible hours message
- Layout: Centered text

**Benefits Grid:**
- Three cards
- Icons: Clock, Money, Map
- Red accent backgrounds

**CTA Section:**
- Red background
- White text
- Download buttons

## Legal Pages Design

### Structure

**Container:**
- Max width: 1024px
- Padding: 80px vertical
- Background: White

**Heading:**
- Font: Poppins Bold (700)
- Size: 56px
- Margin bottom: 16px

**Last Updated:**
- Font: Poppins Regular (400)
- Size: 16px
- Color: gray-600
- Margin bottom: 48px

**Section Heading:**
- Font: Poppins Bold (700)
- Size: 24px
- Margin: 48px top, 16px bottom

**Body Text:**
- Font: Poppins Regular (400)
- Size: 16px
- Line height: 1.625
- Color: gray-600

**Lists:**
- Disc style
- Padding left: 24px
- Spacing: 8px between items

## Contact Page Design

### Layout

**Two Columns:**
- Left: Contact information cards
- Right: Contact form
- Gap: 48px

**Contact Info Card:**
- Icon container: 48px, red/10 background
- Heading: 16px semibold
- Value: 16px, red for links

**Contact Form:**
- Background: gray-50
- Border radius: 24px
- Padding: 32px
- Inputs: White background, rounded-xl
- Submit button: Button red, full width

## About Page Design

### Structure

**Introduction:**
- Large text (20px)
- Gray-600 color
- Max width: 768px

**Mission Section:**
- Heading: 32px bold
- Body: 16px gray-600

**How It Works:**
- Three numbered circles
- Red background circles
- Step descriptions below

**Why Choose POP:**
- Bullet list with red checkmarks
- 16px text
- Proper spacing

## Responsive Breakpoints

```css
/* Mobile First Approach */
sm: 640px   /* Small tablets */
md: 768px   /* Tablets */
lg: 1024px  /* Desktop */
xl: 1280px  /* Large desktop */
2xl: 1536px /* Extra large */
```

### Mobile Adaptations

**Hero Section (< 1024px):**
- Hide bento grid
- Full-width text content
- Stack buttons vertically
- Reduce headline to 40px
- Reduce padding to 16px

**Header (< 768px):**
- Show hamburger menu
- Hide navigation links
- Keep logo and CTA button
- Reduce height to 64px

**Features (< 768px):**
- Stack cards vertically
- Full-width cards
- Maintain padding

**Footer (< 768px):**
- Stack columns vertically
- Center align text
- Reduce padding

## Error Handling

### Missing Images

WHEN an image fails to load, THE POP_Website SHALL:
- Display gray placeholder background
- Show alt text
- Log error to console
- Not break layout

### Form Validation

WHEN a user submits contact form, THE POP_Website SHALL:
- Validate required fields
- Display error messages in red
- Prevent submission if invalid
- Show success message after submission

### 404 Pages

WHEN a user visits non-existent route, THE POP_Website SHALL:
- Display custom 404 page
- Include navigation back to home
- Maintain header and footer
- Follow brand guidelines

## Testing Strategy

### Unit Testing

**Component Tests:**
- Test Header renders with correct links
- Test Footer renders with correct structure
- Test Button components render with correct styles
- Test responsive classes apply at breakpoints

**Page Tests:**
- Test each page renders without errors
- Test meta tags are correct
- Test images have alt text
- Test links are valid

### Property-Based Testing

Property-based testing is not applicable for this static marketing website as there are no complex algorithms or data transformations that require universal property validation. The website is primarily presentational with fixed content and layouts.

### Integration Testing

**Navigation Tests:**
- Test all internal links navigate correctly
- Test external links open in new tabs
- Test mobile menu toggles correctly
- Test sticky header behavior

**Form Tests:**
- Test contact form validation
- Test form submission
- Test error states
- Test success states

**Responsive Tests:**
- Test layout at all breakpoints
- Test images scale correctly
- Test text remains readable
- Test buttons remain clickable

### Visual Regression Testing

**Screenshot Tests:**
- Capture screenshots of all pages
- Compare against reference designs
- Test at multiple breakpoints
- Verify brand colors are correct

### Performance Testing

**Lighthouse Audits:**
- Performance score > 90
- Accessibility score > 90
- Best Practices score > 90
- SEO score > 90

**Load Time Tests:**
- First Contentful Paint < 1.5s
- Largest Contentful Paint < 2.5s
- Time to Interactive < 3.5s
- Cumulative Layout Shift < 0.1

### Browser Compatibility Testing

**Test Browsers:**
- Chrome (latest 2 versions)
- Firefox (latest 2 versions)
- Safari (latest 2 versions)
- Edge (latest 2 versions)
- Mobile Safari (iOS 14+)
- Chrome Mobile (Android 10+)

## Deployment Strategy

### Build Process

1. Run `npm run build` to generate static files
2. Astro compiles .astro files to HTML
3. Tailwind purges unused CSS
4. Images are optimized
5. Output generated in `dist/` folder

### Firebase Hosting Deployment

1. Authenticate with Firebase CLI
2. Select project: purlstores-za
3. Deploy hosting: `firebase deploy --only hosting`
4. Verify deployment at hosting URL
5. Configure custom domain if needed

### Environment Configuration

**Development:**
- Local dev server: `npm run dev`
- Port: 4321
- Hot reload enabled

**Production:**
- Static files in dist/
- Served via Firebase Hosting CDN
- HTTPS enabled
- Custom domain: pop.co.za (to be configured)

### Rollback Strategy

IF deployment issues occur:
1. Firebase Hosting maintains previous versions
2. Rollback via Firebase Console
3. Or redeploy previous git commit
4. Verify rollback successful

## Security Considerations

### Content Security

- No user-generated content
- All content is static and reviewed
- No database connections from frontend
- No API keys exposed in frontend code

### HTTPS

- Firebase Hosting provides auto SSL
- All traffic encrypted
- HTTP redirects to HTTPS
- Secure headers configured

### Form Security

- Contact form uses Firebase Functions for processing
- Input sanitization on backend
- Rate limiting on submissions
- CAPTCHA for spam prevention (future)

## Analytics and Monitoring

### Firebase Analytics

- Track page views
- Track button clicks
- Track app download link clicks
- Track form submissions
- Track user journey through site

### Performance Monitoring

- Monitor Core Web Vitals
- Track load times
- Monitor error rates
- Track bounce rates

## Future Enhancements

### Phase 2 Features

- Blog section for content marketing
- Customer testimonials carousel
- Video demonstrations
- Live chat support widget
- Multi-language support (English, Afrikaans, Zulu)
- Dark mode toggle
- Advanced animations with Framer Motion
- Interactive product showcase

### Phase 3 Features

- Web-based product browsing (read-only)
- Store directory search
- Integration with Firebase Auth for web login
- Order tracking via web
- Seller dashboard preview


## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system - essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

For this static marketing website, most requirements are specific examples (testing that specific content exists in specific places) rather than universal properties. However, we can identify several properties that should hold across all pages or all instances of certain elements.

### Property Reflection

After analyzing the acceptance criteria, I identified the following testable properties and examples:

**Properties (universal rules):**
- 1.7: All bento grid cards use 32px border radius
- 2.1: Header appears on all pages with sticky positioning
- 2.9: All navigation links use 15px font size and gray-700 color
- 3.1: All text elements use Poppins font family
- 3.4: All CTA buttons use button red (#b71000)
- 3.5: All red elements use dark red (#e02509) on hover
- 3.6, 3.7, 3.8: Text color properties by type
- 3.9: No green colors used (except allowed cases)
- 3.10: All buttons use rounded-full border radius
- 3.12: All standard cards use 12px border radius
- 7.1: Footer appears on all pages
- 8.5: Each page has exactly one h1 and proper heading hierarchy

**Examples (specific test cases):**
- Most hero section content tests (1.1, 1.2, 1.4, 1.5, 1.6, 1.8)
- Header content tests (2.2, 2.3, 2.4, 2.5, 2.6)
- Page existence tests (5.1, 5.2, 6.1, 6.2, 9.1, 10.1)
- Responsive behavior tests (1.9, 2.12)

**Redundancies identified:**
- 1.7 and 3.11 both test bento card border radius - keep 1.7
- 1.9 and 4.4 both test mobile bento grid behavior - keep 1.9
- 2.12 and 4.5 both test mobile menu collapse - keep 2.12

### Property 1: Poppins Font Consistency
*For all* text elements on the website, the computed font-family should be 'Poppins' or include 'Poppins' in the font stack
**Validates: Requirements 3.1, 4.1-4.12**

### Property 2: Button Red for CTAs
*For all* buttons with CTA or primary action classes, the background color should be #b71000 (button red)
**Validates: Requirements 1.4, 2.5, 3.4**

### Property 3: Rounded Full Buttons
*For all* button elements, the border-radius should be 9999px (rounded-full)
**Validates: Requirements 2.11, 3.10**

### Property 4: Bento Card Border Radius
*For all* bento grid card elements, the border-radius should be 32px
**Validates: Requirements 1.7**

### Property 5: Navigation Link Styling
*For all* navigation links in the header, the font-size should be 15px and color should be gray-700 (#374151)
**Validates: Requirements 2.9**

### Property 6: Red Hover States
*For all* elements with red background or red text, hovering should change the color to dark red (#e02509)
**Validates: Requirements 2.10, 3.5**

### Property 7: No Unauthorized Green
*For all* elements on the website (excluding explicitly allowed reference design elements), the computed color values should not contain green hues
**Validates: Requirements 3.9**

### Property 8: Footer Presence
*For all* page routes, the footer component should be present in the rendered HTML
**Validates: Requirements 7.1**

### Property 9: Single H1 Per Page
*For all* pages, there should be exactly one h1 element and heading levels should not skip (no h1 → h3)
**Validates: Requirements 8.5**

### Property 10: Text Color Hierarchy
*For all* text elements, primary text should use black (#000000), secondary text should use gray-600 (#4B5563), and tertiary text should use gray-500 (#6B7280)
**Validates: Requirements 3.6, 3.7, 3.8**
