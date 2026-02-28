# MyOkane

MyOkane adalah aplikasi manajemen keuangan pribadi berbasis Android yang dikembangkan dengan framework Flutter. Aplikasi ini berfungsi untuk mencatat transaksi harian, mengelola profil pengguna, dan memantau arus kas secara lokal.

Link Release: https://github.com/ramdanolii14/myokane/releases/tag/v3.0.0

---

## Fitur Utama

- Pencatatan Transaksi: Input data pemasukan dan pengeluaran.
- Manajemen Profil: Pengaturan data pengguna melalui UserProfile.
- State Management: Implementasi Provider untuk reaktivitas data.
- Animasi UI: Transisi antarmuka menggunakan Flutter Animate.
- Penyimpanan Lokal: Penggunaan Shared Preferences untuk persistensi data sederhana.

---

## Required

Aplikasi ini menggunakan dependensi berikut sesuai dengan file pubspec.yaml:

- Framework: Flutter SDK
- State Management: provider: ^6.1.1
- Tipografi: google_fonts: ^6.2.1
- Lokalisasi: intl: ^0.19.0
- Utilitas ID: uuid: ^4.3.3
- Animasi: flutter_animate: ^4.5.0
- Media: image_picker: ^1.2.1
- Path Provider: path_provider: ^2.1.2

---

## Struktur

Struktur direktori pada folder lib disusun sebagai berikut:

- animations/: Berisi widget animasi kustom.
- models/: Definisi entitas data.
- providers/: Logika bisnis dan manajemen state.
- screens/: Implementasi antarmuka pengguna.

---


## Distribusi

File instalasi APK dapat diunduh pada halaman Release:
https://github.com/ramdanolii14/myokane/releases

---

Copyright (c) 2026 ramdanolii14
