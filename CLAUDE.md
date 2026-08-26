@docs/CLAUDE.md

# Claude Code Instructions — RentEase

## Quy trình

- Sau MỖI thay đổi, thêm entry vào `changelog/YYYY-MM-DD.md` (xem [changelog/README.md](changelog/README.md)).
- Quyết định kỹ thuật quan trọng ghi vào [docs/DECISIONS.md](docs/DECISIONS.md) kèm lý do.
- Không tự chọn thư viện/kiến trúc lớn (state management, package chính, cấu trúc `lib/`...) khi chưa có trong [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — dự án đang chờ design UI + mô tả nghiệp vụ chi tiết, hỏi trước khi quyết định.
- Quy tắc code Flutter cụ thể: xem `.claude/rules/flutter.md` (tự load khi làm việc trong `src/`).
