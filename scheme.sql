-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.roles (
  id integer NOT NULL DEFAULT nextval('roles_id_seq'::regclass),
  role_name text NOT NULL UNIQUE,
  CONSTRAINT roles_pkey PRIMARY KEY (id)
);
CREATE TABLE public.users (
  id text NOT NULL,
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  password text NOT NULL,
  role_id integer NOT NULL,
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT fk_user_role FOREIGN KEY (role_id) REFERENCES public.roles(id)
);
CREATE TABLE public.tickets (
  id text NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  status text NOT NULL DEFAULT 'open'::text CHECK (status = ANY (ARRAY['open'::text, 'inProgress'::text, 'closed'::text])),
  priority text NOT NULL CHECK (priority = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text])),
  category text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  creator_id text NOT NULL,
  creator_name text NOT NULL,
  attachments ARRAY DEFAULT '{}'::text[],
  helpdesk_id text,
  finished_at timestamp with time zone,
  CONSTRAINT tickets_pkey PRIMARY KEY (id),
  CONSTRAINT tickets_helpdesk_id_fkey FOREIGN KEY (helpdesk_id) REFERENCES public.users(id)
);
CREATE TABLE public.ticket_histories (
  id bigint NOT NULL DEFAULT nextval('ticket_histories_id_seq'::regclass),
  ticket_id text,
  message text NOT NULL,
  user_name text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT ticket_histories_pkey PRIMARY KEY (id),
  CONSTRAINT ticket_histories_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id)
);
CREATE TABLE public.ticket_comments (
  id bigint NOT NULL DEFAULT nextval('ticket_comments_id_seq'::regclass),
  ticket_id text,
  comment_text text NOT NULL,
  user_name text NOT NULL,
  reply_to_user text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT ticket_comments_pkey PRIMARY KEY (id),
  CONSTRAINT ticket_comments_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id)
);
CREATE TABLE public.notifications (
  id bigint NOT NULL DEFAULT nextval('notifications_id_seq'::regclass),
  ticket_id text NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  target_role_id integer NOT NULL,
  target_user_id text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id)
);




-- ==========================================
-- DDL TABEL
-- ==========================================

-- 1. TABEL ROLES
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    role_name TEXT NOT NULL UNIQUE
);

-- 2. TABEL USERS
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    role_id INT NOT NULL,
    CONSTRAINT fk_user_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT
);

-- 3. MEMBUAT TABEL TICKETS
CREATE TABLE tickets (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'inProgress', 'closed')),
    priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high')),
    category TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    creator_id TEXT NOT NULL,
    creator_name TEXT NOT NULL,
    attachments TEXT[] DEFAULT '{}',
    helpdesk_id TEXT REFERENCES users(id) ON DELETE SET NULL
);
ALTER TABLE tickets ADD COLUMN finished_at TIMESTAMPTZ;

-- 4. MEMBUAT TABEL TICKET HISTORIES
CREATE TABLE ticket_histories (
    id BIGSERIAL PRIMARY KEY,
    ticket_id TEXT REFERENCES tickets(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    user_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. MEMBUAT TABEL TICKET COMMENTS
CREATE TABLE ticket_comments (
    id BIGSERIAL PRIMARY KEY,
    ticket_id TEXT REFERENCES tickets(id) ON DELETE CASCADE,
    comment_text TEXT NOT NULL,
    user_name TEXT NOT NULL,
    reply_to_user TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

  -- 6. MEMBUAT TABEL NOTIFICATIONS
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    ticket_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    target_role_id INT NOT NULL,
    target_user_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==========================================
-- PENGISIAN DATA AWAL
-- ==========================================

-- Data master tabel roles
INSERT INTO roles (role_name) VALUES
('admin'),
('helpdesk'),
('user');

-- Data pengguna ke tabel users
INSERT INTO users (id, name, email, password, role_id) VALUES
('1', 'Admin Ticketing', 'admin@mail.com', 'admin123', 1),
('2', 'Helpdesk Staff', 'helpdesk@mail.com', 'helpdesk123', 2),
('3', 'Regular User', 'user@mail.com', 'user123', 3);


-- ==========================================
-- POLICY
-- ==========================================

-- 1. Mengaktifkan fitur RLS secara penuh pada ke semua tabel
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_histories ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_comments ENABLE ROW LEVEL SECURITY;

-- 2. Memberikan hak akses eksplisit ke PostgREST/Anon Client agar bisa melakukan INSERT
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;


-- Kebijakan Users & Roles
CREATE POLICY "Allow select for login" ON users FOR SELECT USING (true);
CREATE POLICY "Allow insert for registration" ON users
FOR INSERT WITH CHECK (role_id = 3);
CREATE POLICY "Allow read roles for everyone" ON roles FOR SELECT USING (true);

-- Kebijakan Tickets
CREATE POLICY "Allow read tickets based on owner or staff" ON tickets FOR SELECT USING (
    creator_id = (SELECT id FROM users WHERE id = creator_id) OR
    EXISTS (SELECT 1 FROM users WHERE id = users.id AND (role_id = 1 OR role_id = 2))
);

CREATE POLICY "Allow insert for authenticated creators" ON tickets FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = creator_id));
CREATE POLICY "Allow update for tickets for admin or helpdesk" ON tickets FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = users.id AND (role_id = 1 OR role_id = 2))
);

-- Kebijakan Histories
CREATE POLICY "Allow read history if ticket is accessible" ON ticket_histories FOR SELECT USING (
    EXISTS (SELECT 1 FROM tickets WHERE tickets.id = ticket_id)
);
CREATE POLICY "Allow insert history logs" ON ticket_histories
FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM tickets WHERE tickets.id = ticket_id));


-- Kebijakan Comments
CREATE POLICY "Allow read comments if ticket is accessible" ON ticket_comments FOR SELECT USING (
    EXISTS (SELECT 1 FROM tickets WHERE tickets.id = ticket_comments.ticket_id)
);
CREATE POLICY "Allow insert comments for everyone" ON ticket_comments
FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM tickets WHERE tickets.id = ticket_id));


-- Mengaktifkan RLS pada tabel notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE notifications TO anon;
GRANT SELECT, INSERT ON TABLE notifications TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE notifications_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE notifications_id_seq TO authenticated;

-- Kebijakan Membaca Notifikasi
CREATE POLICY "Allow read notifications based on role or user id" ON notifications
FOR SELECT USING (
    (target_role_id = (SELECT role_id FROM users WHERE id = target_user_id)) OR
    (target_role_id IN (1, 2))
);


-- ==========================================
-- TRIGGER DAN FUNGSI
-- ==========================================
-- ====================================================================

-- 1. MEMBUAT FUNGSI TRIGGER OTOMATIS UNTUK NOTIFIKASI TIKET
CREATE OR REPLACE FUNCTION trigger_ticket_notification()
RETURNS TRIGGER
SECURITY DEFINER -- Berjalan sebagai sistem pembuat fungsi (bypass RLS internal)
SET search_path = public, pg_temp -- Mengunci search_path (Fix linter 0011)
AS $$
BEGIN
    -- JIKA TIKET BARU DIBUAT (STATUS: OPEN)
    IF (TG_OP = 'INSERT') THEN
        -- Notif untuk User Pembuat
        INSERT INTO notifications (ticket_id, title, description, target_role_id, target_user_id)
        VALUES (NEW.id, 'Tiket Berhasil Dibuat', 'Tiket #' || NEW.id || ' ("' || NEW.title || '") berhasil diajukan dengan status OPEN.', 3, NEW.creator_id);

        -- Notif untuk Admin & Helpdesk
        INSERT INTO notifications (ticket_id, title, description, target_role_id)
        VALUES (NEW.id, 'Tiket Baru Masuk (OPEN)', 'User ' || NEW.creator_name || ' membuat tiket baru: "' || NEW.title || '".', 1);
        INSERT INTO notifications (ticket_id, title, description, target_role_id)
        VALUES (NEW.id, 'Tiket Baru Masuk (OPEN)', 'Ada tiket servis baru menanti konfirmasi: "' || NEW.title || '".', 2);

    -- JIKA STATUS TIKET BERUBAH (UPDATE)
    ELSIF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        -- Notif untuk User Pembuat saat In Progress atau Closed
        INSERT INTO notifications (ticket_id, title, description, target_role_id, target_user_id)
        VALUES (NEW.id, 'Status Tiket Diperbarui', 'Tiket Anda #' || NEW.id || ' kini berubah status menjadi ' || UPPER(NEW.status) || '.', 3, NEW.creator_id);

        -- Jika Admin memajukan ke In Progress, Helpdesk dapat notif khusus
        IF (NEW.status = 'inProgress') THEN
            INSERT INTO notifications (ticket_id, title, description, target_role_id)
            VALUES (NEW.id, 'Tiket Siap Dikerjakan', 'Tiket #' || NEW.id || ' telah dialihkan oleh Admin menjadi IN PROGRESS.', 2);
        END IF;

        -- Jika Helpdesk menutup tiket menjadi Closed, Admin & User dapat notif
        IF (NEW.status = 'closed') THEN
            INSERT INTO notifications (ticket_id, title, description, target_role_id)
            VALUES (NEW.id, 'Tiket Servis Selesai (CLOSED)', 'Tiket #' || NEW.id || ' resmi ditutup oleh staff Helpdesk.', 1);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ticket_notify_trigger
AFTER INSERT OR UPDATE ON tickets
FOR EACH ROW EXECUTE FUNCTION trigger_ticket_notification();


-- 2. MEMBUAT FUNGSI TRIGGER OTOMATIS UNTUK NOTIFIKASI KOMENTAR
CREATE OR REPLACE FUNCTION trigger_comment_notification()
RETURNS TRIGGER
SECURITY DEFINER -- Berjalan sebagai sistem pembuat fungsi (bypass RLS internal)
SET search_path = public, pg_temp -- Mengunci search_path (Fix linter 0011)
AS $$
DECLARE
    v_creator_id TEXT;
BEGIN
    -- Ambil ID pemilik tiket asli
    SELECT creator_id INTO v_creator_id FROM tickets WHERE id = NEW.ticket_id;

    -- Notif untuk Pemilik Tiket (User) jika yang berkomentar adalah staff
    INSERT INTO notifications (ticket_id, title, description, target_role_id, target_user_id)
    VALUES (NEW.ticket_id, 'Komentar Diskusi Baru', NEW.user_name || ' mengirim komentar baru di tiket Anda.', 3, v_creator_id);

    -- Notif untuk Admin
    INSERT INTO notifications (ticket_id, title, description, target_role_id)
    VALUES (NEW.ticket_id, 'Aktivitas Diskusi Tiket', 'Komentar baru dari ' || NEW.user_name || ' pada tiket #' || NEW.ticket_id, 1);

    -- Notif untuk Helpdesk
    INSERT INTO notifications (ticket_id, title, description, target_role_id)
    VALUES (NEW.ticket_id, 'Aktivitas Diskusi Tiket', 'Komentar baru dari ' || NEW.user_name || ' pada tiket #' || NEW.ticket_id, 2);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER comment_notify_trigger
AFTER INSERT ON ticket_comments
FOR EACH ROW EXECUTE FUNCTION trigger_comment_notification();


-- ====================================================================
-- 1. REVISI : CABUT HAK EKSEKUSI DARI ROLE PUBLIK (ANON & AUTHENTICATED)
-- ====================================================================

-- Cabut hak akses untuk fungsi trigger tiket
REVOKE EXECUTE ON FUNCTION trigger_ticket_notification() FROM public;
REVOKE EXECUTE ON FUNCTION trigger_ticket_notification() FROM anon;
REVOKE EXECUTE ON FUNCTION trigger_ticket_notification() FROM authenticated;

-- Cabut hak akses untuk fungsi trigger komentar
REVOKE EXECUTE ON FUNCTION trigger_comment_notification() FROM public;
REVOKE EXECUTE ON FUNCTION trigger_comment_notification() FROM anon;
REVOKE EXECUTE ON FUNCTION trigger_comment_notification() FROM authenticated;

-- ====================================================================
-- 2. REVISI : BERIKAN HAK EKSEKUSI HANYA KEPADA INTERNAL POSTGRES/SYSTEM (Opsional/Memastikan)
-- ====================================================================
GRANT EXECUTE ON FUNCTION trigger_ticket_notification() TO postgres;
GRANT EXECUTE ON FUNCTION trigger_comment_notification() TO postgres;