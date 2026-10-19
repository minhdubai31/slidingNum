class_name SlideI18n
extends RefCounted

# Vietnamese source strings are the keys; other languages map from them.
# Strings that are formatted with % are translated before formatting.

const LANGUAGES = {"vi": "Tiếng Việt", "en": "English"}
static var language: String = "vi"

static func detect() -> String:
	return "vi" if OS.get_locale_language() == "vi" else "en"

static func t(value: String) -> String:
	if language == "vi" or value.is_empty():
		return value
	return EN.get(value, value)

const EN = {
	# Home & navigation
	"Xếp số · Xếp ảnh · Thư giãn mỗi ngày": "Numbers · Pictures · Relax every day",
	"Mỗi bước nhỏ, một niềm vui.": "Every little move, a little joy.",
	"Đang chuẩn bị những mảnh ghép…": "Preparing the pieces…",
	"Xếp số": "Numbers",
	"Xếp ảnh": "Pictures",
	"Thử thách logic\nvới những con số": "A logic challenge\nwith numbers",
	"Khám phá những\nhình ảnh tuyệt đẹp": "Piece together\nbeautiful pictures",
	"Tiếp tục ván đang chơi": "Continue current game",
	"Thành tích": "Achievements",
	"Thử thách\nhằng ngày": "Daily\nchallenge",
	"Giao diện": "Themes",
	"Cài đặt": "Settings",
	# Levels & gallery
	"%d ô số": "%d tiles",
	"%d mảnh ghép": "%d pieces",
	"Dễ": "Easy",
	"Trung bình": "Medium",
	"Khó": "Hard",
	"Chạm vào cấp độ để bắt đầu. Mỗi bàn đều có lời giải.": "Tap a level to start. Every board is solvable.",
	"Chọn chủ đề ảnh": "Choose a picture",
	"Thiên nhiên": "Nature",
	"Thú cưng": "Pets",
	"Du lịch": "Travel",
	"Sa mạc": "Desert",
	"Hoa lá": "Flowers",
	"Vũ trụ": "Space",
	"1 ảnh": "1 picture",
	"Chọn ảnh từ thiết bị": "Pick from device",
	"Ảnh của bạn": "Your picture",
	# Game
	"Trộn số": "Shuffle",
	"Xem ảnh": "Peek",
	"Gợi ý": "Hint",
	"Làm lại": "Restart",
	"Vuốt hoặc chạm ô cạnh khoảng trống": "Swipe or tap a tile next to the gap",
	"Di chuyển ô đang sáng vào khoảng trống": "Move the glowing tile into the gap",
	"Tuyệt vời! Bạn đã hoàn thành.": "Wonderful! You did it.",
	"THỬ THÁCH NGÀY ": "DAILY CHALLENGE · ",
	"Trộn lại bàn?": "Shuffle the board?",
	"Bạn sẽ bắt đầu một ván mới.": "This starts a new game.",
	"Hủy": "Cancel",
	"Tạm dừng": "Paused",
	"Ván chơi đã được lưu. Bạn muốn làm gì?": "Your game is saved. What would you like to do?",
	"Tiếp tục": "Resume",
	"Về màn hình chính": "Back to home",
	"Chơi lại từ đầu?": "Start over?",
	"Giữ nguyên bàn xếp; đặt lại bước đi và thời gian.": "Keeps the same board; resets moves and time.",
	"Bắt đầu ván mới?": "Start a new game?",
	"Ván đang chơi sẽ được thay thế.": "Your current game will be replaced.",
	"Bắt đầu": "Start",
	"Giữ ván hiện tại": "Keep current game",
	# Result
	"Hoàn thành!": "Complete!",
	"Thời gian": "Time",
	"Số bước": "Moves",
	"Kích thước": "Size",
	"Kỷ lục mới": "New record",
	"Trang chủ": "Home",
	"Chơi tiếp": "Play again",
	# Themes
	"Chọn giao diện": "Choose a theme",
	"Gỗ cổ điển": "Classic wood",
	"Gỗ tối": "Dark wood",
	"Gốm sứ": "Porcelain",
	"Đá cẩm thạch": "Marble",
	"Kim loại": "Metal",
	"Kính mờ": "Frosted glass",
	"Đất sét": "Clay",
	"Neon": "Neon",
	# Settings
	"Âm thanh": "Sound",
	"Trò chơi": "Gameplay",
	"Khác": "More",
	"Hiệu ứng âm thanh": "Sound effects",
	"Nhạc nền": "Music",
	"Rung khi di chuyển": "Vibrate on move",
	"Hiệu ứng động": "Animations",
	"Hiện số khi xếp ảnh": "Numbers on pictures",
	"Ngôn ngữ": "Language",
	"Hướng dẫn chơi": "How to play",
	"Nguồn tài nguyên": "Credits",
	"Xóa dữ liệu trò chơi": "Erase game data",
	"Chơi ngoại tuyến. Tiến trình và ảnh riêng được lưu trên thiết bị.": "Plays offline. Progress and your pictures stay on this device.",
	"SLIDE PUZZLE · Phiên bản %s": "SLIDE PUZZLE · Version %s",
	"Đóng": "Close",
	"Xóa toàn bộ dữ liệu?": "Erase all data?",
	"Xóa tiến trình, thống kê, cài đặt và ảnh đã nhập trên thiết bị. Không thể hoàn tác.": "Removes progress, statistics, settings and imported pictures from this device. This cannot be undone.",
	"Xóa dữ liệu": "Erase data",
	"Giữ lại": "Keep",
	"Không mở được ảnh": "Couldn't open the picture",
	"Hãy thử một ảnh PNG, JPG hoặc WebP khác.": "Try another PNG, JPG or WebP picture.",
	"Icon: Font Awesome Free 6.7.2 · Fonticons (CC BY 4.0)\nIcon màu: vẽ riêng cho dự án · Microsoft Fluent Emoji (MIT) · Google Noto Emoji (Apache 2.0)\nTiếng gỗ: Board Game Wood Piece Slide · Jeff Final Boss (CC0)\nÂm thanh nút: Kenney Interface Sounds (CC0)\nNhạc: Exploration Theme · Cleyton Kauffman (CC0)\nFont: Nunito (OFL)\n\nNguồn và giấy phép đầy đủ đi kèm dự án.": "Icons: Font Awesome Free 6.7.2 · Fonticons (CC BY 4.0)\nColour icons: drawn for this project · Microsoft Fluent Emoji (MIT) · Google Noto Emoji (Apache 2.0)\nWood sounds: Board Game Wood Piece Slide · Jeff Final Boss (CC0)\nButton sounds: Kenney Interface Sounds (CC0)\nMusic: Exploration Theme · Cleyton Kauffman (CC0)\nFont: Nunito (OFL)\n\nFull sources and licences ship with the project.",
	# Stats
	"Thống kê": "Statistics",
	"Đã hoàn thành": "Completed",
	"Nhanh nhất": "Fastest",
	"Ít bước nhất": "Fewest moves",
	"Người mới bắt đầu": "First steps",
	"Nhanh như chớp": "Lightning fast",
	"Chuyên gia 4 × 4": "4 × 4 expert",
	"Hoàn thành 1 màn chơi": "Finish 1 game",
	"Hoàn thành trong 1 phút": "Finish within 1 minute",
	"Hoàn thành với ≤ 50 bước": "Finish in ≤ 50 moves",
	"Hoàn thành 10 màn 4 × 4": "Finish ten 4 × 4 games",
	"%d/4 đã mở": "%d/4 unlocked",
	# Help
	"Hướng dẫn": "How to play",
	"Cách chơi": "Basics",
	"Chạm hoặc vuốt ô nằm cạnh khoảng trống để di chuyển.": "Tap or swipe a tile next to the gap to move it.",
	"Xếp các số tăng dần từ trái sang phải, từ trên xuống dưới; để trống ô cuối.": "Order the numbers left to right, top to bottom, leaving the last cell empty.",
	"Với xếp ảnh, ghép các mảnh thành ảnh gốc. Giữ nút Xem ảnh để xem mẫu.": "In picture mode, rebuild the picture. Hold Peek to see it whole.",
	"Một bước nữa là hoàn thành": "One move to go",
	"Gợi ý làm sáng một ô có thể đi theo đường giải. Mỗi ván có 3 lượt gợi ý. Hoàn tác không giới hạn; Làm lại đưa bạn về bàn ban đầu.": "Hint lights up a tile on the solving path. You get 3 hints per game. Undo is unlimited; Restart returns to the starting board.",
	"Đã hiểu, chơi thôi!": "Got it, let's play!",
	# Daily
	"Thử thách hằng ngày": "Daily challenge",
	"Hôm nay, %s": "Today, %s",
	"Một bức ảnh. Một thử thách mới mỗi ngày.": "One picture. A new challenge every day.",
	"Bạn đã chinh phục hôm nay!": "You conquered today's puzzle!",
	"Ghép khung cảnh núi hồ · 3 × 3": "Mountain lake scene · 3 × 3",
	"Chơi lại thử thách": "Play again",
	"Hoàn thành 7 ngày liên tiếp để mở quà": "Finish 7 days in a row to open the gift",
	"Tuần hoàn hảo!": "A perfect week!",
	"Cùng một bàn xếp cho mỗi ngày. Những ngày hoàn thành sẽ được đánh dấu trên thiết bị.": "Everyone gets the same board each day. Finished days are marked on this device.",
}

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

static func date(day: int, month: int, year: int) -> String:
	if language == "en":
		return "%s %d, %d" % [MONTHS[clampi(month - 1, 0, 11)], day, year]
	return "%d tháng %d, %d" % [day, month, year]
