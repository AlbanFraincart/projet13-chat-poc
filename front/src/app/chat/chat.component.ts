import { Component, OnDestroy, OnInit } from '@angular/core';
import { ChatService, ChatMessage } from '../chat.service';

@Component({
  selector: 'app-chat',
  templateUrl: './chat.component.html',
  styleUrls: ['./chat.component.css']
})
export class ChatComponent implements OnInit, OnDestroy {
  sender = 'Fred le client';       // Nom par défaut de l’utilisateur
  content = '';              // Champ de saisie courant
  messages: ChatMessage[] = []; // Liste des messages affichés

  constructor(private chat: ChatService) { }

  ngOnInit(): void {
    this.chat.connect();  // Ouvre la connexion WebSocket
    // Abonne le composant au flux de messages
    this.chat.messages$.subscribe(ms => this.messages = ms);
  }

  // Envoi d’un nouveau message
  send() {
    const c = this.content.trim();
    if (!c) return;  // Ignore si vide
    this.chat.send(this.sender, c); // Publie via le service
    this.content = '';              // Réinitialise le champ
  }

  ngOnDestroy(): void {
    this.chat.disconnect(); // Ferme la connexion proprement
  }
}
