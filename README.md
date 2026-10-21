# Slide Puzzle · 0.7

Game xếp số / xếp ảnh cho màn hình dọc, viết bằng Godot 4.7.2 và GDScript. Giao diện tiếng Việt, phong cách gỗ nổi và phong cảnh ấm áp.

## Chạy game

- Nhấp đúp **Play.cmd** để chơi trên Windows với Godot đã cài.
- Nhấp đúp **Open Editor.cmd** để mở dự án trong editor. Hoặc import **project.godot**, nhấn F5.
- Cửa sổ mặc định 430 × 900; giao diện thích ứng với màn hình nhỏ và cuộn khi cần. Trên mobile có tính vùng an toàn của màn hình.

## Các màn hình

1. Splash có logo, bàn xếp thu nhỏ và thanh tải.
2. Trang chủ với Xếp số, Xếp ảnh, tiếp tục ván và các lối tắt.
3. Chọn cấp độ: Xếp số có 3 × 3 / 4 × 4 / 5 × 5 / 6 × 6; Xếp ảnh có 3 × 3 / 4 × 4 / 5 × 5.
4. Chọn chủ đề ảnh → xem danh sách ảnh trong chủ đề → chọn cấp độ. Trên mỗi ảnh có cụm sao pha lê bo tròn xanh / vàng / đỏ ghi nhận hoàn thành 3×3 / 4×4 / 5×5, không kèm nhãn; mức chưa hoàn thành hiện sao mờ; màn chọn cấp độ hiển thị thời gian nhanh nhất riêng cho từng ảnh và từng mức. Chủ đề **Của bạn** chứa bộ sưu tập ảnh cá nhân và nút thêm ảnh PNG/JPG/WebP; mỗi ảnh được cắt vuông ở giữa và lưu riêng trên thiết bị. Có thể xóa từng ảnh bằng nút thùng rác; thao tác có xác nhận và chỉ xóa bản sao trong game cùng thành tích của ảnh.
5. Màn chơi số và ảnh với kéo/chạm, thời gian, số bước, xem ảnh, gợi ý, hoàn tác và làm lại.
6. Home/tạm dừng chỉ có **Tiếp tục** và **Về màn hình chính**; giữ nguyên ván khi quay về.
7. Kết quả số/ảnh, kỷ lục thời gian, chơi tiếp hoặc chọn cấp độ.
8. Chọn 8 giao diện: gỗ cổ điển, gỗ tối, gốm, cẩm thạch, kim loại, kính, đất sét, neon.
9. Cài đặt chia nhóm (Âm thanh / Trò chơi / Khác): hiệu ứng âm thanh, nhạc nền, âm lượng riêng, rung, số gợi ý trên ảnh và xóa dữ liệu có xác nhận.
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
- `scripts/ui.gd`: font, nút, icon, chip và ô icon màu.
- `scripts/art.gd`: vật liệu ô/khung dựng bằng SVG (vân gỗ, gốm, cẩm thạch, kim loại xước, kính mờ, đất sét, neon), icon màu vẽ riêng, cành nguyệt quế, bảng gỗ logo.
- `scripts/i18n.gd`: đa ngôn ngữ (Tiếng Việt, English). Chuỗi tiếng Việt là khóa; thêm ngôn ngữ mới bằng một bảng ánh xạ.
- `scripts/switch.gd`: công tắc bật/tắt có núm trượt.
- `scripts/animated_button.gd`: hiệu ứng nhấn lún, bật nảy và hover; tôn trọng cài đặt giảm chuyển động.
- `scripts/audio.gd`: tiếng nút, kéo/đặt/trả ô, hoàn thành, nhạc lặp, âm lượng và xử lý focus.
- `scripts/board.gd`: cảm ứng, kéo ô, animation, bo góc ảnh và hiệu ứng thắng.
- `scripts/puzzle.gd`: luật, trộn có seed, đường giải, hoàn tác.
- `scripts/profile.gd`: cài đặt, thống kê và thành tích.
- `scripts/backdrop.gd`: nền theo màn hình.
- `assets/`: ảnh tạo cho dự án, SVG và font Nunito (giấy phép OFL đi kèm).
- `artifacts/`: ảnh chụp các màn và `overview.png` được sinh cục bộ khi chạy kiểm thử hoặc công cụ chụp; không đưa vào Git và không được Godot import vào game. Chỉ `.gdignore` được lưu để giữ thư mục đầu ra khi clone.

## Icon, hiệu ứng nút và âm thanh

Icon điều khiển dùng SVG tải từ **Font Awesome Free 6.7.2**; các icon màu dùng **Google Noto Emoji v2.047**. File gốc giữ nguyên trong `assets/third_party/`. Nguồn và giấy phép được ghi tại **assets/SOURCES.md** và trong mục Cài đặt → Nguồn tài nguyên.

Nút có mặt chuyển sắc và gờ dưới, co nhẹ khi giữ rồi nảy về khi thả. Nhấn nhanh được chặn kích hoạt lặp trong lúc chuyển màn. Hiệu ứng động luôn bật; đây là một phần của thiết kế.

Kéo ô không phát tiếng. Các hiệu ứng ngắn của **Kenney Interface Sounds** phản hồi khi đặt/trả ô, hoàn tác/phục hồi, dùng gợi ý và làm lại ván; mỗi thao tác có âm lượng/cao độ riêng. Tiếng thắng là một đoạn ngắn biên tập từ âm CC0 của Kenney, phát ở kênh riêng và giảm nhạc nền tạm thời. Playlist nhạc nền gồm **Exploration Theme — Cleyton Kauffman**, **Calm Theme — pebonius** và **Waiting II — Kistol**, tự chuyển bài và không lặp liền cùng một bản. Âm lượng nhạc và hiệu ứng chỉnh riêng; dừng khi ứng dụng mất focus. Bản ghi gỗ cũ giữ lại làm tài nguyên dự phòng. Nguồn và giấy phép ở `assets/SOURCES.md`.

Nút dùng shader bo góc với mặt satin, đế mỏng khoảng 1,8 px và ánh sáng chuyển nhẹ; nhấn/nhả và hover được nội suy mềm. Màn kết quả dùng nền tối có ánh vàng, thẻ thống kê chia hàng, huy hiệu NEW và chỉ hai nút Trang chủ / Chơi tiếp cùng hàng. Ô ảnh dùng khe 2,4 px so với 7 px của ô số (tại bàn rộng 390 px), có lớp bắt sáng mỏng được dựng ở độ phân giải cao để tránh viền gắt. Thẻ chọn ảnh phủ kín khung với nhãn dưới lớp tối chuyển sắc; thẻ chọn chất liệu không in số, có dấu chọn xanh ở góc. Chạy kiểm thử app để tạo lại ảnh tổng quan `artifacts/overview.png` và `artifacts/polish-preview.png`.

## Ngôn ngữ

Mặc định theo ngôn ngữ hệ thống (vi → Tiếng Việt, còn lại English); đổi trong Cài đặt → Ngôn ngữ. Nhãn dài được tự thu nhỏ để không xuống hàng sai.

## Kiểm thử

```powershell
$engine = "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe"
& $engine --headless --path . --editor --import
& $engine --headless --path . --script tests/test_puzzle.gd
& $engine --path . --script tests/test_app.gd --quit-after 1800 -- --test-mode
```

Chụp toàn bộ màn hình theo kích thước và ngôn ngữ: `--script tools/capture_screens.gd -- <thư_mục> <vi|en> <rộng> <cao>` (sao lưu và khôi phục dữ liệu người chơi). `tools/art_preview.gd` xuất bảng xem trước vật liệu và icon.

Kiểm thử logic tạo 160 bàn và kiểm tra parity, các bước hợp lệ, undo, phát hiện thắng và toàn bộ đường gợi ý. Kiểm thử app mô phỏng input thật, duyệt các màn, kiểm tra lưu/khôi phục, pause, restart, ảnh riêng, cài đặt, thống kê, thử thách ngày và bố cục 360 × 780. Kiểm thử app sao lưu và khôi phục dữ liệu người dùng; số liệu trên ảnh chụp kết quả/thống kê là dữ liệu kiểm thử.

## Phát hành mobile

### Build plugin chọn ảnh Android

`android/plugins/ImagePicker.gdap` cần file `ImagePicker.aar` nằm cùng thư mục. File `.aar` được tạo cục bộ và không lưu trong Git; sau khi clone repo cần build plugin trước khi mở Godot/export Android để tránh lỗi `Invalid plugin config file ImagePicker.gdap`.

Trên Windows, cài JDK 17 trở lên và Android SDK Platform, rồi chạy từ thư mục dự án:

```powershell
powershell -ExecutionPolicy Bypass -File android/plugin_src/build_aar.ps1
```

Script tìm JDK qua `JAVA_HOME` hoặc PATH; tìm SDK qua `ANDROID_HOME`, `ANDROID_SDK_ROOT`, hoặc `%LOCALAPPDATA%/Android/Sdk`. Có thể chỉ định trực tiếp:

```powershell
./android/plugin_src/build_aar.ps1 -JavaHome 'C:/path/to/jdk-17' -AndroidJar 'C:/path/to/Android/Sdk/platforms/android-35/android.jar'
```

Trên Linux/macOS:

```bash
ANDROID_JAR="$HOME/Android/Sdk/platforms/android-35/android.jar" bash android/plugin_src/build_aar.sh
```

Build thành công sẽ tạo `android/plugins/ImagePicker.aar`. Mở lại Godot và giữ `ImagePicker` bật trong preset Android. Build lại plugin khi sửa Java source.

Dự án dùng Compatibility renderer, hỗ trợ touch và khóa hướng dọc. Chưa đóng gói APK/IPA hoặc đo hiệu năng trên điện thoại thật. Android cần Godot export templates khớp phiên bản, Android SDK và JDK; iOS cần macOS/Xcode. Cần kiểm tra file picker, haptic và vùng an toàn trên thiết bị trước khi phát hành.

## Preview màn hình trên Web

Mở **https://slide-puzzle-backend.vercel.app/preview/** hoặc liên kết **Preview màn hình** trong trang quản trị.
Bản này dùng giao diện Godot thật, chỉ để xem trước các màn hình và background, không cho chơi hoặc lưu ván.
Chỉ có Home và màn chơi (xếp số/xếp ảnh), là các màn dùng background ảnh. Thanh công cụ cho phép chọn theme, ảnh mẫu và ngôn ngữ.
Background theo theme áp dụng cho cả màn chơi xếp số và xếp ảnh; chọn **Làm mới nội dung** để tải cấu hình mới.
Thay đổi đã tải xong được áp dụng tự động, không cần popup cập nhật. URL lưu màn hình/theme/ngôn ngữ đang chọn để có thể chia sẻ.

Xuất và đưa preview mới lên Vercel:

```bash
python3 tools/export_web.py
cd backend
vercel deploy --prod --yes
```

Script sử dụng Godot trong `PATH` (hoặc `--godot /path/to/godot`), tự tải Web template chính thức khớp phiên bản nếu thiếu.
Chỉ phần Web trong archive template được tải về `builds/templates/`; không cần cài template cho các nền tảng khác.
Dùng `--offline` khi template đã có sẵn. File export đặt tại `backend/public/preview/`, không commit vào Git.
Sau khi clone repo hoặc sửa mã Godot, cần chạy lại script trước khi deploy backend để có preview tương ứng.

Web dùng scene `web_preview.tscn` và profile chỉ lưu trong bộ nhớ, tách khỏi scene chơi trên Android.
Cache nội dung có thể lưu trong IndexedDB để lần mở sau nhanh hơn; không đọc/ghi tiến trình chơi.
Canvas giữ tỷ lệ 430×900, tự co theo bề rộng cửa sổ. Preview cần WebAssembly và WebGL 2, được phục vụ qua HTTP/HTTPS.
Bản export chạy một luồng nên không yêu cầu header cô lập cross-origin.

Kiểm thử scene preview:

```bash
XDG_DATA_HOME=/tmp/slide-preview-tests godot --headless --path . --script tests/test_web_preview.gd -- --test-mode
```

Tài liệu Godot: [Web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html),
[custom HTML shell](https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html).
