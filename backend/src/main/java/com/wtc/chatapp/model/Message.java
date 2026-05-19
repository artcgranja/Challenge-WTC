package com.wtc.chatapp.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "messages")
public class Message {

    @Id
    @Builder.Default
    private String id = UUID.randomUUID().toString();

    @Builder.Default
    private MessageType type = MessageType.CHAT;

    private String senderId;

    @Indexed
    private String recipientId;

    private List<String> segmentTags;

    private MessageContent content;

    @Builder.Default
    private MessageStatus status = MessageStatus.SENT;

    private Instant readAt;

    @Builder.Default
    private boolean starred = false;

    @Builder.Default
    private Instant createdAt = Instant.now();
}
