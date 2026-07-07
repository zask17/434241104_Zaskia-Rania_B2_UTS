# Dokumentasi API - E-Ticketing Helpdesk

Dokumen ini berisi daftar endpoint API yang digunakan dalam aplikasi E-Ticketing Helpdesk. Aplikasi menggunakan **Supabase PostgREST API** sebagai backend serverless.

## ⚙️ Konfigurasi Dasar
Semua permintaan harus dikirimkan ke base URL berikut dengan header autentikasi yang sesuai.

*   **Base URL**: `https://azgcylimfoggyiihpnib.supabase.co/rest/v1`
*   **Headers**:
    | Key | Value | Deskripsi |
    | :--- | :--- | :--- |
    | `Content-Type` | `application/json` | Format data JSON |
    | `apikey` | `sb_publishable_...` | Anon Key Supabase |
    | `Authorization` | `Bearer sb_publishable_...` | Token akses (Anon/User Token) |
    | `Prefer` | `return=representation` | (Opsional) Mengembalikan data setelah POST/PATCH |

---

## 🔐 1. Autentikasi & User (Tabel `users`)

### **Register User**
Mendaftarkan akun baru ke dalam sistem.
*   **Method**: `POST`
*   **Endpoint**: `/users`
*   **Body (JSON)**:
    ```json
    {
      "id": "USR-00000001",
      "name": "Budi Setiawan",
      "email": "budi@mail.com",
      "password": "password123",
      "role_id": 3
    }
    ```

### **Login User**
Mencocokkan kredensial dan mengambil data profil beserta role.
*   **Method**: `GET`
*   **Endpoint**: `/users`
*   **Query Params**:
    *   `select`: `*,roles(role_name)`
    *   `email`: `eq.budi@mail.com`
    *   `password`: `eq.password123`

---

## 🎫 2. Manajemen Tiket (Tabel `tickets`)

### **Ambil Semua Tiket**
Mengambil daftar tiket diurutkan dari yang terbaru.
*   **Method**: `GET`
*   **Endpoint**: `/tickets?select=*&order=created_at.desc`

### **Buat Tiket Baru**
Menyimpan keluhan baru ke database.
*   **Method**: `POST`
*   **Endpoint**: `/tickets`
*   **Body (JSON)**:
    ```json
    {
      "id": "TKT-260707001",
      "title": "Keyboard Rusak",
      "description": "Beberapa tombol tidak berfungsi setelah terkena air.",
      "priority": "high",
      "category": "Hardware",
      "creator_id": "USR-00000001",
      "creator_name": "Budi Setiawan",
      "attachments": ["data:image/png;base64,..."],
      "status": "open"
    }
    ```

### **Assign ke Helpdesk (Update Status)**
Mengubah status tiket menjadi `inProgress` dan menunjuk staf helpdesk.
*   **Method**: `PATCH`
*   **Endpoint**: `/tickets?id=eq.TKT-260707001`
*   **Body (JSON)**:
    ```json
    {
      "helpdesk_id": "2",
      "status": "inProgress"
    }
    ```

### **Selesaikan Tiket (Finish)**
Menutup tiket setelah pekerjaan selesai.
*   **Method**: `PATCH`
*   **Endpoint**: `/tickets?id=eq.TKT-260707001`
*   **Body (JSON)**:
    ```json
    {
      "status": "closed",
      "finished_at": "2024-07-07T10:00:00Z"
    }
    ```

---

## 💬 3. Riwayat & Komentar

### **Get Riwayat Perjalanan Tiket**
*   **Method**: `GET`
*   **Endpoint**: `/ticket_histories?ticket_id=eq.{ticketId}&order=created_at.desc`

### **Post Log Riwayat Baru**
*   **Method**: `POST`
*   **Endpoint**: `/ticket_histories`
*   **Body**: `{"ticket_id": "...", "message": "...", "user_name": "..."}`

### **Get Komentar Diskusi**
*   **Method**: `GET`
*   **Endpoint**: `/ticket_comments?ticket_id=eq.{ticketId}&order=created_at.asc`

---

## 🔔 4. Notifikasi (Tabel `notifications`)

### **Fetch Live Notifications**
Mengambil pesan notifikasi berdasarkan role atau ID user.
*   **Method**: `GET`
*   **Endpoint (Admin/Helpdesk)**: `/notifications?target_role_id=eq.{roleId}`
*   **Endpoint (User)**: `/notifications?target_user_id=eq.{userId}`

---

## ⚠️ Status Kode Response
*   `200 OK`: Berhasil mengambil atau memperbarui data.
*   `201 Created`: Berhasil menambah data baru.
*   `401 Unauthorized`: Kunci API atau Token salah/kadaluarsa.
*   `404 Not Found`: Endpoint atau data tidak ditemukan.
*   `409 Conflict`: Duplikasi data (misal: email sudah ada).
