# 🚀 Guia Rápido de Setup - WTC Chat App

## ⏱️ Tempo estimado: 15 minutos

---

## 📋 Pré-requisitos

Antes de começar, certifique-se de ter:

- ✅ Mac com macOS 13.0+ (Ventura ou superior)
- ✅ Xcode 15.0+ instalado
- ✅ Conta gratuita no [Supabase](https://supabase.com)
- ✅ Conexão com internet

---

## 🎯 Passo a Passo

### 1️⃣ Configure o Supabase (5 min)

#### 1.1. Crie o Projeto
1. Acesse [supabase.com](https://supabase.com) e faça login
2. Clique em **"New Project"**
3. Preencha:
   - **Name:** WTC Chat App
   - **Database Password:** (escolha uma senha forte)
   - **Region:** South America (São Paulo)
4. Clique em **"Create new project"**
5. Aguarde 2-3 minutos até o projeto ser criado

#### 1.2. Copie as Credenciais
1. No dashboard do projeto, vá em **Settings** (ícone de engrenagem)
2. Clique em **API**
3. Copie:
   - **Project URL** (ex: `https://xxxxx.supabase.co`)
   - **anon public** (key longa começando com `eyJ...`)

#### 1.3. Configure o Banco de Dados
1. No menu lateral, clique em **SQL Editor**
2. Clique em **"New query"**
3. Abra o arquivo `WTCChatApp/Database/schema.sql`
4. Copie TODO o conteúdo e cole no SQL Editor
5. Clique em **"Run"** (ou pressione Cmd+Enter)
6. Aguarde até ver "Success. No rows returned"

#### 1.4. Crie Usuários de Teste
1. No menu lateral, clique em **Authentication** → **Users**
2. Clique em **"Add user"** → **"Create new user"**
3. Crie 3 usuários:

**Usuário 1:**
```
Email: joao@test.com
Password: teste123 (ou a senha que preferir)
✓ Auto Confirm User
```

**Usuário 2:**
```
Email: maria@test.com
Password: teste123
✓ Auto Confirm User
```

**Usuário 3:**
```
Email: pedro@test.com
Password: teste123
✓ Auto Confirm User
```

4. Anote os **UUIDs** de cada usuário (coluna `id`)

#### 1.5. Popule Dados de Teste
1. Abra o arquivo `WTCChatApp/Database/seed_data.sql`
2. Substitua os UUIDs:
   - `11111111-1111-1111-1111-111111111111` → UUID do João
   - `22222222-2222-2222-2222-222222222222` → UUID da Maria
   - `33333333-3333-3333-3333-333333333333` → UUID do Pedro
3. Copie TODO o conteúdo do arquivo
4. Volte ao **SQL Editor** no Supabase
5. Cole o conteúdo e clique em **"Run"**
6. Aguarde até ver "Success"

---

### 2️⃣ Configure o App (5 min)

#### 2.1. Abra o Projeto
```bash
cd WTCChatApp
open WTCChatApp.xcodeproj
```

Se o arquivo `.xcodeproj` não existir, você precisará criar um novo projeto no Xcode:
1. Abra o Xcode
2. File → New → Project
3. Escolha **iOS** → **App**
4. Preencha:
   - **Product Name:** WTCChatApp
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Bundle Identifier:** com.wtc.chatapp
5. Salve no diretório do projeto

#### 2.2. Configure as Credenciais do Supabase
1. Abra o arquivo `WTCChatApp/Utils/Constants.swift`
2. Substitua as credenciais:

```swift
struct Constants {
    // Cole aqui a URL do seu projeto
    static let supabaseURL = "https://SEU-PROJETO.supabase.co"

    // Cole aqui a Anon Key do seu projeto
    static let supabaseAnonKey = "SUA-ANON-KEY-AQUI"
}
```

#### 2.3. Adicione as Dependências
1. No Xcode, vá em **File** → **Add Package Dependencies**
2. Adicione o Supabase:
   - URL: `https://github.com/supabase/supabase-swift`
   - Version: `2.0.0` ou superior
   - Clique em **"Add Package"**
   - Selecione **"Supabase"** e clique em **"Add Package"**

3. Adicione o Kingfisher:
   - **File** → **Add Package Dependencies** novamente
   - URL: `https://github.com/onevcat/Kingfisher`
   - Version: `7.0.0` ou superior
   - Clique em **"Add Package"**
   - Selecione **"Kingfisher"** e clique em **"Add Package"**

---

### 3️⃣ Execute o App (2 min)

#### 3.1. Selecione o Simulador
1. No topo do Xcode, clique no menu de simuladores
2. Selecione **iPhone 15 Pro** (recomendado)
3. Se não estiver disponível, selecione qualquer iPhone com iOS 15+

#### 3.2. Build e Run
1. Pressione **Cmd+R** (ou clique no botão Play ▶️)
2. Aguarde o build (primeira vez pode levar 2-3 minutos)
3. O simulador abrirá automaticamente

#### 3.3. Faça Login
1. No app, insira:
   - **Email:** `joao@test.com`
   - **Senha:** `teste123` (ou a que você definiu)
2. Clique em **"Entrar"**
3. Você verá a lista de mensagens! 🎉

---

## ✅ Teste se Está Funcionando

### Teste 1: Ver Mensagens
- ✅ Você deve ver 6-7 mensagens na lista
- ✅ Filtre por "Campanhas" - deve mostrar campanhas
- ✅ Busque por "Black Friday" - deve filtrar

### Teste 2: Abrir Mensagem
- ✅ Toque em uma mensagem
- ✅ Deve abrir os detalhes com título, corpo e botões
- ✅ Clique em um botão - deve executar a ação

### Teste 3: Realtime (o mais legal! 🚀)
1. Deixe o app aberto no simulador
2. Abra o Supabase no navegador
3. Vá em **SQL Editor**
4. Execute este comando (substitua o UUID):

```sql
INSERT INTO messages (type, recipient_id, content, created_at)
VALUES (
    'chat',
    'UUID-DO-JOAO-AQUI', -- Substitua!
    '{
        "title": "🚀 Teste Realtime",
        "body": "Se você está vendo isso, o realtime funciona!",
        "buttons": [
            {"label": "Sucesso! 🎉", "action": "deeplink://profile"}
        ]
    }'::jsonb,
    NOW()
);
```

5. **Resultado esperado:**
   - ✅ Um popup aparece no app instantaneamente
   - ✅ A mensagem aparece no topo da lista
   - ✅ O badge de não lidas incrementa

Se tudo funcionar, **PARABÉNS!** 🎉 Seu app está 100% operacional!

---

## 🐛 Troubleshooting

### ❌ Erro: "Build failed"
**Solução:**
1. File → Packages → Reset Package Caches
2. File → Packages → Update to Latest Package Versions
3. Product → Clean Build Folder (Shift+Cmd+K)
4. Tente buildar novamente (Cmd+R)

### ❌ Erro: "Supabase connection failed"
**Solução:**
1. Verifique se copiou corretamente a URL e Anon Key
2. Verifique se não há espaços extras
3. Teste a URL no navegador (deve abrir uma página do Supabase)

### ❌ Nenhuma mensagem aparece
**Solução:**
1. Verifique se executou o `seed_data.sql`
2. Verifique se substituiu os UUIDs pelos corretos
3. No Supabase, vá em Table Editor → messages → verifique se há dados

### ❌ Login não funciona
**Solução:**
1. Verifique se criou o usuário no Authentication
2. Verifique se marcou "Auto Confirm User"
3. Tente resetar a senha no app
4. Verifique se o email está correto (sem espaços)

### ❌ Realtime não funciona
**Solução:**
1. No Supabase, vá em Database → Replication
2. Ative a replicação para a tabela `messages`
3. Ative a replicação para a tabela `notifications`
4. Reinicie o app

---

## 📱 Próximos Passos

Agora que o app está funcionando:

1. **Explore as features:**
   - Filtre mensagens
   - Favorite uma mensagem (estrela)
   - Swipe para deletar
   - Abra seu perfil
   - Veja as notificações

2. **Teste os botões:**
   - Botões de deeplink (navegação interna)
   - Botões de copy (copiar cupom)
   - Botões de link externo

3. **Personalize:**
   - Adicione suas próprias mensagens no Supabase
   - Crie novas tags
   - Experimente com segmentação

4. **Grave o vídeo de demonstração:**
   - Login
   - Recebimento em realtime
   - Interação com botões
   - Notificações

---

## 📞 Precisa de Ajuda?

- 📖 Veja a [Documentação Completa](Documentation/DOCUMENTATION.md)
- 📧 Email: suporte@wtc.com
- 🐛 Abra uma issue no GitHub

---

**Desenvolvido com ❤️ para o Challenge WTC 2025**
