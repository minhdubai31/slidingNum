# Slide Puzzle · Backend ảnh

API nhỏ trên Vercel, lưu ảnh và metadata trong Supabase. Game đọc danh sách ảnh từ đây; quản trị viên thêm, thay, sửa hoặc ẩn ảnh mà không cần phát hành lại app.

```
backend/
├── api/topics.js                       GET  /api/topics                       (công khai)
├── api/admin/topics.js                 GET/POST /api/admin/topics             (cần token)
├── api/admin/topics/[id].js            PATCH/DELETE /api/admin/topics/:id
├── api/admin/topics/[id]/pictures.js   POST /api/admin/topics/:id/pictures    (thêm ảnh vào chủ đề)
├── api/admin/pictures/[id].js          PUT/PATCH/DELETE /api/admin/pictures/:id
├── public/admin/index.html             Giao diện quản lý ảnh theo chủ đề
├── lib/                                Catalogue, Supabase client, xác thực, kiểm tra ảnh
├── supabase/migrations/                SQL tạo bảng topics, pictures và bucket
├── scripts/seed.mjs                    Tạo 6 chủ đề mẫu của game kèm ảnh
└── test/                               Kiểm thử đơn vị (node:test)
```

## 1. Tạo project Supabase

1. Tạo project mới tại supabase.com (Region gần người chơi, ví dụ Singapore).
2. Vào **SQL Editor**, dán toàn bộ `supabase/migrations/001_catalogue.sql` rồi chạy. Lệnh này tạo bảng `pictures` (RLS bật, không có policy công khai) và bucket public `pictures` (tối đa 4 MiB, chỉ PNG/JPEG/WebP).
3. Vào **Project Settings → API**, lấy:
   - `Project URL` → `SUPABASE_URL`
   - `service_role` key → `SUPABASE_SERVICE_ROLE_KEY`

   Key `service_role` bỏ qua RLS. Chỉ đặt nó trên server, không đưa vào game hay commit.

## 2. Chạy local

```bash
cd backend
npm install
cp .env.example .env        # điền SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, ADMIN_TOKEN
npm test                    # kiểm thử kiểm tra ảnh và tham số
npm run seed                # tùy chọn: đưa 6 ảnh mẫu lên Supabase (chạy một lần)
npx vercel dev              # API tại http://localhost:3000/api/topics, giao diện tại /admin/
```

`ADMIN_TOKEN` là chuỗi ngẫu nhiên tự đặt, ví dụ `openssl rand -hex 32`. Nó là mật khẩu cho các route `/api/admin/*`.

`npm run seed` bỏ qua nếu đã có chủ đề; thêm `-- --force` nếu muốn chèn thêm.

## 3. Deploy lên Vercel

Thư mục `backend/` là một project Vercel riêng (không phải thư mục gốc của game).

```bash
cd backend
npx vercel link                       # tạo hoặc chọn project; Root Directory = backend
npx vercel env add SUPABASE_URL production
npx vercel env add SUPABASE_SERVICE_ROLE_KEY production
npx vercel env add ADMIN_TOKEN production
npx vercel deploy --prod
```

Có thể đặt các biến này trong **Project Settings → Environment Variables** thay cho CLI. Sau khi thay đổi biến, cần deploy lại.

## 4. Giao diện quản lý ảnh

Mở `https://<your-app>.vercel.app/admin/` trên máy tính hoặc điện thoại, nhập `ADMIN_TOKEN`.

- **Cột trái**: danh sách chủ đề, kèm số ảnh đang hiện / tổng số. Thêm chủ đề mới ở dưới cùng.
- **Cột phải** (chủ đề đang chọn):
  - Đổi tên, ẩn/hiện cả chủ đề, xóa chủ đề (xóa luôn ảnh bên trong).
  - Thêm nhiều ảnh cùng lúc. Ảnh được thêm vào cuối danh sách.
  - Từng ảnh: đưa lên/xuống để đổi thứ tự, ẩn/hiện, thay file, chuyển sang chủ đề khác, xóa.
- Token chỉ lưu trong `sessionStorage` của tab, đóng tab là phải nhập lại.

Trang chỉ gọi API cùng origin, không có dependency bên ngoài.

## 5. API

### `GET /api/topics` (công khai)

Game gọi endpoint này để lấy danh sách chủ đề đang hiện và cấu hình hình nền. Chủ đề ẩn hoặc không có ảnh hiện thị sẽ bị bỏ qua.

```json
{
  "version": "3f9a1c0d2b7e8a41",
  "topics": [
    {
      "id": "2f1c9a52-7a1e-4f0e-9b7e-1d2c3b4a5f60",
      "name": "Thiên nhiên",
      "position": 0,
      "updated_at": "2026-10-21T08:00:00.000Z",
      "pictures": [
        {
          "id": "8a0c...",
          "topic_id": "2f1c9a52-7a1e-4f0e-9b7e-1d2c3b4a5f60",
          "position": 0,
          "url": "https://<project>.supabase.co/storage/v1/object/public/pictures/<id>/1761052800000.png",
          "bytes": 2888067,
          "updated_at": "2026-10-21T08:00:00.000Z"
        }
      ]
    }
  ]
}
```

- `version` đổi mỗi khi chủ đề, ảnh hoặc hình nền thay đổi. Client chỉ cần so sánh chuỗi này để biết có cần tải lại không.
- Response có `Cache-Control: no-store` để mỗi lần mở app kiểm tra nội dung hiện tại.
- `url` đổi khi thay file ảnh, nên có thể cache theo `url` mà không bị lỗi cũ.

### Route quản trị

Mọi route cần header `Authorization: Bearer <ADMIN_TOKEN>`.

| Method | Đường dẫn | Body | Mô tả |
|---|---|---|---|
| GET | `/api/admin/topics` | | Tất cả chủ đề và ảnh, kể cả đang ẩn |
| POST | `/api/admin/topics` | JSON `{ "name", "position"? }` | Tạo chủ đề |
| PATCH | `/api/admin/topics/:id` | JSON `{ "name"?, "position"?, "active"? }` | Sửa chủ đề |
| DELETE | `/api/admin/topics/:id` | | Xóa chủ đề và toàn bộ ảnh |
| POST | `/api/admin/topics/:id/pictures?position=` | Byte của file ảnh | Thêm ảnh vào chủ đề (PNG, JPEG, WebP, tối đa 4 MB) |
| PUT | `/api/admin/pictures/:id` | Byte của file ảnh | Thay file ảnh |
| PATCH | `/api/admin/pictures/:id` | JSON `{ "position"?, "active"?, "topic_id"? }` | Sửa ảnh; `topic_id` để chuyển sang chủ đề khác |
| DELETE | `/api/admin/pictures/:id` | | Xóa ảnh và file trong storage |
| GET | `/api/admin/backgrounds` | | Cấu hình hình nền Home, nền chơi chung và theo theme |
| PUT | `/api/admin/backgrounds/:slot` | Byte của file ảnh | Tải hoặc thay hình nền (tối đa 4 MB) |
| DELETE | `/api/admin/backgrounds/:slot` | | Bỏ nền riêng để dùng nền dự phòng |

Ví dụ:

```bash
TOKEN=...   # ADMIN_TOKEN
API=https://<your-app>.vercel.app
TOPIC=2f1c9a52-7a1e-4f0e-9b7e-1d2c3b4a5f60

# Tạo chủ đề
curl -X POST "$API/api/admin/topics" -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"name":"Biển"}'

# Thêm ảnh vào chủ đề
curl -X POST "$API/api/admin/topics/$TOPIC/pictures" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: image/jpeg" \
  --data-binary @night-sea.jpg

# Ẩn một ảnh
curl -X PATCH "$API/api/admin/pictures/<id>" -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"active": false}'
```

Lỗi trả về dạng `{ "error": "..." }` với mã 400 (tham số sai), 401 (sai token), 404 (không có), 405, 413 (quá 4 MB), 415 (không phải PNG/JPEG/WebP), hoặc 500.

Giới hạn body của Vercel Function là khoảng 4.5 MB, nên ảnh tải lên không được vượt 4 MB. Nên resize ảnh về cạnh khoảng 1600 px trước khi tải.

## 6. Ghi chú cho app Godot (chưa làm)

Backend này chưa làm thay đổi phía game. Đã đối chiếu với nhánh `main` (commit `d96cb75`):

- Catalogue hiện là hằng số `PHOTO_NAMES` và `PHOTO_FILES` trong `scripts/main.gd`. Chủ đề **Của bạn** (ảnh cá nhân, lưu `user://custom_pictures/`) giữ nguyên, không đưa lên backend.
- Kỷ lục và thành tích ảnh được khóa bằng `picture_key()`, tức chính đường dẫn `res://assets/...`. Nếu đổi sang `id` từ backend mà không xử lý, kỷ lục của 6 ảnh mẫu sẽ mất. Cần migrate khóa cũ sang `id` của bản ghi seed tương ứng, hoặc giữ tạm bảng ánh xạ `res://...` → `id`.
- Các test `tests/test_app.gd` dùng `picture_key(0)` và `picture_key(1)`, nên cần cập nhật cùng lúc.

Hướng tích hợp:

1. Lúc mở app, gọi `GET /api/topics` bằng `HTTPRequest`. Nếu lỗi mạng, dùng 6 ảnh nhúng sẵn làm dự phòng.
2. Lưu `version` đã dùng; chỉ tải ảnh khi `version` khác. Tải từng `url` và lưu vào `user://pictures/<id>-<hash>.png`.
3. Thay `PHOTO_FILES` / `PHOTO_NAMES` bằng danh sách lấy từ cache và chuyển `picture_key()` sang `id`, kèm migrate kỷ lục cũ.

## Bảo mật

- `SUPABASE_SERVICE_ROLE_KEY` và `ADMIN_TOKEN` chỉ nằm trên Vercel và trong `.env` local (đã bỏ qua trong git).
- Bảng `pictures` bật RLS và không có policy, nên khóa `anon` không đọc hay ghi trực tiếp được.
- Bucket `pictures` là public: ai biết `url` đều xem được ảnh. Đây là chủ đích vì ảnh vốn là nội dung của game.
- Chưa có giới hạn tần suất gọi cho route admin. Với một người quản trị thì token dài ngẫu nhiên là đủ; nếu chia sẻ rộng hơn, nên thêm rate limit.

## Cập nhật nội dung trong game

Mỗi lần mở app, game gọi `/api/topics` để so sánh `version` với catalogue đang dùng.
Nếu có thay đổi, ảnh mới được tải ngầm vào bộ nhớ cục bộ; game tiếp tục dùng nội dung hiện tại.
Khi tải hoàn tất và người dùng ở Home, popup hiển thị “Nội dung mới đã được tải sẵn” với nút **Tải lại** để áp dụng ngay và **Để sau** để giữ bản tải sẵn cho lần mở tiếp theo.
Popup chờ nếu người dùng ở màn khác hoặc đang mở hộp thoại khác. Mỗi phiên bản chỉ được nhắc một lần trong mỗi lần mở app.
Nếu mất mạng hoặc tải ảnh lỗi, nội dung đang dùng được giữ nguyên; lần mở sau sẽ kiểm tra lại.
API catalogue không cache để lần mở app tiếp theo nhận được phiên bản hiện tại. Thay đổi cấu hình này cần deploy lại backend.

Kiểm thử luồng tải và popup (dùng thư mục dữ liệu riêng):

```bash
XDG_DATA_HOME=/tmp/slide-catalogue-check godot --headless --path . --script tests/test_catalogue.gd
XDG_DATA_HOME=/tmp/slide-popup-check godot --headless --path . --script tests/test_catalogue_popup.gd -- --test-mode
```

## Cấu hình hình nền

Trong `/admin/`, chọn tab **Hình nền**:

- **Màn Home**: nền Home và màn khởi động.
- **Màn chơi · nền chung**: nền mặc định cho cả xếp số và xếp ảnh.
- **Theo theme**: nền riêng cho Gỗ cổ điển, Gỗ tối, Gốm sứ, Đá cẩm thạch, Kim loại, Kính mờ, Đất sét và Neon.

Chọn **Chọn ảnh nền** / **Thay ảnh nền** để tải ảnh PNG, JPEG hoặc WebP tối đa 4 MB.
Nên dùng ảnh dọc 9:16; app phóng ảnh đầy màn hình, giữ tỷ lệ và cắt phần dư ở giữa.
Nút **Dùng nền chung** bỏ ảnh riêng của theme; nút **Dùng nền có sẵn** bỏ cấu hình Home hoặc nền chơi chung.

Màn chơi ưu tiên nền của theme → nền chơi chung → nền có sẵn.
Khi không cấu hình, xếp số dùng nền bàn hiện tại và xếp ảnh dùng ảnh đang chơi được làm mờ như trước.
Nền Home không cấu hình sẽ dùng ảnh có sẵn trong app. Màn kết quả và các màn phụ giữ cách hiển thị hiện tại.

`GET /api/topics` có thêm trường:

```json
{
  "backgrounds": {
    "home": { "url": "https://.../pictures/_backgrounds/home--<timestamp>-<uuid>.png", "bytes": 123456 },
    "game": null,
    "themes": { "0": null, "1": null, "2": null, "3": null, "4": null, "5": null, "6": null, "7": null }
  }
}
```

API quản trị nhận `slot` là `home`, `game`, hoặc `theme-0` đến `theme-7` (theo thứ tự theme ở trên).
Ảnh được lưu trong thư mục `_backgrounds/` của bucket `pictures` hiện có, tách khỏi ảnh puzzle.
Không cần chạy thêm SQL hoặc mở quyền ghi công khai. Mỗi lần thay ảnh tạo URL mới để tránh cache cũ.
App tải nền ngầm cùng catalogue, chỉ áp dụng sau khi người dùng chọn **Tải lại** ở Home và dùng được khi offline.
Cần build lại app để sử dụng tính năng hình nền.

## Preview màn hình Godot Web

Mở `/preview/` hoặc liên kết **Preview màn hình** trên trang quản trị để xem giao diện Godot thật.
Chọn màn hình, theme, ảnh và ngôn ngữ bằng thanh công cụ. Đây là bản xem trước, không có thao tác chơi hoặc lưu ván.
Sau khi cập nhật hình nền, chọn **Làm mới nội dung**; các ảnh tải xong được tự động áp dụng vào preview.

Trước khi deploy, từ thư mục gốc repo chạy `python3 tools/export_web.py` để tạo `backend/public/preview/`.
File export không nằm trong Git; deploy từ checkout mới cần tạo lại chúng.
`vercel.json` yêu cầu kiểm tra lại cache các file Web để tránh dùng lẫn engine và tài nguyên khác phiên bản.
`.vercelignore` cho phép upload file export đã tạo và loại trừ file môi trường, dependency local và thư mục kiểm thử.
