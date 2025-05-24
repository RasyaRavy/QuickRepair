# 🚀 QuickRepair

Aplikasi Flutter untuk Pelaporan & Manajemen Perbaikan Fasilitas Pendidikan

---

## 📱 Gambaran Umum
QuickRepair adalah aplikasi mobile berbasis Flutter yang dirancang untuk memudahkan pelaporan, pelacakan, dan pengelolaan permintaan perbaikan di lingkungan pendidikan. Dengan fitur modern seperti autentikasi, pelaporan berbasis lokasi, dokumentasi foto, dan integrasi Supabase, aplikasi ini membantu menjaga fasilitas pendidikan tetap optimal.

---

## 🎯 Fitur Utama

- **Autentikasi Pengguna**: Registrasi, login, dan pemulihan kata sandi yang aman.
- **Manajemen Laporan Perbaikan**: Buat, edit, lihat, dan lacak status laporan perbaikan.
- **Geolokasi**: Tandai lokasi kerusakan secara otomatis menggunakan GPS.
- **Lampiran Foto**: Upload gambar untuk memperjelas laporan kerusakan.
- **Laporan Publik**: Lihat dan eksplorasi laporan yang dibagikan secara publik.
- **Obrolan**: Komunikasi langsung terkait laporan.
- **Tema Gelap/Terang**: Pilihan tema antarmuka sesuai preferensi pengguna.
- **Onboarding**: Panduan interaktif untuk pengguna baru.
- **Statistik & Grafik**: Visualisasi data laporan dengan grafik interaktif.

---

## 🛠️ Teknologi & Library

- **Flutter (Dart)**: Framework utama aplikasi
- **Provider**: Manajemen state
- **Shared Preferences**: Penyimpanan lokal
- **Geolocator & Geocoding**: Layanan lokasi
- **fl_chart, lottie, flutter_animate, flutter_staggered_animations**: Komponen UI & animasi
- **image_picker, cached_network_image**: Pengelolaan gambar
- **uuid, intl, timeago**: Utilitas tambahan

---

## 📂 Struktur Proyek

```
lib/
├── constants/      # Konstanta, tema, rute, string
├── models/         # Model data (user, report, message, dll)
├── screens/        # Layar aplikasi
│   ├── auth/       # Login, register, lupa password
│   ├── home/       # Beranda & profil
│   ├── onboarding/ # Onboarding pengguna
│   ├── report/     # Laporan perbaikan
│   ├── chat/       # Fitur obrolan
│   └── profile/    # Pengaturan & info pengguna
├── services/       # Integrasi Supabase & provider tema
├── utils/          # Fungsi utilitas (validator, status, bucket)
├── widgets/        # Komponen UI reusable (popup, dsb)
└── main.dart       # Entry point aplikasi
assets/
├── wrench.png      # Ikon utama
└── lottie/         # Animasi Lottie
```

---

## 🗄️ Struktur Database (Supabase)

- **users**: Data pengguna & autentikasi
- **reports**: Laporan perbaikan (judul, deskripsi, lokasi, status, foto, dsb)
- **categories**: Kategori/jenis perbaikan
- **messages**: Data chat terkait laporan

---

## ⚡ Instalasi & Menjalankan Aplikasi

### Prasyarat
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio/Xcode
- Akun & project Supabase

### Langkah Instalasi

1. **Clone repositori**
   ```bash
git clone https://github.com/RasyaRavy/QuickRepair.git
cd QuickRepair
   ```
2. **Install dependensi**
   ```bash
flutter pub get
   ```
3. **Jalankan aplikasi**
   ```bash
flutter run
   ```

---

## 🧪 Testing

Tersedia contoh widget test di `test/widget_test.dart`. Jalankan:
```bash
flutter test
```

---

## 📸 Asset & UI
- Ikon utama: `assets/wrench.png`
- Animasi: folder `assets/lottie/`
- (Opsional) Tambahkan gambar/foto lain di folder `assets/`

---

## 🤝 Kontribusi

1. Fork repositori
2. Buat branch fitur (`git checkout -b fitur/nama-fitur`)
3. Commit perubahan (`git commit -m 'Deskripsi fitur'`)
4. Push ke branch (`git push origin fitur/nama-fitur`)
5. Buka Pull Request

---

Dikembangkan dengan ❤️ untuk manajemen fasilitas pendidikan yang lebih baik.
