# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Flutter app (root)

```bash
# Install dependencies
flutter pub get

# Generate freezed models and riverpod providers (MUST run after any model/provider change)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for continuous code generation during development
dart run build_runner watch --delete-conflicting-outputs

# Analyse (lint + type check)
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/auth_flow_test.dart

# Format
dart format lib/ test/
```

### Cloud Functions (`functions/`)

```bash
cd functions
npm install
npm run build          # compile TypeScript
npm run lint           # eslint
firebase deploy --only functions   # deploy
firebase emulators:start           # local emulator (Firestore + Functions)
```

## Code-generation workflow

All models in `lib/models/` use `@freezed` (from `freezed_annotation`) and `@JsonSerializable` (from `json_annotation`). All providers in `lib/providers/` use `@riverpod` (from `riverpod_annotation`).

Generated files (`*.freezed.dart`, `*.g.dart`) are **gitignored**. After checkout or after editing any annotated file, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Without this step the project will not compile (the `part '…'` directives reference the missing generated files).

## Architecture

### Flutter app (`lib/`)

**Entry point**: `lib/main.dart` — initialises Firebase, wraps the tree in `ProviderScope`, sets `AuthGate` as the initial widget, and registers a global `FlutterError.onError` boundary.

**Auth gate** (`lib/screens/home_screen.dart` → `AuthGate`): chains three async providers — `isSignedInProvider` → `firebaseUserStreamProvider` → `needsOnboardingProvider(uid)` — to decide whether to show `SignInScreen`, `OnboardingFlowScreen`, or `MainNavigationWrapper`.

**Navigation**: Named routes + `onGenerateRoute` via `AppRouter` (`lib/routing/app_router.dart`). Bottom tabs managed by `MainNavigationWrapper` (`lib/widgets/main_navigation_wrapper.dart`) using an `IndexedStack`. Tab state lives in `NavigationNotifier` (a `@riverpod` `Notifier`).

**Layers**

| Layer | Path | Description |
|---|---|---|
| Models | `lib/models/` | `@freezed` value objects; include `fromMap()` static helpers for Firestore, `fromJson`/`toJson` for generic JSON |
| Services | `lib/services/` | `AuthService` (Firebase Auth + Google Sign-In), `UrlLauncherService`, `AuthExceptionHandler` |
| Providers | `lib/providers/` | `@riverpod` annotated; pure read providers are functions, mutations use `AsyncNotifier`/`Notifier` subclasses |
| Screens | `lib/screens/` | `ConsumerWidget`/`ConsumerStatefulWidget`; no business logic |
| Theme | `lib/theme/theme.dart` | `ConnectlyTheme.light()` / `.dark()`, plus `AppBrand` `ThemeExtension` with all brand tokens |
| Widgets | `lib/widgets/` | Shared components (`MentorAvatar`, `AuthErrorCard`, `BrandChip`, `Spacers`) |

### State management (Riverpod)

- Read-only data: `@riverpod Future<T>` / `@riverpod Stream<T>` functions → generates `xyzProvider` / `xyzProvider(arg)` (family).
- Mutable state: `class XyzNotifier extends _$XyzNotifier` with `@riverpod` → generates `xyzNotifierProvider`.
- Services injected as `@Riverpod(keepAlive: true)` singletons.
- Widget side: `ref.watch` for reactive reads, `ref.read` inside callbacks, `ref.listen` for one-shot side effects.

### Data models

All models derive from `@freezed`. Key behavioural notes:

- **`AppUser`** — use `AppUser.fromMap(uid, data)` for Firestore documents. `UserRole` enum uses `@JsonValue` so json_serializable maps `'mentor'`/`'mentee'` strings directly.
- **`Mentor`** — `calendlyPAT` is intentionally absent from the client model; PATs are handled exclusively by Cloud Functions reading `mentors/{id}/calendlyInfo/{docId}`.
- **`ScheduledCall`** — Calendly webhooks write `cancel_url`/`reschedule_url` (snake_case); `fromFirestore()` handles both snake_case (webhook-written) and camelCase (legacy) keys.
- **`OnboardingState`** — computed properties (`canProceed`, `totalStepsForRole`, `progressPercentage`) live as instance getters enabled by the `const OnboardingState._()` private constructor trick.

### Firebase collections

| Collection | Description |
|---|---|
| `users/{uid}` | User profile, role, `isOnboardingComplete` |
| `mentors/{uid}` | Public mentor profile (no PAT) |
| `mentors/{uid}/calendlyInfo/{docId}` | Server-only: `access_token`, `event_type_uri` |
| `chats/{menteeId}_{mentorId}` | Chat document (deterministic ID) |
| `chats/{chatId}/messages/{msgId}` | Individual messages |
| `onboarding/{uid}` | In-progress onboarding state |
| `users/{uid}/scheduled_calls/{callId}` | Calendly-sourced scheduled calls |

### Cloud Functions (`functions/src/`)

TypeScript (Firebase Functions v2). Key callables consumed by the Flutter app:

| Function | Type | Purpose |
|---|---|---|
| `availableTimes` | `onCall` | Fetches 7-day Calendly availability for a mentor |
| `scheduleCalendlyInvitee` | `onCall` | Books a Calendly slot on behalf of the mentee |
| `getCalendlyOAuthUrl` | `onCall` | *(to be implemented)* Returns the Calendly OAuth redirect URL for mentor onboarding |
| `calendlyWebhook` | `onRequest` | Receives `invitee.created`/`invitee.canceled` Calendly webhook events and writes `users/{uid}/scheduled_calls` |

Webhook signature validation lives in `functions/src/utils/signature-validation.ts`. The secret is stored in `functions/.env` (`CALENDLY_WEBHOOK_SECRET`).

### Theming

Access brand tokens in any widget:
```dart
final brand = Theme.of(context).extension<AppBrand>()!;
brand.danger   // error colour
brand.success  // positive colour
brand.brand    // Connectly yellow (#F5B400)
```

Never use `Colors.red` or hardcoded hex values — always go through `AppBrand`.

### Calendly OAuth flow

1. Flutter calls `getCalendlyOAuthUrl` Cloud Function → receives OAuth URL.
2. `UrlLauncherService.launchCalendlyUrl()` opens it externally.
3. Calendly redirects to the backend callback; the Cloud Function exchanges the code for an access token and writes it to `mentors/{uid}/calendlyInfo/`.
4. Flutter polls `mentors/{uid}.isCalendlySetup` via `_checkCalendlyStatus()` to confirm.

### Error handling conventions

- Auth errors: catch `AuthException` subtypes (defined in `lib/services/auth_exceptions.dart`); display with `AuthErrorCard` or `AuthErrorSnackBar`.
- Non-auth errors: use `debugPrint` (never bare `print`); `avoid_print` lint rule is enabled.
- Error colours in UI: `brand.danger` (never `Colors.red`).
