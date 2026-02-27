# Implementation Plan: POP Marketing Website

## Overview

This plan implements a modern, high-performance marketing website for POP using Astro and Tailwind CSS. The implementation focuses on creating pixel-perfect pages that match reference designs, follow POP brand guidelines strictly, and provide excellent performance and SEO. Tasks are organized to build incrementally, starting with core infrastructure, then page-by-page implementation, and finally optimization.

## Tasks

- [x] 1. Set up project foundation and design system
  - Initialize Astro project with Tailwind CSS
  - Configure Tailwind with POP brand colors
  - Set up Poppins font loading
  - Create global CSS with brand variables
  - Copy all required image assets to public/images/
  - Configure Firebase Hosting
  - _Requirements: 3.1-3.13, 20.1-20.5_

- [ ]* 1.1 Write property test for font consistency
  - **Property 1: Poppins Font Consistency**
  - **Validates: Requirements 3.1**

- [x] 2. Implement Header component
  - [x] 2.1 Create Header.astro with sticky positioning
    - Build navigation structure with logo, links, and CTA buttons
    - Implement POP logo (red square with "P")
    - Style navigation links with hover states
    - Add "Sign up" link and "Start for free" button
    - Ensure 80px height and proper spacing
    - _Requirements: 2.1-2.12_

- [ ]* 2.2 Write property test for navigation link styling
  - **Property 5: Navigation Link Styling**
  - **Validates: Requirements 2.9**

- [ ]* 2.3 Write unit test for header presence
  - Test header renders on all pages
  - Test logo displays correctly
  - Test all navigation links are present
  - _Requirements: 2.1-2.6_

- [x] 3. Implement Footer component
  - [x] 3.1 Create Footer.astro with link columns
    - Build four-column layout
    - Add POP branding and tagline
    - Organize links by category
    - Add copyright with dynamic year
    - Style with gray background and borders
    - _Requirements: 7.1-7.10_

- [ ]* 3.2 Write property test for footer presence
  - **Property 8: Footer Presence**
  - **Validates: Requirements 7.1**

- [x] 4. Implement Hero Section with Bento Grid
  - [x] 4.1 Create hero section layout
    - Build two-column grid (text left, bento right)
    - Add "— TRY IT NOW!" label
    - Create headline with proper typography
    - Add body text and CTA button
    - Implement social proof (avatars, rating, reviews)
    - Ensure responsive behavior (hide bento on mobile)
    - _Requirements: 1.1-1.13_

  - [x] 4.2 Implement Bento Grid cards
    - Create 2x2 grid with 16px gap
    - Build shopping cart image card (top-left)
    - Build success transaction badge card (top-right)
    - Build R250 transaction card (bottom-left) with red gradient
    - Build store interior image card (bottom-right)
    - Apply 32px border radius to all cards
    - Set all cards to 250px height
    - _Requirements: 2.1-2.11_

- [ ]* 4.3 Write property test for bento card border radius
  - **Property 4: Bento Card Border Radius**
  - **Validates: Requirements 1.7**

- [ ]* 4.4 Write property test for button styling
  - **Property 2: Button Red for CTAs**
  - **Property 3: Rounded Full Buttons**
  - **Validates: Requirements 1.4, 3.4, 3.10**

- [x] 5. Implement Features Section
  - [x] 5.1 Create "Why Choose POP?" section
    - Build section with gray-50 background
    - Add section heading
    - Create three-column grid (single column on mobile)
    - Build feature cards with icons, titles, descriptions
    - Style icon containers with red accent backgrounds
    - Apply 24px border radius to cards
    - _Requirements: 12.1-12.10_

- [ ]* 5.2 Write unit test for features section
  - Test three feature cards render
  - Test icons display correctly
  - Test responsive grid behavior
  - _Requirements: 12.1-12.10_

- [x] 6. Implement Final CTA Section
  - [x] 6.1 Create homepage CTA section
    - Build section with button red background
    - Add headline and descriptive text in white
    - Create white button with red text
    - Apply 48px border radius
    - Center all content
    - Add hover effects
    - _Requirements: 13.1-13.10_

- [x] 7. Checkpoint - Verify homepage is complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Implement Seller Landing Page
  - [x] 8.1 Create seller.astro page
    - Build hero section with headline
    - Create benefits grid with three cards
    - Add icon containers with red accents
    - Build "Start Selling Today" numbered steps section
    - Add download CTA section with red background
    - Include App Store and Google Play buttons
    - _Requirements: 6.1-6.10_

- [ ]* 8.2 Write unit test for seller page
  - Test page renders at /seller route
  - Test download buttons are present
  - Test benefits cards display
  - _Requirements: 5.1, 5.3_

- [x] 9. Implement Rider Landing Page
  - [x] 9.1 Create rider.astro page
    - Build hero section with headline
    - Create benefits grid with three cards
    - Add icon containers with red accents
    - Build "Ready to Start Earning?" CTA section with red background
    - Include App Store and Google Play buttons
    - _Requirements: 7.1-7.10_

- [ ]* 9.2 Write unit test for rider page
  - Test page renders at /rider route
  - Test download buttons are present
  - Test benefits cards display
  - _Requirements: 5.2, 5.4_

- [x] 10. Implement About Page
  - [x] 10.1 Create about.astro page
    - Build introduction section
    - Add "Our Mission" section
    - Create "How It Works" with three numbered steps
    - Add "Why Choose POP?" with checkmark bullets
    - Style with proper typography and spacing
    - _Requirements: 11.1-11.10_

- [ ]* 10.2 Write unit test for about page
  - Test page renders at /about route
  - Test all sections are present
  - Test checkmark icons display
  - _Requirements: 10.1_

- [x] 11. Implement Contact Page
  - [x] 11.1 Create contact.astro page
    - Build two-column layout
    - Create contact information cards with icons
    - Add email, phone, location information
    - Build contact form with validation
    - Style form inputs with rounded-xl and white background
    - Add submit button with button red
    - Display support hours
    - _Requirements: 10.1-10.12_

- [ ]* 11.2 Write unit test for contact page
  - Test page renders at /contact route
  - Test form fields are present
  - Test contact info displays
  - _Requirements: 9.1-9.5_

- [x] 12. Implement Legal Pages
  - [x] 12.1 Create privacy.astro page
    - Build document structure with numbered sections
    - Add all privacy policy sections (1-10)
    - Include last updated date
    - Add contact information
    - Style for readability (max-w-4xl)
    - _Requirements: 8.1-8.10_

  - [x] 12.2 Create terms.astro page
    - Build document structure with numbered sections
    - Add all terms sections (1-14)
    - Include last updated date
    - Add contact information
    - Style for readability (max-w-4xl)
    - _Requirements: 8.1-8.10_

- [ ]* 12.3 Write unit test for legal pages
  - Test privacy page renders at /privacy
  - Test terms page renders at /terms
  - Test last updated date is present
  - Test contact info is present
  - _Requirements: 6.1, 6.2, 6.4, 6.5_

- [ ] 13. Implement responsive design and mobile menu
  - [ ] 13.1 Add mobile hamburger menu to Header
    - Create hamburger icon button
    - Build slide-out mobile menu
    - Add smooth open/close animation
    - Ensure menu closes on link click
    - Hide desktop nav on mobile, show hamburger
    - _Requirements: 2.12, 18.3, 18.10_

  - [ ] 13.2 Verify responsive breakpoints
    - Test hero section on mobile (hide bento grid)
    - Test features section stacks on mobile
    - Test footer columns stack on mobile
    - Test buttons go full-width on mobile
    - Verify padding reduces appropriately
    - _Requirements: 5.1-5.10, 18.1-18.9_

- [ ]* 13.3 Write unit tests for responsive behavior
  - Test bento grid hidden on mobile
  - Test mobile menu appears on small screens
  - Test feature cards stack vertically
  - _Requirements: 1.9, 2.12, 18.1-18.9_

- [ ] 14. Add animations and interactions
  - [ ] 14.1 Enhance hover effects
    - Add scale effect to CTA buttons (scale-105)
    - Add lift effect to feature cards (shadow and translate)
    - Ensure 200-300ms transition duration
    - Use ease-in-out timing
    - _Requirements: 17.1-17.7_

  - [ ] 14.2 Add scroll animations
    - Implement fade-in for bento cards on load
    - Add staggered animation for hero text
    - Trigger animations on viewport enter
    - Respect prefers-reduced-motion
    - _Requirements: 17.4-17.10_

- [ ]* 14.3 Write unit tests for animations
  - Test hover classes are applied
  - Test transition properties are set
  - Test animations respect reduced-motion
  - _Requirements: 17.1-17.10_

- [ ] 15. Implement SEO and meta tags
  - [ ] 15.1 Add enhanced meta tags to Layout.astro
    - Add Open Graph tags for social sharing
    - Add Twitter Card tags
    - Add canonical URLs
    - Ensure all images have alt text
    - _Requirements: 16.1-16.8_

  - [ ] 15.2 Create sitemap and robots.txt
    - Generate sitemap.xml with all routes
    - Create robots.txt allowing all crawlers
    - Add structured data for organization
    - _Requirements: 16.9-16.10_

- [ ]* 15.3 Write property test for heading hierarchy
  - **Property 9: Single H1 Per Page**
  - **Validates: Requirements 8.5**

- [ ] 16. Optimize performance
  - [ ] 16.1 Optimize images
    - Compress all images for web
    - Add responsive image srcsets
    - Implement lazy loading for below-fold images
    - Verify image formats (WebP with fallbacks)
    - _Requirements: 8.4, 15.3, 15.8_

  - [ ] 16.2 Optimize CSS and fonts
    - Preload Poppins font files in Layout.astro
    - Minimize render-blocking resources
    - Purge unused Tailwind classes
    - Minify CSS output
    - _Requirements: 15.4, 15.5, 15.9_

- [ ]* 16.3 Run Lighthouse audits
  - Test performance score > 90
  - Test accessibility score > 90
  - Test SEO score > 90
  - Test best practices score > 90
  - _Requirements: 15.6_

- [ ] 17. Implement accessibility features
  - [ ] 17.1 Add ARIA labels and semantic HTML
    - Add ARIA labels to interactive elements
    - Use semantic HTML (nav, main, footer, article)
    - Add skip-to-content link
    - Ensure keyboard navigation works
    - Add visible focus indicators
    - Associate labels with form inputs
    - _Requirements: 19.1-19.10_

- [ ]* 17.2 Write accessibility tests
  - Test color contrast ratios
  - Test keyboard navigation
  - Test screen reader compatibility
  - Test ARIA labels are present
  - _Requirements: 19.2-19.4_

- [x] 18. Configure Firebase Hosting deployment
  - [x] 18.1 Set up Firebase configuration
    - Create firebase.json with hosting config
    - Create .firebaserc with project ID
    - Add deployment script to package.json
    - Configure rewrite rules for routing
    - Set up cache headers
    - _Requirements: 20.1-20.10_

  - [ ] 18.2 Test deployment process
    - Run build command
    - Deploy to Firebase Hosting
    - Verify site loads at hosting URL
    - Test custom domain configuration
    - Verify SSL certificate
    - _Requirements: 20.6-20.8_

- [ ] 19. Final checkpoint - Complete testing and polish
  - Run all tests and ensure they pass
  - Verify all pages match reference designs
  - Check brand consistency across all pages
  - Test on multiple browsers and devices
  - Verify performance metrics
  - Ask the user for final review

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and page content
- Focus on pixel-perfect implementation matching reference designs
- Strictly follow POP brand guidelines (no green colors, button red for CTAs, Poppins font)
