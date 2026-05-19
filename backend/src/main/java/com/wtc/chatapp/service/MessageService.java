package com.wtc.chatapp.service;

import com.wtc.chatapp.dto.MessageRequest;
import com.wtc.chatapp.model.*;
import com.wtc.chatapp.repository.MessageRepository;
import com.wtc.chatapp.repository.UserRepository;
import com.wtc.chatapp.websocket.WebSocketService;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;

@Service
public class MessageService {

    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final WebSocketService webSocketService;

    public MessageService(MessageRepository messageRepository, UserRepository userRepository,
                          NotificationService notificationService, WebSocketService webSocketService) {
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
        this.webSocketService = webSocketService;
    }

    public Message sendMessage(MessageRequest request, String senderId) {
        MessageType type = MessageType.CHAT;
        if (request.getType() != null) {
            try {
                type = MessageType.valueOf(request.getType().toUpperCase());
            } catch (IllegalArgumentException ignored) {}
        }

        Message message = Message.builder()
                .type(type)
                .senderId(senderId)
                .recipientId(request.getRecipientId())
                .segmentTags(request.getSegmentTags())
                .content(request.getContent())
                .status(MessageStatus.SENT)
                .build();

        message = messageRepository.save(message);

        if (request.getRecipientId() != null) {
            webSocketService.sendMessageToUser(request.getRecipientId(), message);
            notificationService.createAndSend(
                    request.getRecipientId(),
                    message.getContent().getTitle(),
                    message.getContent().getBody(),
                    type == MessageType.CAMPAIGN ? NotificationType.CAMPAIGN : NotificationType.MESSAGE,
                    message.getId()
            );
        }

        if (request.getSegmentTags() != null && !request.getSegmentTags().isEmpty()) {
            List<User> matchingUsers = userRepository.findAll().stream()
                    .filter(u -> u.getRole() == Role.CLIENT)
                    .filter(u -> u.getTags() != null && u.getTags().stream()
                            .anyMatch(tag -> request.getSegmentTags().contains(tag)))
                    .toList();

            for (User user : matchingUsers) {
                webSocketService.sendMessageToUser(user.getId(), message);
                notificationService.createAndSend(
                        user.getId(),
                        message.getContent().getTitle(),
                        message.getContent().getBody(),
                        type == MessageType.CAMPAIGN ? NotificationType.CAMPAIGN : NotificationType.MESSAGE,
                        message.getId()
                );
            }
        }

        return message;
    }

    public Message getById(String id) {
        return messageRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Message not found"));
    }

    public List<Message> getInbox(String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        List<String> userTags = user.getTags();
        if (userTags == null || userTags.isEmpty()) {
            return messageRepository.findByRecipientIdOrderByCreatedAtDesc(userId);
        }

        return messageRepository.findInbox(userId, userTags, Sort.by(Sort.Direction.DESC, "createdAt"));
    }

    public Message markAsRead(String id) {
        Message message = getById(id);
        message.setReadAt(Instant.now());
        message.setStatus(MessageStatus.READ);
        return messageRepository.save(message);
    }

    public Message toggleStar(String id) {
        Message message = getById(id);
        message.setStarred(!message.isStarred());
        return messageRepository.save(message);
    }
}
