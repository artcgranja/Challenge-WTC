# OPERATOR Views — iOS Design Spec

## Overview

Add OPERATOR (admin) views to the WTC Chat iOS app so operators can manage customers, send messages, and create campaigns. The backend (Spring Boot + MongoDB) already supports all required endpoints — this is purely iOS view/viewmodel work plus APIService extensions.

## Architecture

### Role Detection Flow

```
Login → AuthResponse.role → AuthViewModel.currentProfile.role
  ├─ "CLIENT"   → MainTabView (existing, unchanged)
  └─ "OPERATOR" → OperatorTabView (new)
```

`ContentView` branches on `currentProfile?.role == "OPERATOR"` after login. No changes to existing CLIENT flow.

### Approach

Role switch at TabView level. `OperatorTabView` is a completely separate SwiftUI view from `MainTabView`. Both share `APIService`, `Theme`, `WebSocketService`, and base models. New OPERATOR-specific code lives under `Views/Operator/` and `ViewModels/`.

## OperatorTabView — 4 Tabs

| Tab | Label | SF Symbol | View | Purpose |
|-----|-------|-----------|------|---------|
| 0 | CRM | `person.2.fill` | `CustomerListView` | Customer list with search/filters |
| 1 | Campanhas | `megaphone.fill` | `CampaignListView` | Campaign management |
| 2 | Mensagens | `message.fill` | `OperatorMessagesView` | Sent messages history |
| 3 | Perfil | `person.fill` | `ProfileView` (existing) | Reuses existing view |

Tab bar tint: `Theme.primary`. Same `.tint()` modifier as existing `MainTabView`.

## Screen Designs

### 1. CustomerListView (CRM Tab)

**Layout:**
- Large navigation title "Clientes" with subtitle "N clientes ativos"
- Search bar (same `SearchBar` pattern as `MessagesListView`)
- Horizontal filter chips: Todos, then dynamic from available tags (vip, ativo, beta, etc.)
- LazyVStack of compact customer rows
- Pull-to-refresh

**Customer Row:**
- Avatar circle (44pt, `Theme.avatarSM`) with initials + gradient background
- Name (15pt semibold) + status dot (8pt circle: green=active, gray=inactive, yellow=pending)
- Tag pills below name (`Theme.primary.opacity(0.1)` background, same style as ProfileView tags)
- Score badge on right: colored background chip (green 70-100, amber 40-69, red 0-39), bold number

**Interactions:**
- Tap row → NavigationLink push to `CustomerDetailView`
- Pull-to-refresh → re-fetch customers
- Search filters by name/email (client-side, same Combine pattern as `MessagesViewModel`)
- Filter chips filter by tag (client-side)

### 2. CustomerDetailView

**Layout:**
- Gradient navigation bar with back button + "Enviar" toolbar button (opens ComposeMessageSheet pre-filled with this customer)
- Profile card (white, `Theme.cornerMD`, `Theme.cardShadow`):
  - Centered avatar (72pt), name, email, tag pills
  - Stats row: Score | Messages | Notes (3-column, divider above)
- Section title "Timeline"
- Scrollable timeline items (messages + notes, sorted by date descending)
- Fixed bottom button "Adicionar Nota" (primary gradient, `Theme.cornerMD`)

**Timeline Item:**
- Icon circle (32pt): chat icon for messages, note icon for notes
- Title (13pt semibold), description (12pt, secondary color), relative time (11pt, tertiary)

**Interactions:**
- "Enviar" toolbar button → `.sheet` presenting `ComposeMessageSheet(recipientId: customer.userId)`
- "Adicionar Nota" → `.alert` with TextField for quick note input, calls `POST /api/customers/{id}/notes`
- Pull-to-refresh → re-fetch timeline

### 3. CampaignListView (Campaigns Tab)

**Layout:**
- Large title "Campanhas" with subtitle + "+ Nova" button (top right, primary gradient pill)
- Filter chips: Todas, Rascunho, Enviadas
- LazyVStack of campaign cards
- Pull-to-refresh

**Campaign Card — SENT:**
- Status badge (green "ENVIADA", `Theme.success` tinted)
- Campaign name (16pt semibold)
- Segment name below (13pt secondary)
- Message count on right (22pt bold, `Theme.primary`)
- Footer: sent date + sender email (12pt tertiary, divider above)

**Campaign Card — DRAFT:**
- Left amber border (3pt, `Theme.warning`)
- Status badge (amber "RASCUNHO")
- Campaign name + segment
- Two action buttons in footer: "Enviar Agora" (primary gradient) + "Editar" (gray `#F1F5F9`)

**Interactions:**
- "+ Nova" button → `.sheet` presenting `CreateCampaignSheet`
- "Enviar Agora" on draft → confirmation alert, then `POST /api/campaigns/{id}/send`
- "Editar" on draft → `.sheet` presenting `CreateCampaignSheet` pre-filled with campaign data
- Pull-to-refresh → re-fetch campaigns

### 4. ComposeMessageSheet (Bottom Sheet)

**Presentation:** `.sheet` with `.presentationDetents([.large])`, drag handle

**Layout:**
- Title "Nova Mensagem" (18pt bold)
- Segmented control: "Cliente" (1:1) | "Segmento" (broadcast)
  - Cliente mode: customer picker (navigable list or search sheet)
  - Segmento mode: segment picker dropdown
- Title field (labeled input, `#F8FAFC` background, `Theme.cornerSM` radius)
- Body field (multiline TextEditor, same style)
- Optional fields row: "Imagem" chip + "Botoes" chip (progressive disclosure, tap to expand)
  - Image URL text field
  - Dynamic button builder (label + action pairs)
- Primary button "Enviar Mensagem" (full-width, primary gradient, `Theme.cornerMD`)

**Interactions:**
- Segmented control toggles recipient type
- "Enviar Mensagem" → calls `POST /api/messages` with appropriate body → dismisses on success + shows toast
- Disable send button while fields are empty or request in-flight (loading spinner)
- Dismiss via swipe-down or explicit cancel

### 5. CreateCampaignSheet (Bottom Sheet)

**Presentation:** `.sheet` with `.presentationDetents([.large])`, drag handle

**Layout:**
- Title "Nova Campanha" (18pt bold)
- Campaign name field (labeled input)
- Segment picker (dropdown, fetches from `GET /api/segments`)
- Message title field
- Message body field (multiline)
- Deeplink field (optional, labeled)
- Two action buttons side by side:
  - "Salvar Rascunho" (gray, secondary) → `POST /api/campaigns` with status DRAFT
  - "Criar e Enviar" (`Theme.campaignGradient` orange→red) → `POST /api/campaigns` then `POST /api/campaigns/{id}/send`

**Interactions:**
- "Salvar Rascunho" creates draft → dismisses + refreshes campaign list
- "Criar e Enviar" creates + sends immediately → confirmation alert first ("Enviar para N clientes?") → dismisses + refreshes
- Disable buttons while request in-flight

### 6. OperatorMessagesView (Messages Tab)

**Layout:**
- Large title "Mensagens" with subtitle "Historico de envios" + "+ Nova" button
- Search bar
- Filter chips: Todas, Chat, Campanhas
- LazyVStack of sent message rows
- Pull-to-refresh

**Sent Message Row:**
- Type icon circle (40pt): teal background for CHAT, amber gradient for CAMPAIGN
- Title (15pt semibold) + relative time (right-aligned)
- Body preview (13pt secondary, 1 line, truncated)
- Bottom row: type badge (CHAT teal / CAMPANHA amber) + recipient info ("→ Name" or "→ Segmento: tag") + read status (green checkmark "Lida" / gray circle "Não lida")

**Interactions:**
- "+ Nova" → `.sheet` presenting `ComposeMessageSheet`
- Tap row → push to existing `MessageDetailView` (reused from CLIENT)
- Pull-to-refresh → re-fetch sent messages

### 7. SegmentPickerView (Reusable)

**Used by:** ComposeMessageSheet (segment mode), CreateCampaignSheet

**Layout:** Simple List with segment name + description + tag count. Single-selection. Fetches from `GET /api/segments`. Presented as a navigation push or picker sheet.

## Data Models

### New Models

```swift
// Customer.swift
struct Customer: Codable, Identifiable {
    let id: String
    var userId: String
    var tags: [String]
    var score: Int
    var status: String
    var notes: [CustomerNote]?
    var segmentIds: [String]?
    var fullName: String?
    var email: String?
    var phone: String?
}

struct CustomerNote: Codable {
    let text: String
    let createdBy: String
    let createdAt: String
}

// Campaign.swift
struct Campaign: Codable, Identifiable {
    let id: String
    var name: String
    var segmentId: String?
    var content: MessageContent  // reuses existing struct
    var deeplink: String?
    var status: String           // "DRAFT" | "SENT"
    var sentAt: Date?
    var sentBy: String?
    var messageCount: Int?
    var createdAt: Date
}

// Segment.swift
struct Segment: Codable, Identifiable {
    let id: String
    var name: String
    var description: String?
    var tags: [String]
    var createdBy: String?
    var createdAt: Date?
}
```

### Modified Models

```swift
// Profile.swift — add role field
struct Profile: Codable, Identifiable {
    // ... existing fields ...
    var role: String    // "OPERATOR" | "CLIENT"
}
```

### Timeline Response

The backend `GET /api/customers/{id}/timeline` returns separate arrays, not a mixed list:

```swift
struct TimelineResponse: Codable {
    let customer: Customer
    let messages: [Message]
    let notes: [CustomerNote]
}
```

The iOS view merges these into a unified timeline sorted by date:

```swift
enum TimelineEntry: Identifiable {
    case message(Message)
    case note(CustomerNote)

    var id: String { ... }
    var date: Date { ... }
}
```

Merge logic: combine messages + notes, sort by date descending, display as single list.

## ViewModels

### CRMViewModel

```swift
@MainActor
class CRMViewModel: ObservableObject {
    @Published var customers: [Customer] = []
    @Published var filteredCustomers: [Customer] = []
    @Published var searchText = ""
    @Published var selectedTagFilter: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Customer detail state
    @Published var timeline: [TimelineEntry] = []
    @Published var isLoadingTimeline = false

    func fetchCustomers() async
    func fetchTimeline(customerId: String) async
    func addNote(customerId: String, content: String) async
}
```

- Combine publishers for search + tag filter (same pattern as `MessagesViewModel`)
- `fetchCustomers()` → `GET /api/customers`
- `fetchTimeline()` → `GET /api/customers/{id}/timeline` → maps to `[TimelineEntry]`
- `addNote()` → `POST /api/customers/{id}/notes`

### CampaignViewModel

```swift
@MainActor
class CampaignViewModel: ObservableObject {
    @Published var campaigns: [Campaign] = []
    @Published var filteredCampaigns: [Campaign] = []
    @Published var segments: [Segment] = []
    @Published var selectedFilter: CampaignFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchCampaigns() async
    func fetchSegments() async
    func createCampaign(name:, segmentId:, content:, deeplink:) async -> Campaign?
    func sendCampaign(id: String) async
    func sendMessage(recipientId:, segmentTags:, content:) async
}
```

- `CampaignFilter` enum: `.all`, `.draft`, `.sent`
- Manages both campaigns and message sending (used by both Campaigns tab and Messages tab compose)
- `fetchSegments()` loaded on init for pickers

## APIService Extensions

10 new methods added to the existing `APIService`:

| Method | HTTP | Endpoint | Returns |
|--------|------|----------|---------|
| `fetchCustomers()` | GET | `/customers` | `[Customer]` |
| `fetchCustomer(id:)` | GET | `/customers/{id}` | `Customer` |
| `fetchTimeline(customerId:)` | GET | `/customers/{id}/timeline` | `TimelineResponse` (see below) |
| `addNote(customerId:, content:)` | POST | `/customers/{id}/notes` | Void |
| `sendMessage(body:)` | POST | `/messages` | `Message` |
| `fetchSentMessages(senderId:)` | GET | `/messages/sent/{senderId}` | `[Message]` |
| `fetchCampaigns()` | GET | `/campaigns` | `[Campaign]` |
| `createCampaign(body:)` | POST | `/campaigns` | `Campaign` |
| `sendCampaign(id:)` | POST | `/campaigns/{id}/send` | `Campaign` |
| `fetchSegments()` | GET | `/segments` | `[Segment]` |

All follow existing async/await + `request<T>()` pattern. Bearer token auth handled by existing infrastructure.

### Backend Change Required

The `MessageRepository` already has `findBySenderIdOrderByCreatedAtDesc(String senderId)` but no controller endpoint exposes it. Add a single endpoint to `MessageController`:

```java
@GetMapping("/sent/{senderId}")
public ResponseEntity<List<Message>> getSentMessages(@PathVariable String senderId) {
    return ResponseEntity.ok(messageRepository.findBySenderIdOrderByCreatedAtDesc(senderId));
}
```

This is the only backend change needed. Everything else is already implemented.

## File Structure

```
WTCChatApp/
├── Models/
│   ├── Customer.swift        (NEW)
│   ├── Campaign.swift        (NEW)
│   ├── Segment.swift         (NEW)
│   ├── Profile.swift         (MODIFY: add role)
│   └── Message.swift         (unchanged)
├── ViewModels/
│   ├── CRMViewModel.swift    (NEW)
│   ├── CampaignViewModel.swift (NEW)
│   └── AuthViewModel.swift   (MODIFY: populate role)
├── Views/
│   ├── Operator/
│   │   ├── OperatorTabView.swift      (NEW)
│   │   ├── CustomerListView.swift     (NEW)
│   │   ├── CustomerDetailView.swift   (NEW)
│   │   ├── CampaignListView.swift     (NEW)
│   │   ├── ComposeMessageSheet.swift  (NEW)
│   │   ├── CreateCampaignSheet.swift  (NEW)
│   │   ├── OperatorMessagesView.swift (NEW)
│   │   └── SegmentPickerView.swift    (NEW)
│   └── ... (existing views unchanged)
├── Services/
│   └── APIService.swift      (MODIFY: add 9 methods)
└── App/
    └── WTCChatAppApp.swift   (MODIFY: role branch in ContentView)
```

**Total: 8 new iOS files, 4 modified iOS files, 1 backend file modified (MessageController.java).**

## Design System Compliance

All new views follow existing Theme.swift patterns:

| Element | Value |
|---------|-------|
| Card background | `Theme.cardBackground` (secondarySystemBackground) |
| Screen background | `Theme.screenBackground` (systemGroupedBackground) |
| Corner radius (cards) | `Theme.cornerMD` (14pt) |
| Corner radius (chips) | `Theme.cornerLG` (20pt) |
| Corner radius (sheets) | `Theme.cornerXL` (28pt) |
| Avatar size (rows) | `Theme.avatarSM` (44pt) |
| Avatar size (detail) | 72pt (between SM and LG) |
| Card shadow | `Theme.cardShadow()` |
| Primary gradient | `Theme.primaryGradient` |
| Campaign gradient | `Theme.campaignGradient` (orange→red) |
| Active filter chip | `Theme.primaryGradient` fill |
| Inactive filter chip | White + `#E2E8F0` border |
| Tag pills | `Theme.primary.opacity(0.1)` background |
| Score green | `Theme.success` (70-100) |
| Score amber | `Theme.warning` (40-69) |
| Score red | `Theme.danger` (0-39) |
| Status dot green | `#22C55E` (active) |
| Status dot gray | `#94A3B8` (inactive) |
| Status dot yellow | `Theme.warning` (pending) |
| Animations | Spring (response: 0.3, dampingFraction: 0.8) |

## UX Patterns

- **Progressive disclosure:** Image URL and action buttons in compose sheets hidden behind expansion chips
- **Confirmation dialogs:** Before sending campaigns ("Enviar para N clientes?")
- **Loading states:** ProgressView spinner on buttons during async operations; skeleton not needed (lists are fast)
- **Empty states:** Reuse existing `EmptyStateView` pattern with icon + message + action
- **Error handling:** `errorMessage` displayed in `Theme.danger` color, same pattern as existing views
- **Pull-to-refresh:** On all list views
- **Haptic feedback:** UIImpactFeedbackGenerator(.medium) on send actions

## Scope Exclusions

- No segment CRUD UI (segments managed via backend/API tooling; picker only)
- No audit log viewer (backend-only for now)
- No push notification configuration for operators
- No image upload — image URL text field only (matching existing backend contract)
- No rich text editor — plain text body only
- No dark mode-specific overrides (existing Theme handles this via system colors)
- Profile tab reused as-is from CLIENT views
