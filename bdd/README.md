# Base de données – Your Car Your Way

## 🎯 Objectif

Ce dossier contient les fichiers nécessaires pour mettre en place la **structure de données complète** de l’application Your Car Your Way.  
⚠️ **Cette base n’est pas utilisée par le POC chat**, elle sert uniquement à fournir le schéma de données attendu pour l’application finale.

## 📂 Contenu

- `schema.sql` : script SQL complet (tables, types ENUM, contraintes, index).
- `docker-compose.yml` : configuration pour lancer PostgreSQL 16 + Adminer.

## 🚀 Lancer la base avec Docker Compose

Depuis ce dossier :

```bash
docker compose up -d
```

PostgreSQL sera disponible sur : `localhost:5432`

- Utilisateur : `user`
- Mot de passe : `password`
- Base : `ycyw`

Adminer sera accessible sur : [http://localhost:8080](http://localhost:8080)

- Système : PostgreSQL
- Serveur : `db`
- Utilisateur : `user`
- Mot de passe : `password`
- Base : `ycyw`

---

## 🧪 Vérifications rapides

Se connecter dans le conteneur :

```bash
docker exec -it ycyw-postgres psql -U user -d ycyw
```

Puis exécuter dans psql :

```bash
\dt                   -- liste des tables
\d+ users             -- structure de la table users
SELECT * FROM vehicle_categories;  -- doit renvoyer 4 lignes
```

Réinitialiser la base

Pour repartir de zéro :

Puis exécuter dans psql :

```bash
docker compose down -v
docker compose up -d

```
