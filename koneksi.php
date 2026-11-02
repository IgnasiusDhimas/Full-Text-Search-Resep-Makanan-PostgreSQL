<?php

// Cek apakah ada DATABASE_URL (dari Railway)
$dbUrl = getenv('DATABASE_URL');

if ($dbUrl) {
    // === MODE RAILWAY ===
    $db = parse_url($dbUrl);
    $host = $db['host'];
    $port = $db['port'] ?? 5432;
    $user = $db['user'];
    $pass = $db['pass'];
    $dbname = ltrim($db['path'], '/');
    
    // Railway butuh SSL? Coba tanpa dulu, kalau gagal baru pakai sslmode=require
    $koneksi = pg_connect(
        "host=$host port=$port dbname=$dbname user=$user password=$pass"
    );
} else {
    // === MODE LOKAL (LARAGON) ===
    $host = "localhost";
    $port = "5432";
    $dbname = "dbresepfts";
    $user = "postgres";
    $password = "dhimas";

    $koneksi = pg_connect(
        "host=$host port=$port dbname=$dbname user=$user password=$password"
    );
}

if (!$koneksi) {
    die("Koneksi ke PostgreSQL gagal.");
}
?>