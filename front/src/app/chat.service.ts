import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { Client, IMessage } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

// Modèle d'un message de chat
export interface ChatMessage { sender: string; content: string; timestamp?: string; }

@Injectable({ providedIn: 'root' })
export class ChatService {
    private client!: Client; // client STOMP
    private messagesSubject = new BehaviorSubject<ChatMessage[]>([]); // stockage local des messages
    messages$ = this.messagesSubject.asObservable(); // observable pour les composants (UI)

    connect() {
        // Évite de se reconnecter si déjà actif
        if (this.client?.active) return;

        // Configuration du client STOMP avec SockJS
        this.client = new Client({
            webSocketFactory: () => new SockJS('http://localhost:8080/ws/chat'),
            reconnectDelay: 5000, // auto-reconnexion toutes les 5s si coupure
            debug: (msg) => console.log('[STOMP]', msg), // logs pour debug
        });

        // Quand la connexion est établie
        this.client.onConnect = () => {
            // Abonnement au topic diffusé par le backend
            this.client.subscribe('/topic/messages', (m: IMessage) => {
                const body: ChatMessage = JSON.parse(m.body);
                // Ajoute le message reçu à la liste observable
                this.messagesSubject.next([...this.messagesSubject.value, body]);
            });
        };

        // Activation de la connexion
        this.client.activate();
    }

    // Envoi d’un message vers le serveur
    send(sender: string, content: string) {
        if (!this.client?.active) return;
        const payload: ChatMessage = { sender, content };
        this.client.publish({ destination: '/app/chat.send', body: JSON.stringify(payload) });
    }

    // Déconnexion propre
    disconnect() { this.client?.deactivate(); }
}
