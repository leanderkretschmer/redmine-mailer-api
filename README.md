# Extended API Plugin

Ein Redmine 6 Plugin, das die API um die Verwaltung mehrerer E-Mail-Adressen pro User erweitert.

## Features

- **CRUD-Operationen für User-E-Mails**: Vollständige API-Unterstützung zum Erstellen, Lesen, Aktualisieren und Löschen von E-Mail-Adressen
- **Mehrere E-Mails pro User**: Unterstützung für zusätzliche E-Mail-Adressen neben der Standard-E-Mail
- **RESTful API**: Saubere REST-API-Endpunkte im JSON-Format
- **Kontakt-Zuweisung zu Tickets**: Abfrage des zugewiesenen Kontakts zu einem Ticket

## Installation

1. Kopiere das Plugin-Verzeichnis in `plugins/redmine_extended_api` deiner Redmine-Installation
2. Führe die Migrationen aus (falls vorhanden): `rake redmine:plugins:migrate RAILS_ENV=production`
3. Starte Redmine neu

## API-Endpunkte

### Alle E-Mails eines Users abrufen

```
GET /users/:user_id/mails.json
```

**Beispiel:**
```bash
curl -H "X-Redmine-API-Key: YOUR_API_KEY" \
  https://your-redmine-instance.com/users/1/mails.json
```

**Antwort:**
```json
[
  {
    "id": 1,
    "address": "user@example.com",
    "is_default": true,
    "user_id": 1,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  {
    "id": 2,
    "address": "user.alternative@example.com",
    "is_default": false,
    "user_id": 1,
    "created_at": "2024-01-02T00:00:00Z",
    "updated_at": "2024-01-02T00:00:00Z"
  }
]
```

### E-Mail-Adresse suchen

```
GET /mail_search.json
```

**Beispiel:**
```bash
curl -H "X-Redmine-API-Key: YOUR_API_KEY" \
  https://your-redmine-instance.com/mail_search.json?email=example@example.com
```

**Query-Parameter:**
- `email` oder `address` (required): Die zu suchende E-Mail-Adresse

**Antwort wenn gefunden:**
```json
{
  "id": 11816,
  "address": "example@example.com",
  "is_default": true,
  "user_id": 123,
  "notify": 1
}
```

**Antwort wenn nicht gefunden:**
```json
{
  "exists": false
}
```

### Eine spezifische E-Mail abrufen

```
GET /users/:user_id/mails/:id.json
```

**Beispiel:**
```bash
curl -H "X-Redmine-API-Key: YOUR_API_KEY" \
  https://your-redmine-instance.com/users/1/mails/2.json
```

### Neue E-Mail-Adresse erstellen

```
POST /users/:user_id/mails.json
```

**Beispiel:**
```bash
curl -X POST \
  -H "X-Redmine-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"address": "newemail@example.com", "is_default": false, "notify": 1}' \
  https://your-redmine-instance.com/users/1/mails.json
```

**Parameter:**
- `address` (required): Die E-Mail-Adresse
- `is_default` (optional): Ob dies die Standard-E-Mail ist (default: false)
- `notify` (optional): Ob Benachrichtigungen an diese E-Mail gesendet werden sollen (0 oder 1, default: 0)

### E-Mail-Adresse aktualisieren

```
PUT /users/:user_id/mails/:id.json
PATCH /users/:user_id/mails/:id.json
```

**Beispiel:**
```bash
curl -X PUT \
  -H "X-Redmine-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"address": "updated@example.com", "is_default": true, "notify": 1}' \
  https://your-redmine-instance.com/users/1/mails/2.json
```

### E-Mail-Adresse löschen

```
DELETE /users/:user_id/mails/:id.json
```

**Beispiel:**
```bash
curl -X DELETE \
  -H "X-Redmine-API-Key: YOUR_API_KEY" \
https://your-redmine-instance.com/users/1/mails/2.json
```

### Zugewiesenen Kontakt eines Tickets abrufen

```
GET /issues/:issue_id/assigned_contact.json
```

Mit diesem Endpoint kann für ein Ticket der zugewiesene Kontakt abgefragt werden. Es werden sowohl die Kontakt-ID als auch der Name zurückgegeben.

**Beispiel:**
```bash
curl -H "X-Redmine-API-Key: YOUR_API_KEY" \
  https://your-redmine-instance.com/issues/1234/assigned_contact.json
```

**Antwort wenn gefunden:**
```json
{
  "issue_id": 1234,
  "contact_id": 987,
  "contact_name": "Max Muster"
}
```

**Antwort wenn nicht gefunden:**
```json
{
  "issue_id": 1234,
  "exists": false
}
```

### Zugewiesenen Kontakt eines Tickets setzen

```
PUT /issues/:issue_id/assigned_contact.json
POST /issues/:issue_id/assigned_contact.json
```

Parameter:
- `contact_id` (required): ID des Kontakts, der dem Ticket zugewiesen werden soll

Dieser Endpoint schreibt in die Datenbanktabelle `assigned_contacts` und ermöglicht ein Upsert der Zuordnung.

**Beispiel:**
```bash
curl -X PUT \
  -H "X-Redmine-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"contact_id": 987}' \
  https://your-redmine-instance.com/issues/1234/assigned_contact.json
```

**Erfolgsantwort:**
```json
{
  "success": true,
  "issue_id": 1234,
  "contact_id": 987,
  "contact_name": "Max Muster"
}
```

## Authentifizierung

Alle API-Endpunkte erfordern eine Authentifizierung über:
- API-Key im Header: `X-Redmine-API-Key: YOUR_API_KEY`
- Oder Basic Authentication mit Benutzername/Passwort

## Berechtigungen

Benutzer benötigen globale Administratorrechte oder entsprechende Berechtigungen, um E-Mail-Adressen zu verwalten.

## Anforderungen

- Redmine 6.0.0 oder höher
- Ruby on Rails (Version abhängig von Redmine-Version)
- Optional: Plugin zur Kontakt-Zuweisung. Dieses Plugin unterstützt die Zuweisung und Abfrage über `redmine_contact_assigner`:
- `https://github.com/leanderkretschmer/redmine_contact_assigner`
  Die Abfrage und das Setzen erfolgen über die Tabelle `assigned_contacts`.

## Lizenz

Dieses Plugin steht unter der MIT-Lizenz.

## Support

Bei Fragen oder Problemen bitte ein Issue im Repository erstellen.
