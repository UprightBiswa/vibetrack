# VibeTrack BLoC Migration Plan

## Goal
Move VibeTrack from mixed Riverpod/provider-style state into a cleaner feature-by-feature BLoC architecture without a risky big-bang rewrite.

## Target Architecture
- `presentation`
- screens/widgets
- `bloc/`
- `*_bloc.dart`
- `*_event.dart`
- `*_state.dart`
- `data`
- repositories
- DTOs / remote sources
- `domain` (optional later)
- use-cases / entities when feature complexity grows

## State Principles
- Every user-facing async view should expose:
- loading
- error
- data
- empty
- Mutations should update state immediately where possible:
- like/comment/post
- login/logout
- profile update
- notification read state
- Navigation side effects should not be hidden inside repositories.
- API errors should be normalized into clear UI messages.

## Core Foundation Added
- `flutter_bloc`
- `equatable`
- `lib/core/bloc/app_bloc_observer.dart`
- `lib/core/bloc/view_status.dart`
- `lib/core/bloc/view_state.dart`

## Recommended Migration Order

### 1. App Shell and Navigation
- bottom tabs
- auth gate
- splash/auth/home flow
- notification deep-link navigation

Reason:
Navigation issues affect every feature and should stabilize first.

### 2. Auth and Profile
- sign in
- sign out
- current user
- current profile
- profile update

Reason:
These states are used by feed, zones, notifications, and tracking.

### 3. Feed
- fetch posts
- post detail
- comments
- like toggles
- create post

Reason:
Feed has the clearest async/mutation cycles and is a good BLoC fit.

### 4. Notifications
- fetch history
- unread count
- mark read
- mark all read
- push foreground updates

### 5. Zones
- fetch zones
- claim zone
- optimistic refresh

### 6. Tracking
- active session state
- session summary
- publish session result

Tracking may keep some local controller logic initially, then move into Cubit/BLoC after shell/profile/feed are stable.

## Suggested Feature Shape

Example for feed:
- `lib/features/feed/presentation/bloc/feed_bloc.dart`
- `lib/features/feed/presentation/bloc/feed_event.dart`
- `lib/features/feed/presentation/bloc/feed_state.dart`
- `lib/features/feed/presentation/bloc/feed_post_detail_cubit.dart`

## Temporary Compatibility Strategy
- Keep repositories as-is first.
- Replace Riverpod providers feature by feature with BLoC.
- Avoid mixing two different async sources for the same screen.
- Remove Riverpod providers only after a feature is fully migrated and stable.

## Migration Definition of Done
A feature is considered migrated only when:
- screen state comes from BLoC/Cubit
- loading/error/empty/data are handled
- mutations update the visible UI correctly
- navigation side effects are explicit
- old Riverpod state for that feature is removed

## Immediate Next Slice
Start with:
1. shell navigation state
2. auth gate/session state
3. profile screen state

Then move into feed.
