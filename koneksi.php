<?php

$host = "localhost";
$port = "5432";
$dbname = "dbresepfts";
$user = "postgres";
$password = "dhimas";

$koneksi = pg_connect(
    "host=$host port=$port dbname=$dbname user=$user password=$password"
);

if (!$koneksi) {
    die("Koneksi ke PostgreSQL gagal.");
}
?>