# In your project root
flutter create --platforms=android .

#
flutter run -d "adb-R94XA06D1QL-NNKmI6._adb-tls-connect._tcp"

#For Keystore
• Fixed the APNS crash in lib/data/services/notification/push_notification_service.dart.

  What changed:

  - Guards syncDeviceToken() so duplicate calls don’t run concurrently.
  - On iOS/macOS, checks getAPNSToken() before calling FCM getToken().
  - If APNS is not ready yet, it logs and returns instead of throwing.
  - Wraps FCM token fetch in try/catch, so [firebase_messaging/apns-token-not-set] can’t crash the app.
  
#For OpenAI codex
brew install --cask codex

#codex commands
codex --approval-mode suggest

# APP commands
flutter build apk --split-per-abi
• Ran flutter build apk --debug
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk


# To generate icons for platforms
flutter pub run flutter_launcher_icons:main

# To Launch Flutter web with no security flag
flutter run -d chrome --web-browser-flag "--disable-web-security"

# Local Backend Url
static const String baseUrl = 'http://192.168.0.101:8080';

--------------------------------------------------------------------------------------
• Moved into P1 and implemented a first core social slice across app + backend.

  Implemented:

  - Home composer is now directly editable and can publish text posts inline.
  - Create-post flow no longer offers document uploads.
  - Create-post supports selecting up to 4 gallery images.
  - Post cards now show captions above media.
  - Post media supports 2, 3, and 4 image collage layouts.
  - Hashtags are styled/clickable in captions.
  - Added a hashtag feed page for #tag navigation.
  - Added backend hashtag tables/indexes and hashtag feed endpoints.
  - Added backend + app support for save, share, and repost actions.
  - Comment creation now returns the created comment object, and app post comment
    counts update immediately.

  - Feed model now carries shares, saves, reposts, isSaved, isReposted, and
    hashtags.


• Moved on to the P1 Stories/Statuses slice and implemented the next set.
  - Added story upload progress wiring in lib/ui/pages/main/status/create_status_page.dart.
  - Added zoom/pinch support for selected story media.
  - Hid the text prompt when media is selected and no caption is present.
  - Added real story like, unlike, reply, and reshare events/services/UI wiring.
  - Added backend story social tables and endpoints:
      - POST /api/stories/{id}/like
      - DELETE /api/stories/{id}/like
      - POST /api/stories/{id}/replies
      - POST /api/stories/{id}/reshare

  - Story listing now returns like/reply/reshare counts plus isLiked and isReshared.

• Moved on to the P1 Reels improvements slice.

  Implemented:

  - Fixed Reels performance issue where every reel item was treated as active. Now only the visible reel plays/initializes as active in lib/ui/pages/main/reels/
    reels_page.dart.
  - Added mute/unmute control with persisted preference in lib/ui/widgets/reels/reel_item.dart.
  - Synced reel share/comment counters through ReelBloc instead of relying only on temporary local UI deltas.
  - Backend now returns the created reel comment from POST /api/reels/{id}/comments.
  - Added backend reel performance indexes for feed loading, comments, and likes.

• Moved on to the P1 Chat voice-note slice.

  Implemented:

  - Added voice recording UI in lib/ui/widgets/chat/chat_input_bar.dart: mic button, waveform while recording, delete/cancel, and send.
  - Wired completed recordings through the existing Cloudinary audio upload flow in lib/ui/pages/main/chat/chat_page.dart.
  - Added Android/iOS microphone permission declarations.
  - Updated backend chat send-message flow to return the created message instead of a generic “Message sent” response, so the app can replace optimistic messages with
    real IDs/timestamps.


• Implemented the Premium Access foundation.

  What changed:

  - Added centralized backend feature-access response at /api/subscription/access.
  - Added entitlement sync endpoint at /api/subscription/sync-entitlement.
  - Expanded backend free/premium/VIP limits and permissions.
  - Added app-side FeatureAccessCubit, typed access model, FeatureGate, and
    subscription service methods.

  - Added RevenueCat wrapper using purchases_flutter.
  - Updated Subscribe page to use real purchase/restore flows instead of fake
    success.

  - Registered premium access globally in main.dart.
  - Gated chat voice notes behind canUseVoiceNotes.
  

•  Implemented other-user profile viewing.

  What changed:

  - Added route: NamedRoutes.otherProfileScreen
  - Wired navigation to other profiles from:
      - post headers
      - friends list
      - match cards
      - recommendation cards

  - Updated feed user parsing so posts carry a usable user.id
  - Fixed ProfilePage state handling so viewed profiles use viewedStatus/viewedProfile instead of the logged-in
    user profile state

  - Adjusted profile loading so switching viewed users clears stale viewed-profile data first

  Backend check: I inspected the backend profile routes and GET /profiles/{id} already exists, so no backend
  change was needed for this slice.

  
• Implemented the Community Features slice before onboarding.

  Backend:

  - Added new communities module in prive-backend with models, repository, service, and handlers.
  - Added API support for:
      - community discovery
      - create/update/delete community
      - join/leave community
      - community discussion posts
      - create/list groups inside communities
      - join/leave groups
      - group invitations and invitation responses

  - Added migration: internal/migrations/communities.sql
  - Registered routes in cmd/server/main.go.

  Frontend:

  - Added community models, service, and CommunityBloc.
  - Added a new bottom tab: Spaces.
  - Built the Communities UI with:
      - search and category filters
      - create community sheet
      - community cards
      - detail page
      - join/leave actions
      - group creation/listing/joining
      - discussion composer and feed
      - invitation count display

  Signup check/fix:

  - Confirmed frontend was calling POST /api/auth/signup.
  - Found backend was rejecting the frontend payload because supabaseUserId was not accepted by the backend
    decoder.

  - Fixed backend auth signup to accept supabaseUserId and sync/create the local app users row through
    users.Service.

  - Updated backend auth handler wiring in cmd/server/main.go.
  - Fixed frontend signup so backend sync failures are no longer silently ignored.

  Onboarding:

  - Restored onboarding before demographic collection for authenticated users with no profile.
  - OnboardingPage now supports a configurable completion route.
  - Existing unauthenticated onboarding still finishes at login.
  - New authenticated users now go: OnboardingPage -> Demographics -> Success/Main flow.


• Implemented the branding and technical quality pass.

  Branding:

  - Designed a new Clique logo using the image generation workflow.
  - Replaced app logo assets:
      - assets/icons/clique.png
      - assets/images/clique.png

  - Hardened ApiService:
      - deterministic request keys
      - bounded memory cache
      - cleaned completed cancel tokens
      - prevented forced refresh from reusing stale pending GETs

  - Improved feed/reel cache consistency:
      - mutation cache invalidation
      - explicit refresh bypass for feed, comments, media, and reels

  - Reduced race conditions:
      - per-post comment loading guards
      - per-user/type media loading guards
      - reel initial/refresh/load-more in-flight guards
      - community list/detail stale-response guards

  - Improved media loading:
      - switched community remote images to cached image providers

  - Cleaned production logging:
      - replaced remaining print calls under lib with debugPrint

  - Fixed analyzer risk items:
      - async mounted checks
      - unused field
      - return inside finally
      - async context usage

  - Added review notes:
      - docs/technical_quality_review.md


• Implemented the cleanup in lib/core/clients/api_service.dart:1.

  What changed:

  - Removed the global request queue that serialized every API call.
  - Kept first-come, first-serve de-duping for identical GET requests only.
  - forceRefresh now bypasses shared pending GETs cleanly.
  - Stopped retrying POST/PUT/PATCH/DELETE, which avoids duplicate mutation requests.
  - Kept retry behavior for GET on 429, 5xx, and network failures.
  - Fixed cancel-token tracking so concurrent same-key requests do not overwrite each other.
  - Deleted unused duplicate request/auth infrastructure:
      - lib/core/network/auth_interceptor.dart
      - lib/core/network/retry_interceptor.dart
      - lib/core/network/token_refresh_lock.dart
      - lib/core/managers/token_manager.dart


• That log confirms the fixes were pointed at the right places.

  I added a second pass:

  - lib/core/clients/api_service.dart:1: 429 no longer retries and hammers the server. It now starts a
    local cooldown for that request key, using Retry-After when provided or 30 seconds by default.
    Cached GET data can still be returned during cooldown.

  - lib/core/services/notification/push_notification_service.dart:1: device-token sync now requires an
    authenticated Supabase session, so the 401 POST /api/notifications/device-tokens before signin
    should stop. Token registration is also de-duped while the same token is already being registered.

  - lib/main.dart:89: removed the duplicate startup CheckAuthStatus; AuthBloc was already dispatching
    one internally.

  The earlier cleanup still stands: no mutation retries, identical in-flight GETs share the first
  request, global request serialization is gone, and the unused duplicate auth/retry/token manager files
  were deleted.
