# RentEase

Ứng dụng mobile quản lý nhà cho thuê (quản lý phòng/căn hộ, khách thuê, hợp đồng, thanh toán).

> Tên project là tên tạm thời, có thể đổi sau.

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

## Docs

Xem [docs/](docs/) để hiểu yêu cầu sản phẩm, kiến trúc, API, database và các quyết định thiết kế.

## Design

File thiết kế (Figma, mockup, asset) được quản lý tại thư mục [design/](design/), trong cùng repo.

## Changelog

Nhật ký chi tiết từng thay đổi (ngày, giờ, người thực hiện, sửa gì) nằm ở [changelog/](changelog/) — mỗi ngày một file. Khác với [docs/CHANGELOG.md](docs/CHANGELOG.md) là bản tóm tắt theo release.
