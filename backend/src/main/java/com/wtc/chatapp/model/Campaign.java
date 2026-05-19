package com.wtc.chatapp.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "campaigns")
public class Campaign {

    @Id
    @Builder.Default
    private String id = UUID.randomUUID().toString();

    private String name;

    private String segmentId;

    private MessageContent content;

    private String deeplink;

    @Builder.Default
    private CampaignStatus status = CampaignStatus.DRAFT;

    private Instant sentAt;

    private String sentBy;

    @Builder.Default
    private int messageCount = 0;

    @Builder.Default
    private Instant createdAt = Instant.now();
}
