<?php

require "koneksi.php";

$pesan = "";
$pesan_tipe = "";

// Ambil data resep yang akan diedit
if (!isset($_GET["id"]) || !is_numeric($_GET["id"])) {
    die("ID resep tidak valid.");
}

$id = (int) $_GET["id"];

// Proses UPDATE saat form disubmit
if ($_SERVER["REQUEST_METHOD"] === "POST") {

    $title   = trim($_POST["title"] ?? "");
    $content = trim($_POST["content"] ?? "");
    $source  = trim($_POST["source"] ?? "");

    if ($title === "" || $content === "") {
        $pesan = "Judul dan konten resep tidak boleh kosong!";
        $pesan_tipe = "error";
    } else {

        $query = "UPDATE resep_clean
                  SET title = $1,
                      content = $2,
                      source = $3
                  WHERE id = $4";

        $result = pg_query_params(
            $koneksi,
            $query,
            [$title, $content, $source, $id]
        );

        if ($result) {
            $pesan = "Resep berhasil diupdate!";
            $pesan_tipe = "success";
        } else {
            $pesan = "Gagal mengupdate resep: " . pg_last_error($koneksi);
            $pesan_tipe = "error";
        }
    }
}

// Ambil data resep (untuk ditampilkan di form)
$query = "SELECT id, title, content, source, split
          FROM resep_clean
          WHERE id = $1";

$result = pg_query_params($koneksi, $query, [$id]);

if (!$result || pg_num_rows($result) === 0) {
    die("Resep tidak ditemukan.");
}

$resep = pg_fetch_assoc($result);

?>

<!DOCTYPE html>
<html lang="id">

<head>

    <meta charset="UTF-8">

    <title>Edit Resep</title>

    <style>
        /* Import Google Fonts (MasterChef Elegance: Epilogue & Plus Jakarta Sans) */
        @import url('https://fonts.googleapis.com/css2?family=Epilogue:ital,wght@0,600;0,700;0,800;0,900;1,700&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap');

        :root {
            --bg-canvas: #f8f9fc;
            --surface-card: #ffffff;
            --text-main: #111827;
            --text-label: #334155;
            --text-placeholder: #94a3b8;
            --gold-primary: #d97706;
            --gold-gradient: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            --gold-subtle: #fef3c7;
            --border-card: #e2e8f0;
            --input-border: #cbd5e1;
            --input-focus: #f59e0b;
            --shadow-card: 0 4px 20px -2px rgba(15, 23, 42, 0.05), 0 2px 6px -1px rgba(15, 23, 42, 0.03);
            --shadow-btn: 0 4px 14px rgba(217, 119, 6, 0.28);
            --shadow-btn-hover: 0 6px 20px rgba(217, 119, 6, 0.38);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: var(--bg-canvas);
            background-image: 
                radial-gradient(at 0% 0%, rgba(245, 158, 11, 0.04) 0px, transparent 45%),
                radial-gradient(at 100% 100%, rgba(220, 38, 38, 0.03) 0px, transparent 45%);
            color: var(--text-main);
            min-height: 100vh;
            margin: 0;
            padding: 44px 20px 80px;
            -webkit-font-smoothing: antialiased;
        }

        .container {
            max-width: 820px;
            margin: auto;
        }

        /* Tombol Navigasi Kembali */
        .back {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 24px;
            text-decoration: none;
            color: #475569;
            font-family: 'Plus Jakarta Sans', sans-serif;
            font-size: 13.5px;
            font-weight: 700;
            background: #ffffff;
            border: 1px solid var(--border-card);
            padding: 8px 18px;
            border-radius: 9999px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
        }

        .back:hover {
            color: var(--gold-primary);
            border-color: #fde68a;
            background: #fffbeb;
            transform: translateX(-3px);
        }

        /* Kartu Form */
        .form-card {
            background: var(--surface-card);
            border: 1px solid var(--border-card);
            border-top: 5px solid #f59e0b;
            border-radius: 18px;
            padding: 38px 42px;
            box-shadow: var(--shadow-card);
        }

        /* Judul Halaman */
        h1 {
            font-family: 'Epilogue', sans-serif;
            font-size: 26px;
            font-weight: 800;
            letter-spacing: -0.02em;
            color: #18181b;
            margin-top: 0;
            margin-bottom: 26px;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        /* Notifikasi Pesan Sukses / Error */
        .pesan {
            padding: 14px 18px;
            border-radius: 10px;
            margin-bottom: 24px;
            font-size: 14px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
            line-height: 1.5;
        }

        .pesan.success {
            background: #f0fdf4;
            color: #166534;
            border: 1px solid #bbf7d0;
        }

        .pesan.success::before {
            content: "✓";
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 20px;
            height: 20px;
            background: #22c55e;
            color: #ffffff;
            border-radius: 50%;
            font-size: 11px;
            font-weight: 800;
            flex-shrink: 0;
        }

        .pesan.error {
            background: #fef2f2;
            color: #991b1b;
            border: 1px solid #fecaca;
        }

        .pesan.error::before {
            content: "!";
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 20px;
            height: 20px;
            background: #ef4444;
            color: #ffffff;
            border-radius: 50%;
            font-size: 11px;
            font-weight: 800;
            flex-shrink: 0;
        }

        /* Label Form */
        label {
            display: block;
            margin-top: 22px;
            margin-bottom: 7px;
            font-family: 'Epilogue', sans-serif;
            font-size: 13.5px;
            font-weight: 700;
            letter-spacing: 0.01em;
            color: var(--text-label);
        }

        /* Input Teks & Textarea */
        input[type="text"],
        textarea {
            width: 100%;
            padding: 13px 16px;
            margin-top: 2px;
            font-family: 'Plus Jakarta Sans', sans-serif;
            font-size: 14.5px;
            color: var(--text-main);
            background: #fcfcfd;
            border: 1.5px solid var(--input-border);
            border-radius: 10px;
            box-sizing: border-box;
            outline: none;
            transition: all 0.2s ease;
        }

        input[type="text"]::placeholder,
        textarea::placeholder {
            color: var(--text-placeholder);
        }

        input[type="text"]:focus,
        textarea:focus {
            background: #ffffff;
            border-color: var(--input-focus);
            box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.15);
        }

        textarea {
            min-height: 250px;
            line-height: 1.6;
            resize: vertical;
        }

        /* Tombol Update Resep */
        button {
            margin-top: 30px;
            padding: 14px 34px;
            background: var(--gold-gradient);
            color: #ffffff;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-family: 'Epilogue', sans-serif;
            font-size: 14px;
            font-weight: 800;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            box-shadow: var(--shadow-btn);
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        button:hover {
            filter: brightness(1.05);
            transform: translateY(-2px);
            box-shadow: var(--shadow-btn-hover);
        }

        button:active {
            transform: translateY(0);
        }
    </style>

</head>

<body>

<div class="container">

    <a href="detail.php?id=<?= $resep["id"] ?>" class="back">
        ← Kembali ke detail resep
    </a>

    <div class="form-card">

        <h1>✏️ Edit Resep</h1>

        <?php if ($pesan !== ""): ?>
            <div class="pesan <?= $pesan_tipe ?>">
                <?= htmlspecialchars($pesan) ?>
            </div>
        <?php endif; ?>

        <form method="POST">

            <label>Judul Resep *</label>
            <input
                type="text"
                name="title"
                value="<?= htmlspecialchars($resep["title"]) ?>"
                required
            >

            <label>Konten Resep *</label>
            <textarea name="content" required><?= htmlspecialchars($resep["content"]) ?></textarea>

            <label>Sumber</label>
            <input
                type="text"
                name="source"
                value="<?= htmlspecialchars($resep["source"]) ?>"
            >

            <button type="submit">
                💾 Update Resep
            </button>

        </form>

    </div>

</div>

</body>

</html>