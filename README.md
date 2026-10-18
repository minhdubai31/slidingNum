# Slide Puzzle · MVP 0.5

Game xếp số / xếp ảnh cho màn hình dọc, viết bằng Godot 4.7.2 và GDScript. Giao diện tiếng Việt, phong cách gỗ nổi và phong cảnh ấm áp.

## Chạy game

- Nhấp đúp **Play.cmd** để chơi trên Windows với Godot đã cài.
- Nhấp đúp **Open Editor.cmd** để mở dự án trong editor. Hoặc import **project.godot**, nhấn F5.
- Cửa sổ mặc định 430 × 900; giao diện thích ứng với màn hình nhỏ và cuộn khi cần. Trên mobile có tính vùng an toàn của màn hình.

## Các màn hình

1. Splash có logo, bàn xếp thu nhỏ và thanh tải.
2. Trang chủ với Xếp số, Xếp ảnh, tiếp tục ván và các lối tắt.
3. Chọn cấp độ 3 × 3 / 4 × 4 / 5 × 5.
4. Chọn ảnh: 6 ảnh mẫu và nhập ảnh PNG/JPG/WebP riêng, cắt vuông ở giữa.
5. Màn chơi số và ảnh với kéo/chạm, thời gian, số bước, xem ảnh, gợi ý, hoàn tác và làm lại.
6. Home/tạm dừng chỉ có **Tiếp tục** và **Về màn hình chính**; giữ nguyên ván khi quay về.
7. Kết quả số/ảnh, kỷ lục thời gian, chơi tiếp hoặc chọn cấp độ.
8. Chọn 8 giao diện: gỗ cổ điển, gỗ tối, gốm, cẩm thạch, kim loại, kính, đất sét, neon.
9. Cài đặt hiệu ứng âm thanh, nhạc nền, âm lượng riêng, rung, hiệu ứng động, số gợi ý trên ảnh và xóa dữ liệu có xác nhận.
10. Thống kê riêng cho xếp số/xếp ảnh và 4 thành tích mở theo kết quả thật.
11. Hướng dẫn có ví dụ bàn gần hoàn thành.
12. Thử thách hằng ngày: bàn 3 × 3 cố định theo ngày trên thiết bị và lịch hoàn thành 7 ngày.

## Luật và lưu dữ liệu

- Chỉ kéo/chạm ô kề khoảng trống. Kéo quá 24% kích thước ô hoặc vuốt nhanh để đi; kéo ngắn sẽ quay về.
- Trộn bằng các bước hợp lệ từ đích, đảm bảo có lời giải. Lưu đường giải để gợi ý luôn chỉ một bước hợp lệ; mỗi ván có 3 lượt.
- Làm lại giữ nguyên bàn ban đầu và đặt lại thời gian/bước. Hoàn tác không giới hạn trong ván chưa thắng.
- Đồng hồ bắt đầu sau bước đầu, dừng khi tạm nghỉ, rời màn chơi, xem ảnh hoặc ứng dụng mất focus.
- Lưu tự động tiến trình, đường giải, undo, cài đặt, thống kê, lịch ngày và bản sao ảnh riêng trong thư mục `user://` của Godot.
- File lưu MVP cũ được đọc để tiếp tục ván; ván cũ chưa có đường giải sẽ không có gợi ý.
- Dữ liệu hoàn toàn cục bộ; thử thách ngày không có server hay chống thay đổi đồng hồ thiết bị.

## Cấu trúc

- `scripts/main.gd`: điều hướng, màn hình, tương tác UI, lưu ván và âm thanh.
- `scripts/ui.gd`: font, nút, icon SVG, texture ô và bảng màu.
- `scripts/animated_button.gd`: hiệu ứng nhấn lún, bật nảy và hover; tôn trọng cài đặt giảm chuyển động.
- `scripts/audio.gd`: tiếng nút, kéo/đặt/trả ô, hoàn thành, nhạc lặp, âm lượng và xử lý focus.
- `scripts/board.gd`: cảm ứng, kéo ô, animation, bo góc ảnh và hiệu ứng thắng.
- `scripts/puzzle.gd`: luật, trộn có seed, đường giải, hoàn tác.
- `scripts/profile.gd`: cài đặt, thống kê và thành tích.
- `scripts/backdrop.gd`: nền theo màn hình.
- `assets/`: ảnh tạo cho dự án, SVG và font Nunito (giấy phép OFL đi kèm).
- `artifacts/`: ảnh chụp các màn và `overview.png`; thư mục này không được Godot import vào game.

## Icon, hiệu ứng nút và âm thanh

Icon điều khiển dùng SVG tải từ **Font Awesome Free 6.7.2**; các icon màu dùng **Google Noto Emoji v2.047**. File gốc giữ nguyên trong `assets/third_party/`. Nguồn và giấy phép được ghi tại **assets/SOURCES.md** và trong mục Cài đặt → Nguồn tài nguyên.

Nút có mặt chuyển sắc và gờ dưới, co nhẹ khi giữ rồi nảy về khi thả. Nhấn nhanh được chặn kích hoạt lặp trong lúc chuyển màn. Tắt Hiệu ứng động sẽ bỏ chuyển động của nút và ô chơi.

Tiếng kéo và đặt/trả ô dùng bản ghi **Board Game Wood Piece Slide — Jeff Final Boss**, đã lọc bớt phần chói và làm mềm đầu/cuối. Một cử chỉ kéo chỉ phát một lần, không lặp tiếng scratch theo quãng đường. **Kenney Interface Sounds** tiếp tục dùng cho nút bấm và hoàn thành. Nhạc nền **Exploration Theme — Cleyton Kauffman** phát lặp. Âm lượng nhạc và hiệu ứng chỉnh riêng; nhạc nhỏ đi khi mở hộp thoại và dừng khi ứng dụng mất focus. Các tài nguyên âm thanh dùng CC0, bản ghi nguồn đi kèm dự án.

Nút dùng shader bo góc với mặt satin, đế mỏng khoảng 1,8 px và ánh sáng chuyển nhẹ; nhấn/nhả và hover được nội suy mềm. Màn kết quả dùng nền tối có ánh vàng, thẻ thống kê chia hàng, huy hiệu NEW và chỉ hai nút Trang chủ / Chơi tiếp cùng hàng. Ô ảnh dùng khe 2,4 px so với 7 px của ô số (tại bàn rộng 390 px), có lớp bắt sáng mỏng được dựng ở độ phân giải cao để tránh viền gắt. Thẻ chọn ảnh phủ kín khung với nhãn dưới lớp tối chuyển sắc; thẻ chọn chất liệu không in số, có dấu chọn xanh ở góc. Ảnh tổng quan ở `artifacts/overview.png` và `artifacts/polish-preview.png`.

## Kiểm thử

```powershell
$engine = "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe"
& $engine --headless --path . --editor --import
& $engine --headless --path . --script tests/test_puzzle.gd
& $engine --path . --script tests/test_app.gd --quit-after 1800 -- --test-mode
```

Kiểm thử logic tạo 120 bàn và kiểm tra parity, các bước hợp lệ, undo, phát hiện thắng và toàn bộ đường gợi ý. Kiểm thử app mô phỏng input thật, duyệt các màn, kiểm tra lưu/khôi phục, pause, restart, ảnh riêng, cài đặt, thống kê, thử thách ngày và bố cục 360 × 780. Kiểm thử app sao lưu và khôi phục dữ liệu người dùng; số liệu trên ảnh chụp kết quả/thống kê là dữ liệu kiểm thử.

## Phát hành mobile

Dự án dùng Compatibility renderer, hỗ trợ touch và khóa hướng dọc. Chưa đóng gói APK/IPA hoặc đo hiệu năng trên điện thoại thật. Android cần Godot export templates khớp phiên bản, Android SDK và JDK; iOS cần macOS/Xcode. Cần kiểm tra file picker, haptic và vùng an toàn trên thiết bị trước khi phát hành.
