package com.wtc.chatapp.config;

import com.wtc.chatapp.model.*;
import com.wtc.chatapp.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DataLoader implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataLoader.class);

    private final UserRepository userRepository;
    private final SegmentRepository segmentRepository;
    private final MessageRepository messageRepository;
    private final CampaignRepository campaignRepository;
    private final CustomerRepository customerRepository;
    private final PasswordEncoder passwordEncoder;

    public DataLoader(UserRepository userRepository, SegmentRepository segmentRepository,
                      MessageRepository messageRepository, CampaignRepository campaignRepository,
                      CustomerRepository customerRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.segmentRepository = segmentRepository;
        this.messageRepository = messageRepository;
        this.campaignRepository = campaignRepository;
        this.customerRepository = customerRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        if (userRepository.count() > 0) {
            log.info("Database already seeded, skipping...");
            return;
        }

        log.info("Seeding database...");

        // Operators
        User admin = userRepository.save(User.builder()
                .email("admin@wtc.com")
                .password(passwordEncoder.encode("admin123"))
                .fullName("Admin WTC")
                .role(Role.OPERATOR)
                .build());

        userRepository.save(User.builder()
                .email("operador@wtc.com")
                .password(passwordEncoder.encode("oper123"))
                .fullName("Operador WTC")
                .role(Role.OPERATOR)
                .build());

        // Clients
        User joao = userRepository.save(User.builder()
                .email("joao@test.com")
                .password(passwordEncoder.encode("test123"))
                .fullName("João Silva")
                .phone("(11) 99999-1111")
                .role(Role.CLIENT)
                .tags(List.of("vip", "ativo"))
                .status("active")
                .build());

        User maria = userRepository.save(User.builder()
                .email("maria@test.com")
                .password(passwordEncoder.encode("test123"))
                .fullName("Maria Santos")
                .phone("(11) 99999-2222")
                .role(Role.CLIENT)
                .tags(List.of("ativo"))
                .status("active")
                .build());

        User pedro = userRepository.save(User.builder()
                .email("pedro@test.com")
                .password(passwordEncoder.encode("test123"))
                .fullName("Pedro Costa")
                .phone("(11) 99999-3333")
                .role(Role.CLIENT)
                .tags(List.of("vip", "beta", "ativo"))
                .status("active")
                .build());

        // Customers (CRM records)
        customerRepository.save(Customer.builder().userId(joao.getId()).tags(List.of("vip", "ativo")).score(85).status(CustomerStatus.ACTIVE).build());
        customerRepository.save(Customer.builder().userId(maria.getId()).tags(List.of("ativo")).score(60).status(CustomerStatus.ACTIVE).build());
        customerRepository.save(Customer.builder().userId(pedro.getId()).tags(List.of("vip", "beta", "ativo")).score(92).status(CustomerStatus.ACTIVE).build());

        // Segments
        Segment vipSegment = segmentRepository.save(Segment.builder().name("VIP").description("Clientes VIP do WTC").tags(List.of("vip")).createdBy(admin.getId()).build());
        Segment ativosSegment = segmentRepository.save(Segment.builder().name("Ativos").description("Clientes ativos").tags(List.of("ativo")).createdBy(admin.getId()).build());
        segmentRepository.save(Segment.builder().name("Beta Testers").description("Usuários beta").tags(List.of("beta")).createdBy(admin.getId()).build());

        // Messages
        messageRepository.save(Message.builder()
                .type(MessageType.CHAT)
                .senderId(admin.getId())
                .recipientId(joao.getId())
                .content(MessageContent.builder()
                        .title("Bem-vindo ao WTC Chat!")
                        .body("Olá João! Seja bem-vindo à plataforma de comunicação do WTC Business Club. Aqui você receberá mensagens exclusivas, promoções e convites para eventos.")
                        .buttons(List.of(
                                ActionButton.builder().label("Ver Perfil").action("deeplink://profile").build(),
                                ActionButton.builder().label("Ver Eventos").action("https://wtc.com/eventos").build()))
                        .build())
                .build());

        messageRepository.save(Message.builder()
                .type(MessageType.CAMPAIGN)
                .senderId(admin.getId())
                .segmentTags(List.of("vip"))
                .content(MessageContent.builder()
                        .title("Black Friday WTC 2026")
                        .body("Condições exclusivas para membros VIP! Descontos de até 40% em serviços premium do WTC Business Club.")
                        .imageUrl("https://images.unsplash.com/photo-1607083206968-13611e3d76db?w=800")
                        .buttons(List.of(
                                ActionButton.builder().label("Inscrever-se").action("https://wtc.com/blackfriday").build(),
                                ActionButton.builder().label("Saiba Mais").action("https://wtc.com/blackfriday/detalhes").build()))
                        .build())
                .build());

        messageRepository.save(Message.builder()
                .type(MessageType.CAMPAIGN)
                .senderId(admin.getId())
                .segmentTags(List.of("ativo"))
                .content(MessageContent.builder()
                        .title("Nova Coleção de Eventos")
                        .body("Confira os próximos eventos do WTC: Finance Innovation Talks, ESG Summit e CX Experience.")
                        .buttons(List.of(
                                ActionButton.builder().label("Ver Agenda").action("deeplink://orders").build()))
                        .build())
                .build());

        messageRepository.save(Message.builder()
                .type(MessageType.CAMPAIGN)
                .senderId(admin.getId())
                .segmentTags(List.of("beta"))
                .content(MessageContent.builder()
                        .title("Programa Beta - Novidades")
                        .body("Você foi selecionado para testar as novas funcionalidades da plataforma WTC. Sua opinião é essencial!")
                        .buttons(List.of(
                                ActionButton.builder().label("Acessar Beta").action("deeplink://products").build(),
                                ActionButton.builder().label("Dar Feedback").action("https://wtc.com/feedback").build()))
                        .build())
                .build());

        messageRepository.save(Message.builder()
                .type(MessageType.CAMPAIGN)
                .senderId(admin.getId())
                .segmentTags(List.of("vip"))
                .content(MessageContent.builder()
                        .title("Flash Sale Exclusiva")
                        .body("Somente hoje! Acesso antecipado à venda especial de ingressos para o Financial Shift 2026.")
                        .imageUrl("https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800")
                        .buttons(List.of(
                                ActionButton.builder().label("Comprar Agora").action("https://wtc.com/flashsale").build()))
                        .build())
                .build());

        messageRepository.save(Message.builder()
                .type(MessageType.CAMPAIGN)
                .senderId(admin.getId())
                .segmentTags(List.of("vip", "ativo"))
                .content(MessageContent.builder()
                        .title("Convite: Innovation Talks")
                        .body("Você está convidado para o próximo encontro Innovation Talks — Financial Shift 2026. Vagas limitadas para membros VIP.")
                        .buttons(List.of(
                                ActionButton.builder().label("Confirmar Presença").action("https://wtc.com/evento/inscricao").build(),
                                ActionButton.builder().label("Detalhes do Evento").action("https://wtc.com/evento/detalhes").build()))
                        .build())
                .build());

        // Campaigns
        campaignRepository.save(Campaign.builder()
                .name("Black Friday WTC 2026")
                .segmentId(vipSegment.getId())
                .content(MessageContent.builder().title("Black Friday WTC 2026").body("Condições exclusivas para membros VIP!").build())
                .status(CampaignStatus.SENT)
                .sentBy(admin.getId())
                .messageCount(2)
                .build());

        campaignRepository.save(Campaign.builder()
                .name("Nova Coleção de Eventos")
                .segmentId(ativosSegment.getId())
                .content(MessageContent.builder().title("Nova Coleção de Eventos").body("Confira os próximos eventos do WTC.").build())
                .status(CampaignStatus.SENT)
                .sentBy(admin.getId())
                .messageCount(3)
                .build());

        log.info("Database seeded successfully! Users: {}, Messages: {}, Segments: {}, Campaigns: {}",
                userRepository.count(), messageRepository.count(), segmentRepository.count(), campaignRepository.count());
    }
}
