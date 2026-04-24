# 🚀 Cotuong.xyz - Flutter Mobile Client

Dự án mobile đa nền tảng (Android & iOS) cho dự án `cotuong.xyz`.

## 1. Công nghệ (Tech Stack)
*   **Framework**: Flutter 3.x
*   **Networking**: `dio` (REST API)
*   **Real-time**: `socket_io_client`
*   **Rendering**: `CustomPainter` cho bàn cờ và `flutter_svg` cho quân cờ.
*   **State Management**: `provider` (hoặc `bloc/riverpod` tùy quy mô).

## 2. Cấu trúc thư mục
*   `lib/models`: Định nghĩa các thực thể dữ liệu (Game, User, Move).
*   `lib/services`: Xử lý logic kết nối API và Socket.
*   `lib/views`: Các màn hình giao diện (Lobby, Board, Profile).
*   `assets/`: Chứa quân cờ (pieces), âm thanh (sounds) và themes.

## 3. Tài liệu kỹ thuật
Xem hướng dẫn chi tiết tại thư mục `docs/`:
*   [CLIENT_SDK.md](./docs/CLIENT_SDK.md)
*   [SPEC.md](./docs/SPEC.md)

## 4. Cách bắt đầu
1.  Cài đặt Flutter SDK mới nhất.
2.  Chạy `flutter pub get` để tải các thư viện.
3.  Kết nối thiết bị và chạy `flutter run`.

---
*Phát triển bởi đội ngũ Cotuong.xyz*
