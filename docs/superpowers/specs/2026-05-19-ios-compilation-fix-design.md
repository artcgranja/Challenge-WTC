# iOS Compilation Fix — Design Spec

## Goal
Make the WTCChatApp compile with zero external dependencies, removing Supabase legacy and Kingfisher, and generating a valid .xcodeproj via XcodeGen.

## Current State
- 19 Swift files in `WTCChatApp/`
- No .xcodeproj or Package.swift — app cannot compile
- 2 legacy files import `Supabase` (not installed, not referenced by active code)
- 2 views import `Kingfisher` for image loading (KFImage)
- All other code uses only Apple frameworks (Foundation, SwiftUI, Combine)
- Backend integration is complete: APIService + WebSocketService point at `localhost:8080`

## Changes

### 1. Delete legacy files
- `WTCChatApp/Services/SupabaseService.swift` — imports `Supabase`, references undefined constants (`Constants.supabaseURL`, `Constants.Tables.*`)
- `WTCChatApp/Services/RealtimeService.swift` — imports `Supabase`, replaced by WebSocketService

### 2. Replace Kingfisher with AsyncImage (iOS 15+ native)

**MessageDetailView.swift:**
- Remove `import Kingfisher`
- Replace `KFImage(url).resizable()...` with `AsyncImage(url:transaction:content:)` using phase-based pattern:
  - `.empty` → ProgressView on rounded rect placeholder
  - `.success` → resizable image with .fill aspect ratio
  - `.failure` → SF Symbol photo icon on placeholder

**ProfileView.swift:**
- Remove `import Kingfisher`
- Replace `KFImage(url).resizable()...` with `AsyncImage` using the existing `initials` computed property as placeholder/error fallback
- Extract initials circle into `initialsView` computed property to avoid duplication

### 3. Create XcodeGen project

**Install xcodegen:**
```bash
brew install xcodegen
```

**Create `project.yml` at repo root:**
- Target: WTCChatApp (iOS application)
- Platform: iOS 15.0+
- Swift 5.9
- Sources: `WTCChatApp/` (excluding Info.plist)
- Info.plist: existing file at `WTCChatApp/Info.plist`
- Bundle ID: `com.wtc.chatapp`
- Zero SPM dependencies
- `createIntermediateGroups: true` for folder structure

**Generate:**
```bash
xcodegen generate  # creates WTCChatApp.xcodeproj
```

### 4. Verify compilation
```bash
xcodebuild build -project WTCChatApp.xcodeproj -scheme WTCChatApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

## Files Changed
| File | Action |
|------|--------|
| `WTCChatApp/Services/SupabaseService.swift` | DELETE |
| `WTCChatApp/Services/RealtimeService.swift` | DELETE |
| `WTCChatApp/Views/Messages/MessageDetailView.swift` | EDIT — Kingfisher → AsyncImage |
| `WTCChatApp/Views/Profile/ProfileView.swift` | EDIT — Kingfisher → AsyncImage, extract initialsView |
| `project.yml` | CREATE — XcodeGen spec |
| `WTCChatApp.xcodeproj/` | GENERATE — via xcodegen |

## Not Changed
- APIService.swift, WebSocketService.swift, all ViewModels, Constants.swift, Models, other Views
- Info.plist (already correct)
- Backend (already complete and verified)

## Success Criteria
- `xcodebuild build` completes without errors
- App launches in simulator, shows login screen
- No external dependencies in the project
