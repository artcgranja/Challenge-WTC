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
const TEXT = "F4F6FB";
const MUT = "94A1B8";
const LINE = "33415C";

const HFONT = "Trebuchet MS";
const BFONT = "Calibri";
const MONO = "Consolas";

const sh = () => ({ type: "outer", color: "000000", blur: 9, offset: 3, angle: 135, opacity: 0.35 });

function base(slide, dark = true) {
  slide.background = { color: dark ? BG : "F4F6FB" };
}

function kicker(slide, txt) {
  slide.addText(txt.toUpperCase(), {
    x: 0.7, y: 0.5, w: 9, h: 0.32, margin: 0,
    fontFace: HFONT, fontSize: 12, bold: true, color: ORANGE, charSpacing: 3,
  });
}

function title(slide, txt) {
  slide.addText(txt, {
    x: 0.7, y: 0.82, w: 11.9, h: 0.85, margin: 0,
    fontFace: HFONT, fontSize: 32, bold: true, color: TEXT,
  });
}

function pageNum(slide, n) {
  slide.addText(String(n).padStart(2, "0") + " · WTC Chat App", {
    x: 10.4, y: 7.0, w: 2.6, h: 0.3, margin: 0,
    fontFace: BFONT, fontSize: 9, color: MUT, align: "right",
  });
}

// ---------- 1. TITLE ----------
let s = pres.addSlide(); base(s);
s.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: W, h: H, fill: { color: BG } });
s.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 0.22, h: H, fill: { color: ORANGE } });
s.addShape(pres.shapes.OVAL, { x: 10.2, y: -2.0, w: 5.4, h: 5.4, fill: { color: SURF }, line: { color: SURF } });
s.addShape(pres.shapes.OVAL, { x: 11.6, y: 4.4, w: 3.6, h: 3.6, fill: { color: "16203A" }, line: { color: "16203A" } });
s.addText("CHALLENGE WTC 2025  ·  FIAP  ·  ANÁLISE E DESENVOLVIMENTO DE SISTEMAS", {
  x: 0.9, y: 1.5, w: 11, h: 0.4, margin: 0,
  fontFace: HFONT, fontSize: 14, bold: true, color: ORANGE, charSpacing: 2,
});
s.addText("WTC Chat App", {
  x: 0.85, y: 2.1, w: 11.5, h: 1.4, margin: 0,
  fontFace: HFONT, fontSize: 60, bold: true, color: TEXT,
});
s.addText("Plataforma de comunicação CRM — app iOS nativo + backend Java robusto, integrados via APIs REST reais e mensageria em tempo real.", {
  x: 0.9, y: 3.5, w: 9.4, h: 1.0, margin: 0,
  fontFace: BFONT, fontSize: 18, color: MUT,
});
s.addText([
  { text: "SPRINT 2", options: { bold: true, color: BG } },
  { text: "   Backend real · sem mocks", options: { color: BG } },
], { x: 0.9, y: 4.9, w: 5.6, h: 0.55, fill: { color: ORANGE }, align: "center", valign: "middle", fontFace: HFONT, fontSize: 15, rectRadius: 0.05 });
s.addText("Entrega: 19/05 · 23h00   |   Equipe 2TDS", {
  x: 0.9, y: 6.4, w: 8, h: 0.4, margin: 0, fontFace: BFONT, fontSize: 13, color: MUT,
});

// ---------- 2. EQUIPE ----------
s = pres.addSlide(); base(s);
kicker(s, "Integrantes");
title(s, "Equipe");
const team = [
  ["Arthur Cavalcanti Granja", "RM 560650"],
];
let ty = 2.55;
team.forEach(([nm, rm]) => {
  s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: ty, w: 9.6, h: 1.1, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
  s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: ty, w: 0.11, h: 1.1, fill: { color: ORANGE } });
  s.addText(nm, { x: 1.1, y: ty + 0.15, w: 6.7, h: 0.8, margin: 0, valign: "middle", fontFace: HFONT, fontSize: 22, bold: true, color: TEXT });
  s.addText(rm, { x: 7.9, y: ty + 0.15, w: 2.2, h: 0.8, margin: 0, valign: "middle", align: "right", fontFace: MONO, fontSize: 19, bold: true, color: ORANGE });
  ty += 1.3;
});
s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: 4.15, w: 9.6, h: 1.05, fill: { color: "16203A" }, line: { color: LINE, width: 1 } });
s.addText("Análise e Desenvolvimento de Sistemas — 2TDS · FIAP\nChallenge WTC 2025 · Sprint 2 — Backend + Integração", {
  x: 1.0, y: 4.15, w: 9.0, h: 1.05, margin: 0, valign: "middle", fontFace: BFONT, fontSize: 14, color: MUT,
});
pageNum(s, 2);

// ---------- 3. VISÃO GERAL ----------
s = pres.addSlide(); base(s);
kicker(s, "Contexto & Solução");
title(s, "Visão Geral");
const colW = 5.75;
function panel(x, head, color, items) {
  s.addShape(pres.shapes.RECTANGLE, { x, y: 2.0, w: colW, h: 4.4, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
  s.addShape(pres.shapes.RECTANGLE, { x, y: 2.0, w: colW, h: 0.62, fill: { color } });
  s.addText(head, { x: x + 0.25, y: 2.0, w: colW - 0.5, h: 0.62, margin: 0, valign: "middle", fontFace: HFONT, fontSize: 16, bold: true, color: BG });
  s.addText(items.map((t, i) => ({ text: t, options: { bullet: { code: "2022", indent: 16 }, breakLine: i < items.length - 1, paraSpaceAfter: 16, color: TEXT } })),
    { x: x + 0.35, y: 2.78, w: colW - 0.7, h: 3.5, margin: 0, valign: "middle", fontFace: BFONT, fontSize: 15 });
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
  "CRM no app (visão operador) + tempo real (WebSocket)",
]);
pageNum(s, 3);

// ---------- 4. ARQUITETURA ----------
s = pres.addSlide(); base(s);
kicker(s, "Diagrama");
title(s, "Arquitetura do Backend");

// Column geometry — all three columns share the same vertical center (y=4.05)
const colTop = 2.45, colH = 3.2, cy = colTop + colH / 2;

// Left: App iOS
s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: colTop, w: 3.0, h: colH, fill: { color: SURF }, line: { color: BLUE, width: 2 }, shadow: sh() });
s.addText("App iOS", { x: 0.7, y: colTop + 0.35, w: 3.0, h: 0.5, margin: 0, align: "center", fontFace: HFONT, fontSize: 18, bold: true, color: BLUE });
s.addText([
  { text: "SwiftUI · MVVM", options: { breakLine: true } },
  { text: "Combine · iOS 15+", options: { breakLine: true } },
  { text: "Zero deps externas", options: {} },
], { x: 0.85, y: colTop + 1.0, w: 2.7, h: 1.8, margin: 0, align: "center", valign: "middle", fontFace: BFONT, fontSize: 13, color: MUT, paraSpaceAfter: 8 });

// Middle: Spring Boot 3.3 container with 3 inner bars
const mx = 4.95, mw = 3.85;
s.addShape(pres.shapes.RECTANGLE, { x: mx, y: colTop, w: mw, h: colH, fill: { color: SURF }, line: { color: ORANGE, width: 2 }, shadow: sh() });
s.addText("Spring Boot 3.3  ·  Java 17", { x: mx, y: colTop + 0.15, w: mw, h: 0.45, margin: 0, align: "center", fontFace: HFONT, fontSize: 16, bold: true, color: ORANGE });
const bars = [
  ["Controllers REST · Services · Repositories", TEXT, "1B2B45"],
  ["Spring Security — JWT · BCrypt · Roles", TEAL, "16282E"],
  ["Spring AOP — auditoria automática", "C792EA", "241B33"],
];
let by = colTop + 0.7;
bars.forEach(([t, c, fillc]) => {
  s.addShape(pres.shapes.RECTANGLE, { x: mx + 0.2, y: by, w: mw - 0.4, h: 0.72, fill: { color: fillc }, line: { color: LINE, width: 1 } });
  s.addText(t, { x: mx + 0.32, y: by, w: mw - 0.64, h: 0.72, margin: 0, valign: "middle", align: "center", fontFace: BFONT, fontSize: 12, bold: true, color: c });
  by += 0.83;
});

// Right: MongoDB
const rx = 10.05, rw = 2.6;
s.addShape(pres.shapes.RECTANGLE, { x: rx, y: colTop, w: rw, h: colH, fill: { color: SURF }, line: { color: TEAL, width: 2 }, shadow: sh() });
s.addText("MongoDB", { x: rx, y: colTop + 0.85, w: rw, h: 0.5, margin: 0, align: "center", fontFace: HFONT, fontSize: 18, bold: true, color: TEAL });
s.addText([
  { text: "NoSQL", options: { breakLine: true } },
  { text: "7 collections", options: {} },
], { x: rx, y: colTop + 1.45, w: rw, h: 1.0, margin: 0, align: "center", valign: "top", fontFace: BFONT, fontSize: 13, color: MUT, paraSpaceAfter: 6 });

// Arrows in the gaps (no collision with boxes)
s.addText("REST/JSON · JWT", { x: 3.7, y: cy - 0.78, w: 1.25, h: 0.3, margin: 0, align: "center", fontFace: BFONT, fontSize: 9.5, color: BLUE });
s.addShape(pres.shapes.LINE, { x: 3.72, y: cy - 0.4, w: 1.21, h: 0, line: { color: BLUE, width: 2.5, endArrowType: "triangle" } });
s.addText("STOMP / WebSocket", { x: 3.6, y: cy + 0.2, w: 1.45, h: 0.3, margin: 0, align: "center", fontFace: BFONT, fontSize: 9.5, color: TEAL });
s.addShape(pres.shapes.LINE, { x: 3.72, y: cy + 0.55, w: 1.21, h: 0, line: { color: TEAL, width: 2.5, dashType: "dash", beginArrowType: "triangle", endArrowType: "triangle" } });
s.addShape(pres.shapes.LINE, { x: 8.82, y: cy, w: 1.21, h: 0, line: { color: TEAL, width: 2.5, beginArrowType: "triangle", endArrowType: "triangle" } });

s.addText("Fluxo de envio: Controller → Service → Repository → MongoDB; em paralelo cria Notification e faz broadcast via WebSocketService para /topic/messages/{userId}. AuditAspect (AOP) registra toda operação de escrita.", {
  x: 0.7, y: 6.25, w: 12.0, h: 0.6, margin: 0, fontFace: BFONT, fontSize: 12, color: MUT, italic: true,
});
pageNum(s, 4);

// ---------- 5. STACK ----------
s = pres.addSlide(); base(s);
kicker(s, "Tecnologias");
title(s, "Stack & Segurança");
const stackRows = [
  ["iOS", "Swift 5.9 · SwiftUI · Combine · MVVM · iOS 15+ · sem dependências externas (URLSession + STOMP manual)"],
  ["Backend", "Java 17 · Spring Boot 3.3 · Spring Security · Spring Data MongoDB · Spring WebSocket · Spring AOP · Lombok · JJWT"],
  ["Banco", "MongoDB 6.0+ — NoSQL orientado a documentos, 7 collections"],
  ["Auth", "JWT (access 24h / refresh 7d) · BCrypt · roles OPERATOR / CLIENT"],
  ["Realtime", "WebSocket STOMP — /topic/messages/{userId} · /topic/notifications/{userId}"],
  ["Governança", "Auditoria automática via AOP (@AfterReturning) em toda operação de escrita"],
];
let sy = 2.0;
stackRows.forEach(([k, v]) => {
  s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: sy, w: 12.0, h: 0.74, fill: { color: SURF }, line: { color: LINE, width: 1 } });
  s.addText(k, { x: 0.7, y: sy, w: 1.85, h: 0.74, margin: 0, align: "center", valign: "middle", fontFace: HFONT, fontSize: 14, bold: true, color: ORANGE });
  s.addShape(pres.shapes.LINE, { x: 2.55, y: sy + 0.1, w: 0, h: 0.54, line: { color: LINE, width: 1 } });
  s.addText(v, { x: 2.8, y: sy, w: 9.7, h: 0.74, margin: 0, valign: "middle", fontFace: BFONT, fontSize: 12.5, color: TEXT });
  sy += 0.82;
});
pageNum(s, 5);

// ---------- 6. MODELO DE DADOS ----------
s = pres.addSlide(); base(s);
kicker(s, "Modelo NoSQL — MongoDB");
title(s, "Modelo de Dados");
const cols = [
  ["users", "id · email* · password · fullName · phone · role · tags[] · status"],
  ["customers", "id · userId* · tags[] · score · status · notes[] · segmentIds[]"],
  ["segments", "id · name · description · tags[] · createdBy"],
  ["messages", "id · type · senderId · recipientId* · segmentTags[] · content · status · readAt · starred"],
  ["campaigns", "id · name · segmentId · content · deeplink · status · sentBy · messageCount"],
  ["notifications", "id · userId* · title · body · type · read · messageId"],
  ["audit_logs", "id · userId · action · resource · resourceId · details · ipAddress · timestamp"],
];
let my = 1.85;
cols.forEach(([c, f]) => {
  s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: my, w: 12.0, h: 0.62, fill: { color: SURF }, line: { color: LINE, width: 1 } });
  s.addText(c, { x: 0.85, y: my, w: 2.2, h: 0.62, margin: 0, valign: "middle", fontFace: MONO, fontSize: 13, bold: true, color: TEAL });
  s.addText(f, { x: 3.05, y: my, w: 9.5, h: 0.62, margin: 0, valign: "middle", fontFace: MONO, fontSize: 11, color: TEXT });
  my += 0.7;
});
s.addText("* campo indexado   ·   content = { title, body, imageUrl, buttons[] }   ·   Inbox: $or [ recipientId = userId, segmentTags ∈ userTags ]", {
  x: 0.7, y: 6.75, w: 12.0, h: 0.35, margin: 0, fontFace: BFONT, fontSize: 11, color: MUT, italic: true,
});
pageNum(s, 6);

// ---------- 7 & 8. ENDPOINTS ----------
function epHeaderRow() {
  return [
    { text: "Método", options: { fill: { color: SURF2 }, color: ORANGE, bold: true, fontFace: HFONT } },
    { text: "Rota", options: { fill: { color: SURF2 }, color: ORANGE, bold: true, fontFace: HFONT } },
    { text: "Acesso", options: { fill: { color: SURF2 }, color: ORANGE, bold: true, fontFace: HFONT } },
    { text: "Descrição", options: { fill: { color: SURF2 }, color: ORANGE, bold: true, fontFace: HFONT } },
  ];
}
function epRows(rows) {
  return rows.map((r) => r.map((c, i) => ({
    text: c,
    options: {
      fill: { color: SURF }, color: i === 0 ? TEAL : (i === 1 ? TEXT : MUT),
      fontFace: i <= 1 ? MONO : BFONT, fontSize: 11, bold: i === 0,
    },
  })));
}
function epSlide(n, sub, rows) {
  const sl = pres.addSlide(); base(sl);
  kicker(sl, "Especificação — rota · método · acesso");
  sl.addText("Endpoints", { x: 0.7, y: 0.82, w: 3.4, h: 0.8, margin: 0, fontFace: HFONT, fontSize: 30, bold: true, color: TEXT });
  sl.addText(sub, { x: 3.7, y: 0.95, w: 9.0, h: 0.55, margin: 0, valign: "middle", fontFace: HFONT, fontSize: 16, bold: true, color: ORANGE });
  sl.addTable([epHeaderRow(), ...epRows(rows)], {
    x: 0.7, y: 1.9, w: 12.0, colW: [1.5, 5.0, 1.6, 3.9],
    border: { pt: 0.5, color: LINE }, rowH: 0.44, valign: "middle",
    margin: [3, 5, 3, 5],
  });
  pageNum(sl, n);
  return sl;
}
epSlide(7, "Auth · CRM · Segmentos", [
  ["POST", "/api/auth/login", "público", "Login → JWT + perfil"],
  ["POST", "/api/auth/register", "público", "Registrar usuário"],
  ["POST", "/api/auth/refresh", "público", "Renovar token"],
  ["GET", "/api/customers", "OPERATOR", "Listar (filtros tag/status/minScore)"],
  ["POST", "/api/customers", "OPERATOR", "Criar cliente CRM"],
  ["GET/PUT", "/api/customers/{id}", "OPERATOR", "Detalhe / atualizar"],
  ["GET", "/api/customers/{id}/timeline", "OPERATOR", "Perfil 360° (msgs + notas)"],
  ["POST", "/api/customers/{id}/notes", "OPERATOR", "Anotação rápida"],
  ["GET/POST", "/api/segments", "OPERATOR", "Listar / criar segmento"],
  ["PUT/DELETE", "/api/segments/{id}", "OPERATOR", "Atualizar / remover"],
]);
epSlide(8, "Mensagens · Campanhas · Notificações · Auditoria", [
  ["POST", "/api/messages", "autenticado", "Enviar msg (1:1 ou segmento)"],
  ["GET", "/api/messages/{id}", "autenticado", "Detalhe da mensagem"],
  ["GET", "/api/inbox/{customerId}", "autenticado", "Inbox do cliente"],
  ["GET", "/api/messages/sent/{senderId}", "autenticado", "Histórico de enviadas"],
  ["PUT", "/api/messages/{id}/read", "autenticado", "Marcar como lida"],
  ["PUT", "/api/messages/{id}/star", "autenticado", "Favoritar"],
  ["GET/POST", "/api/campaigns", "OPERATOR", "Listar / criar campanha"],
  ["POST", "/api/campaigns/{id}/send", "OPERATOR", "Enviar para segmento"],
  ["GET/PUT", "/api/notifications", "autenticado", "Listar / marcar lida(s)"],
  ["GET", "/api/audit-logs", "OPERATOR", "Logs (filtros resource/userId)"],
]);

// ---------- 9. PAYLOAD / RESPOSTA ----------
s = pres.addSlide(); base(s);
kicker(s, "Exemplo — payload & resposta");
title(s, "Modelo Flexível de Mensagem");
s.addText("REQUEST  ·  POST /api/messages", { x: 0.7, y: 1.8, w: 6, h: 0.32, margin: 0, fontFace: HFONT, fontSize: 13, bold: true, color: ORANGE });
s.addShape(pres.shapes.RECTANGLE, { x: 0.7, y: 2.15, w: 6.0, h: 4.5, fill: { color: SURF }, line: { color: LINE, width: 1 } });
s.addText(
`{
  "type": "CHAT",
  "recipient_id": "uuid-cliente",
  "content": {
    "title": "Campanha Especial",
    "body": "Participe do evento!",
    "image_url": "https://.../img.jpg",
    "buttons": [
      { "label": "Inscrever-se",
        "action": "https://wtc.com/x" },
      { "label": "Ver perfil",
        "action": "deeplink://profile" }
    ]
  }
}`, { x: 0.9, y: 2.3, w: 5.6, h: 4.2, margin: 0, fontFace: MONO, fontSize: 11.5, color: TEXT, valign: "top" });

s.addText("RESPONSE  ·  201 Created", { x: 7.0, y: 1.8, w: 6, h: 0.32, margin: 0, fontFace: HFONT, fontSize: 13, bold: true, color: TEAL });
s.addShape(pres.shapes.RECTANGLE, { x: 7.0, y: 2.15, w: 5.65, h: 4.5, fill: { color: SURF }, line: { color: LINE, width: 1 } });
s.addText(
`{
  "id": "uuid-msg",
  "type": "CHAT",
  "sender_id": "uuid-operador",
  "recipient_id": "uuid-cliente",
  "content": { ... },
  "status": "SENT",
  "starred": false,
  "created_at": "2026-05-19T23:00:00Z"
}

status: SENT → DELIVERED
        → READ → FAILED`, { x: 7.2, y: 2.3, w: 5.3, h: 4.2, margin: 0, fontFace: MONO, fontSize: 11.5, color: TEXT, valign: "top" });
pageNum(s, 9);

// ---------- 10. DIFERENCIAIS ----------
s = pres.addSlide(); base(s);
kicker(s, "Criatividade & Inovação");
title(s, "Diferenciais");
const diffs = [
  ["Tempo real", "WebSocket/STOMP: nova mensagem aparece instantaneamente no app, sem polling.", BLUE],
  ["Governança (AOP)", "Auditoria automática de toda escrita via Spring AOP — zero código manual.", "C792EA"],
  ["Multi-role", "Roteamento por papel: CLIENT (inbox) vs OPERATOR (CRM completo no app).", ORANGE],
  ["Botões interativos", "deeplink:// (navegação interna), https:// (externo), copy: (clipboard).", TEAL],
  ["Status de mensagem", "Ciclo SENT → DELIVERED → READ → FAILED rastreado no documento.", BLUE],
  ["Zero deps no iOS", "App nativo sem libs externas — STOMP client implementado manualmente.", ORANGE],
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
pageNum(s, 10);

// ---------- 11. ENTREGÁVEIS / CLOSING ----------
s = pres.addSlide(); base(s);
s.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: W, h: H, fill: { color: BG } });
s.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 0.22, h: H, fill: { color: ORANGE } });
s.addText("ENTREGÁVEIS & EXECUÇÃO", { x: 0.9, y: 0.9, w: 10, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 14, bold: true, color: ORANGE, charSpacing: 2 });
s.addText("Como rodar o projeto", { x: 0.85, y: 1.35, w: 11.5, h: 0.9, margin: 0, fontFace: HFONT, fontSize: 38, bold: true, color: TEXT });

s.addShape(pres.shapes.RECTANGLE, { x: 0.9, y: 2.5, w: 5.7, h: 3.7, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
s.addText("Backend", { x: 1.15, y: 2.7, w: 5, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 17, bold: true, color: ORANGE });
s.addText(
`brew install openjdk@17 \\
  mongodb-community
brew services start \\
  mongodb-community

cd backend
JAVA_HOME=$(brew --prefix \\
  openjdk@17) ./mvnw \\
  spring-boot:run
# http://localhost:8080`, { x: 1.15, y: 3.15, w: 5.2, h: 2.9, margin: 0, fontFace: MONO, fontSize: 11.5, color: TEXT });

s.addShape(pres.shapes.RECTANGLE, { x: 6.95, y: 2.5, w: 5.45, h: 3.7, fill: { color: SURF }, line: { color: LINE, width: 1 }, shadow: sh() });
s.addText("App iOS", { x: 7.2, y: 2.7, w: 5, h: 0.4, margin: 0, fontFace: HFONT, fontSize: 17, bold: true, color: BLUE });
s.addText(
`brew install xcodegen
cd Challenge-WTC
xcodegen generate
open WTCChatApp.xcodeproj
# Cmd+R (iPhone 15+)

Entregáveis: backend.zip ·
app.zip + WTCChatApp.ipa ·
apresentação (.pptx/.pdf)`, { x: 7.2, y: 3.15, w: 5.0, h: 2.9, margin: 0, fontFace: MONO, fontSize: 11.5, color: TEXT });

s.addText("Repositório: github.com/artcgranja/Challenge-WTC   ·   Challenge WTC 2025 — Sprint 2 — FIAP 2TDS", {
  x: 0.9, y: 6.6, w: 11.5, h: 0.4, margin: 0, fontFace: BFONT, fontSize: 12, color: MUT,
});

pres.writeFile({ fileName: "/Users/arthurgranja/github/Challenge-WTC/Documentation/presentation/WTC-Challenge-Sprint2.pptx" })
  .then(() => console.log("OK pptx written"));
