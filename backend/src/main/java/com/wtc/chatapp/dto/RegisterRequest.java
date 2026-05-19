package com.wtc.chatapp.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;

@Data
public class RegisterRequest {
    @NotBlank @Email
    private String email;
    @NotBlank
    private String password;
    @NotBlank
    private String fullName;
    private String phone;
    private String role;
    private List<String> tags;
}
