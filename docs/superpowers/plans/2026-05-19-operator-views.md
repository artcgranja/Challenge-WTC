# OPERATOR Views Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add OPERATOR admin views to the WTC Chat iOS app — CRM customer management, campaign creation/sending, and message compose — so operators can manage content directly from mobile.

**Architecture:** Role switch at TabView level in ContentView. OPERATOR gets a separate 4-tab view (CRM, Campaigns, Messages, Profile). All new views share existing Theme, APIService, and models. One small backend change needed (sent messages endpoint + customer enrichment with user details).

**Tech Stack:** Swift 5.9 / SwiftUI / Combine / iOS 15+ / MVVM / Spring Boot 3.3 / MongoDB

**Spec:** `docs/superpowers/specs/2026-05-19-operator-views-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| MODIFY | `backend/.../controller/MessageController.java` | Add `GET /api/messages/sent/{senderId}` |
| MODIFY | `backend/.../service/CustomerService.java` | Enrich customer responses with user fullName + email |
| CREATE | `WTCChatApp/Models/Customer.swift` | Customer, CustomerNote, TimelineResponse models |
| CREATE | `WTCChatApp/Models/Campaign.swift` | Campaign model |
| CREATE | `WTCChatApp/Models/Segment.swift` | Segment model |
| MODIFY | `WTCChatApp/Models/Profile.swift` | Add `role` field |
| MODIFY | `WTCChatApp/Services/APIService.swift` | Add 10 OPERATOR endpoint methods |
| MODIFY | `WTCChatApp/ViewModels/AuthViewModel.swift` | Populate `role` from AuthResponse into Profile |
| CREATE | `WTCChatApp/ViewModels/CRMViewModel.swift` | Customer list, search/filter, timeline, notes |
| CREATE | `WTCChatApp/ViewModels/CampaignViewModel.swift` | Campaigns, segments, message sending |
| MODIFY | `WTCChatApp/App/WTCChatAppApp.swift` | Role branch in ContentView + OperatorTabView |
| CREATE | `WTCChatApp/Views/Operator/CustomerListView.swift` | CRM customer list with compact rows |
| CREATE | `WTCChatApp/Views/Operator/CustomerDetailView.swift` | 360° profile + timeline + notes |
| CREATE | `WTCChatApp/Views/Operator/CampaignListView.swift` | Campaign list with status badges |
| CREATE | `WTCChatApp/Views/Operator/CreateCampaignSheet.swift` | Campaign creation bottom sheet |
| CREATE | `WTCChatApp/Views/Operator/ComposeMessageSheet.swift` | Message compose (1:1 or segment) |
| CREATE | `WTCChatApp/Views/Operator/SegmentPickerView.swift` | Reusable segment selector |
| CREATE | `WTCChatApp/Views/Operator/OperatorMessagesView.swift` | Sent messages history |

---

### Task 1: Backend — Sent Messages Endpoint + Customer Enrichment

**Files:**
- Modify: `backend/src/main/java/com/wtc/chatapp/controller/MessageController.java`
- Modify: `backend/src/main/java/com/wtc/chatapp/service/CustomerService.java`

The `Customer` model in MongoDB only stores `userId` (reference), NOT `fullName` or `email`. The iOS CRM views need customer names. We enrich the customer list/detail/timeline responses with user details.

- [ ] **Step 1: Add sent messages endpoint to MessageController**

Add after the existing `toggleStar` method at line 46 of `MessageController.java`:

```java
@GetMapping("/messages/sent/{senderId}")
public ResponseEntity<List<Message>> getSentMessages(@PathVariable String senderId) {
    return ResponseEntity.ok(messageService.getSentMessages(senderId));
}
```

- [ ] **Step 2: Add getSentMessages to MessageService**

In `MessageService.java`, add:

```java
public List<Message> getSentMessages(String senderId) {
    return messageRepository.findBySenderIdOrderByCreatedAtDesc(senderId);
}
```

- [ ] **Step 3: Enrich CustomerService with user details**

Inject `UserRepository` into `CustomerService.java`. Modify the constructor:

```java
private final CustomerRepository customerRepository;
private final MessageRepository messageRepository;
private final UserRepository userRepository;

public CustomerService(CustomerRepository customerRepository, MessageRepository messageRepository, UserRepository userRepository) {
    this.customerRepository = customerRepository;
    this.messageRepository = messageRepository;
    this.userRepository = userRepository;
}
```

Add a private helper method:

```java
private Map<String, Object> enrichCustomer(Customer customer) {
    Map<String, Object> enriched = new HashMap<>();
    enriched.put("id", customer.getId());
    enriched.put("userId", customer.getUserId());
    enriched.put("tags", customer.getTags());
    enriched.put("score", customer.getScore());
    enriched.put("status", customer.getStatus());
    enriched.put("notes", customer.getNotes());
    enriched.put("segmentIds", customer.getSegmentIds());
    enriched.put("createdAt", customer.getCreatedAt());

    if (customer.getUserId() != null) {
        userRepository.findById(customer.getUserId()).ifPresent(user -> {
            enriched.put("fullName", user.getFullName());
            enriched.put("email", user.getEmail());
            enriched.put("phone", user.getPhone());
            enriched.put("avatarUrl", user.getAvatarUrl());
        });
    }
    return enriched;
}
```

- [ ] **Step 4: Update list() to return enriched customers**

Replace the `list()` method return type and body in `CustomerService.java`:

```java
public List<Map<String, Object>> list(String tag, String status, Integer minScore) {
    List<Customer> customers;
    if (tag != null) {
        customers = customerRepository.findByTagsContaining(tag);
    } else if (status != null) {
        customers = customerRepository.findByStatus(CustomerStatus.valueOf(status.toUpperCase()));
    } else if (minScore != null) {
        customers = customerRepository.findByScoreGreaterThanEqual(minScore);
    } else {
        customers = customerRepository.findAll();
    }
    return customers.stream().map(this::enrichCustomer).toList();
}
```

Update `CustomerController.list()` return type to match:

```java
@GetMapping
public ResponseEntity<List<Map<String, Object>>> list(
        @RequestParam(required = false) String tag,
        @RequestParam(required = false) String status,
        @RequestParam(required = false) Integer minScore) {
    return ResponseEntity.ok(customerService.list(tag, status, minScore));
}
```

- [ ] **Step 5: Update getTimeline to include user details**

In `CustomerService.getTimeline()`, add user info:

```java
public Map<String, Object> getTimeline(String id) {
    Customer customer = getById(id);
    Map<String, Object> timeline = new HashMap<>();
    timeline.put("customer", enrichCustomer(customer));

    if (customer.getUserId() != null) {
        List<String> tags = customer.getTags();
        var messages = messageRepository.findInbox(customer.getUserId(),
                tags != null ? tags : List.of(),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        timeline.put("messages", messages);
    }

    timeline.put("notes", customer.getNotes());
    return timeline;
}
```

- [ ] **Step 6: Verify backend compiles and runs**

Run:
```bash
cd backend && ./mvnw compile -q
```
Expected: BUILD SUCCESS

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/wtc/chatapp/controller/MessageController.java backend/src/main/java/com/wtc/chatapp/service/MessageService.java backend/src/main/java/com/wtc/chatapp/service/CustomerService.java backend/src/main/java/com/wtc/chatapp/controller/CustomerController.java
git commit -m "feat(backend): add sent messages endpoint and enrich customer responses with user details"
```

---

### Task 2: iOS Models — Customer, Campaign, Segment

**Files:**
- Create: `WTCChatApp/Models/Customer.swift`
- Create: `WTCChatApp/Models/Campaign.swift`
- Create: `WTCChatApp/Models/Segment.swift`

- [ ] **Step 1: Create Customer.swift**

```swift
import Foundation

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
    var avatarUrl: String?
    var createdAt: Date?

    var displayName: String {
        fullName ?? email ?? "Cliente"
    }

    var initials: String {
        let parts = (fullName ?? "").split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String((fullName ?? "?").prefix(1)).uppercased()
    }

    var statusColor: Color {
        switch status.uppercased() {
        case "ACTIVE": return Color(red: 0.13, green: 0.77, blue: 0.37)
        case "INACTIVE": return Color(red: 0.58, green: 0.64, blue: 0.72)
        case "PENDING": return Theme.warning
        default: return Color(red: 0.58, green: 0.64, blue: 0.72)
        }
    }

    var scoreColor: Color {
        if score >= 70 { return Theme.success }
        if score >= 40 { return Theme.warning }
        return Theme.danger
    }
}

struct CustomerNote: Codable {
    let text: String
    let createdBy: String
    let createdAt: String
}

struct TimelineResponse: Codable {
    let customer: Customer
    let messages: [Message]
    let notes: [CustomerNote]?
}

enum TimelineEntry: Identifiable {
    case message(Message)
    case note(CustomerNote)

    var id: String {
        switch self {
        case .message(let m): return m.id.uuidString
        case .note(let n): return "note-\(n.createdAt)-\(n.text.prefix(10))"
        }
    }

    var date: Date {
        switch self {
        case .message(let m): return m.createdAt
        case .note(let n):
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: n.createdAt) ?? Date.distantPast
        }
    }

    var title: String {
        switch self {
        case .message(let m): return m.content.title
        case .note(_): return "Nota do operador"
        }
    }

    var subtitle: String {
        switch self {
        case .message(let m):
            return m.isRead ? "Recebida e lida" : "Recebida"
        case .note(let n): return n.text
        }
    }

    var icon: String {
        switch self {
        case .message(let m):
            return m.type == .campaign ? "megaphone.fill" : "message.fill"
        case .note(_): return "note.text"
        }
    }

    var iconColor: Color {
        switch self {
        case .message(_): return Theme.primary
        case .note(_): return Theme.warning
        }
    }
}
```

Note: This file needs `import SwiftUI` for Color references.

- [ ] **Step 2: Create Campaign.swift**

```swift
import Foundation

struct Campaign: Codable, Identifiable {
    let id: String
    var name: String
    var segmentId: String?
    var content: MessageContent
    var deeplink: String?
    var status: String
    var sentAt: Date?
    var sentBy: String?
    var messageCount: Int?
    var createdAt: Date

    var isDraft: Bool { status == "DRAFT" }
    var isSent: Bool { status == "SENT" }
}
```

- [ ] **Step 3: Create Segment.swift**

```swift
import Foundation

struct Segment: Codable, Identifiable {
    let id: String
    var name: String
    var description: String?
    var tags: [String]
    var createdBy: String?
    var createdAt: Date?
}
```

- [ ] **Step 4: Commit**

```bash
git add WTCChatApp/Models/Customer.swift WTCChatApp/Models/Campaign.swift WTCChatApp/Models/Segment.swift
git commit -m "feat(ios): add Customer, Campaign, Segment models"
```

---

### Task 3: Modify Profile + AuthViewModel for Role

**Files:**
- Modify: `WTCChatApp/Models/Profile.swift`
- Modify: `WTCChatApp/ViewModels/AuthViewModel.swift`

- [ ] **Step 1: Add role to Profile model**

In `Profile.swift`, add `role` property after `status`:

```swift
struct Profile: Codable, Identifiable {
    let id: UUID
    var fullName: String
    var email: String
    var phone: String?
    var avatarUrl: String?
    var tags: [String]
    var status: String
    var role: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case phone
        case avatarUrl = "avatar_url"
        case tags
        case status
        case role
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), fullName: String, email: String, phone: String? = nil,
         avatarUrl: String? = nil, tags: [String] = [], status: String = "active",
         role: String = "CLIENT", createdAt: Date = Date()) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.avatarUrl = avatarUrl
        self.tags = tags
        self.status = status
        self.role = role
        self.createdAt = createdAt
    }

    var isOperator: Bool { role == "OPERATOR" }
}
```

- [ ] **Step 2: Update AuthViewModel to populate role**

In `AuthViewModel.swift`, update the `signIn` method's Profile construction (around line 58):

```swift
currentProfile = Profile(
    id: UUID(uuidString: response.userId) ?? UUID(),
    fullName: response.fullName,
    email: response.email,
    phone: response.phone,
    avatarUrl: response.avatarUrl,
    tags: response.tags ?? [],
    status: response.status ?? "active",
    role: response.role,
    createdAt: Date()
)
```

Also update `fetchProfile()` in `APIService.swift` (line 106) to pass role:

```swift
func fetchProfile() async throws -> Profile {
    guard let userId = currentUserId else { throw APIError.notAuthenticated }
    let response: AuthResponse = try await request("POST", path: "/auth/refresh",
                                                    body: ["refresh_token": refreshToken ?? ""])
    storeAuth(response)
    return Profile(
        id: UUID(uuidString: response.userId) ?? UUID(),
        fullName: response.fullName,
        email: response.email,
        phone: response.phone,
        avatarUrl: response.avatarUrl,
        tags: response.tags ?? [],
        status: response.status ?? "active",
        role: response.role,
        createdAt: Date()
    )
}
```

- [ ] **Step 3: Commit**

```bash
git add WTCChatApp/Models/Profile.swift WTCChatApp/ViewModels/AuthViewModel.swift WTCChatApp/Services/APIService.swift
git commit -m "feat(ios): add role to Profile and populate from AuthResponse"
```

---

### Task 4: APIService — OPERATOR Endpoint Methods

**Files:**
- Modify: `WTCChatApp/Services/APIService.swift`

- [ ] **Step 1: Add all 10 OPERATOR methods**

Add after the existing Notifications section (after line 145) in `APIService.swift`:

```swift
// MARK: - Customers (OPERATOR)

func fetchCustomers() async throws -> [Customer] {
    return try await request("GET", path: "/customers")
}

func fetchCustomer(id: String) async throws -> Customer {
    return try await request("GET", path: "/customers/\(id)")
}

func fetchTimeline(customerId: String) async throws -> TimelineResponse {
    return try await request("GET", path: "/customers/\(customerId)/timeline")
}

func addNote(customerId: String, text: String) async throws {
    let body = ["text": text]
    let _: Customer = try await request("POST", path: "/customers/\(customerId)/notes", body: body)
}

// MARK: - Messages (OPERATOR)

func sendMessage(type: String = "chat", recipientId: String? = nil, segmentTags: [String]? = nil, content: MessageContent) async throws -> Message {
    var body: [String: Any] = [
        "type": type,
        "content": [
            "title": content.title,
            "body": content.body
        ] as [String: Any]
    ]
    if let recipientId = recipientId { body["recipient_id"] = recipientId }
    if let segmentTags = segmentTags { body["segment_tags"] = segmentTags }
    if let imageUrl = content.imageUrl {
        var contentDict = body["content"] as! [String: Any]
        contentDict["image_url"] = imageUrl
        body["content"] = contentDict
    }
    if let buttons = content.buttons {
        var contentDict = body["content"] as! [String: Any]
        contentDict["buttons"] = buttons.map { ["label": $0.label, "action": $0.action] }
        body["content"] = contentDict
    }
    return try await requestRaw("POST", path: "/messages", jsonBody: body)
}

func fetchSentMessages() async throws -> [Message] {
    guard let userId = currentUserId else { throw APIError.notAuthenticated }
    return try await request("GET", path: "/messages/sent/\(userId)")
}

// MARK: - Campaigns (OPERATOR)

func fetchCampaigns() async throws -> [Campaign] {
    return try await request("GET", path: "/campaigns")
}

func createCampaign(name: String, segmentId: String, content: MessageContent, deeplink: String? = nil) async throws -> Campaign {
    var body: [String: Any] = [
        "name": name,
        "segment_id": segmentId,
        "content": [
            "title": content.title,
            "body": content.body
        ] as [String: Any]
    ]
    if let deeplink = deeplink { body["deeplink"] = deeplink }
    if let imageUrl = content.imageUrl {
        var contentDict = body["content"] as! [String: Any]
        contentDict["image_url"] = imageUrl
        body["content"] = contentDict
    }
    return try await requestRaw("POST", path: "/campaigns", jsonBody: body)
}

func sendCampaign(id: String) async throws -> Campaign {
    return try await request("POST", path: "/campaigns/\(id)/send")
}

// MARK: - Segments (OPERATOR)

func fetchSegments() async throws -> [Segment] {
    return try await request("GET", path: "/segments")
}
```

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/Services/APIService.swift
git commit -m "feat(ios): add 10 OPERATOR API endpoint methods"
```

---

### Task 5: CRMViewModel

**Files:**
- Create: `WTCChatApp/ViewModels/CRMViewModel.swift`

- [ ] **Step 1: Create CRMViewModel**

```swift
import Foundation
import SwiftUI
import Combine

@MainActor
class CRMViewModel: ObservableObject {
    @Published var customers: [Customer] = []
    @Published var filteredCustomers: [Customer] = []
    @Published var searchText = ""
    @Published var selectedTagFilter: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var timeline: [TimelineEntry] = []
    @Published var isLoadingTimeline = false

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()

    var availableTags: [String] {
        Array(Set(customers.flatMap { $0.tags })).sorted()
    }

    init() {
        setupSearchAndFilter()
    }

    private func setupSearchAndFilter() {
        Publishers.CombineLatest3($customers, $searchText, $selectedTagFilter)
            .map { customers, search, tagFilter -> [Customer] in
                var filtered = customers

                if let tag = tagFilter {
                    filtered = filtered.filter { $0.tags.contains(tag) }
                }

                if !search.isEmpty {
                    filtered = filtered.filter { customer in
                        (customer.fullName ?? "").localizedCaseInsensitiveContains(search) ||
                        (customer.email ?? "").localizedCaseInsensitiveContains(search)
                    }
                }

                return filtered
            }
            .assign(to: &$filteredCustomers)
    }

    func fetchCustomers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            customers = try await apiService.fetchCustomers()
        } catch {
            errorMessage = "Erro ao carregar clientes: \(error.localizedDescription)"
        }
    }

    func fetchTimeline(customerId: String) async {
        isLoadingTimeline = true
        defer { isLoadingTimeline = false }

        do {
            let response = try await apiService.fetchTimeline(customerId: customerId)
            var entries: [TimelineEntry] = response.messages.map { .message($0) }
            if let notes = response.notes {
                entries.append(contentsOf: notes.map { .note($0) })
            }
            timeline = entries.sorted { $0.date > $1.date }
        } catch {
            errorMessage = "Erro ao carregar timeline: \(error.localizedDescription)"
        }
    }

    func addNote(customerId: String, text: String) async {
        do {
            try await apiService.addNote(customerId: customerId, text: text)
            await fetchTimeline(customerId: customerId)
        } catch {
            errorMessage = "Erro ao adicionar nota: \(error.localizedDescription)"
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/ViewModels/CRMViewModel.swift
git commit -m "feat(ios): add CRMViewModel with search, filter, timeline, notes"
```

---

### Task 6: CampaignViewModel

**Files:**
- Create: `WTCChatApp/ViewModels/CampaignViewModel.swift`

- [ ] **Step 1: Create CampaignViewModel**

```swift
import Foundation
import SwiftUI
import Combine

enum CampaignFilter: String, CaseIterable {
    case all = "Todas"
    case draft = "Rascunho"
    case sent = "Enviadas"
}

@MainActor
class CampaignViewModel: ObservableObject {
    @Published var campaigns: [Campaign] = []
    @Published var filteredCampaigns: [Campaign] = []
    @Published var segments: [Segment] = []
    @Published var sentMessages: [Message] = []
    @Published var filteredSentMessages: [Message] = []
    @Published var selectedFilter: CampaignFilter = .all
    @Published var messageFilter: MessagesViewModel.MessageFilter = .all
    @Published var messageSearchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupCampaignFilter()
        setupMessageFilter()
    }

    private func setupCampaignFilter() {
        Publishers.CombineLatest($campaigns, $selectedFilter)
            .map { campaigns, filter -> [Campaign] in
                switch filter {
                case .all: return campaigns
                case .draft: return campaigns.filter { $0.isDraft }
                case .sent: return campaigns.filter { $0.isSent }
                }
            }
            .assign(to: &$filteredCampaigns)
    }

    private func setupMessageFilter() {
        Publishers.CombineLatest3($sentMessages, $messageSearchText, $messageFilter)
            .map { messages, search, filter -> [Message] in
                var filtered = messages

                switch filter {
                case .all: break
                case .chat: filtered = filtered.filter { $0.type == .chat }
                case .campaign: filtered = filtered.filter { $0.type == .campaign }
                default: break
                }

                if !search.isEmpty {
                    filtered = filtered.filter { message in
                        message.content.title.localizedCaseInsensitiveContains(search) ||
                        message.content.body.localizedCaseInsensitiveContains(search)
                    }
                }

                return filtered
            }
            .assign(to: &$filteredSentMessages)
    }

    func fetchCampaigns() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            campaigns = try await apiService.fetchCampaigns()
        } catch {
            errorMessage = "Erro ao carregar campanhas: \(error.localizedDescription)"
        }
    }

    func fetchSegments() async {
        do {
            segments = try await apiService.fetchSegments()
        } catch {
            errorMessage = "Erro ao carregar segmentos: \(error.localizedDescription)"
        }
    }

    func fetchSentMessages() async {
        do {
            sentMessages = try await apiService.fetchSentMessages()
        } catch {
            errorMessage = "Erro ao carregar mensagens: \(error.localizedDescription)"
        }
    }

    func createCampaign(name: String, segmentId: String, content: MessageContent, deeplink: String?) async -> Campaign? {
        isLoading = true
        defer { isLoading = false }

        do {
            let campaign = try await apiService.createCampaign(name: name, segmentId: segmentId, content: content, deeplink: deeplink)
            await fetchCampaigns()
            return campaign
        } catch {
            errorMessage = "Erro ao criar campanha: \(error.localizedDescription)"
            return nil
        }
    }

    func sendCampaign(id: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let _ = try await apiService.sendCampaign(id: id)
            await fetchCampaigns()
        } catch {
            errorMessage = "Erro ao enviar campanha: \(error.localizedDescription)"
        }
    }

    func sendMessage(type: String = "chat", recipientId: String? = nil, segmentTags: [String]? = nil, content: MessageContent) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let _ = try await apiService.sendMessage(type: type, recipientId: recipientId, segmentTags: segmentTags, content: content)
            return true
        } catch {
            errorMessage = "Erro ao enviar mensagem: \(error.localizedDescription)"
            return false
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/ViewModels/CampaignViewModel.swift
git commit -m "feat(ios): add CampaignViewModel with campaigns, segments, sent messages"
```

---

### Task 7: OperatorTabView + Role Branch in ContentView

**Files:**
- Modify: `WTCChatApp/App/WTCChatAppApp.swift`

- [ ] **Step 1: Add OperatorTabView and role branch**

In `WTCChatAppApp.swift`, update `ContentView` to branch on role (replace the current body):

```swift
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isLoading {
                SplashView()
            } else if authViewModel.isAuthenticated {
                if authViewModel.currentProfile?.isOperator == true {
                    OperatorTabView()
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
    }
}
```

Add the `OperatorTabView` struct before the `NotificationDelegate` class:

```swift
// MARK: - Operator Tab View

struct OperatorTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var crmViewModel = CRMViewModel()
    @StateObject private var campaignViewModel = CampaignViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CustomerListView()
                .environmentObject(authViewModel)
                .environmentObject(crmViewModel)
                .environmentObject(campaignViewModel)
                .tabItem {
                    Label("CRM", systemImage: "person.2.fill")
                }
                .tag(0)

            CampaignListView()
                .environmentObject(authViewModel)
                .environmentObject(campaignViewModel)
                .tabItem {
                    Label("Campanhas", systemImage: "megaphone.fill")
                }
                .tag(1)

            OperatorMessagesView()
                .environmentObject(authViewModel)
                .environmentObject(campaignViewModel)
                .tabItem {
                    Label("Mensagens", systemImage: "message.fill")
                }
                .tag(2)

            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(Theme.primary)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/App/WTCChatAppApp.swift
git commit -m "feat(ios): add OperatorTabView with role-based routing in ContentView"
```

---

### Task 8: CustomerListView

**Files:**
- Create: `WTCChatApp/Views/Operator/CustomerListView.swift`

- [ ] **Step 1: Create CustomerListView**

```swift
import SwiftUI

struct CustomerListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var crmViewModel: CRMViewModel
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var selectedCustomer: Customer?

    var body: some View {
        NavigationView {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    tagFilterChips

                    SearchBar(text: $crmViewModel.searchText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    if crmViewModel.isLoading && crmViewModel.customers.isEmpty {
                        Spacer()
                        ProgressView().scaleEffect(1.1)
                        Spacer()
                    } else if crmViewModel.filteredCustomers.isEmpty {
                        EmptyStateView(
                            icon: "person.2",
                            message: "Nenhum cliente encontrado",
                            subtitle: "Seus clientes aparecerão aqui"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(crmViewModel.filteredCustomers) { customer in
                                    CustomerRowView(customer: customer)
                                        .onTapGesture { selectedCustomer = customer }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .refreshable {
                            await crmViewModel.fetchCustomers()
                        }
                    }
                }
                .navigationTitle("Clientes")
                .navigationBarTitleDisplayMode(.large)

                if let customer = selectedCustomer {
                    NavigationLink(
                        destination: CustomerDetailView(customer: customer)
                            .environmentObject(crmViewModel)
                            .environmentObject(campaignViewModel),
                        isActive: Binding(
                            get: { selectedCustomer != nil },
                            set: { if !$0 { selectedCustomer = nil } }
                        )
                    ) { EmptyView() }
                }
            }
        }
        .task {
            await crmViewModel.fetchCustomers()
        }
    }

    private var tagFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: "Todos", isSelected: crmViewModel.selectedTagFilter == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        crmViewModel.selectedTagFilter = nil
                    }
                }
                ForEach(crmViewModel.availableTags, id: \.self) { tag in
                    FilterChip(title: tag.capitalized, isSelected: crmViewModel.selectedTagFilter == tag) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            crmViewModel.selectedTagFilter = tag
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Customer Row

struct CustomerRowView: View {
    let customer: Customer

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.primaryGradient)
                    .frame(width: Theme.avatarSM, height: Theme.avatarSM)
                Text(customer.initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(customer.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Circle()
                        .fill(customer.statusColor)
                        .frame(width: 8, height: 8)
                }

                HStack(spacing: 4) {
                    ForEach(customer.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.primary.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }

            Spacer()

            Text("\(customer.score)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(customer.scoreColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(customer.scoreColor.opacity(0.1))
                .cornerRadius(10)
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(Theme.cornerMD)
        .modifier(CardShadow())
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/Views/Operator/CustomerListView.swift
git commit -m "feat(ios): add CustomerListView with search, tag filters, compact rows"
```

---

### Task 9: CustomerDetailView

**Files:**
- Create: `WTCChatApp/Views/Operator/CustomerDetailView.swift`

- [ ] **Step 1: Create CustomerDetailView**

```swift
import SwiftUI

struct CustomerDetailView: View {
    let customer: Customer
    @EnvironmentObject var crmViewModel: CRMViewModel
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var showComposeSheet = false
    @State private var showNoteAlert = false
    @State private var noteText = ""

    var body: some View {
        ZStack {
            Theme.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    profileCard
                    timelineSection
                }
                .padding(16)
                .padding(.bottom, 80)
            }
            .refreshable {
                await crmViewModel.fetchTimeline(customerId: customer.id)
            }

            VStack {
                Spacer()
                Button(action: { showNoteAlert = true }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Adicionar Nota")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Theme.primaryGradient)
                    .cornerRadius(Theme.cornerMD)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle(customer.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showComposeSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 12))
                        Text("Enviar")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.primaryGradient)
                    .cornerRadius(Theme.cornerLG)
                }
            }
        }
        .sheet(isPresented: $showComposeSheet) {
            ComposeMessageSheet(preselectedRecipientId: customer.userId, preselectedRecipientName: customer.displayName)
                .environmentObject(campaignViewModel)
        }
        .alert("Adicionar Nota", isPresented: $showNoteAlert) {
            TextField("Escreva sua nota...", text: $noteText)
            Button("Cancelar", role: .cancel) { noteText = "" }
            Button("Salvar") {
                let text = noteText
                noteText = ""
                Task { await crmViewModel.addNote(customerId: customer.id, text: text) }
            }
        }
        .task {
            await crmViewModel.fetchTimeline(customerId: customer.id)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.primaryGradient)
                    .frame(width: 72, height: 72)
                Text(customer.initials)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(customer.displayName)
                .font(.system(size: 20, weight: .bold))
            if let email = customer.email {
                Text(email)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(customer.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Theme.primary.opacity(0.1))
                        .cornerRadius(10)
                }
            }

            Divider().padding(.top, 4)

            HStack {
                statItem(value: "\(customer.score)", label: "Score", color: customer.scoreColor)
                Spacer()
                statItem(value: "\(crmViewModel.timeline.filter { if case .message = $0 { return true }; return false }.count)", label: "Mensagens", color: Theme.primary)
                Spacer()
                statItem(value: "\(crmViewModel.timeline.filter { if case .note = $0 { return true }; return false }.count)", label: "Notas", color: Theme.warning)
            }
            .padding(.horizontal, 8)
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(Theme.cornerMD)
        .modifier(CardShadow())
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timeline")
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 4)

            if crmViewModel.isLoadingTimeline {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.top, 20)
            } else if crmViewModel.timeline.isEmpty {
                EmptyStateView(icon: "clock", message: "Nenhuma atividade", subtitle: "A timeline do cliente aparecerá aqui")
                    .frame(height: 200)
            } else {
                ForEach(crmViewModel.timeline) { entry in
                    TimelineItemView(entry: entry)
                }
            }
        }
    }
}

struct TimelineItemView: View {
    let entry: TimelineEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(entry.iconColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: entry.icon)
                    .font(.system(size: 14))
                    .foregroundColor(entry.iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(entry.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(entry.date.timeAgo())
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 2)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(Theme.cornerMD)
        .modifier(CardShadow())
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/Views/Operator/CustomerDetailView.swift
git commit -m "feat(ios): add CustomerDetailView with 360° profile, timeline, notes"
```

---

### Task 10: SegmentPickerView

**Files:**
- Create: `WTCChatApp/Views/Operator/SegmentPickerView.swift`

- [ ] **Step 1: Create SegmentPickerView**

```swift
import SwiftUI

struct SegmentPickerView: View {
    let segments: [Segment]
    @Binding var selectedSegment: Segment?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(segments) { segment in
                Button(action: {
                    selectedSegment = segment
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(segment.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            if let description = segment.description {
                                Text(description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            HStack(spacing: 4) {
                                ForEach(segment.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Theme.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Theme.primary.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        Spacer()
                        if selectedSegment?.id == segment.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(Theme.primary)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
            }
            .navigationTitle("Selecionar Segmento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/Views/Operator/SegmentPickerView.swift
git commit -m "feat(ios): add SegmentPickerView for segment selection"
```

---

### Task 11: ComposeMessageSheet

**Files:**
- Create: `WTCChatApp/Views/Operator/ComposeMessageSheet.swift`

- [ ] **Step 1: Create ComposeMessageSheet**

```swift
import SwiftUI

struct ComposeMessageSheet: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @Environment(\.dismiss) private var dismiss

    var preselectedRecipientId: String? = nil
    var preselectedRecipientName: String? = nil

    @State private var recipientMode = 0 // 0 = Cliente, 1 = Segmento
    @State private var recipientId = ""
    @State private var recipientName = ""
    @State private var selectedSegment: Segment? = nil
    @State private var title = ""
    @State private var body = ""
    @State private var showImageField = false
    @State private var imageUrl = ""
    @State private var isSending = false
    @State private var showSegmentPicker = false

    var canSend: Bool {
        !title.isEmpty && !body.isEmpty &&
        (recipientMode == 0 ? !recipientId.isEmpty : selectedSegment != nil)
    }

    var body_view: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Nova Mensagem")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if preselectedRecipientId == nil {
                        Picker("", selection: $recipientMode) {
                            Text("Cliente").tag(0)
                            Text("Segmento").tag(1)
                        }
                        .pickerStyle(.segmented)
                    }

                    if recipientMode == 0 {
                        if let name = preselectedRecipientName {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(Theme.primary)
                                Text(name)
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                            .cornerRadius(Theme.cornerSM)
                        }
                    } else {
                        Button(action: { showSegmentPicker = true }) {
                            HStack {
                                Text(selectedSegment?.name ?? "Selecionar segmento...")
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedSegment != nil ? .primary : .secondary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                            .cornerRadius(Theme.cornerSM)
                            .overlay(RoundedRectangle(cornerRadius: Theme.cornerSM).stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1))
                        }
                    }

                    LabeledField(label: "Título", text: $title, placeholder: "Título da mensagem")
                    LabeledTextEditor(label: "Mensagem", text: $body, placeholder: "Escreva sua mensagem...")

                    HStack(spacing: 8) {
                        Button(action: { withAnimation { showImageField.toggle() } }) {
                            HStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .font(.system(size: 12))
                                Text("Imagem")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(Theme.cornerSM)
                        }
                    }

                    if showImageField {
                        LabeledField(label: "URL da imagem", text: $imageUrl, placeholder: "https://...")
                    }

                    Button(action: { Task { await send() } }) {
                        HStack {
                            if isSending {
                                ProgressView().tint(.white)
                            } else {
                                Text("Enviar Mensagem")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(canSend && !isSending ? Theme.primaryGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(Theme.cornerMD)
                    }
                    .disabled(!canSend || isSending)
                }
                .padding(16)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.large])
        .sheet(isPresented: $showSegmentPicker) {
            SegmentPickerView(segments: campaignViewModel.segments, selectedSegment: $selectedSegment)
        }
        .onAppear {
            if let id = preselectedRecipientId {
                recipientId = id
                recipientMode = 0
            }
            Task { await campaignViewModel.fetchSegments() }
        }
    }

    private func send() async {
        isSending = true
        defer { isSending = false }

        let content = MessageContent(
            title: title,
            body: body,
            imageUrl: imageUrl.isEmpty ? nil : imageUrl
        )

        let success: Bool
        if recipientMode == 0 {
            let rid = preselectedRecipientId ?? recipientId
            success = await campaignViewModel.sendMessage(type: "chat", recipientId: rid, content: content)
        } else {
            let tags = selectedSegment?.tags ?? []
            success = await campaignViewModel.sendMessage(type: "chat", segmentTags: tags, content: content)
        }

        if success {
            dismiss()
        }
    }
}

// MARK: - Reusable Form Fields

struct LabeledField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .font(.system(size: 14))
        }
        .padding(12)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .cornerRadius(Theme.cornerSM)
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerSM).stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1))
    }
}

struct LabeledTextEditor: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
            }
        }
        .padding(12)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .cornerRadius(Theme.cornerSM)
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerSM).stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1))
    }
}
```

Note: The `body` property is named `body_view` in the struct due to the `body` state variable collision. This needs to be handled — rename the `@State` variable to `messageBody` instead. Let me fix that:

Replace `@State private var body = ""` with `@State private var messageBody = ""` and all references to `body` (the state var) to `messageBody` throughout. The SwiftUI `body` computed property stays as `body`.

Actually, let me rewrite the struct properly. Replace the entire `ComposeMessageSheet` with `body` as the SwiftUI property and `messageBody` as the state:

The `@State private var body` should be `@State private var messageBody`. And all references like `!body.isEmpty` become `!messageBody.isEmpty`, the `LabeledTextEditor` binding becomes `$messageBody`, and `body: body` in `MessageContent` becomes `body: messageBody`.

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/Views/Operator/ComposeMessageSheet.swift
git commit -m "feat(ios): add ComposeMessageSheet with client/segment toggle, progressive disclosure"
```

---

### Task 12: CreateCampaignSheet

**Files:**
- Create: `WTCChatApp/Views/Operator/CreateCampaignSheet.swift`

- [ ] **Step 1: Create CreateCampaignSheet**

```swift
import SwiftUI

struct CreateCampaignSheet: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @Environment(\.dismiss) private var dismiss

    var editingCampaign: Campaign? = nil

    @State private var name = ""
    @State private var selectedSegment: Segment? = nil
    @State private var messageTitle = ""
    @State private var messageBody = ""
    @State private var deeplink = ""
    @State private var isSaving = false
    @State private var showSegmentPicker = false
    @State private var showSendConfirmation = false

    var canSave: Bool {
        !name.isEmpty && selectedSegment != nil && !messageTitle.isEmpty && !messageBody.isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Nova Campanha")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LabeledField(label: "Nome da campanha", text: $name, placeholder: "Ex: Black Friday 2026")

                    Button(action: { showSegmentPicker = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Segmento")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text(selectedSegment?.name ?? "Selecionar segmento...")
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedSegment != nil ? .primary : .secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                        .cornerRadius(Theme.cornerSM)
                        .overlay(RoundedRectangle(cornerRadius: Theme.cornerSM).stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1))
                    }

                    LabeledField(label: "Título da mensagem", text: $messageTitle, placeholder: "Título que o cliente verá")
                    LabeledTextEditor(label: "Corpo da mensagem", text: $messageBody, placeholder: "Escreva o conteúdo da campanha...")
                    LabeledField(label: "Deeplink (opcional)", text: $deeplink, placeholder: "deeplink://products")

                    HStack(spacing: 10) {
                        Button(action: { Task { await saveDraft() } }) {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.secondary)
                                } else {
                                    Text("Salvar Rascunho")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(Theme.cornerMD)
                        }
                        .disabled(!canSave || isSaving)

                        Button(action: { showSendConfirmation = true }) {
                            Text("Criar e Enviar")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(canSave && !isSaving ? Theme.campaignGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(Theme.cornerMD)
                        }
                        .disabled(!canSave || isSaving)
                    }
                }
                .padding(16)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.large])
        .sheet(isPresented: $showSegmentPicker) {
            SegmentPickerView(segments: campaignViewModel.segments, selectedSegment: $selectedSegment)
        }
        .alert("Enviar Campanha?", isPresented: $showSendConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Enviar") { Task { await createAndSend() } }
        } message: {
            Text("A campanha será enviada imediatamente para o segmento \"\(selectedSegment?.name ?? "")\".")
        }
        .onAppear {
            Task { await campaignViewModel.fetchSegments() }
            if let campaign = editingCampaign {
                name = campaign.name
                messageTitle = campaign.content.title
                messageBody = campaign.content.body
                deeplink = campaign.deeplink ?? ""
            }
        }
    }

    private func saveDraft() async {
        guard let segmentId = selectedSegment?.id else { return }
        isSaving = true
        defer { isSaving = false }

        let content = MessageContent(title: messageTitle, body: messageBody)
        let _ = await campaignViewModel.createCampaign(
            name: name, segmentId: segmentId, content: content,
            deeplink: deeplink.isEmpty ? nil : deeplink
        )
        dismiss()
    }

    private func createAndSend() async {
        guard let segmentId = selectedSegment?.id else { return }
        isSaving = true
        defer { isSaving = false }

        let content = MessageContent(title: messageTitle, body: messageBody)
        if let campaign = await campaignViewModel.createCampaign(
            name: name, segmentId: segmentId, content: content,
            deeplink: deeplink.isEmpty ? nil : deeplink
        ) {
            await campaignViewModel.sendCampaign(id: campaign.id)
        }
        dismiss()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/Views/Operator/CreateCampaignSheet.swift
git commit -m "feat(ios): add CreateCampaignSheet with draft save and send confirmation"
```

---

### Task 13: CampaignListView

**Files:**
- Create: `WTCChatApp/Views/Operator/CampaignListView.swift`

- [ ] **Step 1: Create CampaignListView**

```swift
import SwiftUI

struct CampaignListView: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var showCreateSheet = false
    @State private var editingCampaign: Campaign? = nil
    @State private var sendConfirmationCampaign: Campaign? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    campaignFilterChips

                    if campaignViewModel.isLoading && campaignViewModel.campaigns.isEmpty {
                        Spacer()
                        ProgressView().scaleEffect(1.1)
                        Spacer()
                    } else if campaignViewModel.filteredCampaigns.isEmpty {
                        EmptyStateView(
                            icon: "megaphone",
                            message: "Nenhuma campanha",
                            subtitle: "Crie sua primeira campanha"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(campaignViewModel.filteredCampaigns) { campaign in
                                    CampaignCardView(
                                        campaign: campaign,
                                        onSend: { sendConfirmationCampaign = campaign },
                                        onEdit: { editingCampaign = campaign }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .refreshable {
                            await campaignViewModel.fetchCampaigns()
                        }
                    }
                }
                .navigationTitle("Campanhas")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showCreateSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Nova")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.primaryGradient)
                            .cornerRadius(Theme.cornerMD)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCampaignSheet()
                .environmentObject(campaignViewModel)
        }
        .sheet(item: $editingCampaign) { campaign in
            CreateCampaignSheet(editingCampaign: campaign)
                .environmentObject(campaignViewModel)
        }
        .alert("Enviar Campanha?", isPresented: Binding(
            get: { sendConfirmationCampaign != nil },
            set: { if !$0 { sendConfirmationCampaign = nil } }
        )) {
            Button("Cancelar", role: .cancel) {}
            Button("Enviar") {
                if let campaign = sendConfirmationCampaign {
                    Task { await campaignViewModel.sendCampaign(id: campaign.id) }
                }
            }
        } message: {
            Text("Enviar a campanha \"\(sendConfirmationCampaign?.name ?? "")\" agora?")
        }
        .task {
            await campaignViewModel.fetchCampaigns()
        }
    }

    private var campaignFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CampaignFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: campaignViewModel.selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            campaignViewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

struct CampaignCardView: View {
    let campaign: Campaign
    var onSend: () -> Void
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(campaign.isSent ? "ENVIADA" : "RASCUNHO")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(campaign.isSent ? Theme.success : Theme.warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background((campaign.isSent ? Theme.success : Theme.warning).opacity(0.1))
                        .cornerRadius(10)

                    Text(campaign.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Segmento: \(campaign.segmentId ?? "-")")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if campaign.isSent, let count = campaign.messageCount {
                    VStack(spacing: 0) {
                        Text("\(count)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Theme.primary)
                        Text("enviadas")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)

            if campaign.isSent {
                Divider().padding(.horizontal, 16)
                HStack {
                    if let sentAt = campaign.sentAt {
                        Text("Enviada em \(sentAt.formatted(date: .numeric, time: .omitted))")
                    }
                    Spacer()
                    if let sentBy = campaign.sentBy {
                        Text("por \(sentBy)")
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            if campaign.isDraft {
                Divider().padding(.horizontal, 16)
                HStack(spacing: 8) {
                    Button(action: onSend) {
                        Text("Enviar Agora")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Theme.primaryGradient)
                            .cornerRadius(10)
                    }
                    Button(action: onEdit) {
                        Text("Editar")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(10)
                    }
                }
                .padding(16)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(Theme.cornerMD)
        .overlay(
            campaign.isDraft ?
                RoundedRectangle(cornerRadius: Theme.cornerMD)
                    .inset(by: 0.5)
                    .stroke(Theme.warning, lineWidth: 0)
                    .overlay(
                        HStack {
                            Rectangle().fill(Theme.warning).frame(width: 3)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerMD))
                    )
                : nil
        )
        .modifier(CardShadow())
    }
}

extension Campaign: Hashable {
    static func == (lhs: Campaign, rhs: Campaign) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
```

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/Views/Operator/CampaignListView.swift
git commit -m "feat(ios): add CampaignListView with status badges, draft actions, send confirmation"
```

---

### Task 14: OperatorMessagesView

**Files:**
- Create: `WTCChatApp/Views/Operator/OperatorMessagesView.swift`

- [ ] **Step 1: Create OperatorMessagesView**

```swift
import SwiftUI

struct OperatorMessagesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var showComposeSheet = false
    @State private var selectedMessage: Message?

    var body: some View {
        NavigationView {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    messageFilterChips

                    SearchBar(text: $campaignViewModel.messageSearchText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    if campaignViewModel.isLoading && campaignViewModel.sentMessages.isEmpty {
                        Spacer()
                        ProgressView().scaleEffect(1.1)
                        Spacer()
                    } else if campaignViewModel.filteredSentMessages.isEmpty {
                        EmptyStateView(
                            icon: "paperplane",
                            message: "Nenhuma mensagem enviada",
                            subtitle: "Suas mensagens aparecerão aqui"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(campaignViewModel.filteredSentMessages) { message in
                                    SentMessageRowView(message: message)
                                        .onTapGesture { selectedMessage = message }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .refreshable {
                            await campaignViewModel.fetchSentMessages()
                        }
                    }
                }
                .navigationTitle("Mensagens")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showComposeSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Nova")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.primaryGradient)
                            .cornerRadius(Theme.cornerMD)
                        }
                    }
                }

                if let message = selectedMessage {
                    NavigationLink(
                        destination: MessageDetailView(message: message)
                            .environmentObject(MessagesViewModel()),
                        isActive: Binding(
                            get: { selectedMessage != nil },
                            set: { if !$0 { selectedMessage = nil } }
                        )
                    ) { EmptyView() }
                }
            }
        }
        .sheet(isPresented: $showComposeSheet) {
            ComposeMessageSheet()
                .environmentObject(campaignViewModel)
        }
        .task {
            await campaignViewModel.fetchSentMessages()
        }
    }

    private var messageFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach([MessagesViewModel.MessageFilter.all, .chat, .campaign], id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter == .chat ? "message" : (filter == .campaign ? "megaphone" : nil),
                        isSelected: campaignViewModel.messageFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            campaignViewModel.messageFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

struct SentMessageRowView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(message.type == .campaign
                          ? LinearGradient(colors: [Theme.campaignOrange.opacity(0.15), Theme.campaignRed.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Theme.primary.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 40, height: 40)
                Image(systemName: message.type == .campaign ? "megaphone.fill" : "message.fill")
                    .font(.system(size: 16))
                    .foregroundColor(message.type == .campaign ? Theme.campaignOrange : Theme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.content.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    Text(message.createdAt.timeAgo())
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Text(message.content.body)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(message.type == .campaign ? "CAMPANHA" : "CHAT")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(message.type == .campaign ? Theme.warning : Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background((message.type == .campaign ? Theme.warning : Theme.accent).opacity(0.1))
                        .cornerRadius(8)

                    if let tags = message.segmentTags, !tags.isEmpty {
                        Text("→ Segmento: \(tags.joined(separator: ", "))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else if message.recipientId != nil {
                        Text("→ Cliente")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if message.isRead {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                            Text("Lida")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Theme.success)
                    } else {
                        HStack(spacing: 2) {
                            Circle().stroke(Color.secondary, lineWidth: 1).frame(width: 8, height: 8)
                            Text("Não lida")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(Theme.cornerMD)
        .modifier(CardShadow())
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/Views/Operator/OperatorMessagesView.swift
git commit -m "feat(ios): add OperatorMessagesView with sent message history and filters"
```

---

### Task 15: Build Verification + XcodeGen

**Files:**
- Verify: `project.yml` (no changes needed — sources wildcard includes new files)
- Run: XcodeGen + build

- [ ] **Step 1: Verify project.yml sources config**

The existing `project.yml` uses `path: WTCChatApp` which includes all files recursively. New files under `WTCChatApp/Views/Operator/` and `WTCChatApp/Models/` are automatically included. No changes needed.

- [ ] **Step 2: Regenerate Xcode project**

Run:
```bash
cd /Users/arthurgranja/github/Challenge-WTC/.claude/worktrees/modest-meitner-1cb371 && xcodegen generate
```
Expected: `⚙️  Generating plists...` then `Created project WTCChatApp.xcodeproj`

- [ ] **Step 3: Build the project**

Run:
```bash
xcodebuild -project WTCChatApp.xcodeproj -scheme WTCChatApp -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

If build fails, fix compile errors and re-run.

- [ ] **Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix(ios): resolve build errors from operator views integration"
```

---

### Task 16: Manual Smoke Test

- [ ] **Step 1: Start the backend**

```bash
cd backend && ./mvnw spring-boot:run &
```
Wait for "Started WtcChatAppApplication" in logs.

- [ ] **Step 2: Run the app in simulator**

```bash
cd /Users/arthurgranja/github/Challenge-WTC/.claude/worktrees/modest-meitner-1cb371 && xcodebuild -project WTCChatApp.xcodeproj -scheme WTCChatApp -destination 'platform=iOS Simulator,name=iPhone 16' build
xcrun simctl boot "iPhone 16" 2>/dev/null; xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/WTCChatApp.app && xcrun simctl launch booted com.wtc.chatapp
```

- [ ] **Step 3: Test OPERATOR flow**

1. Login with `admin@wtc.com` / `admin123`
2. Verify OperatorTabView shows 4 tabs: CRM, Campanhas, Mensagens, Perfil
3. CRM tab: verify customer list loads with names, tags, scores
4. Tap a customer → verify detail view with timeline
5. Add a note → verify it appears in timeline
6. Tap "Enviar" → verify compose sheet opens pre-filled
7. Campanhas tab: verify campaigns load with correct status badges
8. Tap "+ Nova" → verify create campaign sheet
9. Mensagens tab: verify sent messages load
10. Profile tab: verify existing ProfileView works

- [ ] **Step 4: Test CLIENT flow (regression)**

1. Login with `joao@test.com` / `test123`
2. Verify MainTabView shows (NOT OperatorTabView)
3. Verify messages, notifications, profile all work as before

- [ ] **Step 5: Final commit if any fixes**

```bash
git add -A
git commit -m "fix(ios): polish operator views after smoke testing"
```
