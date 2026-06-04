Clique App - Bug Fixes, Improvements & Feature Backlog

P0 - Critical Bugs (Fix First)

Authentication

- Fix signup flow. New users are currently unable to create accounts.

Reels

- Fix app blank screen/crash after reel upload completes.
- Fix Android hardware back button behavior in Reels. Pressing back should navigate correctly instead of closing the application.

Profile

- Fix profile cover photo upload/display issue.
- Fix profile post gallery Cubit. Gallery content is not loading correctly.
- Fix post like counts not syncing/reflected correctly on profile pages.

Insights

- Fix Insights/Analytics functionality. All metrics currently return null values.

Matching

- Fix bugs in the match engine.
- Improve overall stability and consistency of match results.

---

P1 - Core Social Features

Posts

Post Creation

- Make the "What's on your mind?" composer directly editable on the Home screen.
- Alternative: replace the current composer interaction with a Floating Action Button (FAB) that opens the create-post flow.

Hashtags

- Implement hashtag functionality similar to major social platforms:
  - Clickable hashtags
  - Hashtag discovery/navigation
  - Hashtag feeds
  - Hashtag highlighting in captions
- Add required hashtag database schema and indexing.

Post Card Improvements

- Always display caption above media content.
- Render hashtags with proper styling and interactions.
- Support photo collage layouts:
  - 2 images
  - 3 images
  - 4 images (maximum)

Post Interactions

- Implement repost functionality.
- Implement share functionality.
- Implement save/bookmark functionality.
- Implement tagging/mentions functionality.
- Implement edit-post functionality (Premium users only).

Comments

- Fix comment counts not updating or reflecting correctly on post cards.
- Improve comment bottom sheet performance and loading speed.
- Implement threaded replies using visual hierarchy:
  - Reply indentation
  - Vertical thread lines/borders
  - Parent-child relationships
- Add comment reactions:
  - Like
  - Reply
  - Future reaction support

Media Upload

- Remove document uploads from post creation flow (feature no longer required).

---

P1 - Stories / Statuses

Story Creation

- Add zoom-in and zoom-out gestures while selecting/creating stories.
- Hide the "Write Story" prompt after media has been selected.
- Add upload progress indicators during story uploads.

Story Viewing

- Redesign and improve the status viewer experience.
- Add:
  - Like reactions
  - Reply functionality
  - Reshare functionality
- Pause story playback/progress when user focuses the reply/comment input.
- Resume playback when input loses focus.

---

P1 - Reels Improvements

Performance

- Improve reel loading speed.
- Optimize caching strategy.
- Reduce initial loading time.
- Improve reaction responsiveness.

Features

- Add share functionality.
- Add reply/comment functionality.
- Add mute/unmute controls.
- Improve overall user experience to match major short-video platforms.

---

P1 - Chat Improvements

Messaging

- Research and implement voice recordings:
  - Waveform visualization
  - Modern recording UI
  - Android support
  - iOS support

UI Consistency

- Fix inconsistent chat wallpapers.
- Fix inconsistent chat color themes.
- Improve chat loading performance.

---

P1 - Notifications

Notification System

- Improve notification delivery visibility.
- Improve notification UI/UX.
- Improve real-time notification updates.
- Ensure notification counts and badges update correctly.

---
P1 - Premium Access, Monetization & Permission System

Subscription Architecture

Implement a complete feature-access hierarchy for:

- Free Users
- Premium Users
- Future Premium+ / VIP Tier (optional)

The system should be centralized and scalable to avoid feature checks scattered throughout the application.

Free User Restrictions

Posts

- Limited number of post edits.
- Cannot edit posts after a configurable time window.
- Cannot schedule posts.

Reels

- Limited daily reel uploads.
- Limited reel duration.

Stories

- Limited story uploads per day.

Messaging

- Limited media uploads.
- Limited voice note duration.
- Advanced chat customization locked.

Discovery & Matching

- Limited daily profile views.
- Limited daily match requests.
- Limited advanced filters.

Profile Features

- Limited profile customization.
- Premium badges unavailable.
- Advanced profile analytics unavailable.

Groups & Communities

- Limited number of groups joined.
- Cannot create premium communities.

Premium User Benefits

Content

- Unlimited post edits.
- Advanced media uploads.
- Priority media processing.
- Draft saving functionality.

Reels

- Unlimited uploads.
- Longer reel duration.
- Advanced analytics.

Stories

- Unlimited story uploads.
- Story insights.
- Story viewers analytics.

Messaging

- Voice notes.
- Advanced chat themes.
- Chat wallpapers.
- Read receipts.
- Message management tools.

Discovery & Matching

- Unlimited profile views.
- Unlimited match requests.
- Advanced search filters.
- Better recommendation visibility.

Profile

- Profile verification badge.
- Premium badge.
- Advanced profile customization.
- Full profile analytics.

Communities

- Create communities.
- Create groups.
- Advanced moderation tools.

Premium Exclusive Features

- Post editing.
- Post scheduling.
- Profile insights.
- Story insights.
- Advanced match filters.
- Profile verification.
- Advanced chat customization.
- Community creation.
- Group creation.
- Premium badge.

Access Control System

Create a centralized permission system:

Examples:

- canEditPost
- canCreateCommunity
- canCreateGroup
- canViewInsights
- canUseAdvancedFilters
- canUploadLongReels
- canUsePremiumThemes
- canAccessAnalytics

UI should automatically:

- Show feature
- Lock feature
- Upsell premium
- Hide feature where appropriate

RevenueCat Integration

Implement:

- Subscription purchase flow
- Subscription restoration
- Subscription expiration handling
- Trial support
- Feature entitlement sync

Monetization Goal

All premium features should:

- Provide real value
- Avoid degrading free-user experience
- Encourage upgrades naturally
- Generate recurring subscription revenue
---

P2 - Profile & User Experience

User Profiles

- Create dedicated "Other User Profile" page.
- Improve profile experience and consistency.

Loading States

- Replace avatar placeholder initials ("U") with blurred/skeleton avatar placeholders.
- Improve loading states throughout the application.

---

P2 - Community Features

Groups

- Create group functionality:
  - Create group
  - Invite members
  - Group feed
  - Group management

Communities

- Create community functionality:
  - Community discovery
  - Community membership
  - Community discussions

Note: Implement after core social features are stable.

---

P2 - Onboarding

User Journey

- Restore onboarding screens before demographic collection.
- Reintroduce onboarding flow for newly registered users.

---

P2 - Branding

Visual Identity

- Design and implement a new application logo.

---

Technical Quality Goals

Performance

All core features must be:

- Fast
- Responsive
- Cached where appropriate
- Memory efficient
- Optimized for low-end devices

Stability

All core features must be:

- Consistent
- Stable
- Crash-free
- Production-ready

Architecture Review

Perform a complete review of:

- BLoCs/Cubits
- Repository layer
- API calls
- Caching strategy
- Pagination
- Image loading
- Video loading
- State synchronization

Goal:
Eliminate race conditions, stale state issues, duplicate requests, and UI inconsistencies across the entire application.

