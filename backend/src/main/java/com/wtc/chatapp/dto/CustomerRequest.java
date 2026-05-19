package com.wtc.chatapp.dto;

import lombok.Data;

import java.util.List;

@Data
public class CustomerRequest {
    private String userId;
    private List<String> tags;
    private Integer score;
    private String status;
}
