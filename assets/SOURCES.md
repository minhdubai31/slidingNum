# Tài nguyên tải từ internet

## Icon điều khiển — Font Awesome Free 6.7.2

- Tác giả: Fonticons, Inc.
- Nguồn: https://github.com/FortAwesome/Font-Awesome/tree/6.7.2/svgs/solid
- Giấy phép SVG: CC BY 4.0. Bản giấy phép của nguồn: `licenses/Font-Awesome-LICENSE.txt`.
- File gốc trong `third_party/fontawesome/`; giữ nguyên dữ liệu và comment ghi nguồn. Game chỉ rasterize, đổi màu và thu/phóng lúc chạy.
- Dùng cho Home, pause, play, quay lại, trộn số, xem ảnh, làm lại, undo, cài đặt, đồng hồ, bước đi, lưới, âm lượng, công tắc và các điều khiển khác.

## Icon màu — Google Noto Emoji v2.047

- Tác giả: Google.
- Nguồn: https://github.com/googlefonts/noto-emoji/tree/v2.047/svg
- README của nguồn công bố phần hình ảnh theo Apache 2.0; font theo OFL. Giữ kèm README, LICENSE gốc và bản Apache 2.0 trong `licenses/`.
- File gốc trong `third_party/noto/`; đổi tên file để ánh xạ ngắn gọn, không vẽ lại đường nét.
- Dùng cho bóng đèn, cúp, lịch, bảng màu, biểu đồ, sao, tia chớp và icon ứng dụng.

## Hiệu ứng âm thanh — Kenney Interface Sounds 1.0

- Tác giả: Kenney, https://kenney.nl/assets/interface-sounds
- Giấy phép: CC0; xem `licenses/Kenney-CC0.txt`.
- Bản WAV từ gói chuyển đổi cho Godot: https://github.com/Calinou/kenney-interface-sounds
- `click_003.wav`: nút bấm.
- `confirmation_001.wav`: tín hiệu gợi ý nhẹ.
- `drop_003.wav`: đặt ô; `back_001.wav`: trả ô và hoàn tác; `drop_004.wav`: phục hồi và làm lại. Âm lượng/cao độ phân biệt theo thao tác.
- `success-soft.wav`: đoạn thắng ngắn ghép ba lần phát lên cao dần từ `confirmation_001.wav`, có fade mềm và giới hạn đỉnh; tái tạo bằng `tools/prepare_success_audio.py`. Nguồn CC0 như trên.
- Không phát âm thanh trong lúc kéo ô. `scratch_001.wav` và hai file `wood-*.wav` hiện là tài nguyên dự phòng.
- Các file Kenney gốc giữ nguyên; âm lượng và cao độ được điều chỉnh trong game. File `success-soft.wav` là bản biên tập riêng từ nguồn CC0.

## Tiếng quân gỗ trượt — Board Game Wood Piece Slide

- Tác giả: Jeff Final Boss / El Final Boss.
- Nguồn: https://licensing.routenote.com/sound-effect/board-game-wood-piece-slide
- Giấy phép: CC0. Ghi nguồn và mô tả chỉnh âm trong `licenses/Wood-Piece-Slide-CC0.txt`.
- Đây là bản ghi quân cờ trượt trên bàn được dùng ở phiên bản trước; hiện giữ lại làm tài nguyên dự phòng.
- `audio/wood-slide-soft.wav`: lọc bớt phần chói và tiếng trầm thừa, fade hai đầu, giảm đỉnh âm. Hiện không phát trong game.
- `audio/wood-place-soft.wav`: đoạn tiếp xúc ngắn, tài nguyên dự phòng, hiện không phát trong game.
- File MP3 gốc được giữ ở `audio/source/`; công cụ tái tạo WAV trong `tools/`.

## Nhạc nền — Exploration Theme

- Tác giả: Cleyton Kauffman, https://soundcloud.com/cleytonkauffman
- Nguồn: https://opengameart.org/content/exploration-theme
- Giấy phép: CC0. Ghi chú gốc trong `licenses/Exploration-Theme-readme.txt`.
- File Ogg gốc được đổi tên thành `audio/exploration-theme.ogg`, không cắt/biên tập nhạc.
- Ambient/piano dài khoảng 2 phút 14 giây, được tác giả thiết kế để lặp. Trong playlist, game chuyển bài khi bản nhạc kết thúc. Game phát nhỏ, giảm âm khi mở hộp thoại và dừng khi ứng dụng mất focus.

Danh mục và SHA256 của các file tải về nằm trong `third-party-manifest.json`. Có mục **Nguồn tài nguyên** trong màn Cài đặt.

Các tranh nền, ảnh ghép và hình cúp minh họa lớn từ MVP trước vẫn được giữ riêng; chúng không thuộc các bộ icon nói trên. Font Nunito tiếp tục dùng giấy phép OFL đã đi kèm dự án.

## Visual refresh 0.6

- Six color icons: Microsoft Fluent Emoji 3D, https://github.com/microsoft/fluentui-emoji . MIT license at `licenses/Fluent-Emoji-MIT.txt`. Original PNGs retained; mipmaps enabled for smooth small-scale rendering.
- `home-soft.png`, `table-soft.png`, `kitten-soft.png`, `trophy-soft.png`: generated game artwork, replacing the previous high-detail background/cat/trophy in the UI. Originals remain in the project.
- Material tiles, beveled photo overlays and ribbon: native project vector graphics; rendered at higher resolution and mipmapped for softer edges.

## Nhạc nền bổ sung

- **Calm Theme — pebonius**, CC0: https://opengameart.org/content/calm-music-0 ; `audio/calm-theme.ogg`.
- **Waiting II — Kistol**, CC0: https://opengameart.org/content/waiting-ii ; `audio/waiting-ii.ogg`.
- Giữ nguyên bản Ogg. Thông tin giấy phép: `licenses/Additional-Music-CC0.txt`.
- Game tự chuyển giữa ba soundtrack khi hết bài, không phát hai lần liên tiếp cùng một bản; giữ điều khiển âm lượng, giảm nhạc lúc thắng/tạm dừng và tiếp tục khi trở lại ứng dụng.

## Icon ứng dụng — Slide Puzzle

- `branding/slide-puzzle-icon.png`: icon gỗ 1–2–3 và ô trống, tạo riêng bằng công cụ imagegen ngày 22/10/2026.
- Prompt và bản gốc lưu tại `publishing/google-play/ICON.md` và `publishing/google-play/icon-master.png`.
- Bản 512×512 để tải lên Google Play: `publishing/google-play/icon-512.png`.

### Bộ icon adaptive / nhiều hình dạng

- `branding/slide-puzzle-icon-adaptive.png` là icon chính mới; các lớp Android gồm `slide-puzzle-adaptive-foreground.png`, `slide-puzzle-adaptive-background.png` và `slide-puzzle-monochrome.png`.
- Foreground được tách bằng imagegen từ icon gỗ đã tạo; monochrome có source SVG cùng thư mục.
- Bộ xuất Google Play, Windows, macOS và bản mô phỏng mask: `publishing/icons/`; hướng dẫn và prompt tại `publishing/icons/README.md`.
