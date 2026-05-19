# WTC Chat App — Backend

Backend da plataforma de comunicação CRM do WTC Business Club.

## Stack Tecnológica

- **Java 17** + **Spring Boot 3.3**
- **Spring Security** com autenticação JWT
- **Spring Data MongoDB** (banco NoSQL)
- **Spring WebSocket** (STOMP) para mensageria em tempo real
- **Spring AOP** para auditoria automática
- **Lombok** para redução de boilerplate
- **JJWT** para geração e validação de tokens

## Pré-requisitos

- Java 17+
- Maven 3.8+
- MongoDB 6.0+ (rodando em `localhost:27017`)

## Como Executar

```bash
# 1. Iniciar MongoDB (se não estiver rodando)
mongod --dbpath /data/db

# 2. Compilar e executar
cd backend
./mvnw spring-boot:run

# O servidor inicia na porta 8080
# Dados de teste são carregados automaticamente na primeira execução
```

## Dados de Teste (Seed)

| Email | Senha | Tipo | Tags |
|-------|-------|------|------|
| admin@wtc.com | admin123 | OPERATOR | — |
| operador@wtc.com | oper123 | OPERATOR | — |
| joao@test.com | test123 | CLIENT | vip, ativo |
| maria@test.com | test123 | CLIENT | ativo |
| pedro@test.com | test123 | CLIENT | vip, beta, ativo |

## Endpoints da API

### Autenticação (público)

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/auth/register` | Registrar novo usuário |
| POST | `/api/auth/login` | Login (retorna JWT) |
| POST | `/api/auth/refresh` | Renovar token |

**Payload login:**
```json
{ "email": "admin@wtc.com", "password": "admin123" }
```

**Resposta:**
```json
{
  "token": "eyJ...",
  "refresh_token": "eyJ...",
  "user_id": "uuid",
  "email": "admin@wtc.com",
  "full_name": "Admin WTC",
  "role": "OPERATOR",
  "tags": [],
  "status": "active"
}
```

### CRM — Clientes (OPERATOR)

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/customers` | Listar clientes (filtros: tag, status, minScore) |
| POST | `/api/customers` | Criar cliente |
| GET | `/api/customers/{id}` | Detalhe do cliente |
| PUT | `/api/customers/{id}` | Atualizar cliente |
| GET | `/api/customers/{id}/timeline` | Perfil 360° (mensagens + notas) |
| POST | `/api/customers/{id}/notes` | Adicionar anotação rápida |

### Segmentos (OPERATOR)

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/segments` | Listar segmentos |
| POST | `/api/segments` | Criar segmento |
| PUT | `/api/segments/{id}` | Atualizar segmento |
| DELETE | `/api/segments/{id}` | Remover segmento |

### Chat & Mensageria (autenticado)

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/messages` | Enviar mensagem (1:1 ou segmento) |
| GET | `/api/messages/{id}` | Detalhe da mensagem |
| GET | `/api/inbox/{customerId}` | Inbox do cliente |
| PUT | `/api/messages/{id}/read` | Marcar como lida |
| PUT | `/api/messages/{id}/star` | Favoritar/desfavoritar |

**Payload envio de mensagem:**
```json
{
  "type": "CHAT",
  "recipient_id": "uuid-do-cliente",
  "content": {
    "title": "Campanha Especial",
    "body": "Participe do nosso evento exclusivo!",
    "image_url": "https://example.com/img.jpg",
    "buttons": [
      { "label": "Inscrever-se", "action": "https://wtc.com/evento/inscricao" },
      { "label": "Saiba Mais", "action": "deeplink://products" }
    ]
  }
}
```

### Campanhas Express (OPERATOR)

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/campaigns` | Listar campanhas |
| POST | `/api/campaigns` | Criar campanha |
| POST | `/api/campaigns/{id}/send` | Enviar campanha para segmento |

### Notificações (autenticado)

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/notifications` | Listar notificações do usuário |
| PUT | `/api/notifications/{id}/read` | Marcar como lida |
| PUT | `/api/notifications/read-all` | Marcar todas como lidas |

### Auditoria (OPERATOR)

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/audit-logs` | Listar logs (filtros: resource, userId) |

## WebSocket (Tempo Real)

- **Endpoint:** `ws://localhost:8080/ws` (protocolo STOMP)
- **Subscribe mensagens:** `/topic/messages/{userId}`
- **Subscribe notificações:** `/topic/notifications/{userId}`

Quando uma mensagem é enviada via REST, o backend automaticamente:
1. Salva no MongoDB
2. Cria notificação para os destinatários
3. Broadcast via WebSocket para os canais dos destinatários

## Modelo de Dados (MongoDB)

### Collections

| Collection | Descrição |
|------------|-----------|
| `users` | Operadores e clientes (auth + perfil) |
| `customers` | Dados CRM (tags, score, status, notas) |
| `segments` | Segmentos para categorização |
| `messages` | Mensagens 1:1 e broadcast |
| `campaigns` | Campanhas express |
| `notifications` | Notificações por usuário |
| `audit_logs` | Registro de operações (governança) |

## Segurança

- Senhas hash com BCrypt
- JWT com expiração de 24h (access) / 7 dias (refresh)
- Roles: OPERATOR (acesso total CRM) / CLIENT (dados próprios)
- CORS habilitado para integração com app iOS
- Auditoria automática via AOP em operações de escrita

## Arquitetura

```
Controller → Service → Repository → MongoDB
     ↓
  AuditAspect (AOP)
     ↓
  AuditLog
     
Service → WebSocketService → STOMP Broker → Clients
```
