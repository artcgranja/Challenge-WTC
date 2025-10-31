-- ============================================
-- WTC Chat App - Database Schema
-- ============================================
-- Este arquivo contém o schema completo do banco de dados
-- para o WTC Chat App usando Supabase/PostgreSQL
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. PROFILES TABLE
-- ============================================
-- Armazena informações dos usuários/clientes
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    tags TEXT[] DEFAULT '{}',
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index para busca por email
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- Index para busca por tags (usando GIN para arrays)
CREATE INDEX IF NOT EXISTS idx_profiles_tags ON profiles USING GIN(tags);

-- ============================================
-- 2. MESSAGES TABLE
-- ============================================
-- Armazena mensagens e campanhas
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type TEXT NOT NULL CHECK (type IN ('chat', 'campaign')),
    recipient_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    segment_tags TEXT[] DEFAULT '{}',
    content JSONB NOT NULL,
    read_at TIMESTAMPTZ,
    starred BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index para busca por recipient
CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_id);

-- Index para busca por tags (usando GIN para arrays)
CREATE INDEX IF NOT EXISTS idx_messages_tags ON messages USING GIN(segment_tags);

-- Index para busca por tipo
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(type);

-- Index para ordenação por data
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- ============================================
-- 3. NOTIFICATIONS TABLE
-- ============================================
-- Armazena notificações in-app
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT DEFAULT 'message' CHECK (type IN ('message', 'campaign', 'system')),
    read BOOLEAN DEFAULT FALSE,
    message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index para busca por usuário
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);

-- Index para busca por não lidas
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, read);

-- Index para ordenação por data
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- ============================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================
-- Habilita RLS para garantir que usuários só vejam suas próprias mensagens

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policies para PROFILES
-- Usuários podem ver apenas seu próprio perfil
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Usuários podem atualizar apenas seu próprio perfil
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE
    USING (auth.uid() = id);

-- Policies para MESSAGES
-- Usuários podem ver mensagens endereçadas a eles OU que correspondam suas tags
CREATE POLICY "Users can view own messages" ON messages
    FOR SELECT
    USING (
        recipient_id = auth.uid() OR
        (segment_tags && (SELECT tags FROM profiles WHERE id = auth.uid()))
    );

-- Usuários podem atualizar mensagens (para marcar como lida, favoritar, etc)
CREATE POLICY "Users can update own messages" ON messages
    FOR UPDATE
    USING (
        recipient_id = auth.uid() OR
        (segment_tags && (SELECT tags FROM profiles WHERE id = auth.uid()))
    );

-- Policies para NOTIFICATIONS
-- Usuários podem ver apenas suas próprias notificações
CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT
    USING (user_id = auth.uid());

-- Usuários podem atualizar suas próprias notificações
CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE
    USING (user_id = auth.uid());

-- ============================================
-- 5. FUNCTIONS
-- ============================================

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para profiles
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para messages
DROP TRIGGER IF EXISTS update_messages_updated_at ON messages;
CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para criar notificação quando nova mensagem é inserida
CREATE OR REPLACE FUNCTION create_notification_on_new_message()
RETURNS TRIGGER AS $$
BEGIN
    -- Se a mensagem tem recipient_id, cria notificação para ele
    IF NEW.recipient_id IS NOT NULL THEN
        INSERT INTO notifications (user_id, title, body, type, message_id)
        VALUES (
            NEW.recipient_id,
            (NEW.content->>'title'),
            (NEW.content->>'body'),
            NEW.type,
            NEW.id
        );
    END IF;

    -- Se a mensagem tem segment_tags, cria notificação para usuários com essas tags
    IF NEW.segment_tags IS NOT NULL AND array_length(NEW.segment_tags, 1) > 0 THEN
        INSERT INTO notifications (user_id, title, body, type, message_id)
        SELECT
            p.id,
            (NEW.content->>'title'),
            (NEW.content->>'body'),
            NEW.type,
            NEW.id
        FROM profiles p
        WHERE p.tags && NEW.segment_tags;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para criar notificação automaticamente
DROP TRIGGER IF EXISTS create_notification_trigger ON messages;
CREATE TRIGGER create_notification_trigger
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION create_notification_on_new_message();

-- ============================================
-- COMENTÁRIOS
-- ============================================
COMMENT ON TABLE profiles IS 'Armazena informações dos usuários/clientes do sistema';
COMMENT ON TABLE messages IS 'Armazena mensagens e campanhas enviadas para usuários';
COMMENT ON TABLE notifications IS 'Armazena notificações in-app para os usuários';

COMMENT ON COLUMN messages.content IS 'JSON com estrutura: {title, body, imageUrl, buttons: [{label, action}]}';
COMMENT ON COLUMN messages.segment_tags IS 'Array de tags para segmentação de campanhas';
COMMENT ON COLUMN messages.recipient_id IS 'ID do destinatário específico (null para campanhas por segmento)';
