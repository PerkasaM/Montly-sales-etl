# ETL Sell-In Bulanan

Script ETL otomatis untuk proses data **Sell-In bulanan** dari SAP menjadi file raw data final yang siap digunakan untuk reporting dan analisis.

---

# Overview

Flow utama script:

```mermaid
flowchart TD

    A[Load Master Data] --> B[Load MTD YTD]
    
    B --> C[Cleaning Data]
    
    C --> C1[Normalize Customer Code]
    C --> C2[Cleaning SDO]
    C --> C3[Parse SAP Date]
    C --> C4[Cleaning Region]

    C --> D[Update MD_TOKO]
    C --> E[Update MD_SDO]

    D --> F[Process New Month]
    E --> F

    F --> F1[Build raw_new]
    F --> F2[Join MD_TOKO]
    F --> F3[Join MD_SDO]
    F --> F4[Join MD_SKU]
    F --> F5[Join SPV ASM RSM]
    F --> F6[Calculate REAL QTY]
    F --> F7[Filter Total Net != 0]

    F7 --> G[Save raw_new]

    G --> H[Load raw_old]

    H --> I[Update raw_old]
    
    I --> I1[Update Desc Brand]
    I --> I2[Update SDO]
    I --> I3[Remove Total Net = 0]

    I --> J[Merge raw_old + raw_new]

    J --> K[Update Final Data]

    K --> K1[Update Address]
    K --> K2[Update Customer Name MT]
    K --> K3[Update SPV ASM RSM]
    K --> K4[Cleaning Region Reg2]
    K --> K5[Update Desc Pricelist]
    K --> K6[Uppercase Desc SUBPG]

    K --> L[Export Final Excel]

    L --> M[raw_data_CXXXX_rev1.xlsx]
```

---

# Fitur Utama

- Cleaning data customer & region
- Normalisasi customer code
- Update otomatis:
  - MD_TOKO
  - MD_SDO
  - SDO Update
  - SPV / ASM / RSM
  - Desc product dari pricelist
- Merge data raw lama + raw baru
- Handle duplicate DR Number
- Kalkulasi REAL QTY
- Update alamat Google Maps otomatis
- Standardisasi region & reg2
- Export otomatis ke Excel final

---

# Struktur File

## File Python

```bash
sellin_etl.py
```

Script utama ETL.

## File BAT

```bash
run_sellin_etl.bat
```

Digunakan untuk menjalankan ETL tanpa buka terminal manual.

---

# Requirement

Install dependency berikut:

```bash
pip install pandas openpyxl xlrd
```

---

# Struktur Master Data

Script menggunakan beberapa file master:

| File | Fungsi |
|---|---|
| Raw Data Sell IN | Data histori utama |
| TEMPLATE_SELL_IN_SAP | MD_TOKO & MD_SDO |
| SAP Customer Master | Data customer SAP |
| MTD YTD REPORT | Data transaksi bulan berjalan |
| SDO UPDATE | Update SDO terbaru |
| SKU Master | Mapping SKU |
| SPV RSM | Mapping SPV/ASM/RSM |
| MS DC | Update desc/brand |
| Master Data Yee | Mapping PG |
| Group | Mapping customer group |
| SWM Grouping | Mapping SUBPG1 |
| Pricelist | Update description terbaru |

---

# Cara Menjalankan

## 1. Update CONFIG

Di bagian atas script:

```python
PATH_RAW_OLD    = r"..."
PATH_TEMPLATE   = r"..."
PATH_SAP        = r"..."
PATH_MTD_YTD    = r"..."
```

Sesuaikan seluruh path file.

---

## 2. Update Cycle Bulanan

```python
CYCLE       = "C05"
DUMMY_CYCLE = "C0526"
MTD_SHEET   = "SAP CUMULATIVE"
```

Contoh:

| Bulan | CYCLE | DUMMY_CYCLE |
|---|---|---|
| Mei 2026 | C05 | C0526 |
| Juni 2026 | C06 | C0626 |

---

## 3. Jalankan Script

### Via terminal

```bash
python sellin_etl.py
```

### Atau via BAT

Double click:

```bash
run_sellin_etl.bat
```

---

# Output

Script menghasilkan 2 file:

| Output | Fungsi |
|---|---|
| raw_new_CXXXX.xlsx | Data bulan baru |
| raw_data_CXXXX_rev1.xlsx | Data final gabungan |

Contoh:

```bash
raw_new_C0526.xlsx
raw_data_C0526_rev1.xlsx
```

---

# Penjelasan Proses ETL

## 1. Load Master Data

Function:

```python
load_master_data()
```

Load seluruh master data yang dibutuhkan.

---

## 2. Update MD_TOKO

Function:

```python
update_md_toko()
```

Menambahkan customer baru otomatis dari SAP & MTD.

### Flow Update MD_TOKO & MD_SDO

```mermaid
flowchart TD

    A[Customer Baru dari MTD] --> B{Ada di MD_TOKO?}

    B -->|No| C[Ambil Data dari SAP]
    B -->|Yes| D[Skip]

    C --> E[Mapping Region SDO Type]
    E --> F[Tambah ke MD_TOKO]

    A --> G{Ada di MD_SDO?}

    G -->|No| H[Ambil SDO Update]
    G -->|Yes| I[Skip]

    H --> J[Tambah ke MD_SDO]
```

---

## 3. Update MD_SDO

Function:

```python
update_md_sdo()
```

Update SDO customer:
- dari file konfirmasi
- fallback dari MTD

---

## 4. Process New Month

Function:

```python
process_new_month()
```

Tahapan:
- build raw_new
- merge seluruh master
- mapping SKU
- hitung REAL QTY
- generate cycle
- filtering Total Net = 0

---

## 5. Merge Raw Lama + Baru

Function:

```python
update_master_data()
```

Logic:
- DR Number lama yang direvisi dihapus
- raw_new replace raw_old

### Flow Merge DR Number

```mermaid
flowchart TD

    A[raw_old] --> B[Check DR Number]
    C[raw_new] --> B

    B --> D{DR Number Sama?}

    D -->|Yes| E[Hapus dari raw_old]
    D -->|No| F[Keep Data Lama]

    E --> G[Gabungkan raw_new]
    F --> G

    G --> H[df_final]
```

---

## 6. Update Final Data

Termasuk:
- update alamat
- update desc
- update region
- update SPV/ASM/RSM
- update customer modern trade

---

# Function Penting

| Function | Fungsi |
|---|---|
| cleaning_type | Cleaning customer group |
| cleaning_region | Cleaning region |
| normalize_customer_code | Format customer code |
| cleaning_sdo | Cleaning nama SDO |
| parse_sap_date | Convert tanggal SAP |
| realqty | Hitung multiplier qty |

---

# Logic REAL QTY

Contoh:

| Internal Code | Multiplier |
|---|---|
| AB4 / EB4 | x4 |
| AB3 / BBT | x3 |
| BBL | x5 |
| lainnya | x1 |

Formula:

```python
REAL QTY = QTY * multiplier
```

### Flow REAL QTY

```mermaid
flowchart TD

    A[Internal Code] --> B{Contains AB4 / EB4 / BL4?}

    B -->|Yes| C[x4]
    B -->|No| D{Contains AB3 / BBT / EB3?}

    D -->|Yes| E[x3]
    D -->|No| F{Contains BBL?}

    F -->|Yes| G[x5]
    F -->|No| H[x1]

    C --> I[REAL QTY = QTY * Multiplier]
    E --> I
    G --> I
    H --> I
```

---

# Handling Duplicate DR Number

Script otomatis:

```python
raw_old_filtered = raw_old[~raw_old['DR Number'].isin(doc_revisi)]
```

Tujuan:
- menghapus transaksi lama yang sudah direvisi
- mengganti dengan data terbaru

---

# Standardisasi Region

Function:

```python
cleaning_reg2()
```

Contoh mapping:

| RSM / ASM | Region |
|---|---|
| IMAM SHOVII | CENTRAL JAVA |
| JEKY TIRTA | SULAWESI |
| IMAM TAUFIQ | WEST JAVA |

---

# Error yang Sering Terjadi

## File tidak ditemukan

```python
FileNotFoundError
```

Cek:
- path file
- nama file
- extension

---

## Sheet tidak ditemukan

```python
ValueError: Worksheet not found
```

Cek:

```python
MTD_SHEET = "SAP CUMULATIVE"
```

Pastikan nama sheet benar.

---

## Kolom tidak ada

```python
KeyError
```

Biasanya karena:
- format file berubah
- nama kolom SAP berubah

---

# Best Practice

Disarankan struktur folder:

```bash
project/
│
├── raw/
├── master/
├── output/
├── script/
└── backup/
```

---

# Future Improvement

Beberapa improvement yang bisa ditambahkan:

- Logging otomatis
- Config YAML
- GUI sederhana
- Auto detect cycle
- Database integration
- Scheduler automation
- Error report otomatis
- Email notification

---

# Simple Architecture Flow

```mermaid
flowchart LR

    SAP[MTD YTD SAP]
    MASTER[Master Data]
    RAWOLD[Raw Old]

    SAP --> ETL[ETL Processing]
    MASTER --> ETL

    ETL --> RAWNEW[raw_new]

    RAWOLD --> MERGE[Merge Data]
    RAWNEW --> MERGE

    MERGE --> FINAL[Final Raw Data Excel]
```

---

# Author

Developed for internal ETL automation & sell-in reporting process.

