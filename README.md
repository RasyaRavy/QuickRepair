# QuickRepair

## Gambaran Umum

QuickRepair adalah aplikasi Flutter yang dirancang untuk fasilitas pendidikan untuk menyederhanakan pelaporan pemeliharaan dan perbaikan. Aplikasi ini memungkinkan pengguna untuk membuat, melacak, dan mengelola permintaan perbaikan, sehingga mempermudah pemeliharaan infrastruktur pendidikan secara efektif.

## Fitur

- **Autentikasi Pengguna**: Login aman, registrasi, dan pemulihan kata sandi
- **Manajemen Permintaan Perbaikan**: Buat, lihat, edit, dan lacak permintaan perbaikan
- **Layanan Lokasi**: Geolokasi untuk menentukan lokasi perbaikan di dalam fasilitas
- **Dokumentasi Foto**: Lampirkan gambar ke permintaan perbaikan untuk visualisasi masalah yang lebih baik
- **Tampilan Laporan Publik**: Jelajahi masalah perbaikan yang dibagikan secara publik
- **Tema Gelap/Terang**: Tema antarmuka pengguna yang dapat disesuaikan
- **Proses Onboarding**: Panduan pengenalan untuk pengguna pertama kali

## Teknologi yang Digunakan

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (Autentikasi, Database, Penyimpanan)
- **Manajemen State**: Provider
- **Penyimpanan Lokal**: Shared Preferences
- **Layanan Lokasi**: Geolocator, Geocoding
- **Komponen UI**: fl_chart, flutter_animate, flutter_staggered_animations

## Memulai

### Prasyarat

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode untuk deployment mobile
- Akun dan proyek Supabase

### Instalasi

1. **Clone repositori**

```bash
git clone https://github.com/RasyaRavy/QuickRepair.git
cd QuickRepair
```

2. **Instal dependensi**

```bash
flutter pub get
```

3. **Konfigurasi Supabase**

Buat file `.env` di direktori root dengan kredensial Supabase Anda:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. **Jalankan aplikasi**

```bash
flutter run
```

## Struktur Proyek

```
lib/
├── constants/      # Konstanta aplikasi, tema, rute, string
├── models/         # Model data
├── screens/        # Layar UI
│   ├── auth/       # Layar autentikasi
│   ├── home/       # Layar utama aplikasi
│   ├── onboarding/ # Panduan pengguna pertama kali
│   └── report/     # Pembuatan dan pengelolaan laporan
├── services/       # Layanan backend
├── utils/          # Fungsi utilitas
├── widgets/        # Komponen UI yang dapat digunakan kembali
└── main.dart       # Titik masuk aplikasi
```

## Struktur Database

Aplikasi ini menggunakan Supabase sebagai layanan backend. Tabel utama meliputi:
- `users`: Informasi pengguna dan autentikasi
- `reports`: Detail permintaan perbaikan
- `categories`: Jenis perbaikan

## Kontribusi

1. Fork repositori
2. Buat branch fitur Anda (`git checkout -b feature/fitur-luar-biasa`)
3. Commit perubahan Anda (`git commit -m 'Menambahkan fitur luar biasa'`)
4. Push ke branch (`git push origin feature/fitur-luar-biasa`)
5. Buka Pull Request

---

Dikembangkan dengan ❤️ untuk manajemen fasilitas pendidikan
