# POC – Chat Support

## 🎯 Objectif

Ce POC valide la faisabilité d’un système de **chat support** entre un frontend Angular et un backend Spring Boot.  
Il ne comprend **pas de base de données**, uniquement la communication front ↔ back.

## 🏗️ Architecture du POC

- **Frontend** : Angular 17 (SPA minimale).
- **Backend** : Spring Boot 3 (API REST + WebSocket).
- **Communication** : HTTP + WebSocket.

## 🚀 Lancer le POC

### 1. Backend

Voir [back/README.md](./back/README.md)

### 2. Frontend

Voir [front/README.md](./front/README.md)

## 📖 Notes

- Le code est volontairement simplifié (pas de persistance).
- Sert uniquement à démontrer la communication en temps réel.
