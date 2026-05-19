package com.wtc.chatapp.service;

import com.wtc.chatapp.dto.CampaignRequest;
import com.wtc.chatapp.model.*;
import com.wtc.chatapp.repository.CampaignRepository;
import com.wtc.chatapp.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CampaignServiceTest {

    @Mock CampaignRepository campaignRepository;
    @Mock SegmentService segmentService;
    @Mock MessageService messageService;
    @Mock UserRepository userRepository;
    @InjectMocks CampaignService campaignService;

    private static final String UUID_ID = "123e4567-e89b-12d3-a456-426614174000"; // length > 30

    @Test
    void list_resolvesSentByUuidToFullName() {
        Campaign withUuid = Campaign.builder().name("C1").sentBy(UUID_ID).build();
        Campaign withName = Campaign.builder().name("C2").sentBy("Admin WTC").build();
        when(campaignRepository.findAllByOrderByCreatedAtDesc()).thenReturn(List.of(withUuid, withName));
        when(userRepository.findById(UUID_ID))
                .thenReturn(Optional.of(User.builder().id(UUID_ID).fullName("João Operador").build()));

        List<Campaign> result = campaignService.list();

        assertThat(result.get(0).getSentBy()).isEqualTo("João Operador");
        assertThat(result.get(1).getSentBy()).isEqualTo("Admin WTC"); // short → untouched
        verify(userRepository, never()).findById("Admin WTC");
    }

    @Test
    void create_setsOperatorNameAndPersists() {
        CampaignRequest req = new CampaignRequest();
        req.setName("Promo");
        req.setSegmentId("seg-1");
        req.setContent(MessageContent.builder().title("T").build());
        req.setDeeplink("deeplink://x");
        when(userRepository.findById("op-1"))
                .thenReturn(Optional.of(User.builder().id("op-1").fullName("Admin WTC").build()));
        when(campaignRepository.save(any(Campaign.class))).thenAnswer(i -> i.getArgument(0));

        Campaign created = campaignService.create(req, "op-1");

        assertThat(created.getName()).isEqualTo("Promo");
        assertThat(created.getSegmentId()).isEqualTo("seg-1");
        assertThat(created.getDeeplink()).isEqualTo("deeplink://x");
        assertThat(created.getSentBy()).isEqualTo("Admin WTC");
        assertThat(created.getStatus()).isEqualTo(CampaignStatus.DRAFT);
    }

    @Test
    void create_unknownOperator_fallsBackToOperatorId() {
        CampaignRequest req = new CampaignRequest();
        req.setName("Promo");
        req.setSegmentId("seg-1");
        req.setContent(MessageContent.builder().title("T").build());
        when(userRepository.findById("op-x")).thenReturn(Optional.empty());
        when(campaignRepository.save(any(Campaign.class))).thenAnswer(i -> i.getArgument(0));

        assertThat(campaignService.create(req, "op-x").getSentBy()).isEqualTo("op-x");
    }

    @Test
    void send_campaignNotFound_throwsNotFound() {
        when(campaignRepository.findById("c-1")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> campaignService.send("c-1", "op-1"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void send_alreadySent_throwsBadRequest() {
        Campaign sent = Campaign.builder().id("c-1").status(CampaignStatus.SENT).build();
        when(campaignRepository.findById("c-1")).thenReturn(Optional.of(sent));

        assertThatThrownBy(() -> campaignService.send("c-1", "op-1"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void send_dispatchesCampaignMessageAndCountsRecipients() {
        Campaign draft = Campaign.builder()
                .id("c-1").name("Promo").segmentId("seg-1")
                .content(MessageContent.builder().title("T").body("B").build())
                .status(CampaignStatus.DRAFT).build();
        when(campaignRepository.findById("c-1")).thenReturn(Optional.of(draft));
        when(segmentService.getById("seg-1"))
                .thenReturn(Segment.builder().id("seg-1").tags(List.of("vip")).build());
        User vipClient = User.builder().id("c-vip").role(Role.CLIENT).tags(List.of("vip")).build();
        User otherClient = User.builder().id("c-other").role(Role.CLIENT).tags(List.of("ativo")).build();
        User vipOperator = User.builder().id("op").role(Role.OPERATOR).tags(List.of("vip")).build();
        when(userRepository.findAll()).thenReturn(List.of(vipClient, otherClient, vipOperator));
        when(userRepository.findById("op-1"))
                .thenReturn(Optional.of(User.builder().id("op-1").fullName("Admin WTC").build()));
        when(campaignRepository.save(any(Campaign.class))).thenAnswer(i -> i.getArgument(0));

        Campaign result = campaignService.send("c-1", "op-1");

        ArgumentCaptor<com.wtc.chatapp.dto.MessageRequest> msgCaptor =
                ArgumentCaptor.forClass(com.wtc.chatapp.dto.MessageRequest.class);
        verify(messageService).sendMessage(msgCaptor.capture(), eq("op-1"));
        assertThat(msgCaptor.getValue().getType()).isEqualTo("CAMPAIGN");
        assertThat(msgCaptor.getValue().getSegmentTags()).containsExactly("vip");

        assertThat(result.getStatus()).isEqualTo(CampaignStatus.SENT);
        assertThat(result.getSentAt()).isNotNull();
        assertThat(result.getSentBy()).isEqualTo("Admin WTC");
        assertThat(result.getMessageCount()).isEqualTo(1); // only vipClient matches
    }
}
