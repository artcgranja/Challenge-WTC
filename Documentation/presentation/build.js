const pptxgen = require("pptxgenjs");

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE"; // 13.333 x 7.5
pres.author = "Arthur Cavalcanti Granja";
pres.title = "WTC Chat App — Challenge WTC 2025 (Sprint 2)";

const W = 13.333, H = 7.5;

// Palette (WTC dark + orange accent)
const BG = "0E1525";
const SURF = "1B2438";
const SURF2 = "232E47";
const ORANGE = "F2960C";
const BLUE = "4F8DF7";
const TEAL = "2DD4BF";
const PURPLE = "C792EA";
const TEXT = "F4F6FB";
const MUT = "94A1B8";
const LINE = "33415C";

const HFONT = "Trebuchet MS";
const BFONT = "Calibri";
const MONO = "Consolas";

const sh = () => ({ type: "outer", color: "000000", blur: 9, offset: 3, angle: 135, opacity: 0.35 });

function base(slide) { slide.background = { color: BG }; }

function kicker(slide, txt) {
  slide.addText(txt.toUpperCase(), {
    x: 0.7, y: 0.5, w: 11.9, h: 0.32, margin: 0,
    fontFace: HFONT, fontSize: 12, bold: true, color: ORANGE, charSpacing: 3,
  });
}

function title(slide, txt) {
  slide.addText(txt, {
    x: 0.7, y: 0.82, w: 11.9, h: 0.8, margin: 0,
    fontFace: HFONT, fontSize: 30, bold: true, color: TEXT,
  });
}

function pageNum(slide, n) {
  slide.addText(String(n).padStart(2, "0") + " · WTC Chat App", {
    x: 10.0, y: 7.04, w: 3.0, h: 0.3, margin: 0,
    fontFace: BFONT, fontSize: 9, color: MUT, align: "right",
  });
}

// code/JSON box
function codeBox(slide, x, y, w, h, label, labelColor, code, codeSize) {
  slide.addText(label, { x, y, w, h: 0.3, margin: 0, fontFace: HFONT, fontSize: 12, bold: true, color: labelColor });
  slide.addShape(pres.shapes.RECTANGLE, { x, y: y + 0.34, w, h: h - 0.34, fill: { color: "121A2E" }, line: { color: LINE, width: 1 } });
  slide.addText(code, { x: x + 0.18, y: y + 0.46, w: w - 0.36, h: h - 0.58, margin: 0, fontFace: MONO, fontSize: codeSize || 10.5, color: TEXT, valign: "top" });
}

// endpoint row (method chip + route + access)
function endpointList(slide, x, y, w, rows, rowH) {
  let cy = y;
  const mColor = { GET: TEAL, POST: ORANGE, PUT: BLUE, DELETE: "F2706C", "GET/PUT": BLUE, "GET/POST": ORANGE, "PUT/DELETE": "F2706C" };
  rows.forEach(([m, route, access]) => {
    slide.addShape(pres.shapes.RECTANGLE, { x, y: cy, w, h: rowH, fill: { color: SURF }, line: { color: LINE, width: 1 } });
    slide.addText(m, { x: x + 0.1, y: cy, w: 1.35, h: rowH, margin: 0, valign: "middle", align: "center", fontFace: HFONT, fontSize: 10.5, bold: true, color: mColor[m] || TEXT });
    slide.addText(route, { x: x + 1.5, y: cy, w: w - 2.95, h: rowH, margin: 0, valign: "middle", fontFace: MONO, fontSize: 10.5, color: TEXT });
    slide.addText(access, { x: x + w - 1.45, y: cy, w: 1.4, h: rowH, margin: 0, valign: "middle", align: "right", fontFace: BFONT, fontSize: 9, italic: true, color: MUT });
    cy += rowH + 0.08;
  });
}

// ====================================================================
// 1. TITLE
// ====================================================================
let s = pres.addSlide(); base(s);
s.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: W, h: H, fill: { color: BG } });
s.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 0.22, h: H, fill: { color: ORANGE } });
s.addShape(pres.shapes.OVAL, { x: 10.2, y: -2.0, w: 5.4, h: 5.4, fill: { color: SURF }, line: { color: SURF } });
s.addShape(pres.shapes.OVAL, { x: 11.6, y: 4.4, w: 3.6, h: 3.6, fill: { color: "16203A" }, line: { color: "16203A" } });
s.addText("CHALLENGE WTC 2025  ·  FIAP  ·  ANÁLISE E DESENVOLVIMENTO DE SISTEMAS", {
  x: 0.9, y: 1.45, w: 11, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 14, bold: true, color: ORANGE, charSpacing: 2,
});
s.addText("WTC Chat App", { x: 0.85, y: 2.0, w: 11.5, h: 1.3, margin: 0, fontFace: HFONT, fontSize: 58, bold: true, color: TEXT });
s.addText("Plataforma de comunicação CRM — app iOS nativo + backend Java robusto, integrados via APIs REST reais e mensageria em tempo real.", {
  x: 0.9, y: 3.35, w: 9.2, h: 1.0, margin: 0, fontFace: BFONT, fontSize: 18, color: MUT,
});
s.addText([
  { text: "SPRINT 2", options: { bold: true, color: BG } },
  { text: "   Backend real · sem mocks", options: { color: BG } },
], { x: 0.9, y: 4.7, w: 5.6, h: 0.55, fill: { color: ORANGE }, align: "center", valign: "middle", fontFace: HFONT, fontSize: 15, rectRadius: 0.05 });
s.addText("Documentação técnica completa — arquitetura · modelo de dados · endpoints · execução · testes", {
  x: 0.9, y: 5.55, w: 9.5, h: 0.4, margin: 0, fontFace: BFONT, fontSize: 13, color: TEXT,
});
s.addText("Arthur Cavalcanti Granja · RM 560650   |   Entrega: 19/05 · 23h00   |   2TDS", {
  x: 0.9, y: 6.35, w: 9.5, h: 0.4, margin: 0, fontFace: BFONT, fontSize: 13, color: MUT,
});

// ====================================================================
// 2. EQUIPE
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Integrantes");
title(s, "Equipe");
s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: 2.55, w: 9.6, h: 1.1, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: 2.55, w: 0.11, h: 1.1, fill: { color: ORANGE } });
s.addText("Arthur Cavalcanti Granja", { x: 1.1, y: 2.7, w: 6.7, h: 0.8, margin: 0, valign: "middle", fontFace: HFONT, fontSize: 22, bold: true, color: TEXT });
s.addText("RM 560650", { x: 7.9, y: 2.7, w: 2.2, h: 0.8, margin: 0, valign: "middle", align: "right", fontFace: MONO, fontSize: 19, bold: true, color: ORANGE });
s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: 4.0, w: 9.6, h: 1.05, fill: { color: "16203A" }, line: { color: LINE, width: 1 } });
s.addText("Análise e Desenvolvimento de Sistemas — 2TDS · FIAP\nChallenge WTC 2025 · Sprint 2 — Backend + Integração · Equipe SOLO", {
  x: 1.0, y: 4.0, w: 9.0, h: 1.05, margin: 0, valign: "middle", fontFace: BFONT, fontSize: 14, color: MUT,
});
s.addText("Repositório: github.com/artcgranja/Challenge-WTC", {
  x: 0.7, y: 5.4, w: 9.6, h: 0.4, margin: 0, fontFace: MONO, fontSize: 12, color: TEAL,
});
pageNum(s, 2);

// ====================================================================
// 3. VISÃO GERAL
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Contexto & Solução");
title(s, "Visão Geral");
const colW = 5.75;
function panel(x, head, color, items) {
  s.addShape(pres.shapes.RECTANGLE, { x, y: 2.0, w: colW, h: 4.5, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
  s.addShape(pres.shapes.RECTANGLE, { x, y: 2.0, w: colW, h: 0.62, fill: { color } });
  s.addText(head, { x: x + 0.25, y: 2.0, w: colW - 0.5, h: 0.62, margin: 0, valign: "middle", fontFace: HFONT, fontSize: 16, bold: true, color: BG });
  s.addText(items.map((t, i) => ({ text: t, options: { bullet: { code: "2022", indent: 16 }, breakLine: i < items.length - 1, paraSpaceAfter: 14, color: TEXT } })),
    { x: x + 0.35, y: 2.8, w: colW - 0.7, h: 3.5, margin: 0, valign: "middle", fontFace: BFONT, fontSize: 14 });
}
panel(0.7, "PROBLEMA", BLUE, [
  "Comunicação fragmentada entre empresa e clientes",
  "Falta de personalização nas mensagens de marketing",
  "Notificações sem interatividade",
  "Dificuldade em segmentar o público-alvo",
]);
panel(6.85, "SOLUÇÃO", ORANGE, [
  "Mensagens segmentadas 1:1 e por grupo/tag",
  "Push + pop-up in-app, histórico de chat",
  "Botões de ação e deeplinks interativos",
  "CRM no app (operador) + tempo real (WebSocket)",
]);
s.addText("WTC Business Club São Paulo — operadores/marketing disparam promoções, campanhas, banners e eventos diretamente para clientes ou segmentos.", {
  x: 0.7, y: 6.65, w: 12.0, h: 0.4, margin: 0, fontFace: BFONT, fontSize: 11.5, italic: true, color: MUT,
});
pageNum(s, 3);

// ====================================================================
// 4. ARQUITETURA
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Diagrama");
title(s, "Arquitetura do Backend");
const colTop = 2.45, colH = 3.2, cy = colTop + colH / 2;
s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: colTop, w: 3.0, h: colH, fill: { color: SURF }, line: { color: BLUE, width: 2 }, shadow: sh() });
s.addText("App iOS", { x: 0.7, y: colTop + 0.35, w: 3.0, h: 0.5, margin: 0, align: "center", fontFace: HFONT, fontSize: 18, bold: true, color: BLUE });
s.addText([
  { text: "SwiftUI · MVVM", options: { breakLine: true } },
  { text: "Combine · iOS 15+", options: { breakLine: true } },
  { text: "Zero deps externas", options: {} },
], { x: 0.85, y: colTop + 1.0, w: 2.7, h: 1.8, margin: 0, align: "center", valign: "middle", fontFace: BFONT, fontSize: 13, color: MUT, paraSpaceAfter: 8 });
const mx = 4.95, mw = 3.85;
s.addShape(pres.shapes.RECTANGLE, { x: mx, y: colTop, w: mw, h: colH, fill: { color: SURF }, line: { color: ORANGE, width: 2 }, shadow: sh() });
s.addText("Spring Boot 3.3  ·  Java 17", { x: mx, y: colTop + 0.15, w: mw, h: 0.45, margin: 0, align: "center", fontFace: HFONT, fontSize: 16, bold: true, color: ORANGE });
const bars = [
  ["Controllers · Services · Repositories", TEXT, "1B2B45"],
  ["Spring Security — JWT · BCrypt · Roles", TEAL, "16282E"],
  ["Spring AOP — auditoria automática", PURPLE, "241B33"],
];
let by = colTop + 0.7;
bars.forEach(([t, c, fillc]) => {
  s.addShape(pres.shapes.RECTANGLE, { x: mx + 0.2, y: by, w: mw - 0.4, h: 0.72, fill: { color: fillc }, line: { color: LINE, width: 1 } });
  s.addText(t, { x: mx + 0.32, y: by, w: mw - 0.64, h: 0.72, margin: 0, valign: "middle", align: "center", fontFace: BFONT, fontSize: 12, bold: true, color: c });
  by += 0.83;
});
const rx = 10.05, rw = 2.6;
s.addShape(pres.shapes.RECTANGLE, { x: rx, y: colTop, w: rw, h: colH, fill: { color: SURF }, line: { color: TEAL, width: 2 }, shadow: sh() });
s.addText("MongoDB", { x: rx, y: colTop + 0.85, w: rw, h: 0.5, margin: 0, align: "center", fontFace: HFONT, fontSize: 18, bold: true, color: TEAL });
s.addText([
  { text: "NoSQL", options: { breakLine: true } },
  { text: "7 collections", options: {} },
], { x: rx, y: colTop + 1.45, w: rw, h: 1.0, margin: 0, align: "center", valign: "top", fontFace: BFONT, fontSize: 13, color: MUT, paraSpaceAfter: 6 });
s.addText("REST/JSON · JWT", { x: 3.7, y: cy - 0.78, w: 1.25, h: 0.3, margin: 0, align: "center", fontFace: BFONT, fontSize: 9.5, color: BLUE });
s.addShape(pres.shapes.LINE, { x: 3.72, y: cy - 0.4, w: 1.21, h: 0, line: { color: BLUE, width: 2.5, endArrowType: "triangle" } });
s.addText("STOMP / WebSocket", { x: 3.6, y: cy + 0.2, w: 1.45, h: 0.3, margin: 0, align: "center", fontFace: BFONT, fontSize: 9.5, color: TEAL });
s.addShape(pres.shapes.LINE, { x: 3.72, y: cy + 0.55, w: 1.21, h: 0, line: { color: TEAL, width: 2.5, dashType: "dash", beginArrowType: "triangle", endArrowType: "triangle" } });
s.addShape(pres.shapes.LINE, { x: 8.82, y: cy, w: 1.21, h: 0, line: { color: TEAL, width: 2.5, beginArrowType: "triangle", endArrowType: "triangle" } });
s.addText("Camadas: Controller (REST) → Service (regra de negócio) → Repository (Spring Data) → MongoDB. Em paralelo: cria Notification + broadcast WebSocket; AuditAspect (AOP) registra toda escrita.", {
  x: 0.7, y: 6.25, w: 12.0, h: 0.6, margin: 0, fontFace: BFONT, fontSize: 12, color: MUT, italic: true,
});
pageNum(s, 4);

// ====================================================================
// 5. FLUXO DE UMA MENSAGEM
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Como funciona — passo a passo");
title(s, "Fluxo de Envio de uma Mensagem");
const steps = [
  ["1", "Operador autentica", "POST /api/auth/login → recebe JWT (access 24h). Header Authorization: Bearer <token> em todas as chamadas seguintes.", ORANGE],
  ["2", "Envia a mensagem", "POST /api/messages com type CHAT (1:1, recipient_id) ou CAMPAIGN (segment_tags[]). JwtAuthFilter valida o token e injeta o senderId.", BLUE],
  ["3", "Persiste no MongoDB", "MessageService grava o documento na collection messages com status SENT e createdAt.", TEAL],
  ["4", "Notifica destinatários", "Cria Notification por destinatário (1:1 = recipient; segmento = todos os users cujas tags batem).", PURPLE],
  ["5", "Broadcast em tempo real", "WebSocketService publica em /topic/messages/{userId} via STOMP — app recebe sem polling.", BLUE],
  ["6", "Auditoria automática", "AuditAspect (@AfterReturning) grava em audit_logs: userId, action, resource, resourceId, ipAddress, timestamp.", ORANGE],
];
let fy = 1.9;
steps.forEach(([n, h, d, c]) => {
  s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: fy, w: 12.0, h: 0.78, fill: { color: SURF }, line: { color: LINE, width: 1 } });
  s.addShape(pres.shapes.OVAL, { x: 0.85, y: fy + 0.16, w: 0.46, h: 0.46, fill: { color: c }, line: { color: c } });
  s.addText(n, { x: 0.85, y: fy + 0.16, w: 0.46, h: 0.46, margin: 0, align: "center", valign: "middle", fontFace: HFONT, fontSize: 16, bold: true, color: BG });
  s.addText(h, { x: 1.5, y: fy + 0.06, w: 3.0, h: 0.66, margin: 0, valign: "middle", fontFace: HFONT, fontSize: 14, bold: true, color: c });
  s.addText(d, { x: 4.55, y: fy + 0.06, w: 8.0, h: 0.66, margin: 0, valign: "middle", fontFace: BFONT, fontSize: 11, color: TEXT });
  fy += 0.85;
});
pageNum(s, 5);

// ====================================================================
// 6. STACK & SEGURANÇA
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Tecnologias");
title(s, "Stack & Segurança");
const stackRows = [
  ["iOS", "Swift 5.9 · SwiftUI · Combine · MVVM · iOS 15+ · sem dependências externas (URLSession + STOMP manual)"],
  ["Backend", "Java 17 · Spring Boot 3.3 · Spring Security · Spring Data MongoDB · Spring WebSocket · Spring AOP · Lombok · JJWT"],
  ["Banco", "MongoDB 6.0+ — NoSQL orientado a documentos, 7 collections, IDs UUID string"],
  ["Auth", "JWT (access 24h / refresh 7d) · BCrypt · roles OPERATOR / CLIENT no claim"],
  ["Realtime", "WebSocket STOMP — /topic/messages/{userId} · /topic/notifications/{userId}"],
  ["Governança", "Auditoria automática via AOP (@AfterReturning) em toda operação de escrita (POST/PUT/DELETE)"],
];
let sy = 2.0;
stackRows.forEach(([k, v]) => {
  s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: sy, w: 12.0, h: 0.74, fill: { color: SURF }, line: { color: LINE, width: 1 } });
  s.addText(k, { x: 0.7, y: sy, w: 1.85, h: 0.74, margin: 0, align: "center", valign: "middle", fontFace: HFONT, fontSize: 14, bold: true, color: ORANGE });
  s.addShape(pres.shapes.LINE, { x: 2.55, y: sy + 0.1, w: 0, h: 0.54, line: { color: LINE, width: 1 } });
  s.addText(v, { x: 2.8, y: sy, w: 9.7, h: 0.74, margin: 0, valign: "middle", fontFace: BFONT, fontSize: 12.5, color: TEXT });
  sy += 0.82;
});
pageNum(s, 6);

// ====================================================================
// 7. MODELO DE DADOS — VISÃO GERAL
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Modelo NoSQL — MongoDB");
title(s, "Modelo de Dados — 7 Collections");
const cols = [
  ["users", "operadores + clientes — auth, perfil, role, tags[], status", TEAL],
  ["customers", "registro CRM — userId, tags[], score 0-100, status, notes[], segmentIds[]", BLUE],
  ["segments", "name, description, tags[], createdBy", PURPLE],
  ["messages", "type, senderId, recipientId, segmentTags[], content{}, status, readAt, starred", ORANGE],
  ["campaigns", "name, segmentId, content{}, deeplink, status, sentBy, messageCount", BLUE],
  ["notifications", "userId, title, body, type, read, messageId", PURPLE],
  ["audit_logs", "userId, action, resource, resourceId, details, ipAddress, timestamp", TEAL],
];
let my = 1.85;
cols.forEach(([c, f, col]) => {
  s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: my, w: 12.0, h: 0.62, fill: { color: SURF }, line: { color: LINE, width: 1 } });
  s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: my, w: 0.09, h: 0.62, fill: { color: col } });
  s.addText(c, { x: 0.95, y: my, w: 2.2, h: 0.62, margin: 0, valign: "middle", fontFace: MONO, fontSize: 13, bold: true, color: col });
  s.addText(f, { x: 3.15, y: my, w: 9.4, h: 0.62, margin: 0, valign: "middle", fontFace: MONO, fontSize: 10.5, color: TEXT });
  my += 0.7;
});
s.addText("Relações por referência (sem joins): customers.userId → users.id   ·   campaigns.segmentId → segments.id   ·   notifications.messageId → messages.id", {
  x: 0.7, y: 6.75, w: 12.0, h: 0.35, margin: 0, fontFace: BFONT, fontSize: 11, color: MUT, italic: true,
});
pageNum(s, 7);

// ====================================================================
// 8. MODELO — users & customers
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Modelo NoSQL — documentos reais");
title(s, "Documentos: users & customers");
codeBox(s, 0.7, 1.75, 6.0, 3.6, "users", TEAL,
`{
  "id": "uuid",                // _id
  "email": "joao@test.com",    // único*
  "password": "$2a$ (BCrypt)",
  "fullName": "João Silva",
  "phone": "(11) 99999-1111",
  "avatarUrl": null,
  "role": "CLIENT",            // OPERATOR|CLIENT
  "tags": ["vip", "ativo"],
  "status": "active",
  "createdAt": "2026-05-19T...",
  "updatedAt": "2026-05-19T..."
}`, 10.5);
codeBox(s, 6.95, 1.75, 5.7, 3.6, "customers", BLUE,
`{
  "id": "uuid",
  "userId": "uuid (→ users.id)*",
  "tags": ["vip", "ativo"],
  "score": 85,                 // 0-100
  "status": "ACTIVE",          // ACTIVE
                               // INACTIVE
                               // PENDING
  "notes": [
    { "text": "Cliente VIP",
      "createdBy": "uuid",
      "createdAt": "..." }
  ],
  "segmentIds": ["uuid"],
  "createdAt": "...", "updatedAt": "..."
}`, 10.5);
s.addText("* campo indexado   ·   id = UUID string (compatível com tipo UUID do iOS)   ·   senhas em BCrypt, nunca retornadas pela API", {
  x: 0.7, y: 6.3, w: 12.0, h: 0.3, margin: 0, fontFace: BFONT, fontSize: 10.5, color: MUT, italic: true,
});
pageNum(s, 8);

// ====================================================================
// 9. MODELO — segments & messages
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Modelo NoSQL — documentos reais");
title(s, "Documentos: segments & messages");
codeBox(s, 0.7, 1.75, 5.0, 3.95, "segments", PURPLE,
`{
  "id": "uuid",
  "name": "VIP",
  "description":
    "Clientes VIP do WTC",
  "tags": ["vip"],
  "createdBy": "uuid",
  "createdAt": "...",
  "updatedAt": "..."
}`, 10.5);
codeBox(s, 5.95, 1.75, 6.7, 3.95, "messages  (content embute buttons[])", ORANGE,
`{
  "id": "uuid",
  "type": "CAMPAIGN",          // CHAT|CAMPAIGN
  "senderId": "uuid",
  "recipientId": "uuid*",      // 1:1 (CHAT)
  "segmentTags": ["vip"],      // broadcast
  "content": {
    "title": "Black Friday WTC 2026",
    "body": "Condições exclusivas...",
    "imageUrl": "https://.../img.jpg",
    "buttons": [
      { "label": "Inscrever-se",
        "action": "https://wtc.com/bf" }
    ]
  },
  "status": "SENT",   // SENT|DELIVERED|READ|FAILED
  "readAt": null, "starred": false,
  "createdAt": "..."
}`, 9.8);
pageNum(s, 9);

// ====================================================================
// 10. MODELO — campaigns, notifications, audit_logs
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Modelo NoSQL — documentos reais");
title(s, "Documentos: campaigns · notifications · audit_logs");
codeBox(s, 0.7, 1.75, 4.0, 3.5, "campaigns", BLUE,
`{
  "id": "uuid",
  "name": "Black Friday",
  "segmentId": "uuid",
  "content": { ... },
  "deeplink":
    "deeplink://promo",
  "status": "SENT",
       // DRAFT|SENT
  "sentAt": "...",
  "sentBy": "uuid",
  "messageCount": 2,
  "createdAt": "..."
}`, 9.8);
codeBox(s, 4.95, 1.75, 3.85, 3.5, "notifications", PURPLE,
`{
  "id": "uuid",
  "userId": "uuid*",
  "title": "Nova msg",
  "body": "...",
  "type": "MESSAGE",
   // MESSAGE
   // CAMPAIGN
   // SYSTEM
  "read": false,
  "messageId": "uuid",
  "createdAt": "..."
}`, 9.8);
codeBox(s, 9.05, 1.75, 3.6, 3.5, "audit_logs", TEAL,
`{
  "id": "uuid",
  "userId": "uuid",
  "action": "CREATE",
  "resource":
    "messages",
  "resourceId":
    "uuid",
  "details": "...",
  "ipAddress":
    "127.0.0.1",
  "timestamp": "..."
}`, 9.8);
pageNum(s, 10);

// ====================================================================
// 11. SEGMENTAÇÃO SERVER-SIDE
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Regra-chave de negócio");
title(s, "Segmentação Server-Side (Inbox)");
s.addText("A inbox de um cliente combina mensagens diretas (1:1) e campanhas cujas tags de segmento batem com as tags do usuário — uma única query MongoDB com $or, sem joins:", {
  x: 0.7, y: 1.8, w: 12.0, h: 0.7, margin: 0, fontFace: BFONT, fontSize: 14, color: TEXT,
});
codeBox(s, 0.7, 2.65, 12.0, 1.65,
  "MessageRepository.findInbox(userId, userTags, sort)", ORANGE,
`@Query("{ '$or': [ { 'recipientId': ?0 },
                  { 'segmentTags': { '$in': ?1 } } ] }")`, 13);
const segCards = [
  ["Mensagem 1:1", "recipientId = userId → entra na inbox do destinatário direto.", BLUE],
  ["Campanha por tag", "segmentTags ∩ userTags ≠ ∅ → entra para todos os clientes do segmento.", TEAL],
  ["Vantagem", "Filtro no servidor (sem RLS, sem lógica no app); GET /api/inbox/{id} ordenado por createdAt desc.", ORANGE],
];
let scx = 0.7;
segCards.forEach(([h, d, c]) => {
  s.addShape(pres.shapes.RECTANGLE, { x: scx, y: 4.55, w: 3.85, h: 2.05, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
  s.addShape(pres.shapes.RECTANGLE, { x: scx, y: 4.55, w: 3.85, h: 0.08, fill: { color: c } });
  s.addText(h, { x: scx + 0.22, y: 4.75, w: 3.4, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 14, bold: true, color: c });
  s.addText(d, { x: scx + 0.22, y: 5.2, w: 3.45, h: 1.3, margin: 0, valign: "top", fontFace: BFONT, fontSize: 11.5, color: TEXT });
  scx += 4.07;
});
pageNum(s, 11);

// ====================================================================
// 12. ENDPOINTS — MAPA GERAL
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Especificação da API");
title(s, "Mapa de Endpoints");
const epHeader = ["Grupo", "Endpoints", "Acesso"];
const epTable = [
  ["Auth", "POST /register · /login · /refresh", "público"],
  ["Customers", "GET/POST /customers · GET/PUT /{id} · /{id}/timeline · POST /{id}/notes", "OPERATOR"],
  ["Segments", "GET/POST /segments · GET/PUT/DELETE /{id}", "OPERATOR"],
  ["Messages", "POST /messages · GET /{id} · /inbox/{id} · /sent/{id} · PUT /{id}/read · /star", "autenticado"],
  ["Campaigns", "GET/POST /campaigns · POST /{id}/send", "OPERATOR"],
  ["Notifications", "GET /notifications · PUT /{id}/read · /read-all", "autenticado"],
  ["Audit", "GET /audit-logs?resource&userId", "OPERATOR"],
  ["WebSocket", "ws://host:8080/ws → /topic/messages/{id} · /topic/notifications/{id}", "STOMP"],
];
s.addTable(
  [epHeader.map(h => ({ text: h, options: { fill: { color: SURF2 }, color: ORANGE, bold: true, fontFace: HFONT, fontSize: 12 } })),
   ...epTable.map(r => r.map((c, i) => ({ text: c, options: { fill: { color: SURF }, color: i === 0 ? TEAL : (i === 2 ? MUT : TEXT), fontFace: i === 1 ? MONO : BFONT, fontSize: 11, bold: i === 0 } })))],
  { x: 0.7, y: 1.85, w: 12.0, colW: [1.9, 8.3, 1.8], border: { pt: 0.5, color: LINE }, rowH: 0.47, valign: "middle", margin: [3, 6, 3, 6] }
);
s.addText("Prefixo base: /api   ·   todas as rotas (exceto auth) exigem header  Authorization: Bearer <jwt>", {
  x: 0.7, y: 6.62, w: 12.0, h: 0.3, margin: 0, fontFace: BFONT, fontSize: 11, color: MUT, italic: true,
});
pageNum(s, 12);

// ====================================================================
// 13. ENDPOINTS — AUTH (payload & resposta)
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Especificação — rota · método · payload · resposta");
title(s, "Auth  ·  público");
endpointList(s, 0.7, 1.8, 5.0, [
  ["POST", "/api/auth/login", "público"],
  ["POST", "/api/auth/register", "público"],
  ["POST", "/api/auth/refresh", "público"],
], 0.52);
s.addText("register exige email, password, fullName; role/tags/phone opcionais. login retorna 200; register 201; refresh troca refresh_token por novo par.", {
  x: 0.7, y: 3.7, w: 5.0, h: 2.8, margin: 0, valign: "top", fontFace: BFONT, fontSize: 12, color: MUT,
});
codeBox(s, 5.95, 1.75, 3.3, 3.2, "REQUEST  POST /login", ORANGE,
`{
  "email":
    "admin@wtc.com",
  "password":
    "admin123"
}`, 10);
codeBox(s, 9.4, 1.75, 3.25, 3.2, "RESPONSE  200 OK", TEAL,
`{
  "token": "eyJ...",
  "refresh_token":
    "eyJ...",
  "user_id": "uuid",
  "email": "...",
  "full_name": "...",
  "role": "OPERATOR",
  "tags": [],
  "status": "active"
}`, 10);
pageNum(s, 13);

// ====================================================================
// 14. ENDPOINTS — CUSTOMERS (CRM)
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Especificação — rota · método · payload · resposta");
title(s, "CRM · Customers  ·  OPERATOR");
endpointList(s, 0.7, 1.8, 5.4, [
  ["GET", "/api/customers", "OPERATOR"],
  ["POST", "/api/customers", "OPERATOR"],
  ["GET", "/api/customers/{id}", "OPERATOR"],
  ["PUT", "/api/customers/{id}", "OPERATOR"],
  ["GET", "/{id}/timeline", "OPERATOR"],
  ["POST", "/{id}/notes", "OPERATOR"],
], 0.44);
s.addText("GET aceita filtros: ?tag= ?status= ?minScore=. Lista retorna customer enriquecido com dados do user (full_name, email, phone). timeline = customer + mensagens + notas (perfil 360°).", {
  x: 0.7, y: 5.35, w: 5.4, h: 1.4, margin: 0, valign: "top", fontFace: BFONT, fontSize: 11.5, color: MUT,
});
codeBox(s, 6.35, 1.75, 3.05, 3.5, "REQUEST  POST", ORANGE,
`{
  "userId":
    "uuid",
  "tags":
   ["vip"],
  "score": 85,
  "status":
    "ACTIVE"
}

POST /{id}/notes
{ "text":
   "Ligar amanhã" }`, 9.5);
codeBox(s, 9.55, 1.75, 3.1, 3.5, "RESPONSE 201/200", TEAL,
`{
  "id": "uuid",
  "user_id": "uuid",
  "full_name":
    "João Silva",
  "email": "...",
  "tags": ["vip"],
  "score": 85,
  "status": "ACTIVE",
  "notes": [...],
  "segment_ids": []
}`, 9.5);
pageNum(s, 14);

// ====================================================================
// 15. ENDPOINTS — SEGMENTS & CAMPAIGNS
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Especificação — rota · método · payload · resposta");
title(s, "Segments & Campaigns  ·  OPERATOR");
endpointList(s, 0.7, 1.8, 5.4, [
  ["GET/POST", "/api/segments", "OPERATOR"],
  ["GET", "/api/segments/{id}", "OPERATOR"],
  ["PUT/DELETE", "/api/segments/{id}", "OPERATOR"],
  ["GET/POST", "/api/campaigns", "OPERATOR"],
  ["POST", "/api/campaigns/{id}/send", "OPERATOR"],
], 0.46);
s.addText("POST /campaigns cria DRAFT. POST /{id}/send dispara para o segmento: gera uma mensagem CAMPAIGN por destinatário, marca status SENT, sentAt e messageCount.", {
  x: 0.7, y: 4.75, w: 5.4, h: 1.9, margin: 0, valign: "top", fontFace: BFONT, fontSize: 11.5, color: MUT,
});
codeBox(s, 6.35, 1.75, 3.2, 3.4, "REQUEST campaign", ORANGE,
`{
  "name":
   "Black Friday",
  "segmentId":
   "uuid",
  "content": {
    "title": "...",
    "body": "..."
  },
  "deeplink":
   "deeplink://x"
}`, 9.5);
codeBox(s, 9.7, 1.75, 2.95, 3.4, "RESPONSE 201", TEAL,
`{
  "id": "uuid",
  "name": "...",
  "segmentId":
   "uuid",
  "status":
   "DRAFT",
  "sentBy":
   "uuid",
  "messageCount": 0
}`, 9.5);
pageNum(s, 15);

// ====================================================================
// 16. ENDPOINTS — MESSAGES
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Especificação — rota · método · payload · resposta");
title(s, "Messages  ·  autenticado");
endpointList(s, 0.7, 1.8, 4.2, [
  ["POST", "/api/messages", "autenticado"],
  ["GET", "/messages/{id}", "autenticado"],
  ["GET", "/inbox/{id}", "autenticado"],
  ["GET", "/sent/{id}", "autenticado"],
  ["PUT", "/{id}/read", "autenticado"],
  ["PUT", "/{id}/star", "autenticado"],
], 0.5);
codeBox(s, 5.15, 1.75, 4.0, 3.65, "REQUEST  POST /messages", ORANGE,
`{
  "type": "CHAT",
  "recipient_id":
    "uuid-cliente",
  "content": {
    "title": "Olá!",
    "body": "Mensagem...",
    "image_url": "https://",
    "buttons": [
      { "label": "Ver",
        "action":
        "deeplink://profile" }
    ]
  }
}`, 9.5);
codeBox(s, 9.35, 1.75, 3.3, 3.65, "RESPONSE 201", TEAL,
`{
  "id": "uuid",
  "type": "CHAT",
  "sender_id": "uuid",
  "recipient_id":
    "uuid",
  "content": { ... },
  "status": "SENT",
  "starred": false,
  "created_at": "..."
}

SENT→DELIVERED
   →READ →FAILED`, 9.5);
pageNum(s, 16);

// ====================================================================
// 17. ENDPOINTS — NOTIFICATIONS & AUDIT
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Especificação — rota · método · resposta");
title(s, "Notifications & Audit");
endpointList(s, 0.7, 1.8, 5.4, [
  ["GET", "/api/notifications", "autenticado"],
  ["PUT", "/notifications/{id}/read", "autenticado"],
  ["PUT", "/notifications/read-all", "autenticado"],
  ["GET", "/api/audit-logs", "OPERATOR"],
], 0.48);
s.addText("notifications: userId vem do JWT (não da URL). audit-logs aceita ?resource= e ?userId=. PUT read / read-all retornam 200 sem corpo.", {
  x: 0.7, y: 4.3, w: 5.4, h: 2.3, margin: 0, valign: "top", fontFace: BFONT, fontSize: 11.5, color: MUT,
});
codeBox(s, 6.35, 1.75, 3.05, 3.5, "RESP  notifications", TEAL,
`[
 {
  "id": "uuid",
  "userId": "uuid",
  "title": "Nova msg",
  "body": "...",
  "type": "MESSAGE",
  "read": false,
  "messageId":
    "uuid"
 }
]`, 9.5);
codeBox(s, 9.55, 1.75, 3.1, 3.5, "RESP  audit-logs", PURPLE,
`[
 {
  "id": "uuid",
  "userId": "uuid",
  "action": "CREATE",
  "resource":
    "messages",
  "resourceId":
    "uuid",
  "ipAddress":
    "127.0.0.1",
  "timestamp": "..."
 }
]`, 9.5);
pageNum(s, 17);

// ====================================================================
// 18. TEMPO REAL — WEBSOCKET
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Diferencial — usabilidade");
title(s, "Tempo Real · WebSocket / STOMP");
s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: 1.85, w: 5.85, h: 2.3, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
s.addText("Endpoint & Tópicos", { x: 0.95, y: 2.0, w: 5.3, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 15, bold: true, color: TEAL });
s.addText([
  { text: "ws://localhost:8080/ws  (STOMP)", options: { breakLine: true, color: TEXT } },
  { text: "/topic/messages/{userId}", options: { breakLine: true, color: TEXT } },
  { text: "/topic/notifications/{userId}", options: { color: TEXT } },
], { x: 0.95, y: 2.5, w: 5.4, h: 1.5, margin: 0, fontFace: MONO, fontSize: 12, paraSpaceAfter: 8 });
s.addShape(pres.shapes.RECTANGLE, { x: 6.8, y: 1.85, w: 5.85, h: 2.3, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
s.addText("Quando uma msg é enviada via REST", { x: 7.05, y: 2.0, w: 5.4, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 15, bold: true, color: ORANGE });
s.addText([
  { text: "1. Salva no MongoDB", options: { breakLine: true } },
  { text: "2. Cria Notification por destinatário", options: { breakLine: true } },
  { text: "3. Broadcast STOMP → app sem polling", options: {} },
], { x: 7.05, y: 2.5, w: 5.4, h: 1.5, margin: 0, fontFace: BFONT, fontSize: 12.5, color: TEXT, paraSpaceAfter: 8 });
s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: 4.45, w: 11.95, h: 2.15, fill: { color: "16203A" }, line: { color: LINE, width: 1 } });
s.addText("Por que é um diferencial", { x: 0.95, y: 4.6, w: 11, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 15, bold: true, color: BLUE });
s.addText("Nova mensagem aparece instantaneamente no app — sem refresh, sem polling. O cliente iOS implementa um STOMP client manual sobre URLSessionWebSocketTask (zero dependências externas), atualizando badge e lista em tempo real.", {
  x: 0.95, y: 5.05, w: 11.4, h: 1.4, margin: 0, valign: "top", fontFace: BFONT, fontSize: 13, color: TEXT,
});
pageNum(s, 18);

// ====================================================================
// 19. GOVERNANÇA & AUDITORIA (AOP)
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Governança & Observabilidade");
title(s, "Auditoria Automática (Spring AOP)");
s.addText("Um único AuditAspect intercepta toda operação de escrita com @AfterReturning — zero código manual nos controllers/services. Cada CREATE/UPDATE/DELETE vira um registro imutável em audit_logs.", {
  x: 0.7, y: 1.8, w: 12.0, h: 0.8, margin: 0, fontFace: BFONT, fontSize: 14, color: TEXT,
});
codeBox(s, 0.7, 2.7, 6.0, 2.0, "AuditAspect", PURPLE,
`@AfterReturning("POST|PUT|DELETE
  em controllers")
→ grava AuditLog`, 12);
const auditFields = [
  ["userId", "quem executou (do JWT)"],
  ["action", "CREATE · UPDATE · DELETE"],
  ["resource", "messages · customers · ..."],
  ["resourceId", "id do documento afetado"],
  ["ipAddress", "origem da requisição"],
  ["timestamp", "data/hora (Instant)"],
];
let ay = 2.7;
auditFields.forEach(([k, v]) => {
  s.addShape(pres.shapes.RECTANGLE, { x: 6.95, y: ay, w: 5.7, h: 0.62, fill: { color: SURF }, line: { color: LINE, width: 1 } });
  s.addText(k, { x: 7.1, y: ay, w: 1.7, h: 0.62, margin: 0, valign: "middle", fontFace: MONO, fontSize: 11.5, bold: true, color: PURPLE });
  s.addText(v, { x: 8.8, y: ay, w: 3.7, h: 0.62, margin: 0, valign: "middle", fontFace: BFONT, fontSize: 11.5, color: TEXT });
  ay += 0.68;
});
s.addText("Consulta: GET /api/audit-logs?resource=messages&userId=<uuid>  (OPERATOR) — trilha completa para compliance.", {
  x: 0.7, y: 6.7, w: 12.0, h: 0.35, margin: 0, fontFace: BFONT, fontSize: 11, color: MUT, italic: true,
});
pageNum(s, 19);

// ====================================================================
// 20. DIFERENCIAIS
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Criatividade & Inovação");
title(s, "Diferenciais");
const diffs = [
  ["Tempo real", "WebSocket/STOMP: nova mensagem aparece na hora, sem polling.", BLUE],
  ["Governança (AOP)", "Auditoria automática de toda escrita — zero código manual.", PURPLE],
  ["Multi-role", "Roteamento por papel: CLIENT (inbox) vs OPERATOR (CRM completo).", ORANGE],
  ["Botões interativos", "deeplink:// (interno), https:// (externo), copy: (clipboard).", TEAL],
  ["Status de mensagem", "Ciclo SENT → DELIVERED → READ → FAILED no documento.", BLUE],
  ["Zero deps no iOS", "App nativo sem libs; STOMP client implementado manualmente.", ORANGE],
];
let dx = 0.7, dy = 1.95;
diffs.forEach((d, i) => {
  const x = dx + (i % 2) * 6.15;
  const y = dy + Math.floor(i / 2) * 1.62;
  s.addShape(pres.shapes.RECTANGLE, { x, y, w: 5.95, h: 1.45, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
  s.addShape(pres.shapes.RECTANGLE, { x, y, w: 0.09, h: 1.45, fill: { color: d[2] } });
  s.addText(d[0], { x: x + 0.32, y: y + 0.2, w: 5.4, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 16, bold: true, color: d[2] });
  s.addText(d[1], { x: x + 0.32, y: y + 0.62, w: 5.45, h: 0.68, margin: 0, valign: "middle", fontFace: BFONT, fontSize: 12.5, color: TEXT });
});
pageNum(s, 20);

// ====================================================================
// 21. SETUP — BACKEND + SEED
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Execução");
title(s, "Rodar o Backend & Popular o Banco");
codeBox(s, 0.7, 1.8, 6.7, 3.95, "Passo a passo (macOS)", ORANGE,
`# 1. Pré-requisitos
brew install openjdk@17 \\
  mongodb-community xcodegen
brew services start mongodb-community

# 2. Subir o backend
cd backend
JAVA_HOME=$(brew --prefix openjdk@17) \\
  ./mvnw spring-boot:run
# → http://localhost:8080

# 3. Seed automático (1ª execução)
#   DataLoader roda se o banco
#   estiver vazio. Para re-popular:
mongosh wtc_chatapp --eval \\
  "db.dropDatabase()"
# e reinicie o backend`, 10.5);
s.addShape(pres.shapes.RECTANGLE, { x: 7.6, y: 1.8, w: 5.05, h: 3.95, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
s.addText("Seed inicial (DataLoader)", { x: 7.85, y: 2.0, w: 4.6, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 15, bold: true, color: TEAL });
s.addText([
  { text: "5 usuários  (2 OPERATOR · 3 CLIENT)", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 12 } },
  { text: "3 customers (CRM, score 60–92)", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 12 } },
  { text: "3 segmentos (VIP · Ativos · Beta)", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 12 } },
  { text: "6 mensagens (1 CHAT · 5 CAMPAIGN)", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 12 } },
  { text: "2 campanhas (status SENT)", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 12 } },
  { text: "Idempotente: só roda se count() = 0", options: { bullet: { code: "2022" } } },
], { x: 7.85, y: 2.55, w: 4.65, h: 3.1, margin: 0, valign: "top", fontFace: BFONT, fontSize: 12, color: TEXT });
pageNum(s, 21);

// ====================================================================
// 22. SETUP — APP iOS
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Execução");
title(s, "Rodar o App iOS");
codeBox(s, 0.7, 1.8, 6.7, 2.75, "Passo a passo", BLUE,
`# Pré-requisitos: macOS,
# Xcode 15+, XcodeGen

cd Challenge-WTC
xcodegen generate
open WTCChatApp.xcodeproj
# Cmd+R → simulador iPhone 15+
# Backend rodando em :8080`, 11.5);
s.addShape(pres.shapes.RECTANGLE, { x: 7.6, y: 1.8, w: 5.05, h: 2.75, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
s.addText("Integração", { x: 7.85, y: 2.0, w: 4.6, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 15, bold: true, color: ORANGE });
s.addText([
  { text: "Base URL em Utils/Constants.swift (localhost:8080)", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 11 } },
  { text: "Jackson snake_case ↔ CodingKeys do iOS", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 11 } },
  { text: "JWT salvo após login; enviado em toda chamada", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 11 } },
  { text: "WebSocket conecta após login → realtime", options: { bullet: { code: "2022" } } },
], { x: 7.85, y: 2.55, w: 4.65, h: 2.0, margin: 0, valign: "top", fontFace: BFONT, fontSize: 12, color: TEXT });
s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: 5.6, w: 11.95, h: 1.05, fill: { color: "16203A" }, line: { color: LINE, width: 1 } });
s.addText("Entregável: app.zip + WTCChatApp.ipa (archive unsigned, CODE_SIGNING_ALLOWED=NO). Para rodar em device físico, abra no Xcode e assine com sua conta de desenvolvedor Apple.", {
  x: 0.95, y: 5.6, w: 11.5, h: 1.05, margin: 0, valign: "middle", fontFace: BFONT, fontSize: 12, color: TEXT,
});
pageNum(s, 22);

// ====================================================================
// 23. COMO TESTAR — CREDENCIAIS & CENÁRIOS
// ====================================================================
s = pres.addSlide(); base(s);
kicker(s, "Validação");
title(s, "Como Testar — Credenciais & Cenários");
const credHeader = ["Email", "Senha", "Tipo", "Tags"];
const creds = [
  ["admin@wtc.com", "admin123", "OPERATOR", "—"],
  ["operador@wtc.com", "oper123", "OPERATOR", "—"],
  ["joao@test.com", "test123", "CLIENT", "vip, ativo"],
  ["maria@test.com", "test123", "CLIENT", "ativo"],
  ["pedro@test.com", "test123", "CLIENT", "vip, beta, ativo"],
];
s.addTable(
  [credHeader.map(h => ({ text: h, options: { fill: { color: SURF2 }, color: ORANGE, bold: true, fontFace: HFONT, fontSize: 12 } })),
   ...creds.map(r => r.map((c, i) => ({ text: c, options: { fill: { color: SURF }, color: i < 2 ? TEXT : MUT, fontFace: i < 2 ? MONO : BFONT, fontSize: 11.5 } })))],
  { x: 0.7, y: 1.85, w: 6.7, colW: [2.6, 1.5, 1.5, 1.1], border: { pt: 0.5, color: LINE }, rowH: 0.5, valign: "middle", margin: [3, 5, 3, 5] }
);
s.addShape(pres.shapes.RECTANGLE, { x: 7.65, y: 1.85, w: 5.0, h: 3.5, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
s.addText("Cenários", { x: 7.9, y: 2.0, w: 4.5, h: 0.35, margin: 0, fontFace: HFONT, fontSize: 14, bold: true, color: TEAL });
s.addText([
  { text: "CLIENT (joao): inbox VIP+ativo, ler/favoritar, notificações, perfil", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 10 } },
  { text: "OPERATOR (admin): CRM, filtros, notas, enviar 1:1/segmento, campanhas", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 10 } },
  { text: "Realtime: envie por admin → chega na hora no app do joao", options: { bullet: { code: "2022" } } },
], { x: 7.9, y: 2.4, w: 4.55, h: 2.85, margin: 0, fontFace: BFONT, fontSize: 11, color: TEXT });
codeBox(s, 0.7, 5.5, 11.95, 1.4, "Teste rápido via curl", ORANGE,
`curl -s localhost:8080/api/auth/login -H 'Content-Type: application/json' \\
  -d '{"email":"admin@wtc.com","password":"admin123"}'   # → copie o token e use em  Authorization: Bearer <token>`, 9.5);
pageNum(s, 23);

// ====================================================================
// 24. ENTREGÁVEIS / CLOSING
// ====================================================================
s = pres.addSlide(); base(s);
s.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: W, h: H, fill: { color: BG } });
s.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 0.22, h: H, fill: { color: ORANGE } });
s.addShape(pres.shapes.OVAL, { x: 10.6, y: 4.6, w: 4.0, h: 4.0, fill: { color: "16203A" }, line: { color: "16203A" } });
s.addText("ENTREGÁVEIS — SPRINT 2", { x: 0.9, y: 0.9, w: 10, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 14, bold: true, color: ORANGE, charSpacing: 2 });
s.addText("Resumo da Entrega", { x: 0.85, y: 1.35, w: 11.5, h: 0.9, margin: 0, fontFace: HFONT, fontSize: 38, bold: true, color: TEXT });
const deliv = [
  ["backend.zip", "código-fonte por camadas + README de execução", TEAL],
  ["app.zip + WTCChatApp.ipa", "app iOS integrado ao backend (APIs REST reais)", BLUE],
  ["Apresentação .pdf / .pptx", "nomes/RM · arquitetura · endpoints · modelo NoSQL · execução", ORANGE],
];
let vy = 2.55;
deliv.forEach(([h, d, c]) => {
  s.addShape(pres.shapes.RECTANGLE, { x: 0.9, y: vy, w: 9.0, h: 1.05, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
  s.addShape(pres.shapes.RECTANGLE, { x: 0.9, y: vy, w: 0.09, h: 1.05, fill: { color: c } });
  s.addText(h, { x: 1.15, y: vy + 0.13, w: 8.5, h: 0.45, margin: 0, fontFace: HFONT, fontSize: 16, bold: true, color: c });
  s.addText(d, { x: 1.15, y: vy + 0.55, w: 8.5, h: 0.4, margin: 0, fontFace: BFONT, fontSize: 12, color: TEXT });
  vy += 1.2;
});
s.addText("Arthur Cavalcanti Granja · RM 560650   |   github.com/artcgranja/Challenge-WTC", {
  x: 0.9, y: 6.55, w: 11.5, h: 0.4, margin: 0, fontFace: BFONT, fontSize: 12, color: MUT,
});

pres.writeFile({ fileName: "/Users/arthurgranja/github/Challenge-WTC/.claude/worktrees/elated-albattani-423fb8/Documentation/presentation/WTC-Challenge-Sprint2.pptx" })
  .then(() => console.log("OK pptx written"));
