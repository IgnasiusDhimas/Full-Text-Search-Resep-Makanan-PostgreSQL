<?php

require "koneksi.php";

if (!isset($_GET["id"]) || !is_numeric($_GET["id"])) {
    die("ID resep tidak valid.");
}

$id = (int) $_GET["id"];

$query = "SELECT id, title, content, source
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

    <title>
        <?= htmlspecialchars($resep["title"]) ?>
    </title>

    <style>
        /* Import Google Fonts (MasterChef Elegance: Epilogue & Plus Jakarta Sans) */
        @import url('https://fonts.googleapis.com/css2?family=Epilogue:ital,wght@0,600;0,700;0,800;0,900;1,700&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap');

        :root {
            --bg-canvas: #f8f9fc;
            --surface-card: #ffffff;
            --text-main: #18181b;
            --text-body: #334155;
            --gold-primary: #d97706;
            --gold-gradient: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            --gold-subtle: #fef3c7;
            --border-card: #e2e8f0;
            --shadow-card: 0 4px 20px -2px rgba(15, 23, 42, 0.05), 0 2px 6px -1px rgba(15, 23, 42, 0.03);
            --shadow-hover: 0 10px 24px -2px rgba(217, 119, 6, 0.15);
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
            max-width: 900px;
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

        /* Kartu Tampilan Resep */
        .recipe {
            background: var(--surface-card);
            border: 1px solid var(--border-card);
            border-top: 5px solid #f59e0b;
            border-radius: 18px;
            padding: 40px 46px;
            box-shadow: var(--shadow-card);
        }

        /* Header Resep & Tombol */
        .recipe-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            gap: 20px;
            padding-bottom: 24px;
            border-bottom: 1px solid var(--border-card);
        }

        /* Judul Resep */
        h1 {
            font-family: 'Epilogue', sans-serif;
            font-size: 32px;
            font-weight: 800;
            letter-spacing: -0.025em;
            color: #18181b;
            margin-top: 0;
            line-height: 1.25;
            flex: 1;
        }

        .btn-group {
            display: flex;
            gap: 10px;
            flex-shrink: 0;
        }

        /* Tombol Edit */
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 9px 20px;
            border-radius: 10px;
            text-decoration: none;
            font-family: 'Plus Jakarta Sans', sans-serif;
            font-size: 13.5px;
            font-weight: 700;
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
        }

        .btn-edit {
            background: #ffffff;
            border: 1.5px solid #fde68a;
            color: #b45309;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
        }

        .btn-edit:hover {
            background: #fef3c7;
            color: #78350f;
            border-color: #f59e0b;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(245, 158, 11, 0.2);
        }

        /* Tampilan Konten (Bahan & Langkah Masak) */
        .content {
            white-space: pre-wrap;
            line-height: 1.85;
            font-size: 15.5px;
            color: var(--text-body);
            margin-top: 30px;
            letter-spacing: -0.005em;
            background: #fafafc;
            border: 1px solid #f1f5f9;
            padding: 30px 34px;
            border-radius: 14px;
        }
    </style>

</head>

<body>

<div class="container">

    <a href="index.php" class="back">
        ← Kembali ke pencarian
    </a>

    <div class="recipe">

        <div class="recipe-header">

            <h1>
                <?= htmlspecialchars($resep["title"]) ?>
            </h1>

            <div class="btn-group">

                <a
                    href="edit.php?id=<?= $resep["id"] ?>"
                    class="btn btn-edit"
                >
                    ✏️ Edit
                </a>

            </div>

        </div>

        <div class="content">
            <?= htmlspecialchars($resep["content"]) ?>
        </div>

    </div>

</div>

</body>

</html>