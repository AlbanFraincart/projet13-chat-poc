package com.ycyw.chat.model;

import lombok.*;

@Data @NoArgsConstructor @AllArgsConstructor
public class ChatMessage {
    private String sender;    // ex: CUSTOMER, AGENT
    private String content;
    private String timestamp; // ISO-8601
}
