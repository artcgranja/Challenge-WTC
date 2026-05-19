package com.wtc.chatapp.service;

import com.wtc.chatapp.model.Notification;
import com.wtc.chatapp.model.NotificationType;
import com.wtc.chatapp.repository.NotificationRepository;
import com.wtc.chatapp.websocket.WebSocketService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final WebSocketService webSocketService;

    public NotificationService(NotificationRepository notificationRepository, WebSocketService webSocketService) {
        this.notificationRepository = notificationRepository;
        this.webSocketService = webSocketService;
    }

    public Notification createAndSend(String userId, String title, String body, NotificationType type, String messageId) {
        Notification notification = Notification.builder()
                .userId(userId)
                .title(title)
                .body(body)
                .type(type)
                .messageId(messageId)
                .build();

        notification = notificationRepository.save(notification);
        webSocketService.sendNotificationToUser(userId, notification);
        return notification;
    }

    public List<Notification> getByUserId(String userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public void markAsRead(String id) {
        notificationRepository.findById(id).ifPresent(n -> {
            n.setRead(true);
            notificationRepository.save(n);
        });
    }

    public void markAllAsRead(String userId) {
        List<Notification> unread = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().filter(n -> !n.isRead()).toList();
        unread.forEach(n -> {
            n.setRead(true);
            notificationRepository.save(n);
        });
    }
}
