# BizTown Rent-Manager

Ứng dụng mobile quản lý nhà cho thuê (quản lý phòng/căn hộ, khách thuê, hợp đồng, thanh toán).

> Brand: **BizTown** — Sản phẩm: **Rent-Manager** (tên chính thức do khách hàng chốt).

## Stack

- **Frontend**: Flutter (mobile app, iOS/Android)
- **Backend**: Supabase (DB/Auth/Storage/Edge Functions) — không dùng Vercel

## Cấu trúc thư mục

```
.
├── src/                 # Flutter mobile app (pubspec.yaml, lib/, ...)
├── supabase/            # Supabase backend (functions/, migrations/)
├── tests/               # Test cho frontend & backend
├── design/              # File thiết kế (Figma export, mockup, asset UI/UX)
├── docs/                # Tài liệu dự án (AI đọc để hiểu context)
└── changelog/           # Nhật ký thay đổi chi tiết theo ngày/giờ/người thực hiện
```

## Setup môi trường

Người mới nhận project (kể cả khách hàng sau khi bàn giao) xem [docs/SETUP.md](docs/SETUP.md) — hướng dẫn cài đặt đầy đủ từ đầu (Flutter SDK, Supabase CLI, lấy API keys, link project...).

## Docs

Xem [docs/](docs/) để hiểu yêu cầu sản phẩm, kiến trúc, API, database và các quyết định thiết kế.

## Design

File thiết kế (Figma, mockup, asset) được quản lý tại thư mục [design/](design/), trong cùng repo.

## Changelog

Nhật ký chi tiết từng thay đổi (ngày, giờ, người thực hiện, sửa gì) nằm ở [changelog/](changelog/) — mỗi ngày một file. Khác với [docs/CHANGELOG.md](docs/CHANGELOG.md) là bản tóm tắt theo release.
