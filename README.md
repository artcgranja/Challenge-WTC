# 📱 WTC Chat App — Challenge WTC 2025 (Sprint 2)

> Plataforma de comunicação CRM do **WTC Business Club São Paulo**: app iOS nativo + backend Java robusto, integrados via APIs REST reais (sem mocks).

![iOS](https://img.shields.io/badge/iOS-15.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-MVVM-purple)
![Java](https://img.shields.io/badge/Java-17-red)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3-green)
![MongoDB](https://img.shields.io/badge/MongoDB-NoSQL-darkgreen)

---

## 🎯 Sobre

Solução completa que permite a operadores e times de marketing dispararem mensagens
segmentadas (promoções, campanhas, banners, eventos) em tempo real para clientes ou
grupos, com notificações push/in-app, histórico de chat e botões de ação interativos —
tudo integrado a um CRM corporativo.

**Sprint 1** entregou o app iOS (protótipo). **Sprint 2** substituiu os mocks por um
backend real em Spring Boot + MongoDB, com o app consumindo APIs REST funcionais.

## 🏗️ Arquitetura

```
┌─────────────────────┐      REST/JSON (JWT)      ┌──────────────────────────┐
│   iOS App (SwiftUI) │ ───────────────────────▶  │  Spring Boot 3.3 (Java17)│
│   MVVM + Combine    │ ◀─── STOMP / WebSocket ─── │  Security · AOP · WS     │
└─────────────────────┘                            └────────────┬─────────────┘
                                                                 │
                                                          ┌──────▼──────┐
                                                          │  MongoDB    │
                                                          │  (NoSQL)    │
                                                          └─────────────┘
```

- **App iOS** — Swift 5.9, SwiftUI, MVVM, **zero dependências externas** (URLSession + STOMP manual)
- **Backend** — Java 17, Spring Boot 3.3, Spring Security (JWT), Spring Data MongoDB, Spring WebSocket (STOMP), Spring AOP (auditoria)
- **Banco** — MongoDB (7 collections)
- **Diferencial** — comunicação **em tempo real** via WebSocket/STOMP + governança via auditoria automática (AOP)

## 📂 Estrutura do Repositório

```
Challenge-WTC/
├── backend/            # Spring Boot + MongoDB (Sprint 2) — ver backend/README.md
│   └── src/main/java/com/wtc/chatapp/
│       ├── config/     # Security, WebSocket, Jackson, DataLoader (seed)
│       ├── security/   # JWT (filter, util, userdetails)
│       ├── model/      # 7 documents + value objects + enums
│       ├── repository/ # Spring Data MongoDB
│       ├── service/    # regras de negócio
│       ├── controller/ # 7 controllers REST
│       ├── audit/      # AuditAspect (AOP)
│       └── websocket/  # WebSocketService (STOMP)
├── WTCChatApp/         # App iOS nativo (SwiftUI)
│   ├── App/            # entry point + roteamento por role
│   ├── Models/         # Message, Profile, Customer, Campaign, Segment...
│   ├── ViewModels/     # Auth, Messages, Notifications, CRM, Campaign
│   ├── Views/          # CLIENT (Login, Messages...) + Operator (CRM, Campanhas...)
│   ├── Services/       # APIService (REST), WebSocketService (STOMP), Notification
│   └── Utils/          # Theme (design system), Constants, DeeplinkHandler
├── project.yml         # XcodeGen → gera WTCChatApp.xcodeproj
└── Documentation/      # documentação técnica
```

## 🛠️ Stack

| Camada | Tecnologias |
|--------|-------------|
| **iOS** | Swift 5.9 · SwiftUI · Combine · MVVM · iOS 15+ · sem deps externas |
| **Backend** | Java 17 · Spring Boot 3.3 · Spring Security · Spring Data MongoDB · Spring WebSocket · Spring AOP · Lombok · JJWT |
| **Banco** | MongoDB 6.0+ |
| **Auth** | JWT (access 24h / refresh 7d) · BCrypt · roles OPERATOR/CLIENT |
| **Realtime** | WebSocket STOMP (`/topic/messages/{userId}`, `/topic/notifications/{userId}`) |

## 🚀 Setup

### 1. Backend (Spring Boot + MongoDB)

```bash
# Pré-requisitos: Java 17, Maven, MongoDB rodando em localhost:27017

# macOS (Homebrew)
brew install openjdk@17 mongodb-community
brew services start mongodb-community

cd backend
JAVA_HOME=$(brew --prefix openjdk@17) ./mvnw spring-boot:run
# Servidor em http://localhost:8080
# Seed automático na 1ª execução (5 usuários, 3 segmentos, 6 msgs, 2 campanhas)
```

Detalhes completos da API em **[backend/README.md](backend/README.md)**.

### 2. App iOS

```bash
# Pré-requisitos: macOS, Xcode 15+, XcodeGen (brew install xcodegen)

cd Challenge-WTC
xcodegen generate          # gera WTCChatApp.xcodeproj
open WTCChatApp.xcodeproj  # Cmd+R em um simulador (iPhone 15+)
```

O app aponta para `http://localhost:8080` por padrão (`WTCChatApp/Utils/Constants.swift`).

## 🧪 Credenciais de Teste

| Email | Senha | Tipo | Tags |
|-------|-------|------|------|
| admin@wtc.com | admin123 | OPERATOR | — |
| operador@wtc.com | oper123 | OPERATOR | — |
| joao@test.com | test123 | CLIENT | vip, ativo |
| maria@test.com | test123 | CLIENT | ativo |
| pedro@test.com | test123 | CLIENT | vip, beta, ativo |

- **Login como CLIENT** → inbox de mensagens, campanhas, notificações, perfil
- **Login como OPERATOR** → CRM (clientes, busca/filtros), campanhas express, envio 1:1/segmento, notas, timeline 360°

## ✅ Funcionalidades

**Autenticação** — login operador/cliente, JWT, refresh, roles.

**Chat integrado ao CRM** — conversas 1:1 e por segmento, push + pop-up in-app, histórico, status de mensagem (SENT/DELIVERED/READ/FAILED).

**CRM no App (visão operador)** — lista de clientes com busca e filtros (tags/score/status), anotações rápidas por cliente, perfil 360° (timeline de mensagens + notas).

**Campanhas Express** — envio imediato de promoções/comunicados por segmento, deeplinks internos.

**Governança** — auditoria automática (AOP) de operações de escrita.

**Interatividade** — botões dinâmicos: `deeplink://` (navegação interna), `https://` (link externo), `copy:` (clipboard).

**Tempo real** — WebSocket/STOMP: nova mensagem aparece instantaneamente no app.

## 📊 Modelo de Dados (MongoDB, 7 collections)

| Collection | Conteúdo |
|------------|----------|
| `users` | operadores + clientes (auth, perfil, role, tags, status) |
| `customers` | registro CRM (userId, tags, score 0-100, status, notes[], segmentIds[]) |
| `segments` | name, description, tags[], createdBy |
| `messages` | type (CHAT/CAMPAIGN), senderId, recipientId, segmentTags[], content{title,body,imageUrl,buttons[]}, status, readAt, starred |
| `campaigns` | name, segmentId, content, deeplink, status (DRAFT/SENT), sentBy, messageCount |
| `notifications` | userId, title, body, type, read, messageId |
| `audit_logs` | userId, action, resource, resourceId, details, ipAddress, timestamp |

**Inbox query:** `$or: [recipientId = userId, segmentTags ∈ userTags]` — segmentação server-side.

## 📚 Documentação

- **[backend/README.md](backend/README.md)** — setup, todos os endpoints, payloads, modelo de dados
- **[Documentation/DOCUMENTATION.md](Documentation/DOCUMENTATION.md)** — arquitetura técnica detalhada

## 👨‍💻 Equipe — Challenge WTC 2025 · FIAP · 2TDS

| Nome | RM |
|------|-----|
| Arthur Cavalcanti Granja | 560650 |

---

*Challenge WTC 2025 — Sprint 2. FIAP · Análise e Desenvolvimento de Sistemas.*
