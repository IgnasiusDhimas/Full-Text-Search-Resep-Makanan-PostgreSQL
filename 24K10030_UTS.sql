\c postgres
DROP DATABASE IF EXISTS dbresepfts;
CREATE DATABASE dbresepfts;
\c dbresepfts
\encoding UTF8

CREATE TABLE resep_mentah(
    id SERIAL PRIMARY KEY,
    content TEXT,
    title TEXT,
    source TEXT,
    split TEXT
);

--import dataset dari laptop 
\copy resep_mentah(content, title, source, split) FROM 'C:\Users\LENOVO\Downloads\resep_mentah.csv' WITH (FORMAT CSV,HEADER TRUE);

--cek datanya udah berhasil dibaca apa nggak
SELECT COUNT(*) AS jumlah_data_mentah
FROM resep_mentah;

--cek struktur data
\d resep_mentah

-- lihat 5 data pertama
SELECT *
FROM resep_mentah
LIMIT 5;

-- CLEANING DATA
--cek null di data
SELECT
    COUNT(*) FILTER (WHERE content IS NULL) AS content_null,
    COUNT(*) FILTER (WHERE title IS NULL) AS title_null,
    COUNT(*) FILTER (WHERE source IS NULL) AS source_null,
    COUNT(*) FILTER (WHERE split IS NULL) AS split_null
FROM resep_mentah;

--cek string kosong
SELECT
    COUNT(*) FILTER (WHERE TRIM(content) = '') AS content_kosong,
    COUNT(*) FILTER (WHERE TRIM(title) = '') AS title_kosong,
    COUNT(*) FILTER (WHERE TRIM(source) = '') AS source_kosong,
    COUNT(*) FILTER (WHERE TRIM(split) = '') AS split_kosong
FROM resep_mentah;

--cek duplikat
SELECT
    content,
    title,
    source,
    split,
    COUNT(*) AS jumlah
FROM resep_mentah
GROUP BY content, title, source, split
HAVING COUNT(*) > 1
ORDER BY jumlah DESC;

--cek data dengan title kosong
SELECT *
FROM resep_mentah
WHERE TRIM(title) = '';
-- dipertahankan karena rupanya datanya isinya masih

--cek jumlah kelompok baris duplikat 
SELECT
    COUNT(*) AS jumlah_baris_duplicate
FROM (
    SELECT
        content,
        title,
        source,
        split
    FROM resep_mentah
    GROUP BY content, title, source, split
    HAVING COUNT(*) > 1
) AS duplikat;

--cek baris duplikat yg harus dibuang
SELECT
    SUM(jumlah - 1) AS jumlah_baris_yang_dihapus
FROM (
    SELECT
        content,
        title,
        source,
        split,
        COUNT(*) AS jumlah
    FROM resep_mentah
    GROUP BY content, title, source, split
    HAVING COUNT(*) > 1
) AS duplikat;

-- Membuat tabel baru tanpa duplikat
CREATE TABLE resep_clean AS
SELECT DISTINCT
    content,
    title,
    source,
    split
FROM resep_mentah;

-- tambahkan ID untuk tabel data bersih
ALTER TABLE resep_clean 
ADD COLUMN id SERIAL PRIMARY KEY;

-- bandingkan jumlah data setelah cleaning & sblm
SELECT COUNT(*) AS jumlah_data_clean
FROM resep_clean;
SELECT COUNT(*) AS jumlah_data_mentah
FROM resep_mentah;

--cek konfigurasi bahasa indonesia di Postgres
SELECT cfgname
FROM pg_ts_config
WHERE cfgname = 'indonesian';

-- Tokenization (pecahkata) & Normalization (pecahan kata diubah menjadi kata yg punya makna)
-- cari resep yg judulnya ayam
SELECT title,
ts_debug('indonesian', content) AS hasil_tokenisasi
FROM resep_clean
WHERE title ILIKE '%ayam%'
LIMIT 1;

-- lihat seluruh token & lexemes
-- stemming = 'indonesian'
SELECT alias,
description,
token,
dictionary,
lexemes
FROM ts_debug(
    'indonesian',
    'Ayam bakar sederhana & Urap2 Sayur'
);
-- jadi tokenization itu memecah teks, kemudian diubah menjadi lexeme yaitu bentuk kkata yang disimpan oleh sistem FTS untuk proses pencarian
-- misal user nyari AYAM ya maka akan dinormalisasi jadi ayam gitu supaya pencarian lebih konsisten
/*
Stemming
di output nampak dictionary = indonesian_stem
artiya postgres memakai indonesian stemmer untuk kata2 tersebut
nantinya akan bisa diuji dengan kata yang mengalami perubahan bentuk
misal memasak, memasaklah, dimasak, masakan

tujuannya melihat apakah token yg udah normalisasi (lexeme)
benar2 bekerja

kemudian simbol space yang jadi blank 
berarti postgres mengenali simbol spasi tsb
menjadi bagian yg tidak menjadi lexeme pencarian

kemudian Urap2 terdiri atas huruf dan angka maka postgres mengkategorikan ini jadi
numword dan memakai dictionary simple untuk dinormalisasi jadi Lexeme urap2
*/

-- Uji Stop words bahasa indonesia
SELECT alias,
token,
dictionary,
lexemes
FROM ts_debug(
    'indonesian',
    'saya ingin membuat resep ayam yang sangat enak dan lezat'
);
/*
pada tes validasi FTS disini  
menunjukkan bahwa postgres tidak membuang
kata2 seperti saya, yang, dan sebagai stop word
kata2 yang dianggap stopword biasanya hasil lexemes nya kosong {}

sementara disini stemming word nya sudah bekerja membuat-> {buat}
*/

-- cek stop word yang ada di konfigurasi indonesian
SELECT cfgname,
dictname,
dictnamespace
FROM pg_ts_config_map
JOIN pg_ts_config
    ON pg_ts_config.oid = pg_ts_config_map.mapcfg
JOIN pg_ts_dict
    ON pg_ts_dict.oid = pg_ts_config_map.mapdict
WHERE cfgname = 'indonesian'
    AND dictname LIKE '%stop%';
/*
karena stop word di indonesian tidak ada dictionary nya
jadi disini saya akan membuat konfigurasi FTS custom yang menggabungkan stop-word filtering
dan indonesian stemming
jadi harus nambahin sendiri pakai notepad dengan nama file indonesian.stop 
isinya stop word dalam bahasa indonesia yaitu kata2 yg nggak punya arti penting
*/

-- buat dictionary stop word indonesia
CREATE TEXT SEARCH DICTIONARY indonesian_stop (
    TEMPLATE = snowball,
    Language = indonesian,
    StopWords = indonesian
);

-- cek apakah dictionary berhasil
SELECT dictname,
dicttemplate::regproc
FROM pg_ts_dict
WHERE dictname = 'indonesian_stop';

-- tes dulu apakah stemming dan stopword berjalan dgn baik
-- misal membuat di stem jadi buat, dan yang dianggap stopword sehingga dibuang
SELECT 
    ts_lexize(
        'indonesian_stop',
        'membuat'
    ) AS hasil_stemming,
    ts_lexize(
        'indonesian_stop',
        'yang'
    ) AS hasil_stopword;

-- buat konfigurasi indonesian_custom
CREATE TEXT SEARCH CONFIGURATION indonesian_custom
(COPY = indonesian);

-- ubah mapping kata
ALTER TEXT SEARCH CONFIGURATION indonesian_custom
ALTER MAPPING FOR asciiword, asciihword, hword_asciipart
WITH indonesian_stop, indonesian_stem;

-- tes konfigurasi apakah sudah bekerja dengan baik atau belum
SELECT alias,
token,
dictionary,
lexemes
FROM ts_debug(
    'indonesian_custom',
    'saya ingin membuat resep ayam yang sangat enak dan lezat'
);
/*
1. Tokenization = Postgres memecah kalimat saya ingin membuat resep ayam yang sangat enak dan lezat
menjadi token (pecahan kata) yaitu saya,ingin,membuat,resep,ayam,yang,sangat,enak,dan,lezat
kata spasi muncul sebagai blank sedangkan kata2 dikenali sebagai asciiword

2. Stop Words = tampak saya -> {}, yang -> {}, dan -> {}
artinya ketiga kata tersebut masuk daftar stop word dan tidak digunakan sebagai lexeme pencarian

3. Stemming/Lexeme = membuat -> {buat}
tampak bahwa postgres sudah mengubah kata kedalam bentuk dasar / stem sebelum 
digunakan untuk pencarian
*/

/*
tsvector

disini konfigurasi indonesian_custom akan diterapkan ke dataset resep_clean
maka kita tes satu resep dulu (satu baris data dulu)
*/

-- tes konfigurasi indonesian_custom untuk satu baris data resep 
SELECT 
    title,
    to_tsvector(
        'indonesian_custom',
        content
    ) AS document_vector
FROM resep_clean
LIMIT 1;
/*
to_tsvector('indonesian_custom', content) sudah mengubah 
isi resep menjadi tsvector
output nya 'ayam':1,7,12,17,97,100,121,129,144,150,185
berarti lexeme ayam muncul di posisi 1,7,12,17,97,100,121,129,144,150,185

sedangkan membuat -> buat sudah menunjukkan bahwa stemming yang dibuat sebelumnya 
berjalan dengan baik dan stop word seperti saya,yang,dan tidak muncul karena sudah dibuang
indonesian_stop
*/

/*
sekarang kita simpan tsvector ke tabel
supaya nggak perlu menjalankan to_tsvector ('indonesian_custom', content)
secara berulang2 
*/
-- simpan hasil nya dikolom khusus
ALTER TABLE resep_clean
ADD COLUMN search_vector TSVECTOR;
-- isi seluruh 16.122 resep
UPDATE resep_clean
SET search_vector =
    setweight(
        to_tsvector(
            'indonesian_custom',
            COALESCE(title, '')
        ),
        'A'
    )
    ||
    setweight(
        to_tsvector(
            'indonesian_custom',
            COALESCE(content, '')
        ),
        'B'
    );

--cek hasilnya
SELECT id,
title,
search_vector
FROM resep_clean
LIMIT 5;

--cek apakah ada vector yg kosong
SELECT COUNT(*) AS vector_kosong
FROM resep_clean
WHERE search_vector IS NULL;

-- Tes Fitur Full Text Search + Relevance Ranking bekerja
--tes apakah user bisa cari 10 resep dengan keyword ayam 
SELECT id,
title,
ts_rank(
    search_vector,
    plainto_tsquery('indonesian_custom', 'ayam')
) AS ranking
FROM resep_clean
WHERE search_vector @@ plainto_tsquery(
    'indonesian_custom',
    'ayam'
)
ORDER BY ranking DESC
LIMIT 10;
/*
jadi cara kerjanya
1. postgre mengubah 'ayam' jadi tsquery
2. kemudian mencocokannya dengan tsvector
3. kemudian mengambil resep yg punya lexeme ayam
4. ts_rank() menghitung tingkat relevansi
5. ORDER BY ranking DESC yaitu mengurutkan dari yg paling relevan
*/

/*
Sekarang nambahin highlighting karena pencarian bukan cuma 'Mie Ayam'
tapi isi resep bisa menunjukkan bagian yg cocok dengan query
postgres menyediakan ts_headline()
*/
SELECT id,
title,
ts_headline(
    'indonesian_custom',
    content,
    plainto_tsquery('indonesian_custom', 'ayam'),
    'StartSel=<b>, StopSel=</b>, MaxWords=30, MinWords=10'
) AS snippet,
ts_rank(
    search_vector,
    plainto_tsquery('indonesian_custom', 'ayam')
) AS ranking
FROM resep_clean
WHERE search_vector @@ plainto_tsquery(
    'indonesian_custom',
    'ayam'
)
ORDER BY ranking DESC
LIMIT 5;
/*
Ranking & Highlighting sudah berjalan
hasil sudah menunjukkan <b>AYAM</b>
dan misal 1/2 kg <b>ayam</b> (potong 6 bagian
artinya ts_headline() berhasil menemukan kata yang sesuai 
dengan query dan menandainya dengan <b>...</b>
*/

-- Analisis Performa Query
-- Menggunakan EXPLAIN ANALYZE
EXPLAIN ANALYZE
SELECT id,
title, 
ts_rank(
    search_vector,
    plainto_tsquery('indonesian_custom', 'ayam')
) AS ranking
FROM resep_clean
WHERE search_vector @@ plainto_tsquery(
    'indonesian_custom',
    'ayam'
)
ORDER BY ranking DESC
LIMIT 10;
/*
Hasil BEFORE INDEX
                                                        QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=5307.35..5307.38 rows=10 width=40) (actual time=15.917..15.918 rows=10 loops=1)
   ->  Sort  (cost=5307.35..5307.87 rows=208 width=40) (actual time=15.915..15.916 rows=10 loops=1)
         Sort Key: (ts_rank(search_vector, '''ayam'''::tsquery)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Seq Scan on resep_clean  (cost=0.00..5302.86 rows=208 width=40) (actual time=0.049..15.500 rows=4121 loops=1)
               Filter: (search_vector @@ '''ayam'''::tsquery)
               Rows Removed by Filter: 12001
 Planning Time: 0.070 ms
 Execution Time: 15.932 ms

Disini Postgres melakukan sequential scan yaitu memeriksa tabel
resep_clean secara berurutan untuk nyari resep yg mengandung 'ayam'
Dari 16.122 data:
- cocok dengan 'ayam' = 4.121 baris
- tidak cocok = 12.001 baris
- total = 16.122 baris data

waktu eksekusi before index= 15.932 ms
 */

-- GIN INDEX
/*
GIN (Generalized Inverted Index) adalah metode FTS 
yang mana indexnya menyimpan hubungan antara lexeme dengan dokumen/baris yang 
mengandung lexeme tersebut
*/

CREATE INDEX idx_resep_search_vector_gin
ON resep_clean
USING GIN (search_vector);

SELECT id,
title,
ts_rank(
    search_vector,
    plainto_tsquery('indonesian_custom', 'ayam')
) AS ranking
FROM resep_clean
WHERE search_vector @@ plainto_tsquery(
    'indonesian_custom', 'ayam'
)
ORDER BY ranking DESC
LIMIT 10;

-- cek performa dengan EXPLAIN ANALYZE
EXPLAIN ANALYZE
SELECT id,
title,
ts_rank(
    search_vector,
    plainto_tsquery('indonesian_custom', 'ayam')
) AS ranking
FROM resep_clean
WHERE search_vector @@ plainto_tsquery(
    'indonesian_custom', 'ayam'
)
ORDER BY ranking DESC
LIMIT 10;
/*
Hasil GIN INDEX
                                                                     QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=312.84..312.86 rows=10 width=40) (actual time=7.711..7.713 rows=10 loops=1)
   ->  Sort  (cost=312.84..313.04 rows=81 width=40) (actual time=7.709..7.710 rows=10 loops=1)
         Sort Key: (ts_rank(search_vector, '''ayam'''::tsquery)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Bitmap Heap Scan on resep_clean  (cost=17.51..311.09 rows=81 width=40) (actual time=1.042..7.197 rows=4121 loops=1)
               Recheck Cond: (search_vector @@ '''ayam'''::tsquery)
               Heap Blocks: exact=1761
               ->  Bitmap Index Scan on idx_resep_search_vector_gin  (cost=0.00..17.49 rows=81 width=0) (actual time=0.707..0.707 rows=4121 loops=1)
                     Index Cond: (search_vector @@ '''ayam'''::tsquery)
 Planning Time: 2.259 ms
 Execution Time: 7.763 ms
(11 rows)

Dari hasil output uji performa GIN index ini menunjukkan
bahwa performa nya lebih cepat dibanding sbelum indexing

1. Bitmap Index Scan on idx_resep_search_vector_gin 
artinya postgres benar2 menggunakan GIN bukan sequential scan lagi
perbandingannya saat sebelum index (sequential scan) = 15 ms
                                   sesudah GIN Index = 7 ms
penurunan waktu ini sekitar 50 persenan atau kira-kira 2x lebih lepat

2. Alasan kenapa masih ada Bitmap Heap Scan karena alur GIN yaitu
GIN Index -> Bitmap Index Scan -> Bitmap Heap Scan -> Sort berdasarkan ts_rank -> ambil 10 teratas
GIN digunakan untuk menemukan baris yang mengandung lexeme 'ayam'

3. rows=4121 artinya ada 4121 resep yang cocok dengan pencarian ayam
setelah itu postgres mengambil data resep tsb dari tabel dan menghitung
ts_rank(...) untuk menentukan mana yang paling relevan
makanya Sort Key: (ts_rank(search_vector, '''ayam'''::tsquery)) DESC masih ada
jadi GIN mempercepat pencarian tapi nggak otomatis ngilangin proses ranking dan sorting

4. estimasi planner rows=81 awalnya memperkirakan hanya 81 baris yang cocok
tapi kenyataannya ada 4121 baris bukan berarti index GIN gagal tapi hanya menunjukkan
bahwa estimasi statistik planner yang kurang akurat untuk query ini
*/

-- GIST INDEX
/*
Hapus GIN dulu supaya ketika menguji GiST postgres tidak memilih GIN
*/
DROP INDEX idx_resep_search_vector_gin;
-- lalu buat GiST INDEX nya
CREATE INDEX idx_resep_search_vector_gist
ON resep_clean
USING GIST (search_vector);

-- jalankan query lagi
SELECT id,
title,
ts_rank(
    search_vector,
    plainto_tsquery('indonesian_custom', 'ayam')
) AS ranking
FROM resep_clean
WHERE search_vector @@ plainto_tsquery(
    'indonesian_custom', 'ayam'
)
ORDER BY ranking DESC
LIMIT 10;

--uji performa GiST Index menggunakan EXPLAIN ANALYZE
EXPLAIN ANALYZE
SELECT id,
title,
ts_rank(
    search_vector,
    plainto_tsquery('indonesian_custom', 'ayam')
) AS ranking
FROM resep_clean
WHERE search_vector @@ plainto_tsquery(
    'indonesian_custom', 'ayam'
)
ORDER BY ranking DESC
LIMIT 10;
/*
Hasil GiST INDEX
                                                                      QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=316.24..316.26 rows=10 width=40) (actual time=9.720..9.722 rows=10 loops=1)
   ->  Sort  (cost=316.24..316.44 rows=81 width=40) (actual time=9.718..9.719 rows=10 loops=1)
         Sort Key: (ts_rank(search_vector, '''ayam'''::tsquery)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Bitmap Heap Scan on resep_clean  (cost=20.90..314.49 rows=81 width=40) (actual time=1.935..9.309 rows=4121 loops=1)
               Recheck Cond: (search_vector @@ '''ayam'''::tsquery)
               Rows Removed by Index Recheck: 37
               Heap Blocks: exact=1782
               ->  Bitmap Index Scan on idx_resep_search_vector_gist  (cost=0.00..20.88 rows=81 width=0) (actual time=1.738..1.738 rows=4158 loops=1)
                     Index Cond: (search_vector @@ '''ayam'''::tsquery)
 Planning Time: 0.091 ms
 Execution Time: 9.761 ms
(12 rows)

Dari hasil output uji performa GiST INDEX ini menunjukkan bahwa 
performanya lebih cepat dibanding tanpa indexing namun masih sedikit lebih lambat 
daripada GIN Index dari sisi execution timenya

GIN = 15 ms -> 7 ms = turun sekitar 50%
GiST = 15 ms -> 9 ms = turun sekitar 35%
GIN lebih cepat 20% an dibanding GiST pada query ini
jadi untuk dataset resep dan query rank ayam, GIN memberikan performa tercepat

Alasan GiST punya Rows Removed by Index Recheck 
adalah GiST menghasilkan candidate matches dari index yang kemudian
perlu diperiksa kembali oleh postgres pada tabel 
makanya 
Bitmap Index Scan
actual rows=4158

kemudian setelah pengecekan
Bitmap Heap Scan
actual rows=4121
Rows Removed by Index Recheck: 77

jadi dari 4158 kandidat dari index -> 37 tidak lolos cek sehingga 4121 resep cocok
beda dengan GIN yang 
Bitmap Index Scan 
actual_rows=4121
tanpa menunjukkan Rows Removed by Index Recheck

Jadi dari dua index ini GIN INDEX dan GiST INDEX dapat diketahui
bahwa perbedaan cara kerja mereka mempengaruhi kecepatan eksekusi yang dihasilkan
dimana kalau GIN menggunakan Bitmap Index Scan dan Bitmap Heap Scan
untuk menemukan dokumen yang sesuai.
Sedangkan GiST juga menggunakan Bitmap Index Scan dan Bitmap Heap Scam, 
tetapi ada langkah tambahan yaitu proses index recheck dan menghasilkan 37 baris yang harus dibuang
setelah pengecekan. Dengan hasil itu GIN adalah metode indexing yang paling sesuai
untuk implementasi Full Text Search pada sistem pencarian resep karena memberikan performa
pencarian yang lebih baik pada dataset dan query pengujian ini
*/

/*
INDEX FINAL
Implementasi Final Index
memakai GIN INDEX
*/
-- Hapus dulu index GiST supaya tidak tumpang tindih
DROP INDEX idx_resep_search_vector_gist;

CREATE INDEX idx_resep_search_vector_gin
ON resep_clean
USING GIN (search_vector);

EXPLAIN ANALYZE
SELECT id,
title,
ts_rank(
    search_vector,
    plainto_tsquery('indonesian_custom', 'ayam')
) AS ranking
FROM resep_clean
WHERE search_vector @@ plainto_tsquery(
    'indonesian_custom', 'ayam'
)
ORDER BY ranking DESC
LIMIT 10;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'resep_clean';

-- Advanced Search: AND
/*
misal pencarian dengan keyword dua kata yg sama2 ada misal
'ayam goreng'
*/
SELECT id,
title,
ts_rank(
    search_vector,
    to_tsquery('indonesian_custom', 'ayam & goreng')
) AS ranking
FROM resep_clean
WHERE search_vector @@
    to_tsquery('indonesian_custom', 'ayam & goreng')
ORDER BY ranking DESC
LIMIT 10;
/*
disini output dengan ranking tertinggi adalah 'SERBA AYAM'
walaupun judulnya tidak mengandung kata goreng, karena disini 
tidak hanya melihat title nya saja melainkan untuk kata dalam content
juga memberikan skor terhadap ranking ini
*/

-- Advanced Search: OR
/*
kalau AND data harus mengandung keduanya yaitu 'ayam' dan 'goreng'
kalau OR cukup mengandung salah satu dari 'ayam' atau 'goreng'
*/
SELECT id,
title,
ts_rank(
    search_vector,
    to_tsquery('indonesian_custom', 'ayam | goreng')
) AS ranking
FROM resep_clean
WHERE search_vector @@
    to_tsquery('indonesian_custom', 'ayam | goreng')
ORDER BY ranking DESC
LIMIT 10;
/*
disini outputnya sesuai banyak yang hanya ayam muncul sebagai ranking atas
dan disini ada juga yang mengandung keduanya, dan menariknya ada resep
dengan judul RESEP MEMBUAT COMBRO ENAK padahal dalam judul tidak ada ayam atau goreng
jadi bobot pencariannya juga dipengaruhi oleh content itu sendiri
*/

-- Advanced Search: Prefix Search
/*
misal user ngetik gor maka dengan prefix search kita bisa mencari lexeme yang
diawali 'gor'
misal goreng, gorengan
*/
SELECT id,
title,
ts_rank(
    search_vector,
    to_tsquery('indonesian_custom','gor:*')
) AS ranking
FROM resep_clean
WHERE search_vector @@
    to_tsquery('indonesian_custom', 'gor:*')
ORDER BY ranking DESC
LIMIT 10;
/*
walaupun beberapa judul tidak terlihat mengandung gor pada output
namun perlu dicatat kembali bahwa pencarian dilakukan pada seluruh content, bukan hanya title
jadi lexeme yang cocok bisa berada di bagian bahan atau cara memasak
*/

-- Buat Query Utama Sistem
SELECT id,
title,
ts_headline(
    'indonesian_custom',
    content,
    plainto_tsquery(
        'indonesian_custom',
        'ayam goreng'
    ),
    'StartSel=<b>, StopSel=</b>, MaxWords=30, MinWords=10'
) AS snippet,
ts_rank(
    search_vector,
    plainto_tsquery(
        'indonesian_custom',
        'ayam goreng'
    )
) AS ranking
FROM resep_clean
WHERE search_vector @@
    plainto_tsquery(
        'indonesian_custom',
        'ayam goreng'
    )
ORDER BY ranking DESC
LIMIT 10;

-- Fungsi Untuk Backend pencarian
CREATE OR REPLACE FUNCTION cari_resep(keyword TEXT)
RETURNS TABLE (
    id INTEGER,
    title TEXT,
    snippet TEXT,
    ranking REAL
)
LANGUAGE SQL
AS $$
    SELECT
        r.id,
        r.title,

        ts_headline(
            'indonesian_custom',
            r.content,
            plainto_tsquery(
                'indonesian_custom',
                keyword
            ),
            'StartSel=<b>, StopSel=</b>, MaxWords=30, MinWords=10'
        ) AS snippet,
        
        ts_rank(
            r.search_vector,
            plainto_tsquery(
                'indonesian_custom',
                keyword
            )
        ) AS ranking
    FROM resep_clean r
    WHERE r.search_vector @@
        plainto_tsquery(
            'indonesian_custom',
            keyword
        )
    ORDER BY ranking DESC
    LIMIT 20;
$$;

-- Tes Fungsi
-- cari ayam goreng
SELECT *
FROM cari_resep('ayam goreng');

--cari mie ayam
SELECT *
FROM cari_resep('mie ayam');

--cari sambal
SELECT *
FROM cari_resep('sambal');

-- Opsional (Tambahan)
/*
TRIGGER untuk otomatis menghitung ulang search_vector setiap kali
ada INSERT atau UPDATE pada tabel resep_clean.

*/

-- Buat Fungsi Trigger
CREATE OR REPLACE FUNCTION update_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector :=
        setweight(
            to_tsvector('indonesian_custom', COALESCE(NEW.title, '')),
            'A'
        )
        ||
        setweight(
            to_tsvector('indonesian_custom', COALESCE(NEW.content, '')),
            'B'
        );
    RETURN NEW;
END;
$$;
/*
NEW adalah baris data yang akan di insert atau di update
NEW.search_vector := .. mengisi kolom search_vector secara otomatis
RETURN NEW mengembalikan baris yang sudah dimodifikasi
*/

-- Membuat Trigger nya
CREATE TRIGGER trg_update_search_vector
BEFORE INSERT OR UPDATE ON resep_clean
FOR EACH ROW
EXECUTE FUNCTION update_search_vector();
/*
BEFORE INSERT OR UPDATE artinya trigger dijalankan sebelum data disimpan
FOR EACH ROW artinya dijalankan untuk tiap baris yang terpengaruh
EXECUTE FUNCTION update_search_vector() adalah pemanggil fungsi trigger yang sebelumnya dibuat
*/


-- Uji Trigger 
/*
Trigger ini diuji dengan mengINSERT data kedalam tabel resep_clean
gunanya supaya kita bisa lihat apakah search_vector otomatis berisi lexeme
dari title dan content tanpa perlu update manual
*/

--Uji Insert
INSERT INTO resep_clean (title, content, source, split)
VALUES (
    'Ayam Bakar Madu Spesial',
    'Ayam bakar dengan madu dan bumbu rempah. Bahan: ayam, madu, kecap,
    bawang putih',
    'Manual Input',
    'train'
);

-- cek apakah search_vector otomatis terisi
SELECT id, title, search_vector
FROM resep_clean
WHERE title = 'Ayam Bakar Madu Spesial';
/*
Outputnya : id   |          title          |                                                             search_vector                       
-------+-------------------------+----------------------------------------------------------------------------------------------------------------------------------------
 16123 | Ayam Bakar Madu Spesial | 'ayam':1A,5B,13B 'bahan':12B 'bakar':2A,6B 'bawang':16B 'bumbu':10B 'kecap':15B 'madu':3A,8B,14B 'putih':17B 'rempah':11B 'spesial':4A
*/

-- Uji Update
UPDATE resep_clean
SET title = 'Ayam Bakar Madu Super Spesial'
WHERE title = 'Ayam Bakar Madu Spesial';

-- Cek apakah search_vector ikut berubah
SELECT id, title, search_vector
FROM resep_clean
WHERE title = 'Ayam Bakar Madu Super Spesial';
/*
  id   |             title             |                                                                   search_vector           
-------+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------
 16123 | Ayam Bakar Madu Super Spesial | 'ayam':1A,6B,14B 'bahan':13B 'bakar':2A,7B 'bawang':17B 'bumbu':11B 'kecap':16B 'madu':3A,9B,15B 'putih':18B 'rempah':12B 'spesial':5A 'super':4A
 */

-- Perbandingan tanpa trigger & dengan trigger
-- Matikan trigger sementara
ALTER TABLE resep_clean DISABLE TRIGGER trg_update_search_vector;

INSERT INTO resep_clean (title, content, source, split)
VALUES (
    'Nasi Goreng Kampung Dhimas',
    'Nasi goreng dengan telur dan kecap manis.',
    'Manual Test A',
    'train'
);

SELECT id, title, search_vector
FROM resep_clean
WHERE title = 'Nasi Goreng Kampung Dhimas';
/*
Hasilnya
 id   |        title        | search_vector
-------+---------------------+---------------
 16125 | Nasi Goreng Kampung |
search_vector = NULL, artinya resep baru ini tidak akan muncul
 di pencarian FTS walaupun judulnya mengandung "nasi goreng".
*/
SELECT * FROM cari_resep('nasi goreng kampung dhimas');
-- Hasil: nggak ada (kosong) 

-- Nyalakan kembali trigger
ALTER TABLE resep_clean ENABLE TRIGGER trg_update_search_vector;

INSERT INTO resep_clean (title, content, source, split)
VALUES (
    'Mie Goreng Jawa Dhimas',
    'Mie goreng dengan bumbu khas Jawa.',
    'Manual Test B',
    'train'
);

SELECT id, title, search_vector
FROM resep_clean
WHERE title = 'Mie Goreng Jawa Dhimas';
/*
Hasilnya
  id   |      title      |                        search_vector
-------+-----------------+--------------------------------------------------------------
 16126 | Mie Goreng Jawa | 'bumbu':7B 'goreng':2A,5B 'jawa':3A,9B 'khas':8B 'mie':1A,4B
search_vector otomatis terisi, dan resep baru langsung bisa ditemukan:
*/
-- bisa lnangsung nemu
SELECT * FROM cari_resep('mie goreng jawa dhimas');
-- Hasil: 1 baris (resep baru langsung ketemu!)