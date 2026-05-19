package com.wtc.chatapp.websocket;

import com.wtc.chatapp.model.Message;
import com.wtc.chatapp.model.Notification;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

@Service
public class WebSocketService {

    private final SimpMessagingTemplate messagingTemplate;

    public WebSocketService(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    public void sendMessageToUser(String userId, Message message) {
        messagingTemplate.convertAndSend("/topic/messages/" + userId, message);
    }

    public void sendNotificationToUser(String userId, Notification notification) {
        messagingTemplate.convertAndSend("/topic/notifications/" + userId, notification);
    }
}
