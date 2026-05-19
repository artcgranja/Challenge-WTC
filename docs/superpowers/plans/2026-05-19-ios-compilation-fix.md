# iOS Compilation Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the WTCChatApp compile with zero external dependencies and a valid Xcode project.

**Architecture:** Delete 2 legacy Supabase files, replace Kingfisher with native AsyncImage in 2 views, create XcodeGen project.yml to generate .xcodeproj, verify compilation.

**Tech Stack:** Swift 5.9, SwiftUI, iOS 15+, XcodeGen, xcodebuild

---

### Task 1: Delete legacy Supabase files

**Files:**
- Delete: `WTCChatApp/Services/SupabaseService.swift`
- Delete: `WTCChatApp/Services/RealtimeService.swift`

- [ ] **Step 1: Verify files are not referenced by active code**

Run:
```bash
grep -rn "SupabaseService\|RealtimeService" WTCChatApp/ --include="*.swift" | grep -v "SupabaseService.swift" | grep -v "RealtimeService.swift"
```
Expected: No output (zero references from other files)

- [ ] **Step 2: Delete the legacy files**

```bash
rm WTCChatApp/Services/SupabaseService.swift
rm WTCChatApp/Services/RealtimeService.swift
```

- [ ] **Step 3: Commit**

```bash
git add -A WTCChatApp/Services/SupabaseService.swift WTCChatApp/Services/RealtimeService.swift
git commit -m "chore: remove legacy Supabase files (SupabaseService, RealtimeService)"
```

---

### Task 2: Replace Kingfisher with AsyncImage in MessageDetailView

**Files:**
- Modify: `WTCChatApp/Views/Messages/MessageDetailView.swift`

- [ ] **Step 1: Remove Kingfisher import**

In `WTCChatApp/Views/Messages/MessageDetailView.swift`, remove line 9:
```swift
import Kingfisher
```

- [ ] **Step 2: Replace KFImage with AsyncImage**

Replace this block (lines 27-33):
```swift
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                        .shadow(radius: 5)
```

With:
```swift
                    AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .frame(height: 200)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .transition(.opacity)
                        case .failure:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .cornerRadius(12)
                    .shadow(radius: 5)
```

- [ ] **Step 3: Commit**

```bash
git add WTCChatApp/Views/Messages/MessageDetailView.swift
git commit -m "refactor: replace Kingfisher with AsyncImage in MessageDetailView"
```

---

### Task 3: Replace Kingfisher with AsyncImage in ProfileView

**Files:**
- Modify: `WTCChatApp/Views/Profile/ProfileView.swift`

- [ ] **Step 1: Remove Kingfisher import**

In `WTCChatApp/Views/Profile/ProfileView.swift`, remove line 9:
```swift
import Kingfisher
```

- [ ] **Step 2: Extract initialsView computed property**

Add this computed property to `ProfileView` (after the existing `statusText` computed property, before the closing brace of the struct, around line 259):

```swift
    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)

            Text(initials)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
```

- [ ] **Step 3: Replace avatar block with AsyncImage**

Replace the entire avatar section (lines 23-60, from `// Avatar` comment through the closing `.shadow(radius: 10)`):

```swift
                        // Avatar
                        if let avatarUrl = authViewModel.currentProfile?.avatarUrl,
                           let url = URL(string: avatarUrl) {
                            AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                                switch phase {
                                case .empty:
                                    initialsView
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .transition(.opacity)
                                case .failure:
                                    initialsView
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(radius: 10)
                        } else {
                            initialsView
                                .shadow(radius: 10)
                        }
```

- [ ] **Step 4: Commit**

```bash
git add WTCChatApp/Views/Profile/ProfileView.swift
git commit -m "refactor: replace Kingfisher with AsyncImage in ProfileView"
```

---

### Task 4: Install XcodeGen

- [ ] **Step 1: Install xcodegen via Homebrew**

```bash
brew install xcodegen
```

- [ ] **Step 2: Verify installation**

```bash
xcodegen --version
```
Expected: Version number (e.g., `2.42.0`)

---

### Task 5: Create project.yml and generate .xcodeproj

**Files:**
- Create: `project.yml` (repo root)
- Generate: `WTCChatApp.xcodeproj/`

- [ ] **Step 1: Create project.yml at repo root**

Create `project.yml` with this content:

```yaml
name: WTCChatApp

options:
  bundleIdPrefix: com.wtc
  deploymentTarget:
    iOS: "15.0"
  createIntermediateGroups: true

settings:
  base:
    SWIFT_VERSION: "5.9"
    DEVELOPMENT_TEAM: ""

targets:
  WTCChatApp:
    type: application
    platform: iOS
    sources:
      - path: WTCChatApp
        excludes:
          - Info.plist
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.wtc.chatapp
        INFOPLIST_FILE: WTCChatApp/Info.plist
        GENERATE_INFOPLIST_FILE: false
```

- [ ] **Step 2: Add .xcodeproj to .gitignore**

Append to `.gitignore`:
```
# Generated Xcode project
*.xcodeproj
```

- [ ] **Step 3: Generate the Xcode project**

```bash
xcodegen generate
```
Expected: `⚙  Generating plists...` then `Created project WTCChatApp.xcodeproj`

- [ ] **Step 4: Commit**

```bash
git add project.yml .gitignore
git commit -m "build: add XcodeGen project.yml for iOS app (zero external deps)"
```

---

### Task 6: Verify compilation

- [ ] **Step 1: Build for iOS Simulator**

```bash
xcodebuild build \
  -project WTCChatApp.xcodeproj \
  -scheme WTCChatApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet \
  CODE_SIGNING_ALLOWED=NO
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: If build fails, diagnose and fix**

Common issues:
- Missing `@unknown default` in switch → add the case
- Date formatting availability → check iOS 15 availability
- Any remaining Kingfisher/Supabase references → remove them

Run:
```bash
grep -rn "import Kingfisher\|import Supabase" WTCChatApp/ --include="*.swift"
```
Expected: No output

- [ ] **Step 3: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "fix: resolve compilation issues"
```
