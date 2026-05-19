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
@Document(collection = "users")
public class User {

    @Id
    @Builder.Default
    private String id = UUID.randomUUID().toString();

    @Indexed(unique = true)
    private String email;

    private String password;

    private String fullName;

    private String phone;

    private String avatarUrl;

    @Builder.Default
    private Role role = Role.CLIENT;

    @Builder.Default
    private List<String> tags = new ArrayList<>();

    @Builder.Default
    private String status = "active";

    @Builder.Default
    private Instant createdAt = Instant.now();

    @Builder.Default
    private Instant updatedAt = Instant.now();
}
