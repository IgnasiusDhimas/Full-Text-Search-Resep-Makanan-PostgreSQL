<?php

require "koneksi.php";

$keyword = "";
$hasil = [];

if (isset($_GET["keyword"])) {
    $keyword = trim($_GET["keyword"]);
    if ($keyword !== "") {
        $query = "SELECT * FROM cari_resep($1)";
        $result = pg_query_params($koneksi, $query, [$keyword]);
        if ($result) {
            while ($row = pg_fetch_assoc($result)) {
                $hasil[] = $row;
            }
        }
    }
}

?>

<!DOCTYPE html>
<html lang="id">

<head>

    <meta charset="UTF-8">

    <title>Recipe Search System</title>

    <style>
        /* Import Google Fonts (MasterChef Elegance: Epilogue & Plus Jakarta Sans) */
        @import url('https://fonts.googleapis.com/css2?family=Epilogue:ital,wght@0,600;0,700;0,800;0,900;1,700&family=JetBrains+Mono:wght@600;700&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap');

        :root {
            --bg-canvas: #f8f9fc;
            --surface-card: #ffffff;
            --text-main: #111827;
            --text-muted: #52525b;
            --gold-primary: #d97706;
            --gold-gradient: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            --red-gradient: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
            --border-color: #e2e8f0;
            --shadow-card: 0 4px 20px -2px rgba(15, 23, 42, 0.05), 0 2px 6px -1px rgba(15, 23, 42, 0.03);
            --shadow-hover: 0 14px 30px -4px rgba(217, 119, 6, 0.14), 0 4px 12px -2px rgba(15, 23, 42, 0.04);
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
                radial-gradient(at 0% 0%, rgba(245, 158, 11, 0.05) 0px, transparent 45%),
                radial-gradient(at 100% 100%, rgba(220, 38, 38, 0.04) 0px, transparent 45%);
            color: var(--text-main);
            margin: 0;
            padding: 48px 20px 80px;
            -webkit-font-smoothing: antialiased;
            min-height: 100vh;
        }

        .container {
            max-width: 900px;
            margin: auto;
        }

        /* Top Bar & Tombol Tambah Resep */
        .top-bar {
            display: flex;
            justify-content: flex-end;
            margin-bottom: 24px;
        }

        .btn-tambah {
            background: var(--gold-gradient);
            color: #ffffff;
            padding: 10px 22px;
            border-radius: 10px;
            text-decoration: none;
            font-family: 'Epilogue', sans-serif;
            font-size: 13px;
            font-weight: 800;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            box-shadow: 0 4px 14px rgba(217, 119, 6, 0.28);
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .btn-tambah:hover {
            background: var(--gold-gradient);
            filter: brightness(1.05);
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(217, 119, 6, 0.36);
        }

        /* Judul Utama */
        h1 {
            font-family: 'Epilogue', sans-serif;
            font-size: 38px;
            font-weight: 900;
            letter-spacing: -0.03em;
            color: #18181b;
            text-align: center;
            margin-bottom: 30px;
            line-height: 1.2;
        }

        /* Form Pencarian */
        .search-box {
            display: flex;
            gap: 12px;
            background: #ffffff;
            padding: 8px;
            border-radius: 16px;
            box-shadow: 0 8px 30px rgba(15, 23, 42, 0.06), 0 1px 3px rgba(15, 23, 42, 0.03);
            border: 1px solid var(--border-color);
            margin: 25px 0 32px;
            transition: border-color 0.2s, box-shadow 0.2s;
        }

        .search-box:focus-within {
            border-color: #f59e0b;
            box-shadow: 0 8px 30px rgba(245, 158, 11, 0.15), 0 0 0 3px rgba(245, 158, 11, 0.12);
        }

        .search-box input {
            flex: 1;
            padding: 14px 20px;
            font-family: 'Plus Jakarta Sans', sans-serif;
            font-size: 16px;
            color: var(--text-main);
            background: transparent;
            border: none;
            outline: none;
        }

        .search-box input::placeholder {
            color: #94a3b8;
        }

        .search-box button {
            padding: 13px 32px;
            cursor: pointer;
            font-family: 'Epilogue', sans-serif;
            font-size: 14px;
            font-weight: 800;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            background: var(--red-gradient);
            color: #ffffff;
            border: none;
            border-radius: 10px;
            box-shadow: 0 4px 14px rgba(220, 38, 38, 0.25);
            transition: all 0.2s ease;
        }

        .search-box button:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 18px rgba(220, 38, 38, 0.35);
            filter: brightness(1.04);
        }

        /* Header Teks Hasil Pencarian */
        h3 {
            font-size: 15px;
            font-weight: 600;
            color: #475569;
            margin-bottom: 20px;
            padding-left: 2px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        h3::before {
            content: "";
            display: inline-block;
            width: 8px;
            height: 8px;
            background: #f59e0b;
            border-radius: 50%;
            box-shadow: 0 0 0 4px rgba(245, 158, 11, 0.2);
        }

        /* Kartu Hasil Resep */
        .result-wrapper {
            position: relative;
            margin-bottom: 18px;
        }

        .result {
            display: block;
            background: var(--surface-card);
            border: 1px solid var(--border-color);
            border-left: 5px solid #f59e0b;
            border-radius: 14px;
            padding: 24px 28px;
            text-decoration: none;
            color: inherit;
            box-shadow: var(--shadow-card);
            transition: all 0.24s cubic-bezier(0.16, 1, 0.3, 1);
        }

        .result:hover {
            transform: translateY(-3px);
            border-color: #cbd5e1;
            border-left-color: #d97706;
            box-shadow: var(--shadow-hover);
        }

        .result h2 {
            font-family: 'Epilogue', sans-serif;
            font-size: 21px;
            font-weight: 700;
            color: #0f172a;
            margin-top: 0;
            margin-bottom: 12px;
            padding-right: 90px; /* Ruang agar tidak tertabrak tombol Edit */
            line-height: 1.35;
            transition: color 0.2s;
        }

        .result:hover h2 {
            color: #d97706;
        }

        .snippet {
            font-size: 14.5px;
            line-height: 1.65;
            color: var(--text-muted);
            margin-bottom: 16px;
        }

        /* Penyorotan kata kunci snippet tag <b> */
        .snippet b {
            background: #fef3c7;
            color: #92400e;
            padding: 2px 7px;
            border-radius: 6px;
            font-weight: 600;
            border: 1px solid #fde68a;
        }

        /* Ranking / Relevance Score */
        .ranking {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            padding: 5px 12px;
            border-radius: 8px;
            font-family: 'JetBrains Mono', monospace;
            font-size: 12px;
            font-weight: 700;
            color: #b45309;
            letter-spacing: 0.02em;
            margin-top: 6px;
        }

        .ranking::before {
            content: "★";
            color: #f59e0b;
            font-size: 13px;
        }

        /* Tombol Edit di pojok kanan kartu */
        .btn-edit {
            position: absolute;
            top: 22px;
            right: 24px;
            background: #ffffff;
            border: 1px solid #fde68a;
            color: #b45309;
            padding: 6px 14px;
            border-radius: 8px;
            text-decoration: none;
            font-family: 'Plus Jakarta Sans', sans-serif;
            font-size: 12.5px;
            font-weight: 700;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
            z-index: 10;
            transition: all 0.2s ease;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .btn-edit:hover {
            background: #fef3c7;
            color: #78350f;
            border-color: #f59e0b;
            transform: scale(1.04);
        }

        /* Empty State */
        .empty {
            text-align: center;
            padding: 48px 24px;
            background: #ffffff;
            border-radius: 16px;
            border: 1px dashed #cbd5e1;
            color: #64748b;
            font-size: 15px;
            font-weight: 500;
            margin-top: 10px;
        }
    </style>

</head>

<body>

<div class="container">

    <h1>🍳 Recipe Search System</h1>

    <div class="top-bar">
        <a href="tambah.php" class="btn-tambah">
            ➕ Tambah Resep
        </a>
    </div>

    <form method="GET" class="search-box">

        <input
            type="text"
            name="keyword"
            placeholder="Cari resep..."
            value="<?= htmlspecialchars($keyword) ?>"
        >

        <button type="submit">
            Cari
        </button>

    </form>

    <?php if ($keyword !== ""): ?>

        <h3>
            Hasil pencarian untuk:
            "<?= htmlspecialchars($keyword) ?>"
        </h3>

        <?php if (count($hasil) > 0): ?>

            <?php foreach ($hasil as $resep): ?>

                <div class="result-wrapper">

                    <a
                        href="edit.php?id=<?= $resep["id"] ?>"
                        class="btn-edit"
                        onclick="event.stopPropagation();"
                    >
                        ✏️ Edit
                    </a>

                    <a
                        href="detail.php?id=<?= $resep["id"] ?>"
                        class="result"
                    >

                        <h2>
                            <?= htmlspecialchars($resep["title"]) ?>
                        </h2>

                        <div class="snippet">
                            <?= $resep["snippet"] ?>
                        </div>

                        <div class="ranking">
                            Relevance Score:
                            <?= number_format((float)$resep["ranking"], 6) ?>
                        </div>

                    </a>

                </div>

            <?php endforeach; ?>

        <?php else: ?>

            <div class="empty">
                Tidak ada resep yang ditemukan.
            </div>

        <?php endif; ?>

    <?php endif; ?>

</div>

</body>

</html>