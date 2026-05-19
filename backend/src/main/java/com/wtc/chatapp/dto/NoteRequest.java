package com.wtc.chatapp.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class NoteRequest {
    @NotBlank
    private String text;
}
