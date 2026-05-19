package com.wtc.chatapp.service;

import com.wtc.chatapp.model.Notification;
import com.wtc.chatapp.model.NotificationType;
import com.wtc.chatapp.repository.NotificationRepository;
import com.wtc.chatapp.websocket.WebSocketService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock NotificationRepository notificationRepository;
    @Mock WebSocketService webSocketService;
    @InjectMocks NotificationService notificationService;

    @Test
    void createAndSend_persistsAndBroadcasts() {
        when(notificationRepository.save(any(Notification.class))).thenAnswer(i -> {
            Notification n = i.getArgument(0);
            n.setId("n-1");
            return n;
        });

        Notification result = notificationService.createAndSend(
                "u-1", "Title", "Body", NotificationType.CAMPAIGN, "m-1");

        assertThat(result.getId()).isEqualTo("n-1");
        assertThat(result.getUserId()).isEqualTo("u-1");
        assertThat(result.getType()).isEqualTo(NotificationType.CAMPAIGN);
        assertThat(result.getMessageId()).isEqualTo("m-1");
        verify(webSocketService).sendNotificationToUser(eq("u-1"), eq(result));
    }

    @Test
    void getByUserId_delegatesToRepository() {
        List<Notification> list = List.of(Notification.builder().id("n").build());
        when(notificationRepository.findByUserIdOrderByCreatedAtDesc("u-1")).thenReturn(list);
        assertThat(notificationService.getByUserId("u-1")).isEqualTo(list);
    }

    @Test
    void markAsRead_present_setsReadAndSaves() {
        Notification n = Notification.builder().id("n-1").read(false).build();
        when(notificationRepository.findById("n-1")).thenReturn(Optional.of(n));

        notificationService.markAsRead("n-1");

        assertThat(n.isRead()).isTrue();
        verify(notificationRepository).save(n);
    }

    @Test
    void markAsRead_absent_isNoOp() {
        when(notificationRepository.findById("ghost")).thenReturn(Optional.empty());

        notificationService.markAsRead("ghost");

        verify(notificationRepository, never()).save(any());
    }

    @Test
    void markAllAsRead_onlyFlipsUnread() {
        Notification read = Notification.builder().id("r").read(true).build();
        Notification unread1 = Notification.builder().id("u1").read(false).build();
        Notification unread2 = Notification.builder().id("u2").read(false).build();
        when(notificationRepository.findByUserIdOrderByCreatedAtDesc("u-1"))
                .thenReturn(List.of(read, unread1, unread2));

        notificationService.markAllAsRead("u-1");

        assertThat(unread1.isRead()).isTrue();
        assertThat(unread2.isRead()).isTrue();
        verify(notificationRepository, times(2)).save(any(Notification.class));
        verify(notificationRepository, never()).save(read);
    }
}
