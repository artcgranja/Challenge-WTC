# Sprint 2 — WTC Chat App Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Java Spring Boot + MongoDB backend for the WTC CRM Chat platform and rewire the iOS SwiftUI app to consume it, replacing Supabase.

**Architecture:** Spring Boot 3.3 REST API with JWT auth, Spring Data MongoDB, STOMP WebSocket for real-time. Backend outputs snake_case JSON (via Jackson config) to minimize iOS model changes. MongoDB stores UUID strings as document IDs for compatibility with the iOS UUID type.

**Tech Stack:** Java 17, Spring Boot 3.3, Spring Security, Spring Data MongoDB, Spring WebSocket (STOMP), Jackson, BCrypt, JJWT

**Spec:** `docs/superpowers/specs/2026-05-18-sprint2-backend-design.md`

**DEADLINE: 2026-05-19 23:00 — core-first, skip tests and polish.**

---

## File Structure

### Backend (`backend/`)

```
backend/
├── pom.xml
├── src/main/java/com/wtc/chatapp/
│   ├── WtcChatApplication.java
│   ├── config/
│   │   ├── SecurityConfig.java
│   │   ├── WebSocketConfig.java
│   │   └── JacksonConfig.java
│   ├── security/
│   │   ├── JwtUtil.java
│   │   ├── JwtAuthFilter.java
│   │   └── CustomUserDetailsService.java
│   ├── model/
│   │   ├── User.java
│   │   ├── Customer.java
│   │   ├── Segment.java
│   │   ├── Message.java
│   │   ├── Campaign.java
│   │   ├── Notification.java
│   │   └── AuditLog.java
│   ├── repository/
│   │   ├── UserRepository.java
│   │   ├── CustomerRepository.java
│   │   ├── SegmentRepository.java
│   │   ├── MessageRepository.java
│   │   ├── CampaignRepository.java
│   │   ├── NotificationRepository.java
│   │   └── AuditLogRepository.java
│   ├── dto/
│   │   ├── LoginRequest.java
│   │   ├── RegisterRequest.java
│   │   ├── AuthResponse.java
│   │   ├── CustomerRequest.java
│   │   ├── SegmentRequest.java
│   │   ├── MessageRequest.java
│   │   ├── CampaignRequest.java
│   │   └── NoteRequest.java
│   ├── service/
│   │   ├── AuthService.java
│   │   ├── CustomerService.java
│   │   ├── SegmentService.java
│   │   ├── MessageService.java
│   │   ├── CampaignService.java
│   │   ├── NotificationService.java
│   │   └── AuditService.java
│   ├── controller/
│   │   ├── AuthController.java
│   │   ├── CustomerController.java
│   │   ├── SegmentController.java
│   │   ├── MessageController.java
│   │   ├── CampaignController.java
│   │   ├── NotificationController.java
│   │   └── AuditLogController.java
│   └── websocket/
│       └── WebSocketService.java
├── src/main/resources/
│   └── application.yml
```

### iOS Changes (`WTCChatApp/`)

```
WTCChatApp/
├── Services/
│   ├── APIService.swift          (NEW — replaces SupabaseService)
│   └── WebSocketService.swift    (NEW — replaces RealtimeService)
├── Models/
│   ├── Message.swift             (MODIFY — String id, add status field)
│   ├── Profile.swift             (MODIFY — String id, camelCase keys)
│   └── Notification.swift        (MODIFY — String id, camelCase keys)
├── ViewModels/
│   ├── AuthViewModel.swift       (MODIFY — use APIService + JWT)
│   ├── MessagesViewModel.swift   (MODIFY — use APIService)
│   └── NotificationsViewModel.swift (MODIFY — use APIService)
└── Utils/
    └── Constants.swift           (MODIFY — API base URL instead of Supabase)
```

---

## Phase 1: Backend Foundation

### Task 1: Project Scaffold

**Files:**
- Create: `backend/pom.xml`
- Create: `backend/src/main/java/com/wtc/chatapp/WtcChatApplication.java`
- Create: `backend/src/main/resources/application.yml`
- Create: `backend/src/main/java/com/wtc/chatapp/config/JacksonConfig.java`

- [ ] **Step 1: Create `backend/pom.xml`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.5</version>
        <relativeTo/>
    </parent>
    <groupId>com.wtc</groupId>
    <artifactId>chatapp</artifactId>
    <version>1.0.0</version>
    <name>WTC Chat App Backend</name>
    <description>Backend for WTC CRM Chat Platform</description>
    <properties>
        <java.version>17</java.version>
        <jjwt.version>0.12.6</jjwt.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-mongodb</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-websocket</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-aop</artifactId>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-api</artifactId>
            <version>${jjwt.version}</version>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-impl</artifactId>
            <version>${jjwt.version}</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-jackson</artifactId>
            <version>${jjwt.version}</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

- [ ] **Step 2: Create `application.yml`**

```yaml
server:
  port: 8080

spring:
  data:
    mongodb:
      uri: mongodb://localhost:27017/wtc_chatapp
  jackson:
    property-naming-strategy: SNAKE_CASE
    serialization:
      write-dates-as-timestamps: false
    default-property-inclusion: non_null

jwt:
  secret: wtc-chat-app-secret-key-2026-spring-boot-jwt-authentication
  expiration: 86400000
  refresh-expiration: 604800000

logging:
  level:
    com.wtc.chatapp: DEBUG
```

- [ ] **Step 3: Create `WtcChatApplication.java`**

```java
package com.wtc.chatapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class WtcChatApplication {
    public static void main(String[] args) {
        SpringApplication.run(WtcChatApplication.class, args);
    }
}
```

- [ ] **Step 4: Create `JacksonConfig.java`**

```java
package com.wtc.chatapp.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JacksonConfig {
    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
        mapper.registerModule(new JavaTimeModule());
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        return mapper;
    }
}
```

- [ ] **Step 5: Verify project compiles**

Run: `cd backend && ./mvnw compile` (or `mvn compile` if Maven is installed)
Expected: BUILD SUCCESS

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "feat: scaffold Spring Boot project with MongoDB and JWT dependencies"
```

---

## Phase 2: Models + Security (parallel)

### Task 2: MongoDB Document Models

**Files:**
- Create: `backend/src/main/java/com/wtc/chatapp/model/User.java`
- Create: `backend/src/main/java/com/wtc/chatapp/model/Customer.java`
- Create: `backend/src/main/java/com/wtc/chatapp/model/Segment.java`
- Create: `backend/src/main/java/com/wtc/chatapp/model/Message.java`
- Create: `backend/src/main/java/com/wtc/chatapp/model/Campaign.java`
- Create: `backend/src/main/java/com/wtc/chatapp/model/Notification.java`
- Create: `backend/src/main/java/com/wtc/chatapp/model/AuditLog.java`

**Design decisions:**
- All IDs are `String` type, auto-generated as UUIDs via `@Id` + default value in constructor
- Embedded types (MessageContent, ActionButton, Note) are inner static classes or separate simple classes within the same file
- Enums: Role (OPERATOR, CLIENT), MessageType (CHAT, CAMPAIGN), MessageStatus (SENT, DELIVERED, READ, FAILED), CustomerStatus (ACTIVE, INACTIVE, PENDING), CampaignStatus (DRAFT, SENT), NotificationType (MESSAGE, CAMPAIGN, SYSTEM)
- Timestamps use `java.time.Instant`
- Lombok `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor` for brevity

- [ ] **Step 1: Create all enum types as a single file `backend/src/main/java/com/wtc/chatapp/model/Enums.java`**

This file contains: `Role`, `MessageType`, `MessageStatus`, `CustomerStatus`, `CampaignStatus`, `NotificationType` — all as public enums in one file for simplicity.

- [ ] **Step 2: Create `User.java`**

Fields: `id` (String, UUID default), `email` (unique, indexed), `password` (bcrypt hash), `fullName`, `phone`, `avatarUrl`, `role` (Role enum), `tags` (List<String>), `status` (String, default "active"), `createdAt`, `updatedAt`. Collection name: `users`. Add `@Indexed(unique = true)` on email.

IMPORTANT: The `User` model also serves as the profile for CLIENT users. The iOS app's `Profile` model maps to this. Include `tags` and `status` fields here so that CLIENT users have their CRM data directly on the user document. This simplifies the iOS integration — login returns the user with profile data.

- [ ] **Step 3: Create `Customer.java`**

Fields: `id`, `userId` (ref to User), `tags` (List<String>), `score` (int, 0-100), `status` (CustomerStatus), `notes` (List<Note> embedded), `segmentIds` (List<String>), `createdAt`, `updatedAt`. Embedded `Note` class: `text`, `createdAt`, `createdBy`.

- [ ] **Step 4: Create `Segment.java`**

Fields: `id`, `name`, `description`, `tags` (List<String>), `createdBy`, `createdAt`, `updatedAt`.

- [ ] **Step 5: Create `Message.java`**

Fields: `id`, `type` (MessageType), `senderId`, `recipientId` (nullable), `segmentTags` (List<String>, nullable), `content` (embedded MessageContent), `status` (MessageStatus), `readAt` (Instant, nullable), `starred` (boolean), `createdAt`. Embedded `MessageContent`: `title`, `body`, `imageUrl`, `buttons` (List<ActionButton>). Embedded `ActionButton`: `label`, `action`.

- [ ] **Step 6: Create `Campaign.java`**

Fields: `id`, `name`, `segmentId`, `content` (MessageContent — same embedded type as Message), `deeplink`, `status` (CampaignStatus), `sentAt`, `sentBy`, `messageCount` (int), `createdAt`.

- [ ] **Step 7: Create `Notification.java`**

Fields: `id`, `userId`, `title`, `body`, `type` (NotificationType), `read` (boolean), `messageId` (nullable), `createdAt`.

- [ ] **Step 8: Create `AuditLog.java`**

Fields: `id`, `userId`, `action` (String: CREATE/READ/UPDATE/DELETE), `resource` (String), `resourceId`, `details`, `ipAddress`, `timestamp`.

- [ ] **Step 9: Commit**

```bash
git add backend/src/main/java/com/wtc/chatapp/model/
git commit -m "feat: add all MongoDB document models and enums"
```

---

### Task 3: JWT Security

**Files:**
- Create: `backend/src/main/java/com/wtc/chatapp/security/JwtUtil.java`
- Create: `backend/src/main/java/com/wtc/chatapp/security/JwtAuthFilter.java`
- Create: `backend/src/main/java/com/wtc/chatapp/security/CustomUserDetailsService.java`
- Create: `backend/src/main/java/com/wtc/chatapp/config/SecurityConfig.java`
- Create: `backend/src/main/java/com/wtc/chatapp/repository/UserRepository.java`

- [ ] **Step 1: Create `UserRepository.java`**

```java
package com.wtc.chatapp.repository;

import com.wtc.chatapp.model.User;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface UserRepository extends MongoRepository<User, String> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
```

- [ ] **Step 2: Create `JwtUtil.java`**

Utility class that:
- Generates access tokens (24h) with claims: `sub` = userId, `role` = user role, `email` = user email
- Generates refresh tokens (7d)
- Validates tokens and extracts claims
- Uses `@Value("${jwt.secret}")` for the secret key
- Uses JJWT library (io.jsonwebtoken)

Key methods:
```java
public String generateToken(User user)
public String generateRefreshToken(User user)
public String extractUserId(String token)
public String extractRole(String token)
public boolean isTokenValid(String token)
```

- [ ] **Step 3: Create `CustomUserDetailsService.java`**

Implements `UserDetailsService`. Loads user by email from `UserRepository`. Returns a `org.springframework.security.core.userdetails.User` with the user's role as authority.

- [ ] **Step 4: Create `JwtAuthFilter.java`**

Extends `OncePerRequestFilter`. Extracts JWT from `Authorization: Bearer <token>` header. Validates token via JwtUtil. Sets `SecurityContextHolder` authentication with userId as principal and role as authority. Skips filter for `/api/auth/**` paths.

- [ ] **Step 5: Create `SecurityConfig.java`**

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http, JwtAuthFilter jwtAuthFilter) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/ws/**").permitAll()
                .requestMatchers("/api/customers/**", "/api/segments/**", "/api/campaigns/**", "/api/audit-logs/**").hasAuthority("OPERATOR")
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of("*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

- [ ] **Step 6: Verify compilation**

Run: `cd backend && ./mvnw compile`
Expected: BUILD SUCCESS

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/wtc/chatapp/security/ backend/src/main/java/com/wtc/chatapp/config/SecurityConfig.java backend/src/main/java/com/wtc/chatapp/repository/UserRepository.java
git commit -m "feat: add JWT authentication and Spring Security config"
```

---

## Phase 3: Services + Controllers (parallel — each task touches only its own files)

### Task 4: Auth API

**Files:**
- Create: `backend/src/main/java/com/wtc/chatapp/dto/LoginRequest.java`
- Create: `backend/src/main/java/com/wtc/chatapp/dto/RegisterRequest.java`
- Create: `backend/src/main/java/com/wtc/chatapp/dto/AuthResponse.java`
- Create: `backend/src/main/java/com/wtc/chatapp/service/AuthService.java`
- Create: `backend/src/main/java/com/wtc/chatapp/controller/AuthController.java`

- [ ] **Step 1: Create DTOs**

`LoginRequest`: `email` (String, @NotBlank), `password` (String, @NotBlank)
`RegisterRequest`: `email`, `password`, `fullName`, `phone` (optional), `role` (String, default "CLIENT")
`AuthResponse`: `token`, `refreshToken`, `userId`, `email`, `fullName`, `role`, `tags` (List<String>), `status`, `avatarUrl`, `phone`

The `AuthResponse` includes profile fields so the iOS app gets user+profile data in one call (matching the current behavior where login + fetchProfile happens).

- [ ] **Step 2: Create `AuthService.java`**

Methods:
- `register(RegisterRequest)` → creates User with BCrypt password, returns AuthResponse
- `login(LoginRequest)` → validates credentials, returns AuthResponse with JWT
- `refresh(String refreshToken)` → validates refresh token, issues new access token

Uses: `UserRepository`, `JwtUtil`, `PasswordEncoder`

- [ ] **Step 3: Create `AuthController.java`**

```java
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request)

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request)

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@RequestBody Map<String, String> body)
    // body contains "refresh_token"
}
```

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/wtc/chatapp/dto/LoginRequest.java backend/src/main/java/com/wtc/chatapp/dto/RegisterRequest.java backend/src/main/java/com/wtc/chatapp/dto/AuthResponse.java backend/src/main/java/com/wtc/chatapp/service/AuthService.java backend/src/main/java/com/wtc/chatapp/controller/AuthController.java
git commit -m "feat: add auth API with register, login, and refresh endpoints"
```

---

### Task 5: Customer API

**Files:**
- Create: `backend/src/main/java/com/wtc/chatapp/repository/CustomerRepository.java`
- Create: `backend/src/main/java/com/wtc/chatapp/dto/CustomerRequest.java`
- Create: `backend/src/main/java/com/wtc/chatapp/dto/NoteRequest.java`
- Create: `backend/src/main/java/com/wtc/chatapp/service/CustomerService.java`
- Create: `backend/src/main/java/com/wtc/chatapp/controller/CustomerController.java`

- [ ] **Step 1: Create `CustomerRepository.java`**

```java
public interface CustomerRepository extends MongoRepository<Customer, String> {
    Optional<Customer> findByUserId(String userId);
    List<Customer> findByTagsContaining(String tag);
    List<Customer> findByStatus(CustomerStatus status);
    List<Customer> findByScoreGreaterThanEqual(int score);
}
```

- [ ] **Step 2: Create DTOs**

`CustomerRequest`: `userId`, `tags` (List<String>), `score` (int), `status` (String)
`NoteRequest`: `text` (String, @NotBlank)

- [ ] **Step 3: Create `CustomerService.java`**

Methods:
- `listCustomers(String tag, String status, Integer minScore)` → filtered list
- `createCustomer(CustomerRequest)` → returns Customer
- `getCustomer(String id)` → returns Customer
- `updateCustomer(String id, CustomerRequest)` → returns updated Customer
- `getTimeline(String id)` → returns map with: customer data, recent messages, recent campaigns, notes
- `addNote(String id, NoteRequest, String operatorId)` → adds Note to customer

Uses: `CustomerRepository`, `MessageRepository` (for timeline), `CampaignRepository` (for timeline)

- [ ] **Step 4: Create `CustomerController.java`**

```java
@RestController
@RequestMapping("/api/customers")
public class CustomerController {
    @GetMapping
    public ResponseEntity<List<Customer>> list(@RequestParam(required = false) String tag,
                                                @RequestParam(required = false) String status,
                                                @RequestParam(required = false) Integer minScore)

    @PostMapping
    public ResponseEntity<Customer> create(@Valid @RequestBody CustomerRequest request)

    @GetMapping("/{id}")
    public ResponseEntity<Customer> get(@PathVariable String id)

    @PutMapping("/{id}")
    public ResponseEntity<Customer> update(@PathVariable String id, @Valid @RequestBody CustomerRequest request)

    @GetMapping("/{id}/timeline")
    public ResponseEntity<Map<String, Object>> timeline(@PathVariable String id)

    @PostMapping("/{id}/notes")
    public ResponseEntity<Customer> addNote(@PathVariable String id, @Valid @RequestBody NoteRequest request)
}
```

Note: Extract authenticated userId from SecurityContextHolder in controller methods.

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/wtc/chatapp/repository/CustomerRepository.java backend/src/main/java/com/wtc/chatapp/dto/CustomerRequest.java backend/src/main/java/com/wtc/chatapp/dto/NoteRequest.java backend/src/main/java/com/wtc/chatapp/service/CustomerService.java backend/src/main/java/com/wtc/chatapp/controller/CustomerController.java
git commit -m "feat: add customer CRUD API with timeline and notes"
```

---

### Task 6: Segment API

**Files:**
- Create: `backend/src/main/java/com/wtc/chatapp/repository/SegmentRepository.java`
- Create: `backend/src/main/java/com/wtc/chatapp/dto/SegmentRequest.java`
- Create: `backend/src/main/java/com/wtc/chatapp/service/SegmentService.java`
- Create: `backend/src/main/java/com/wtc/chatapp/controller/SegmentController.java`

- [ ] **Step 1: Create `SegmentRepository.java`**

```java
public interface SegmentRepository extends MongoRepository<Segment, String> {
    List<Segment> findByTagsContaining(String tag);
}
```

- [ ] **Step 2: Create DTO and Service**

`SegmentRequest`: `name` (@NotBlank), `description`, `tags` (List<String>, @NotEmpty)

`SegmentService` methods: `list()`, `create(SegmentRequest, String createdBy)`, `update(String id, SegmentRequest)`, `delete(String id)`, `getById(String id)`

- [ ] **Step 3: Create `SegmentController.java`**

Full CRUD: GET /api/segments, POST, PUT /{id}, DELETE /{id}

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/wtc/chatapp/repository/SegmentRepository.java backend/src/main/java/com/wtc/chatapp/dto/SegmentRequest.java backend/src/main/java/com/wtc/chatapp/service/SegmentService.java backend/src/main/java/com/wtc/chatapp/controller/SegmentController.java
git commit -m "feat: add segment CRUD API"
```

---

### Task 7: Message API + WebSocket Broadcasting

**Files:**
- Create: `backend/src/main/java/com/wtc/chatapp/repository/MessageRepository.java`
- Create: `backend/src/main/java/com/wtc/chatapp/repository/NotificationRepository.java`
- Create: `backend/src/main/java/com/wtc/chatapp/dto/MessageRequest.java`
- Create: `backend/src/main/java/com/wtc/chatapp/service/MessageService.java`
- Create: `backend/src/main/java/com/wtc/chatapp/service/NotificationService.java`
- Create: `backend/src/main/java/com/wtc/chatapp/websocket/WebSocketService.java`
- Create: `backend/src/main/java/com/wtc/chatapp/config/WebSocketConfig.java`
- Create: `backend/src/main/java/com/wtc/chatapp/controller/MessageController.java`

This is the most complex task — it combines messaging, notifications, and WebSocket broadcasting.

- [ ] **Step 1: Create repositories**

`MessageRepository`:
```java
public interface MessageRepository extends MongoRepository<Message, String> {
    List<Message> findByRecipientIdOrderByCreatedAtDesc(String recipientId);
    List<Message> findByRecipientIdOrSegmentTagsInOrderByCreatedAtDesc(String recipientId, List<String> tags);
    List<Message> findBySenderIdOrderByCreatedAtDesc(String senderId);
}
```

`NotificationRepository`:
```java
public interface NotificationRepository extends MongoRepository<Notification, String> {
    List<Notification> findByUserIdOrderByCreatedAtDesc(String userId);
    long countByUserIdAndReadFalse(String userId);
}
```

- [ ] **Step 2: Create `WebSocketConfig.java`**

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic");
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").setAllowedOriginPatterns("*");
    }
}
```

- [ ] **Step 3: Create `WebSocketService.java`**

Uses `SimpMessagingTemplate` to broadcast:
```java
@Service
public class WebSocketService {
    private final SimpMessagingTemplate messagingTemplate;

    public void sendMessageToUser(String userId, Message message) {
        messagingTemplate.convertAndSend("/topic/messages/" + userId, message);
    }

    public void sendNotificationToUser(String userId, Notification notification) {
        messagingTemplate.convertAndSend("/topic/notifications/" + userId, notification);
    }
}
```

- [ ] **Step 4: Create `NotificationService.java`**

```java
@Service
public class NotificationService {
    // Uses NotificationRepository and WebSocketService
    public Notification createAndSend(String userId, String title, String body, NotificationType type, String messageId)
    public List<Notification> getByUserId(String userId)
    public void markAsRead(String id)
    public void markAllAsRead(String userId)
}
```

When creating a notification, also broadcasts via WebSocket.

- [ ] **Step 5: Create `MessageRequest.java` DTO**

Fields: `type` (String: "chat" or "campaign"), `recipientId` (nullable), `segmentTags` (nullable List<String>), `content` (object with `title`, `body`, `imageUrl`, `buttons`)

Validation: either `recipientId` or `segmentTags` must be provided.

- [ ] **Step 6: Create `MessageService.java`**

Key method — `sendMessage(MessageRequest, String senderId)`:
1. Create Message document with status SENT
2. Save to MongoDB
3. If recipientId is set → broadcast via WebSocket to that user + create notification
4. If segmentTags is set → find all users with matching tags → broadcast to each + create notifications
5. Return saved message

Other methods: `getById(String id)`, `getInbox(String customerId, List<String> userTags)`, `markAsRead(String id)`, `toggleStar(String id)`

For `getInbox`: query messages where `recipientId == userId` OR any of `segmentTags` matches user's tags. Use a custom MongoDB query:
```java
@Query("{ '$or': [ { 'recipientId': ?0 }, { 'segmentTags': { '$in': ?1 } } ] }")
List<Message> findInbox(String userId, List<String> tags, Sort sort);
```

- [ ] **Step 7: Create `MessageController.java`**

```java
@RestController
@RequestMapping("/api")
public class MessageController {
    @PostMapping("/messages")
    public ResponseEntity<Message> send(@Valid @RequestBody MessageRequest request)

    @GetMapping("/messages/{id}")
    public ResponseEntity<Message> get(@PathVariable String id)

    @GetMapping("/inbox/{customerId}")
    public ResponseEntity<List<Message>> inbox(@PathVariable String customerId)

    @PutMapping("/messages/{id}/read")
    public ResponseEntity<Message> markAsRead(@PathVariable String id)

    @PutMapping("/messages/{id}/star")
    public ResponseEntity<Message> toggleStar(@PathVariable String id)
}
```

For the inbox endpoint: extract the authenticated user's tags from the JWT/security context, or look up the user from DB to get their tags.

- [ ] **Step 8: Commit**

```bash
git add backend/src/main/java/com/wtc/chatapp/repository/MessageRepository.java backend/src/main/java/com/wtc/chatapp/repository/NotificationRepository.java backend/src/main/java/com/wtc/chatapp/dto/MessageRequest.java backend/src/main/java/com/wtc/chatapp/service/MessageService.java backend/src/main/java/com/wtc/chatapp/service/NotificationService.java backend/src/main/java/com/wtc/chatapp/websocket/WebSocketService.java backend/src/main/java/com/wtc/chatapp/config/WebSocketConfig.java backend/src/main/java/com/wtc/chatapp/controller/MessageController.java
git commit -m "feat: add message API with WebSocket real-time broadcasting"
```

---

### Task 8: Campaign API

**Files:**
- Create: `backend/src/main/java/com/wtc/chatapp/repository/CampaignRepository.java`
- Create: `backend/src/main/java/com/wtc/chatapp/dto/CampaignRequest.java`
- Create: `backend/src/main/java/com/wtc/chatapp/service/CampaignService.java`
- Create: `backend/src/main/java/com/wtc/chatapp/controller/CampaignController.java`

- [ ] **Step 1: Create `CampaignRepository.java`**

```java
public interface CampaignRepository extends MongoRepository<Campaign, String> {
    List<Campaign> findAllByOrderByCreatedAtDesc();
}
```

- [ ] **Step 2: Create `CampaignRequest.java`**

Fields: `name` (@NotBlank), `segmentId` (@NotBlank), `content` (MessageContent object: title, body, imageUrl, buttons), `deeplink` (optional String)

- [ ] **Step 3: Create `CampaignService.java`**

Methods:
- `list()` → all campaigns ordered by createdAt desc
- `create(CampaignRequest, String operatorId)` → creates with DRAFT status
- `send(String campaignId, String operatorId)` → looks up segment → gets segment tags → creates Message for each matching user (type=CAMPAIGN) → broadcasts via WebSocket → creates notifications → updates campaign status to SENT with sentAt and messageCount

The `send` method reuses `MessageService.sendMessage()` internally to create the broadcast messages.

- [ ] **Step 4: Create `CampaignController.java`**

```java
@RestController
@RequestMapping("/api/campaigns")
public class CampaignController {
    @GetMapping
    public ResponseEntity<List<Campaign>> list()

    @PostMapping
    public ResponseEntity<Campaign> create(@Valid @RequestBody CampaignRequest request)

    @PostMapping("/{id}/send")
    public ResponseEntity<Campaign> send(@PathVariable String id)
}
```

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/wtc/chatapp/repository/CampaignRepository.java backend/src/main/java/com/wtc/chatapp/dto/CampaignRequest.java backend/src/main/java/com/wtc/chatapp/service/CampaignService.java backend/src/main/java/com/wtc/chatapp/controller/CampaignController.java
git commit -m "feat: add campaign API with express send to segments"
```

---

### Task 9: Notification API

**Files:**
- Create: `backend/src/main/java/com/wtc/chatapp/controller/NotificationController.java`

Note: `NotificationService` and `NotificationRepository` were already created in Task 7 (Message API).

- [ ] **Step 1: Create `NotificationController.java`**

```java
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {
    @GetMapping
    public ResponseEntity<List<Notification>> list()
    // Gets userId from SecurityContext, returns user's notifications

    @PutMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable String id)

    @PutMapping("/read-all")
    public ResponseEntity<Void> markAllAsRead()
    // Gets userId from SecurityContext
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/java/com/wtc/chatapp/controller/NotificationController.java
git commit -m "feat: add notification API endpoints"
```

---

## Phase 4: Cross-Cutting

### Task 10: Audit Logging (AOP)

**Files:**
- Create: `backend/src/main/java/com/wtc/chatapp/repository/AuditLogRepository.java`
- Create: `backend/src/main/java/com/wtc/chatapp/service/AuditService.java`
- Create: `backend/src/main/java/com/wtc/chatapp/audit/AuditAspect.java`
- Create: `backend/src/main/java/com/wtc/chatapp/controller/AuditLogController.java`

- [ ] **Step 1: Create `AuditLogRepository.java`**

```java
public interface AuditLogRepository extends MongoRepository<AuditLog, String> {
    List<AuditLog> findByResourceOrderByTimestampDesc(String resource);
    List<AuditLog> findByUserIdOrderByTimestampDesc(String userId);
    List<AuditLog> findAllByOrderByTimestampDesc();
}
```

- [ ] **Step 2: Create `AuditService.java`**

```java
@Service
public class AuditService {
    public void log(String userId, String action, String resource, String resourceId, String details, String ipAddress)
    public List<AuditLog> list(String resource, String userId)  // both optional filters
}
```

- [ ] **Step 3: Create `AuditAspect.java`**

AOP aspect that intercepts `@PostMapping`, `@PutMapping`, `@DeleteMapping` controller methods. Determines action (CREATE/UPDATE/DELETE) from the annotation. Extracts userId from SecurityContext. Extracts resourceId from path variables. Logs via AuditService.

```java
@Aspect
@Component
public class AuditAspect {
    @AfterReturning(pointcut = "within(com.wtc.chatapp.controller..*) && (@annotation(org.springframework.web.bind.annotation.PostMapping) || @annotation(org.springframework.web.bind.annotation.PutMapping) || @annotation(org.springframework.web.bind.annotation.DeleteMapping))", returning = "result")
    public void auditAction(JoinPoint joinPoint, Object result) {
        // Extract method annotation to determine action type
        // Extract userId from SecurityContextHolder
        // Extract resource from controller class name
        // Extract resourceId from path variable or response body
        // Log via AuditService
    }
}
```

Use `HttpServletRequest` (injected via `RequestContextHolder`) to get IP address.

- [ ] **Step 4: Create `AuditLogController.java`**

```java
@RestController
@RequestMapping("/api/audit-logs")
public class AuditLogController {
    @GetMapping
    public ResponseEntity<List<AuditLog>> list(
        @RequestParam(required = false) String resource,
        @RequestParam(required = false) String userId)
}
```

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/wtc/chatapp/repository/AuditLogRepository.java backend/src/main/java/com/wtc/chatapp/service/AuditService.java backend/src/main/java/com/wtc/chatapp/audit/AuditAspect.java backend/src/main/java/com/wtc/chatapp/controller/AuditLogController.java
git commit -m "feat: add AOP-based audit logging with API endpoint"
```

---

### Task 11: Seed Data + DataLoader

**Files:**
- Create: `backend/src/main/java/com/wtc/chatapp/config/DataLoader.java`

- [ ] **Step 1: Create `DataLoader.java`**

Implements `CommandLineRunner`. On startup, checks if the DB is empty. If empty, seeds:

**Users (operators):**
- admin@wtc.com / admin123 / "Admin WTC" / OPERATOR
- operador@wtc.com / oper123 / "Operador WTC" / OPERATOR

**Users (clients):**
- joao@test.com / test123 / "João Silva" / CLIENT / tags: [vip, ativo] / status: active
- maria@test.com / test123 / "Maria Santos" / CLIENT / tags: [ativo] / status: active
- pedro@test.com / test123 / "Pedro Costa" / CLIENT / tags: [vip, beta, ativo] / status: active

**Segments:**
- "VIP" / tags: [vip]
- "Ativos" / tags: [ativo]
- "Beta Testers" / tags: [beta]

**Messages (matching Sprint 1 seed data):**
- Welcome message to João (chat, direct)
- Black Friday promo (campaign, segmentTags: [vip])
- New collection (campaign, segmentTags: [ativo])
- Beta invite (campaign, segmentTags: [beta])

**Campaigns:**
- "Black Friday 2026" / segment: VIP / status: SENT
- "Nova Coleção" / segment: Ativos / status: SENT

All passwords hashed with BCrypt via `passwordEncoder.encode()`.

- [ ] **Step 2: Verify full application starts**

Run: `cd backend && ./mvnw spring-boot:run`
Expected: Application starts on port 8080, seed data loaded, no errors.

Test with curl:
```bash
curl -X POST http://localhost:8080/api/auth/login -H "Content-Type: application/json" -d '{"email":"admin@wtc.com","password":"admin123"}'
```
Expected: JSON response with token, user data.

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/com/wtc/chatapp/config/DataLoader.java
git commit -m "feat: add seed data loader with test users, segments, and messages"
```

---

## Phase 5: iOS Integration

### Task 12: iOS APIService

**Files:**
- Create: `WTCChatApp/Services/APIService.swift`
- Modify: `WTCChatApp/Utils/Constants.swift`

- [ ] **Step 1: Update `Constants.swift`**

Replace Supabase config with backend API config:

```swift
struct Constants {
    // Backend API Configuration
    static let apiBaseURL = "http://localhost:8080/api"
    static let wsBaseURL = "ws://localhost:8080/ws"

    // Keep the rest unchanged (appName, Deeplink, NotificationType, UserDefaultsKeys)
    // Remove: Tables struct, supabaseURL, supabaseAnonKey
}
```

- [ ] **Step 2: Create `APIService.swift`**

Singleton service replacing `SupabaseService`. Uses URLSession. Stores JWT token in memory (UserDefaults for persistence).

```swift
class APIService {
    static let shared = APIService()

    private var accessToken: String?
    private var refreshToken: String?
    private var currentUserId: String?

    // MARK: - Auth
    func login(email: String, password: String) async throws -> AuthResponse
    func register(email: String, password: String, fullName: String) async throws -> AuthResponse
    func refreshTokenIfNeeded() async throws
    func logout()

    // MARK: - Messages
    func fetchMessages() async throws -> [Message]
    func markMessageAsRead(messageId: String) async throws
    func toggleMessageStar(messageId: String) async throws

    // MARK: - Notifications
    func fetchNotifications() async throws -> [AppNotification]
    func markNotificationAsRead(notificationId: String) async throws
    func markAllNotificationsAsRead() async throws

    // MARK: - Profile
    func fetchProfile() async throws -> Profile
    // Profile data comes from the auth response (User model on backend)

    // MARK: - Private Helpers
    private func request<T: Decodable>(_ method: String, path: String, body: Encodable? = nil) async throws -> T
    private func authorizedRequest(_ request: inout URLRequest)
}
```

The `AuthResponse` struct (new, local to iOS):
```swift
struct AuthResponse: Codable {
    let token: String
    let refreshToken: String
    let userId: String
    let email: String
    let fullName: String
    let role: String
    let tags: [String]?
    let status: String?
    let avatarUrl: String?
    let phone: String?
}
```

JSON decoding uses `keyDecodingStrategy = .convertFromSnakeCase` since the backend outputs snake_case.

The `fetchMessages()` method calls `GET /inbox/{currentUserId}` — the backend handles the tag-based filtering server-side.

- [ ] **Step 3: Commit**

```bash
git add WTCChatApp/Services/APIService.swift WTCChatApp/Utils/Constants.swift
git commit -m "feat: add APIService replacing SupabaseService for backend integration"
```

---

### Task 13: iOS WebSocketService

**Files:**
- Create: `WTCChatApp/Services/WebSocketService.swift`

- [ ] **Step 1: Create `WebSocketService.swift`**

Replace `RealtimeService` with a native URLSessionWebSocketTask-based STOMP client. Since iOS doesn't have a built-in STOMP library and we want to avoid adding dependencies, implement a minimal STOMP-over-WebSocket client:

```swift
class WebSocketService: ObservableObject {
    static let shared = WebSocketService()

    @Published var newMessage: Message?
    @Published var newNotification: AppNotification?

    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false

    func connect(userId: String)
    func disconnect()

    // STOMP frame helpers
    private func sendStompConnect()
    private func sendStompSubscribe(destination: String, id: String)
    private func receiveMessages()  // recursive listen loop
    private func parseStompFrame(_ text: String) -> (command: String, headers: [String: String], body: String)?
    private func handleMessage(_ body: String, destination: String)

    func cleanup()
}
```

On `connect(userId)`:
1. Create URLSessionWebSocketTask to `Constants.wsBaseURL`
2. Send STOMP CONNECT frame
3. Subscribe to `/topic/messages/{userId}` and `/topic/notifications/{userId}`
4. Start receive loop
5. On receiving MESSAGE frames, decode JSON body and publish to `@Published` properties

STOMP frame format:
```
CONNECT\naccept-version:1.2\nheart-beat:0,0\n\n\0
SUBSCRIBE\nid:sub-0\ndestination:/topic/messages/{userId}\n\n\0
```

- [ ] **Step 2: Commit**

```bash
git add WTCChatApp/Services/WebSocketService.swift
git commit -m "feat: add WebSocketService with STOMP client for real-time messaging"
```

---

### Task 14: iOS ViewModel + Model Updates

**Files:**
- Modify: `WTCChatApp/Models/Message.swift`
- Modify: `WTCChatApp/Models/Profile.swift`
- Modify: `WTCChatApp/Models/Notification.swift`
- Modify: `WTCChatApp/ViewModels/AuthViewModel.swift`
- Modify: `WTCChatApp/ViewModels/MessagesViewModel.swift`
- Modify: `WTCChatApp/ViewModels/NotificationsViewModel.swift`
- Modify: `WTCChatApp/App/WTCChatAppApp.swift`

- [ ] **Step 1: Update `Message.swift`**

Changes:
- `id` type: `UUID` → `String`
- Add `status: String?` field (SENT/DELIVERED/READ/FAILED)
- Add `senderId: String?` field
- CodingKeys remain snake_case (backend outputs snake_case via Jackson)
- `recipientId` type: `UUID?` → `String?`
- Keep all other fields the same

- [ ] **Step 2: Update `Profile.swift`**

Changes:
- `id` type: `UUID` → `String`
- Add initializer that maps from `AuthResponse` data
- Keep CodingKeys as snake_case

- [ ] **Step 3: Update `Notification.swift`**

Changes:
- `id` type: `UUID` → `String`
- `userId` type: `UUID` → `String`
- `messageId` type: `UUID?` → `String?`

- [ ] **Step 4: Update `AuthViewModel.swift`**

Replace Supabase auth with APIService:

```swift
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserId: String?
    @Published var currentProfile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func checkSession() async {
        // Check if we have a stored token
        if let token = UserDefaults.standard.string(forKey: "access_token") {
            apiService.restoreSession(token: token, ...)
            // Try to fetch profile to verify token validity
            do {
                currentProfile = try await apiService.fetchProfile()
                isAuthenticated = true
            } catch {
                isAuthenticated = false
            }
        }
    }

    func signIn(email: String, password: String) async {
        // Call apiService.login() → store token → set currentProfile from AuthResponse
    }

    func signOut() async {
        apiService.logout()
        currentUserId = nil
        currentProfile = nil
        isAuthenticated = false
        WebSocketService.shared.cleanup()
    }
}
```

Remove `import Supabase`. Remove `currentUser: User?` (Supabase User type). Use `currentUserId: String?` instead.

- [ ] **Step 5: Update `MessagesViewModel.swift`**

Changes:
- Replace `supabaseService` with `apiService = APIService.shared`
- Replace `realtimeService` with `webSocketService = WebSocketService.shared`
- `fetchMessages(userId:userTags:)` → `fetchMessages()` (no params needed — backend uses JWT to identify user)
- `setupRealtimeSubscription()` → observe `webSocketService.$newMessage`
- All message action methods use `apiService` instead of `supabaseService`
- Remove `import Supabase`
- Update ID types from `UUID` to `String` in method signatures

- [ ] **Step 6: Update `NotificationsViewModel.swift`**

Same pattern as MessagesViewModel:
- Replace `supabaseService` with `apiService`
- Replace `realtimeService` with `webSocketService`
- `fetchNotifications(userId:)` → `fetchNotifications()` (no params — backend uses JWT)
- Remove `import Supabase`

- [ ] **Step 7: Update `WTCChatAppApp.swift` if it initializes Supabase**

Remove any Supabase initialization. Ensure WebSocketService connects after login.

- [ ] **Step 8: Verify compilation**

Run: Xcode build (or `xcodebuild` CLI)
Expected: No compilation errors. All views should work with the updated models.

- [ ] **Step 9: Commit**

```bash
git add WTCChatApp/
git commit -m "feat: rewire iOS app to use Spring Boot backend APIs and WebSocket"
```

---

## Phase 6: Documentation

### Task 15: Backend README

**Files:**
- Create: `backend/README.md`

- [ ] **Step 1: Write `backend/README.md`**

Content:
1. Project description
2. Tech stack
3. Prerequisites (Java 17+, MongoDB, Maven)
4. How to run: `cd backend && ./mvnw spring-boot:run`
5. Default port: 8080
6. Seed data: auto-loaded on first run (operator: admin@wtc.com/admin123)
7. API endpoint table (all routes with method, path, auth requirement)
8. WebSocket: connect to `ws://localhost:8080/ws`, subscribe to `/topic/messages/{userId}`
9. MongoDB collections overview

- [ ] **Step 2: Update root `README.md`**

Add Sprint 2 section describing the backend, how to run both backend and iOS app together.

- [ ] **Step 3: Commit**

```bash
git add backend/README.md README.md
git commit -m "docs: add backend README with execution instructions"
```

---

## Parallelization Guide

```
Task 1 (scaffold) ──────────────────────────────┐
                                                  ├─ Task 2 (models) ──┐
                                                  ├─ Task 3 (security) ─┤
                                                  │                     │
                                                  │   ┌─ Task 4 (auth) ─┤
                                                  │   ├─ Task 5 (customer)
                                                  │   ├─ Task 6 (segment)
                                                  │   ├─ Task 7 (message+ws)
                                                  │   ├─ Task 8 (campaign)
                                                  │   └─ Task 9 (notification)
                                                  │                     │
                                                  │   ┌─ Task 10 (audit)│
                                                  │   └─ Task 11 (seed) ┤
                                                  │                     │
                                                  │   ┌─ Task 12 (iOS API)
                                                  │   ├─ Task 13 (iOS WS)
                                                  │   └─ Task 14 (iOS VMs)
                                                  │                     │
                                                  │   └─ Task 15 (docs) ┘
```

**Safe parallel groups:**
- Tasks 2+3 (models + security — no file overlap)
- Tasks 4+5+6+8+9 (each touches only its own controller/service/repo/dto files)
- Task 7 must run alone (creates shared WebSocketService, NotificationService, repos used by others)
- Tasks 12+13 (iOS — separate files)
- Task 14 depends on 12+13 (uses APIService and WebSocketService)
