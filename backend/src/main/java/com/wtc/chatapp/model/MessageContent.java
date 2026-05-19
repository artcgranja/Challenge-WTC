package com.wtc.chatapp.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MessageContent {
    private String title;
    private String body;
    private String imageUrl;
    private List<ActionButton> buttons;
}
