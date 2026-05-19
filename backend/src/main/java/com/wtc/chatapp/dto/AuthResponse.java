package com.wtc.chatapp.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class AuthResponse {
    private String token;
    private String refreshToken;
    private String userId;
    private String email;
    private String fullName;
    private String role;
    private List<String> tags;
    private String status;
    private String avatarUrl;
    private String phone;
}
