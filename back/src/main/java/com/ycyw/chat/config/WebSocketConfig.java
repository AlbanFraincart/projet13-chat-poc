package com.ycyw.chat.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.*;

@Configuration
@EnableWebSocketMessageBroker // Active le support STOMP/WebSocket dans Spring Boot
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Active un broker simple en mémoire qui envoie les messages aux clients
        // Tous les messages envoyés à des destinations commençant par /topic
        // seront diffusés aux abonnés correspondants
        config.enableSimpleBroker("/topic");

        // Définit le préfixe pour les destinations côté serveur (entrantes)
        // Les clients doivent envoyer leurs messages sur /app/xxx
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Définit le point d'entrée WebSocket que les clients utiliseront pour se connecter
        // Ici : ws://localhost:8080/ws/chat (avec fallback SockJS)
        registry.addEndpoint("/ws/chat")
                // Autorise les connexions venant de l'UI Angular en dev
                .setAllowedOriginPatterns("http://localhost:4200")
                // Active SockJS comme solution de repli si WebSocket natif n’est pas dispo
                .withSockJS();
    }
}