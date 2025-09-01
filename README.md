# POC – Chat Support

## 🎯 Objectif

Ce POC valide la faisabilité d’un système de **chat support** entre un frontend Angular et un backend Spring Boot.  
⚠️ **Important** : le POC **ne dépend pas de la base de données**.  
Le dossier [`bdd/`](./bdd) contient uniquement les scripts et la configuration pour mettre en place **la structure de données complète de l’application finale**, indépendamment de ce POC.

## 🏗️ Architecture du POC

- **Frontend** : Angular 17 (SPA minimale).
- **Backend** : Spring Boot 3 (API REST + WebSocket).
- **Communication** : HTTP + WebSocket.
- **BDD** : présente dans `bdd/`, mais **non utilisée dans ce POC**.

## 🚀 Lancer le POC

### 1. Backend

Voir [back/README.md](./back/README.md)

### 2. Frontend

Voir [front/README.md](./front/README.md)

## 📖 Notes

- Le code est volontairement simplifié.
- Sert uniquement à démontrer la communication en temps réel.
- La BDD est fournie séparément pour respecter les livrables du projet.
