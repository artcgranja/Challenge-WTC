-- ============================================
-- WTC Chat App - Seed Data
-- ============================================
-- Dados de teste para o WTC Chat App
-- ============================================

-- ============================================
-- 1. CRIAR USUÁRIOS DE TESTE
-- ============================================
-- IMPORTANTE: Estes usuários devem ser criados via Supabase Auth primeiro
-- Depois você deve atualizar os UUIDs abaixo com os IDs reais

-- Usuário 1: João Silva (VIP)
INSERT INTO profiles (id, full_name, email, phone, avatar_url, tags, status)
VALUES (
    '11111111-1111-1111-1111-111111111111',
    'João Silva',
    'joao@test.com',
    '+55 11 98888-7777',
    'https://i.pravatar.cc/150?img=12',
    ARRAY['vip', 'ativo'],
    'active'
) ON CONFLICT (email) DO NOTHING;

-- Usuário 2: Maria Santos (Regular)
INSERT INTO profiles (id, full_name, email, phone, avatar_url, tags, status)
VALUES (
    '22222222-2222-2222-2222-222222222222',
    'Maria Santos',
    'maria@test.com',
    '+55 11 97777-6666',
    'https://i.pravatar.cc/150?img=45',
    ARRAY['ativo'],
    'active'
) ON CONFLICT (email) DO NOTHING;

-- Usuário 3: Pedro Costa (VIP + Beta)
INSERT INTO profiles (id, full_name, email, phone, avatar_url, tags, status)
VALUES (
    '33333333-3333-3333-3333-333333333333',
    'Pedro Costa',
    'pedro@test.com',
    '+55 11 96666-5555',
    'https://i.pravatar.cc/150?img=33',
    ARRAY['vip', 'beta', 'ativo'],
    'active'
) ON CONFLICT (email) DO NOTHING;

-- ============================================
-- 2. MENSAGENS PARA USUÁRIO ESPECÍFICO
-- ============================================

-- Mensagem de boas-vindas para João
INSERT INTO messages (type, recipient_id, content, created_at)
VALUES (
    'chat',
    '11111111-1111-1111-1111-111111111111',
    '{
        "title": "Bem-vindo ao WTC Chat!",
        "body": "Olá João! Estamos felizes em ter você conosco. Aqui você receberá mensagens importantes e promoções exclusivas.",
        "buttons": [
            {"label": "Ver Meu Perfil", "action": "deeplink://profile"}
        ]
    }'::jsonb,
    NOW() - INTERVAL '2 days'
);

-- Mensagem sobre pedido para Maria
INSERT INTO messages (type, recipient_id, content, created_at)
VALUES (
    'chat',
    '22222222-2222-2222-2222-222222222222',
    '{
        "title": "Seu pedido foi enviado!",
        "body": "Maria, seu pedido #1234 foi enviado e deve chegar em 2 dias úteis. Clique abaixo para acompanhar.",
        "buttons": [
            {"label": "Rastrear Pedido", "action": "deeplink://orders"},
            {"label": "Ver Detalhes", "action": "https://wtc.com/orders/1234"}
        ]
    }'::jsonb,
    NOW() - INTERVAL '1 day'
);

-- ============================================
-- 3. CAMPANHAS POR SEGMENTAÇÃO
-- ============================================

-- Campanha Black Friday (para todos com tag 'vip')
INSERT INTO messages (type, segment_tags, content, created_at)
VALUES (
    'campaign',
    ARRAY['vip'],
    '{
        "title": "Black Friday VIP 2025",
        "body": "Exclusivo para clientes VIP! Aproveite 50% de desconto em TODOS os produtos. Use o cupom BF50VIP no checkout.",
        "imageUrl": "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800",
        "buttons": [
            {"label": "Ver Ofertas", "action": "deeplink://products"},
            {"label": "Copiar Cupom: BF50VIP", "action": "copy:BF50VIP"},
            {"label": "Visitar Loja", "action": "https://wtc.com/blackfriday"}
        ]
    }'::jsonb,
    NOW() - INTERVAL '12 hours'
);

-- Nova Coleção (para todos com tag 'ativo')
INSERT INTO messages (type, segment_tags, content, created_at)
VALUES (
    'campaign',
    ARRAY['ativo'],
    '{
        "title": "Nova Coleção Primavera/Verão",
        "body": "Descubra as últimas tendências da moda! Nossa nova coleção já está disponível com peças exclusivas.",
        "imageUrl": "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800",
        "buttons": [
            {"label": "Ver Coleção", "action": "deeplink://collection"},
            {"label": "Acessar Loja Online", "action": "https://wtc.com/new-collection"}
        ]
    }'::jsonb,
    NOW() - INTERVAL '6 hours'
);

-- Beta Testing (para usuários com tag 'beta')
INSERT INTO messages (type, segment_tags, content, created_at)
VALUES (
    'campaign',
    ARRAY['beta'],
    '{
        "title": "Convite Exclusivo - Beta Tester",
        "body": "Você foi selecionado para testar nossas novas funcionalidades antes de todos! Acesse agora e compartilhe seu feedback.",
        "imageUrl": "https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800",
        "buttons": [
            {"label": "Acessar Beta", "action": "https://beta.wtc.com"},
            {"label": "Dar Feedback", "action": "https://wtc.com/feedback"}
        ]
    }'::jsonb,
    NOW() - INTERVAL '3 hours'
);

-- Promoção Relâmpago (para todos 'vip')
INSERT INTO messages (type, segment_tags, content, created_at)
VALUES (
    'campaign',
    ARRAY['vip'],
    '{
        "title": "⚡ Promoção Relâmpago - 2 horas!",
        "body": "CORRE! Apenas nas próximas 2 horas: frete grátis + 30% OFF em produtos selecionados. Não perca!",
        "imageUrl": "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800",
        "buttons": [
            {"label": "Aproveitar Agora", "action": "deeplink://products"},
            {"label": "Cupom: FLASH30", "action": "copy:FLASH30"}
        ]
    }'::jsonb,
    NOW() - INTERVAL '30 minutes'
);

-- Evento Presencial
INSERT INTO messages (type, segment_tags, content, created_at)
VALUES (
    'campaign',
    ARRAY['vip', 'ativo'],
    '{
        "title": "Convite: Lançamento de Produtos",
        "body": "Você está convidado para nosso evento exclusivo de lançamento! Data: 15/11, às 19h. Drinks e brindes para os convidados.",
        "imageUrl": "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800",
        "buttons": [
            {"label": "Confirmar Presença", "action": "https://wtc.com/events/2025-11"},
            {"label": "Ver Localização", "action": "https://maps.google.com/?q=WTC+Events"}
        ]
    }'::jsonb,
    NOW() - INTERVAL '2 hours'
);

-- Pesquisa de Satisfação
INSERT INTO messages (type, segment_tags, content, created_at)
VALUES (
    'chat',
    ARRAY['ativo'],
    '{
        "title": "Sua opinião é importante!",
        "body": "Ajude-nos a melhorar! Responda nossa rápida pesquisa de satisfação e concorra a um vale-compras de R$ 500.",
        "buttons": [
            {"label": "Responder Pesquisa", "action": "https://wtc.com/survey"},
            {"label": "Mais Tarde", "action": "deeplink://profile"}
        ]
    }'::jsonb,
    NOW() - INTERVAL '4 hours'
);

-- ============================================
-- VERIFICAÇÃO
-- ============================================

-- Contar mensagens por tipo
SELECT type, COUNT(*) as total
FROM messages
GROUP BY type;

-- Contar perfis
SELECT COUNT(*) as total_profiles
FROM profiles;

-- Mostrar mensagens recentes
SELECT
    m.type,
    m.content->>'title' as title,
    m.recipient_id,
    m.segment_tags,
    m.created_at
FROM messages m
ORDER BY m.created_at DESC
LIMIT 10;
