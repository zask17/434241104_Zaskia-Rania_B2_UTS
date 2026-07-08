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

CREATE POLICY "Allow insert for all authenticated users" ON tickets
    FOR INSERT  WITH CHECK (true);
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

-- 1. MEMBUAT FUNGSI TRIGGER OTOMATIS UNTUK NOTIFIKASI TIKET
CREATE OR REPLACE FUNCTION trigger_ticket_notification()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_creator_role_id INT;
BEGIN
    -- Ambil role_id asli dari user pembuat tiket
    SELECT role_id INTO v_creator_role_id FROM users WHERE id = NEW.creator_id;

    -- JIKA TIKET BARU DIBUAT (STATUS: OPEN)
    IF (TG_OP = 'INSERT') THEN
        -- Notif personal untuk Pembuat (apapun rolenya sekarang menjadi dinamis)
        INSERT INTO notifications (ticket_id, title, description, target_role_id, target_user_id)
        VALUES (NEW.id, 'Tiket Berhasil Dibuat', 'Tiket #' || NEW.id || ' ("' || NEW.title || '") berhasil diajukan dengan status OPEN.', v_creator_role_id, NEW.creator_id);

        -- Notif siaran global untuk Admin & Helpdesk lainnya
        INSERT INTO notifications (ticket_id, title, description, target_role_id)
        VALUES (NEW.id, 'Tiket Baru Masuk (OPEN)', 'User ' || NEW.creator_name || ' membuat tiket baru: "' || NEW.title || '".', 1);
        INSERT INTO notifications (ticket_id, title, description, target_role_id)
        VALUES (NEW.id, 'Tiket Baru Masuk (OPEN)', 'Ada tiket servis baru menanti konfirmasi: "' || NEW.title || '".', 2);

    -- JIKA STATUS TIKET BERUBAH (UPDATE)
    ELSIF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        -- Notif perkembangan status untuk User Pembuat
        INSERT INTO notifications (ticket_id, title, description, target_role_id, target_user_id)
        VALUES (NEW.id, 'Status Tiket Diperbarui', 'Tiket Anda #' || NEW.id || ' kini berubah status menjadi ' || UPPER(NEW.status) || '.', v_creator_role_id, NEW.creator_id);

        IF (NEW.status = 'inProgress') THEN
            INSERT INTO notifications (ticket_id, title, description, target_role_id)
            VALUES (NEW.id, 'Tiket Siap Dikerjakan', 'Tiket #' || NEW.id || ' telah dialihkan oleh Admin menjadi IN PROGRESS.', 2);
        END IF;

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
-- FORGOT PASSWORD
-- ====================================================================

ALTER TABLE users
ADD COLUMN IF NOT EXISTS reset_token TEXT,
ADD COLUMN IF NOT EXISTS reset_token_expires_at TIMESTAMPTZ;

-- FUNGSI UNTUK MERESET PASSWORD SECARA AMAN

CREATE OR REPLACE FUNCTION reset_password_with_token(
    p_email TEXT,
    p_token TEXT,
    p_new_password TEXT
)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id TEXT;
BEGIN
    -- Cek apakah email, token, dan masa berlaku token valid
    SELECT id INTO v_user_id
    FROM users
    WHERE email = p_email
      AND reset_token = p_token
      AND reset_token_expires_at > NOW();

    -- Jika user tidak ditemukan atau token kedaluwarsa
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Update password baru dan hapus token yang sudah dipakai
    UPDATE users
    SET password = p_new_password,
        reset_token = NULL,
        reset_token_expires_at = NULL
    WHERE id = v_user_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Cabut akses fungsi reset dari publik dan berikan ke role anon & authenticated
REVOKE EXECUTE ON FUNCTION reset_password_with_token(TEXT, TEXT, TEXT) FROM public;
GRANT EXECUTE ON FUNCTION reset_password_with_token(TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION reset_password_with_token(TEXT, TEXT, TEXT) TO authenticated;

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