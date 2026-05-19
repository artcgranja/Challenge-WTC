package com.wtc.chatapp.service;

import com.wtc.chatapp.dto.MessageRequest;
import com.wtc.chatapp.model.*;
import com.wtc.chatapp.repository.MessageRepository;
import com.wtc.chatapp.repository.UserRepository;
import com.wtc.chatapp.websocket.WebSocketService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MessageServiceTest {

    @Mock MessageRepository messageRepository;
    @Mock UserRepository userRepository;
    @Mock NotificationService notificationService;
    @Mock WebSocketService webSocketService;
    @InjectMocks MessageService messageService;

    private MessageContent content() {
        return MessageContent.builder().title("T").body("B").build();
    }

    private void stubSaveEchoesWithId() {
        when(messageRepository.save(any(Message.class))).thenAnswer(i -> {
            Message m = i.getArgument(0);
            m.setId("m-1");
            return m;
        });
    }

    // ---------- sendMessage: type parsing ----------

    @Test
    void sendMessage_nullType_defaultsToChat() {
        stubSaveEchoesWithId();
        MessageRequest req = new MessageRequest();
        req.setContent(content());

        Message msg = messageService.sendMessage(req, "sender-1");

        assertThat(msg.getType()).isEqualTo(MessageType.CHAT);
        assertThat(msg.getStatus()).isEqualTo(MessageStatus.SENT);
        assertThat(msg.getSenderId()).isEqualTo("sender-1");
        verifyNoInteractions(notificationService, webSocketService);
    }

    @Test
    void sendMessage_invalidType_defaultsToChat() {
        stubSaveEchoesWithId();
        MessageRequest req = new MessageRequest();
        req.setType("not-a-type");
        req.setContent(content());

        assertThat(messageService.sendMessage(req, "s").getType()).isEqualTo(MessageType.CHAT);
    }

    @Test
    void sendMessage_directRecipient_broadcastsAndNotifiesOnce() {
        stubSaveEchoesWithId();
        MessageRequest req = new MessageRequest();
        req.setType("CAMPAIGN");
        req.setRecipientId("r-1");
        req.setContent(content());

        Message msg = messageService.sendMessage(req, "op-1");

        assertThat(msg.getType()).isEqualTo(MessageType.CAMPAIGN);
        verify(webSocketService, times(1)).sendMessageToUser(eq("r-1"), eq(msg));
        verify(notificationService, times(1)).createAndSend(
                "r-1", "T", "B", NotificationType.CAMPAIGN, "m-1");
        verify(userRepository, never()).findAll();
    }

    @Test
    void sendMessage_segmentTags_onlyMatchingClientsReceive() {
        stubSaveEchoesWithId();
        User vipClient = User.builder().id("c-vip").role(Role.CLIENT).tags(List.of("vip", "ativo")).build();
        User otherClient = User.builder().id("c-other").role(Role.CLIENT).tags(List.of("ativo")).build();
        User noTagClient = User.builder().id("c-nil").role(Role.CLIENT).tags(null).build();
        User vipOperator = User.builder().id("op").role(Role.OPERATOR).tags(List.of("vip")).build();
        when(userRepository.findAll()).thenReturn(List.of(vipClient, otherClient, noTagClient, vipOperator));

        MessageRequest req = new MessageRequest();
        req.setSegmentTags(List.of("vip"));
        req.setContent(content());

        messageService.sendMessage(req, "op-1");

        verify(webSocketService, times(1)).sendMessageToUser(eq("c-vip"), any());
        verify(notificationService, times(1)).createAndSend(
                eq("c-vip"), any(), any(), eq(NotificationType.MESSAGE), eq("m-1"));
        verify(webSocketService, never()).sendMessageToUser(eq("c-other"), any());
        verify(webSocketService, never()).sendMessageToUser(eq("c-nil"), any());
        verify(webSocketService, never()).sendMessageToUser(eq("op"), any());
    }

    @Test
    void sendMessage_emptySegmentTagsAndNoRecipient_doesNotBroadcast() {
        stubSaveEchoesWithId();
        MessageRequest req = new MessageRequest();
        req.setSegmentTags(List.of());
        req.setContent(content());

        messageService.sendMessage(req, "op-1");

        verifyNoInteractions(notificationService, webSocketService);
        verify(userRepository, never()).findAll();
    }

    // ---------- getById ----------

    @Test
    void getById_found_returnsMessage() {
        Message m = Message.builder().id("m-9").build();
        when(messageRepository.findById("m-9")).thenReturn(Optional.of(m));
        assertThat(messageService.getById("m-9")).isSameAs(m);
    }

    @Test
    void getById_missing_throwsNotFound() {
        when(messageRepository.findById("nope")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> messageService.getById("nope"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    // ---------- getInbox ----------

    @Test
    void getInbox_unknownUser_throwsNotFound() {
        when(userRepository.findById("ghost")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> messageService.getInbox("ghost"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void getInbox_userWithoutTags_usesRecipientQuery() {
        User u = User.builder().id("u-1").tags(List.of()).build();
        when(userRepository.findById("u-1")).thenReturn(Optional.of(u));
        List<Message> expected = List.of(Message.builder().id("m").build());
        when(messageRepository.findByRecipientIdOrderByCreatedAtDesc("u-1")).thenReturn(expected);

        assertThat(messageService.getInbox("u-1")).isEqualTo(expected);
    }

    @Test
    void getInbox_userWithTags_usesOrQuerySortedDesc() {
        User u = User.builder().id("u-1").tags(List.of("vip")).build();
        when(userRepository.findById("u-1")).thenReturn(Optional.of(u));
        List<Message> expected = List.of(Message.builder().id("m").build());
        ArgumentCaptor<Sort> sortCaptor = ArgumentCaptor.forClass(Sort.class);
        when(messageRepository.findInbox(eq("u-1"), eq(List.of("vip")), sortCaptor.capture()))
                .thenReturn(expected);

        assertThat(messageService.getInbox("u-1")).isEqualTo(expected);
        Sort.Order order = sortCaptor.getValue().getOrderFor("createdAt");
        assertThat(order).isNotNull();
        assertThat(order.getDirection()).isEqualTo(Sort.Direction.DESC);
    }

    // ---------- markAsRead / toggleStar / sent ----------

    @Test
    void markAsRead_setsReadStatusAndTimestamp() {
        Message m = Message.builder().id("m-1").status(MessageStatus.SENT).build();
        when(messageRepository.findById("m-1")).thenReturn(Optional.of(m));
        when(messageRepository.save(any(Message.class))).thenAnswer(i -> i.getArgument(0));

        Message res = messageService.markAsRead("m-1");

        assertThat(res.getStatus()).isEqualTo(MessageStatus.READ);
        assertThat(res.getReadAt()).isNotNull();
    }

    @Test
    void toggleStar_flipsStarredFlag() {
        Message m = Message.builder().id("m-1").starred(false).build();
        when(messageRepository.findById("m-1")).thenReturn(Optional.of(m));
        when(messageRepository.save(any(Message.class))).thenAnswer(i -> i.getArgument(0));

        assertThat(messageService.toggleStar("m-1").isStarred()).isTrue();
    }

    @Test
    void getSentMessages_delegatesToRepository() {
        List<Message> sent = List.of(Message.builder().id("m").build());
        when(messageRepository.findBySenderIdOrderByCreatedAtDesc("op-1")).thenReturn(sent);
        assertThat(messageService.getSentMessages("op-1")).isEqualTo(sent);
    }
}
