CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS citext;

-- ======================= Types ENUM =======================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reservation_status') THEN
    CREATE TYPE reservation_status AS ENUM ('PENDING','CONFIRMED','CANCELLED');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
    CREATE TYPE payment_status AS ENUM ('REQUIRES_ACTION','SUCCEEDED','FAILED','REFUNDED');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ticket_status') THEN
    CREATE TYPE ticket_status AS ENUM ('OPEN','PENDING','CLOSED');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ticket_channel') THEN
    CREATE TYPE ticket_channel AS ENUM ('TICKET','CHAT');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'message_sender') THEN
    CREATE TYPE message_sender AS ENUM ('CUSTOMER','AGENT','SYSTEM');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notif_status') THEN
    CREATE TYPE notif_status AS ENUM ('SENT','BOUNCED','FAILED');
  END IF;
END$$;

-- ======================= Utilisateurs =======================
CREATE TABLE users (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email             CITEXT NOT NULL UNIQUE,
  password_hash     TEXT   NOT NULL,
  email_verified_at TIMESTAMPTZ,
  last_login_at     TIMESTAMPTZ,
  failed_logins     INT    NOT NULL DEFAULT 0,
  locked_until      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE user_profiles (
  user_id       UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  first_name    TEXT NOT NULL,
  last_name     TEXT NOT NULL,
  date_of_birth DATE,
  phone         TEXT,
  addr_line1    TEXT,
  addr_line2    TEXT,
  city          TEXT,
  postal_code   TEXT,
  country       CHAR(2),
  pref_lang     TEXT   NOT NULL DEFAULT 'EN',
  pref_currency CHAR(3) NOT NULL DEFAULT 'EUR',  -- ISO-4217
  pref_units    TEXT   NOT NULL DEFAULT 'km'
);

CREATE TABLE consents (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind       TEXT NOT NULL,   -- terms | privacy | marketing
  granted    BOOLEAN NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_consents_user ON consents(user_id, granted_at DESC);

-- ======================= Référentiels =======================
CREATE TABLE agencies (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL,
  code        TEXT,
  addr_line1  TEXT NOT NULL,
  city        TEXT NOT NULL,
  country     CHAR(2) NOT NULL,
  timezone    TEXT NOT NULL,  -- IANA (ex: Europe/Paris)
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE vehicle_categories (
  acriss CHAR(4) PRIMARY KEY,  -- norme ACRISS (ex: CDMR)
  label  TEXT NOT NULL
);

-- ======================= Réservations & Paiements =======================
CREATE TABLE reservations (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  pickup_agency_id  UUID NOT NULL REFERENCES agencies(id),
  return_agency_id  UUID NOT NULL REFERENCES agencies(id),
  pickup_at_utc     TIMESTAMPTZ NOT NULL,
  return_at_utc     TIMESTAMPTZ NOT NULL,
  category_acriss   CHAR(4) NOT NULL REFERENCES vehicle_categories(acriss),
  status            reservation_status NOT NULL DEFAULT 'PENDING',
  price_total       NUMERIC(12,2) NOT NULL,
  currency          CHAR(3) NOT NULL,  -- ISO-4217
  price_breakdown   JSONB NOT NULL,    -- snapshot du prix affiché
  policy_applied    JSONB NOT NULL,    -- règles appliquées (48h/25%…)
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (return_at_utc > pickup_at_utc)
);
CREATE INDEX idx_res_by_user_created ON reservations(user_id, created_at DESC);
CREATE INDEX idx_res_by_pickup_time ON reservations(pickup_at_utc);
CREATE INDEX idx_res_by_return_time ON reservations(return_at_utc);

CREATE TABLE payments (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reservation_id   UUID NOT NULL UNIQUE REFERENCES reservations(id) ON DELETE CASCADE,
  provider         TEXT NOT NULL DEFAULT 'stripe',
  intent_id        TEXT NOT NULL,                      -- PaymentIntent id (ex: pi_...)
  status           payment_status NOT NULL,
  amount           NUMERIC(12,2) NOT NULL,
  currency         CHAR(3) NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  confirmed_at     TIMESTAMPTZ,
  refunded_amount  NUMERIC(12,2),
  provider_payload JSONB                                -- détails PSP optionnels (pas de données carte)
);
CREATE INDEX idx_payment_status ON payments(status);

-- ======================= Support (tickets, messages, pièces) =======================
CREATE TABLE support_tickets (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID REFERENCES users(id) ON DELETE SET NULL,
  reservation_id UUID REFERENCES reservations(id) ON DELETE SET NULL,
  channel        ticket_channel NOT NULL,              -- TICKET | CHAT
  status         ticket_status  NOT NULL DEFAULT 'OPEN',
  subject        TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ticket_user ON support_tickets(user_id, created_at DESC);
CREATE INDEX idx_ticket_res  ON support_tickets(reservation_id);

CREATE TABLE support_messages (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_id  UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  sender     message_sender NOT NULL,                  -- CUSTOMER | AGENT | SYSTEM
  body       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_msg_ticket_time ON support_messages(ticket_id, created_at);

CREATE TABLE attachments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id  UUID NOT NULL REFERENCES support_messages(id) ON DELETE CASCADE,
  s3_key      TEXT NOT NULL,
  filename    TEXT NOT NULL,
  mime        TEXT NOT NULL,                           -- ex: image/png, application/pdf
  size_bytes  BIGINT NOT NULL CHECK (size_bytes > 0)
);

-- ======================= Notifications (e-mail only, V2) =======================
CREATE TABLE notification_logs (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES users(id) ON DELETE SET NULL,  -- notif possible sans user
  template        TEXT NOT NULL,                 -- ex: account_activation, booking_confirmed
  provider_msg_id TEXT,                          -- id côté SendGrid/Mailgun
  status          notif_status NOT NULL,         -- SENT | BOUNCED | FAILED
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notif_user_time ON notification_logs(user_id, created_at DESC);

-- ======================= Données de base utiles =======================
INSERT INTO vehicle_categories (acriss, label) VALUES
  ('ECMN','Economy 4D Manual, No A/C'),
  ('CDMR','Compact 4D Manual, A/C'),
  ('IDAR','Intermediate 4D Auto, A/C'),
  ('SDAR','Standard 4D Auto, A/C')
ON CONFLICT DO NOTHING;
