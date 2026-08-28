# SETUP.md — Hướng dẫn setup môi trường

Hướng dẫn setup toàn bộ môi trường dev cho BizTown Rent-Manager từ đầu (máy mới, người mới nhận project).

## 1. Tài khoản cần có

- **GitHub** — quyền truy cập vào repo (Organization `townsoft-dev`, hoặc org của bạn nếu đã bàn giao).
- **Supabase** — tài khoản + quyền truy cập project `rentease` (tên project trên Supabase Dashboard, chưa đổi theo tên mới; chức năng không đổi) — hoặc tạo project mới nếu build lại từ đầu, xem mục 4.
- **Apple Developer** — chỉ cần khi build/publish app lên App Store (chưa cần ở giai đoạn dev).

## 2. Clone repo

```bash
git clone git@github.com:townsoft-dev/biztown-rent.git
cd biztown-rent
```

Cần SSH key đã add vào GitHub account của bạn. Nếu chưa có, tạo bằng:

```bash
ssh-keygen -t ed25519 -C "email-cua-ban@example.com"
cat ~/.ssh/id_ed25519.pub   # copy, add vào https://github.com/settings/ssh/new
```

## 3. Setup Flutter (frontend)

1. Cài [Flutter SDK](https://docs.flutter.dev/get-started/install) (bản `stable`).
2. Thêm `flutter/bin` vào PATH (hướng dẫn trong link trên tùy hệ điều hành).
3. Kiểm tra: `flutter doctor` — cần ít nhất mục Flutter và 1 platform (Android hoặc iOS/macOS) báo `[✓]`.
   - Build Android: cần cài Android Studio (tự cài Android SDK khi mở lần đầu).
   - Build iOS/macOS: cần cài Xcode đầy đủ từ App Store + CocoaPods (`sudo gem install cocoapods`).
4. Trong `src/`: xem [src/README.md](../src/README.md) để biết bước tiếp theo (`flutter create .`, thêm dependency `supabase_flutter`).

## 4. Setup Node + Supabase CLI (tooling)

Supabase CLI được cài như dev dependency Node ở root repo, không cần cài global.

```bash
npm install
npx supabase --version   # kiểm tra chạy được
```

## 5. Setup Supabase (backend)

### Nếu dùng lại project Supabase hiện có (`rentease`)

1. Được thêm làm member của project/organization Supabase (người quản lý hiện tại mời qua email).
2. Lấy thông tin tại Supabase Dashboard → chọn project `rentease` → **Project Settings → API Keys**:
   - **Project URL** (`https://<ref>.supabase.co`)
   - **Publishable key**
   - **Secret key** (chỉ dùng phía server/Edge Functions, không đưa vào app)
3. Tạo **Personal Access Token** riêng cho bạn tại **Account → Access Tokens** (mỗi người dùng token riêng, không dùng chung).
4. Copy `supabase/.env.example` thành `supabase/.env`, điền 4 giá trị trên:
   ```
   SUPABASE_URL=
   SUPABASE_PUBLISHABLE_KEY=
   SUPABASE_SECRET_KEY=
   SUPABASE_ACCESS_TOKEN=
   ```
5. Link CLI với project:
   ```bash
   export SUPABASE_ACCESS_TOKEN=<token-vua-tao>
   npx supabase link --project-ref <project-ref>
   ```
6. Kiểm tra: `npx supabase projects list` — thấy project với `"linked": true`.

### Nếu tạo project Supabase mới (build lại từ đầu / project riêng của khách)

1. Tạo project mới tại [supabase.com/dashboard](https://supabase.com/dashboard) (dùng tài khoản/org sẽ sở hữu lâu dài, tránh phải transfer sau).
2. Làm theo bước 2-6 ở trên với project mới.
3. Chạy migration có sẵn (khi đã có) trong `supabase/migrations/`:
   ```bash
   npx supabase db push
   ```

**Lưu ý bảo mật** (áp dụng cho môi trường thật/production, không bắt buộc lúc dev): không commit `supabase/.env` lên git (đã có trong `.gitignore` sẵn), không chia sẻ Secret key/Access Token qua kênh không mã hoá (chat, email thường) — dùng công cụ quản lý secret (1Password, Bitwarden...) nếu có.

## 6. Chạy thử

```bash
cd src
flutter run   # chọn thiết bị/emulator khi được hỏi
```

## 7. (Tùy chọn) Cho Claude Code đọc trực tiếp Figma

Nếu dùng Claude Code và muốn agent đọc được file Figma trực tiếp (không cần export ảnh thủ công):

1. Cài CLI chuẩn (bản VS Code extension không có sẵn lệnh này): `npm install -g @anthropic-ai/claude-code`
2. Đăng ký server chính thức của Figma: `claude mcp add --transport http figma https://mcp.figma.com/mcp`
3. Xác thực (**phải chạy ở terminal thật, có tương tác được**, không chạy được trong phiên non-interactive): `claude mcp login figma` → trình duyệt mở ra → đăng nhập Figma → **Allow Access**.
4. Mở phiên Claude Code mới — agent sẽ thấy công cụ Figma khả dụng.

Không bắt buộc — nếu bỏ qua bước này, dùng cách thủ công ở mục "Design" trong [DESIGN.md](DESIGN.md) (export ảnh + design tokens) vẫn đủ để code chính xác.

## 8. Tài liệu liên quan

- [ARCHITECTURE.md](ARCHITECTURE.md) — kiến trúc hệ thống
- [DATABASE.md](DATABASE.md) — schema dữ liệu
- [PRODUCT-OVERVIEW.md](PRODUCT-OVERVIEW.md) — Tổng quan sản phẩm
- [../CLAUDE.md](../CLAUDE.md) + [../.claude/rules/flutter.md](../.claude/rules/flutter.md) — quy ước code nếu dùng Claude Code
- [../changelog/](../changelog/) — lịch sử thay đổi chi tiết
