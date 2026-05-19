package com.wtc.chatapp.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "segments")
public class Segment {

    @Id
    @Builder.Default
    private String id = UUID.randomUUID().toString();

    private String name;

    private String description;

    @Builder.Default
    private List<String> tags = new ArrayList<>();

    private String createdBy;

    @Builder.Default
    private Instant createdAt = Instant.now();

    @Builder.Default
    private Instant updatedAt = Instant.now();
}
