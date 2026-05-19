package com.wtc.chatapp.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "notifications")
public class Notification {

    @Id
    @Builder.Default
    private String id = UUID.randomUUID().toString();

    @Indexed
    private String userId;

    private String title;

    private String body;

    @Builder.Default
    private NotificationType type = NotificationType.MESSAGE;

    @Builder.Default
    private boolean read = false;

    private String messageId;

    @Builder.Default
    private Instant createdAt = Instant.now();
}
