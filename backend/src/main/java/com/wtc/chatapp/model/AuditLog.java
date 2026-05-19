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
@Document(collection = "audit_logs")
public class AuditLog {

    @Id
    @Builder.Default
    private String id = UUID.randomUUID().toString();

    private String userId;

    private String action;

    private String resource;

    private String resourceId;

    private String details;

    private String ipAddress;

    @Builder.Default
    private Instant timestamp = Instant.now();
}
