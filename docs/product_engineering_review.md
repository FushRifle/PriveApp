# Product Engineering Review

## Chat Architecture Review

Current chat is split across:

- `lib/core/services/chat/chat_service.dart`: API access, Stream Chat bridge, Hive-backed conversation/message caches, pending retry support.
- `lib/bloc/chat/*`: conversation/message/settings state orchestration.
- `lib/ui/pages/main/chat/*`: inbox, chat room, call screens, settings, archived chats.
- `lib/ui/widgets/chat/*`: message bubbles, input bar, avatar, audio message display.
- `lib/core/services/calls/*`: call permissions plus Stream video/call integration.

Findings:

- Archive UI existed but was not wired. `archived_chat_page.dart` was empty and inbox archive action only logged.
- Inbox merged cached and live conversations correctly, but it had no archived-state filter.
- Chat cache is already local-first for conversations/messages, which is the right foundation for archived state and offline inbox behavior.
- Message and conversation rendering should keep avoiding broad parent rebuilds. Existing cached merge logic in the inbox is good; future chat changes should keep expensive media and message bubble widgets isolated.
- Wallpaper state already flows through chat settings/preferences; the library needs more categorized assets and preview UX, but the persistence path exists.
- Call functionality is separated from messaging state, which limits blast radius. Permission and Stream connection failures should continue to be logged/handled in call-specific services, not surfaced as chat-list failures.

Implemented:

- Added local persistent archived-chat state in `ChatService`.
- Added a dedicated archived chats page with search, unread badges, open chat, and unarchive actions.
- Inbox now hides archived conversations and its swipe action archives instead of pretending to delete.
- Chat settings Archive Chat row now persists archive state.

## App Lock Review

Implemented:

- App lock now reads from encrypted Hive local storage as primary truth.
- App lock backend sync is background-only and retries after failures.
- Backend settings no longer override local app-lock state during settings load.
- App-lock settings updates no longer roll back when backend sync fails.

Remaining:

- PIN comparison still requires the decrypted local value at runtime. Hive storage is encrypted at rest; a future hardening pass could move to salted verifier storage if biometric/PIN reset flows are updated.

## Status Review

Implemented:

- HTTP 401 and 500 status failures are logged silently without user-facing snackbars.
- Status fetch requests continue to ask backend for following-only scope.
- Client now defensively filters explicit `isFollowing == false` status authors.
- Media status captions render below media, not centered over media.
- Status create flow avoids the invalid `String as int` cast during tag sync.

## Feed/Profile Review

Implemented:

- Home avatar opens the profile page instead of settings.
- People You May Know card is inserted after every six posts when real suggestions are available.
- Suggestions exclude current user and already-followed users client-side.
- Saved/bookmarked posts now unwrap saved-post wrapper records, ignore invalid post IDs, and best-effort remove broken bookmark references.
- Post media backgrounds are black for images, video, and mixed image media.

## Multi-Profile Design

Recommended hierarchy:

- Authenticated user account owns authentication, billing, device tokens, app lock, and global privacy/security settings.
- Profile records belong to the user account and own display identity, avatar, bio, audience-facing metadata, content ownership, creator/business settings, and per-profile feed/status attribution.
- Active profile ID should be stored locally and synced to backend.
- Content queries should accept or infer active profile ID for create/edit/delete while public reads continue to expose profile identity.

Existing support:

- `UserService` already includes profile switch/link/unlink endpoints.
- `AccountSwitchPage` already loads and switches linked profiles.

Missing backend/UI contracts before full implementation:

- Create profile endpoint and schema.
- Delete profile endpoint and ownership constraints.
- Profile-specific settings schema.
- Profile-specific content filters for posts, reels, events, status, and chat identity.

## Deferred Items

- Crop screen button placement depends on native `image_cropper` UI. A custom crop screen is needed for precise Safe Area/top-control positioning.
- Wallpaper expansion needs final asset selection and categorized picker UX beyond the existing persistence path.
- Full profile-specific content partitioning needs backend contract confirmation.
