# Technical Quality Review

## Scope

Reviewed high-risk shared paths for performance, stability, and state consistency:

- BLoCs/Cubits for feed, reels, communities, chat, friends, profile, insights, and notifications
- Shared API request, cache, retry, and cancellation behavior
- Pagination paths for feed, comments, profile media, reels, friends, notifications, and communities
- Image/video loading patterns in core social surfaces
- State synchronization after create/update/delete/reaction mutations

## Changes Applied

- Stabilized `ApiService` request keys with deterministic encoding.
- Prevented forced-refresh GETs from attaching to stale pending requests.
- Added API memory-cache bounds and cleaned completed cancel tokens.
- Added cache invalidation after feed and reel mutations.
- Made feed refresh, comments refresh, user media refresh, and reel refresh explicitly bypass cache.
- Scoped feed comment loading guards per post instead of globally.
- Scoped feed media loading guards per user/type instead of globally.
- Added in-flight guards for reels initial load, refresh, and pagination.
- Added request sequencing for community list/detail loads to prevent stale responses from overwriting newer UI state.
- Switched community remote images to `CachedNetworkImageProvider`.

## Current Architecture Risks

- Several BLoCs still rely on manual boolean guards. This works, but event transformers or reusable request coordinators would be cleaner for large-scale consistency.
- Community discovery currently loads the first page only in the UI. Backend and service support pagination, but the tab should add infinite scroll before large production usage.
- Some screens still use raw `Image.network`/`NetworkImage`. Those should be migrated to cached image widgets/providers.
- Video controllers are generally disposed, but video-heavy surfaces should be profiled on low-end devices for memory pressure and decode churn.
- Backend and frontend pagination response shapes are not fully standardized across modules. Some endpoints return lists while others return `{data, page}`.
- Cache invalidation is now improved for feed/reels, but should be centralized by feature namespace so future modules do not forget it.
- Some optimistic updates roll back entire lists. Per-entity rollback is safer when multiple actions happen quickly.

## Recommended Next Pass

- Standardize API response envelopes: `{data, page, pageSize, hasMore, total}`.
- Add BLoC event transformers for restartable search/refresh and droppable load-more events.
- Add integration tests for feed/reel/community mutation -> refresh/cache invalidation.
- Add low-end-device profiling for reels, stories, post videos, and image-heavy profile grids.
- Migrate remaining raw network images to cached image loading.
- Add backend migration runner or documented migration order if not already handled in deployment.
