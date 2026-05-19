package com.wtc.chatapp.dto;

import com.wtc.chatapp.model.MessageContent;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class MessageRequest {
    private String type;
    private String recipientId;
    private List<String> segmentTags;
    @NotNull
    private MessageContent content;
}
