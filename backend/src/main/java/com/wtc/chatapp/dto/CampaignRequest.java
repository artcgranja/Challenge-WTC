package com.wtc.chatapp.dto;

import com.wtc.chatapp.model.MessageContent;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CampaignRequest {
    @NotBlank
    private String name;
    @NotBlank
    private String segmentId;
    @NotNull
    private MessageContent content;
    private String deeplink;
}
