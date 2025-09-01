package com.ycyw.chat.controllers;

import com.ycyw.chat.model.ChatMessage;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

import java.time.Instant;

@Controller
public class ChatController {

    @MessageMapping("/chat.send")     // le client publie sur /app/chat.send
    @SendTo("/topic/messages")        // tous les abonnés reçoivent /topic/messages
    public ChatMessage send(ChatMessage in) {
        return new ChatMessage(in.getSender(), in.getContent(), Instant.now().toString());
    }
}
