package com.wtc.chatapp.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "customers")
public class Customer {

    @Id
    @Builder.Default
    private String id = UUID.randomUUID().toString();

    @Indexed
    private String userId;

    @Builder.Default
    private List<String> tags = new ArrayList<>();

    @Builder.Default
    private int score = 0;

    @Builder.Default
    private CustomerStatus status = CustomerStatus.ACTIVE;

    @Builder.Default
    private List<Note> notes = new ArrayList<>();

    @Builder.Default
    private List<String> segmentIds = new ArrayList<>();

    @Builder.Default
    private Instant createdAt = Instant.now();

    @Builder.Default
    private Instant updatedAt = Instant.now();
}
