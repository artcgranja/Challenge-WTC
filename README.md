# 📱 WTC Chat App

<div align="center">

![iOS](https://img.shields.io/badge/iOS-15.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0-purple)
![Supabase](https://img.shields.io/badge/Supabase-2.0-green)
![License](https://img.shields.io/badge/license-MIT-blue)

**Sistema de Mensagens em Tempo Real para CRM Corporativo**

[Sobre](#-sobre) • [Features](#-features) • [Stack](#-stack) • [Setup](#-setup-rápido) • [Documentação](#-documentação) • [Demo](#-demo)

</div>

---

## 🎯 Sobre

O **WTC Chat App** é um aplicativo iOS nativo desenvolvido para o **Challenge WTC 2025** que revoluciona a comunicação entre empresas e clientes. Permite que operadores de atendimento e times de marketing disparem mensagens segmentadas (promoções, campanhas, banners, eventos) em tempo real, diretamente para grupos ou clientes específicos.

### Problema Resolvido
- ❌ Comunicação fragmentada entre empresa e clientes
- ❌ Falta de personalização em mensagens de marketing
- ❌ Ausência de interatividade em notificações
- ❌ Dificuldade em segmentar público-alvo

### Solução
- ✅ Mensagens em tempo real via WebSocket
- ✅ Segmentação inteligente por tags
- ✅ Botões de ação interativos
- ✅ Interface moderna e intuitiva

---

## ✨ Features

### 🔐 Autenticação
- Login seguro com email/senha
- Persistência de sessão
- Recuperação de senha
- Suporte a Supabase Auth

### 💬 Mensagens
- Lista de mensagens com filtros (Todas, Chat, Campanhas, Não Lidas, Favoritas)
- Busca em tempo real
- Marcar como lida/favorita
- Swipe para deletar
- Pull-to-refresh

### 🔔 Notificações
- **In-app:** Popup elegante quando app está aberto
- **Push:** Notificações APNs em background
- Badge automático com contador
- Centro de notificações integrado

### 🎨 Interatividade
Botões dinâmicos que executam ações:
- `deeplink://` → Navegação interna no app
- `copy:TEXTO` → Copia para clipboard
- `https://` → Abre link externo no Safari

### 🎯 Segmentação
- Mensagens para usuários específicos
- Campanhas para grupos por tags (VIP, Beta, Ativo, etc.)
- RLS (Row Level Security) no banco de dados

### 🚀 Realtime
- WebSocket com Supabase Realtime
- Atualização instantânea de mensagens
- Reconexão automática
- Latência < 100ms

---

## 🛠️ Stack

### Frontend
```yaml
Linguagem: Swift 5.9+
UI Framework: SwiftUI
Arquitetura: MVVM
Mínimo iOS: 15.0
Dependências:
  - Supabase Swift 2.0+
  - Kingfisher 7.0+ (cache de imagens)
```

### Backend
```yaml
BaaS: Supabase
Database: PostgreSQL
Auth: Supabase Auth
Realtime: Supabase Realtime (WebSocket)
Storage: Supabase Storage
```

---

## 📂 Estrutura do Projeto

```
WTCChatApp/
├── 📱 App/
│   └── WTCChatAppApp.swift         # Entry point
├── 📦 Models/
│   ├── Message.swift
│   ├── Profile.swift
│   └── Notification.swift
├── 🧠 ViewModels/
│   ├── AuthViewModel.swift
│   ├── MessagesViewModel.swift
│   └── NotificationsViewModel.swift
├── 🎨 Views/
│   ├── Auth/
│   │   └── LoginView.swift
│   ├── Messages/
│   │   ├── MessagesListView.swift
│   │   └── MessageDetailView.swift
│   ├── Notifications/
│   │   └── NotificationsView.swift
│   └── Profile/
│       └── ProfileView.swift
├── ⚙️ Services/
│   ├── SupabaseService.swift
│   ├── RealtimeService.swift
│   └── NotificationService.swift
├── 🔧 Utils/
│   ├── DeeplinkHandler.swift
│   └── Constants.swift
├── 🗄️ Database/
│   ├── schema.sql                  # Schema do banco
│   └── seed_data.sql               # Dados de teste
└── 📚 Documentation/
    └── DOCUMENTATION.md            # Documentação completa
```

---

## 🚀 Setup Rápido

### Pré-requisitos
- macOS 13.0+ (Ventura)
- Xcode 15.0+
- Conta Supabase (gratuita)

### 1. Clone o Repositório
```bash
git clone https://github.com/seu-usuario/wtc-chat-app.git
cd wtc-chat-app/WTCChatApp
```

### 2. Configure o Supabase

#### 2.1. Crie um Projeto
1. Acesse [supabase.com](https://supabase.com)
2. Clique em "New Project"
3. Anote a **URL** e **Anon Key**

#### 2.2. Configure o Banco de Dados
```bash
# No Supabase Dashboard:
# SQL Editor → New Query → Cole o conteúdo de Database/schema.sql → Run
```

#### 2.3. Crie Usuários de Teste
```bash
# Authentication → Users → Add User
# Crie 3 usuários com emails:
# - joao@test.com
# - maria@test.com
# - pedro@test.com
```

#### 2.4. Popule Dados de Teste
```bash
# Atualize os UUIDs em Database/seed_data.sql
# Execute no SQL Editor
```

### 3. Configure o App

Edite `WTCChatApp/Utils/Constants.swift`:

```swift
struct Constants {
    static let supabaseURL = "https://SEU-PROJETO.supabase.co"
    static let supabaseAnonKey = "SUA-ANON-KEY-AQUI"
}
```

### 4. Instale Dependências

No Xcode:
1. `File` → `Add Package Dependencies`
2. Adicione:
   - `https://github.com/supabase/supabase-swift`
   - `https://github.com/onevcat/Kingfisher`

### 5. Build e Run

```bash
# Abra o projeto no Xcode
open WTCChatApp.xcodeproj

# Selecione um simulador (iPhone 15 Pro recomendado)
# Pressione Cmd+R para rodar
```

---

## 🧪 Testando o App

### 1. Login
```
Email: joao@test.com
Senha: (a que você definiu no Supabase)
```

### 2. Ver Mensagens
- Você verá mensagens de teste já populadas
- Filtre por tipo (Chat, Campanhas, etc.)
- Busque por palavra-chave

### 3. Testar Realtime

#### Via SQL Editor (Supabase):
```sql
-- Inserir nova mensagem para João (substitua o UUID)
INSERT INTO messages (type, recipient_id, content, created_at)
VALUES (
    'chat',
    '11111111-1111-1111-1111-111111111111', -- UUID do João
    '{
        "title": "Teste Realtime",
        "body": "Esta mensagem aparecerá instantaneamente no app!",
        "buttons": [
            {"label": "Testar", "action": "deeplink://profile"}
        ]
    }'::jsonb,
    NOW()
);
```

#### Resultado Esperado:
- ✅ Popup in-app aparece imediatamente
- ✅ Mensagem aparece na lista
- ✅ Badge de não lidas incrementa
- ✅ Notificação push (se app em background)

### 4. Testar Botões Interativos

Abra uma mensagem e clique nos botões:
- **"Ver Ofertas"** → Navega internamente
- **"Copiar Cupom"** → Copia código e mostra toast
- **"Visitar Site"** → Abre Safari

---

## 📊 Database Schema

### Tabela: `profiles`
```sql
id           UUID (PK)
full_name    TEXT
email        TEXT
tags         TEXT[]     -- ['vip', 'ativo', 'beta']
status       TEXT       -- 'active', 'inactive', 'pending'
```

### Tabela: `messages`
```sql
id            UUID (PK)
type          TEXT       -- 'chat' | 'campaign'
recipient_id  UUID (FK)  -- Usuário específico
segment_tags  TEXT[]     -- ['vip'] → Para todos VIPs
content       JSONB      -- {title, body, imageUrl, buttons}
read_at       TIMESTAMP
starred       BOOLEAN
```

### Tabela: `notifications`
```sql
id          UUID (PK)
user_id     UUID (FK)
title       TEXT
body        TEXT
type        TEXT       -- 'message' | 'campaign' | 'system'
read        BOOLEAN
message_id  UUID (FK)
```

---

## 🎨 Screenshots

### Login
```
┌──────────────────────┐
│   💬 WTC Chat       │
│                      │
│  ┌────────────────┐ │
│  │ Email          │ │
│  └────────────────┘ │
│  ┌────────────────┐ │
│  │ Senha          │ │
│  └────────────────┘ │
│                      │
│  ┌────────────────┐ │
│  │    ENTRAR      │ │
│  └────────────────┘ │
└──────────────────────┘
```

### Home - Lista de Mensagens
```
┌──────────────────────┐
│  Mensagens       👤  │
├──────────────────────┤
│ [Todas][Chat][Camp.] │
├──────────────────────┤
│ 🔍 Buscar mensagens  │
├──────────────────────┤
│ 📢 Black Friday VIP  │
│ Aproveite 50% OFF... │
│ 2h atrás         ⭐● │
├──────────────────────┤
│ 💬 Seu pedido #1234  │
│ Foi enviado e deve.. │
│ 1 dia atrás          │
└──────────────────────┘
```

### Detalhes da Mensagem
```
┌──────────────────────┐
│  ◀ Mensagem      ⭐  │
├──────────────────────┤
│ ┌────────────────┐   │
│ │   [BANNER]     │   │
│ └────────────────┘   │
│                      │
│ Black Friday VIP 🎉  │
│ 📢 Campanha          │
│                      │
│ Aproveite 50% de     │
│ desconto em TODOS    │
│ os produtos...       │
│                      │
│ ┌────────────────┐   │
│ │ Ver Ofertas  → │   │
│ └────────────────┘   │
│ ┌────────────────┐   │
│ │ Copiar: BF50 📋│   │
│ └────────────────┘   │
└──────────────────────┘
```

---

## 🎯 Funcionalidades Implementadas

### Checklist Completo

#### ✅ Autenticação
- [x] Login com email/senha
- [x] Persistência de sessão
- [x] Logout
- [x] Recuperação de senha

#### ✅ Mensagens
- [x] Listar mensagens
- [x] Filtrar por tipo
- [x] Buscar por palavra-chave
- [x] Marcar como lida
- [x] Favoritar mensagem
- [x] Swipe para deletar

#### ✅ Realtime
- [x] WebSocket subscription
- [x] Atualização automática
- [x] Badge de não lidas

#### ✅ Notificações
- [x] In-app popup
- [x] Push notifications (APNs)
- [x] Centro de notificações
- [x] Badge de app

#### ✅ Interatividade
- [x] Botões dinâmicos
- [x] Deeplinks
- [x] Copiar para clipboard
- [x] Links externos

#### ✅ Segmentação
- [x] Mensagens para usuário específico
- [x] Campanhas por tags
- [x] RLS no banco de dados

---

## 📚 Documentação

### Documentação Completa
Veja a documentação técnica completa em:
- **[DOCUMENTATION.md](WTCChatApp/Documentation/DOCUMENTATION.md)** - Documentação completa com diagramas, fluxos e detalhes técnicos

### Arquivos Importantes
- **[schema.sql](WTCChatApp/Database/schema.sql)** - Schema do banco de dados
- **[seed_data.sql](WTCChatApp/Database/seed_data.sql)** - Dados de teste

---

## 🎥 Demo

### Vídeo de Demonstração
(Grave um vídeo de 5 minutos mostrando:)
1. Login
2. Recebimento de mensagem em tempo real
3. Abertura e leitura de mensagem
4. Interação com botões
5. Notificação in-app

---

## 🔧 Troubleshooting

### Erro: "Supabase connection failed"
**Solução:** Verifique se a URL e Anon Key em `Constants.swift` estão corretas

### Erro: "No messages appearing"
**Solução:**
1. Verifique se executou o `seed_data.sql`
2. Verifique se o UUID do usuário corresponde ao criado no Supabase Auth
3. Verifique as policies RLS no Supabase

### Erro: "Realtime not working"
**Solução:**
1. Verifique se o Realtime está habilitado no Supabase
2. Verifique se a subscription foi estabelecida (log no console)

### Erro: "Build failed - Package not found"
**Solução:**
1. `File` → `Packages` → `Reset Package Caches`
2. `File` → `Packages` → `Update to Latest Package Versions`

---

## 🚀 Deploy

### TestFlight
```bash
# 1. Archive o projeto
# Product → Archive

# 2. Distribua para TestFlight
# Organizer → Distribute App → App Store Connect

# 3. Configure TestFlight
# App Store Connect → TestFlight → Adicione testadores
```

### App Store
Siga o guia oficial da Apple:
https://developer.apple.com/app-store/submissions/

---

## 🛣️ Roadmap

### Sprint 2 (Futuro)
- [ ] Comandos rápidos "/" (ex: /promo)
- [ ] Cache offline
- [ ] Dark mode
- [ ] Animações avançadas

### Sprint 3 (Futuro)
- [ ] Envio de mensagens pelo cliente
- [ ] Upload de imagens
- [ ] Localização PT/EN
- [ ] Estatísticas de engajamento

---

## 📄 Licença

Este projeto foi desenvolvido como parte do **Challenge WTC 2025**.

---

## 👨‍💻 Autor

**Desenvolvido por:** Claude Code
**Data:** 30/10/2025
**Challenge:** WTC 2025 - Sprint 1

---

## 🙏 Agradecimentos

- WTC pela oportunidade
- Supabase pela plataforma incrível
- Comunidade Swift/iOS

---

## 📞 Suporte

Para dúvidas ou issues:
- 📧 Email: suporte@wtc.com
- 📖 Docs: [docs.wtc.com](https://docs.wtc.com)
- 🐛 Issues: [GitHub Issues](https://github.com/seu-usuario/wtc-chat-app/issues)

---

<div align="center">

**Feito com ❤️ usando Swift e SwiftUI**

[⬆ Voltar ao topo](#-wtc-chat-app)

</div>