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
	"Chính sách quyền riêng tư": "Privacy Policy",
	"Có nội dung mới": "New content available",
	"Nội dung mới đã được tải sẵn. Tải lại để áp dụng cập nhật.": "New content has been downloaded. Reload to apply the update.",
	"Tải lại": "Reload",
	"Để sau": "Later",
	"Đang tải…": "Loading…",
	"Xóa ảnh": "Delete picture",
	"Xóa ảnh?": "Delete picture?",
	"Xóa ảnh và thành tích của ảnh này?": "Delete this picture and its records?",
	"Ảnh đang dùng trong ván hiện tại. Xóa ảnh sẽ xóa cả ván đang chơi và thành tích của ảnh.": "This picture is in your current game. Deleting it also removes that game and this picture's records.",
	"Không xóa được ảnh": "Couldn't delete the picture",
	"Thử lại sau.": "Try again later.",
	# Home & navigation
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
	"Rất khó": "Expert",
	"Chọn chủ đề ảnh": "Choose a picture topic",
	"Thiên nhiên": "Nature",
	"Thú cưng": "Pets",
	"Du lịch": "Travel",
	"Sa mạc": "Desert",
	"Hoa lá": "Flowers",
	"Vũ trụ": "Space",
	"1 ảnh": "1 picture",
	"%d ảnh": "%d pictures",
	"Của bạn": "Yours",
	"Chưa có ảnh": "No pictures yet",
	"Nhanh nhất: %s": "Best: %s",
	"Chưa hoàn thành": "Not completed",
	"Thêm ảnh cá nhân": "Add your pictures",
	"Không lưu được ảnh": "Couldn't save the picture",
	"Hãy kiểm tra dung lượng trống trên thiết bị.": "Check the free space on your device.",
	"Chọn ảnh từ thiết bị": "Pick from device",
	"Ảnh của bạn": "Your picture",
	# Game
	"Trộn số": "Shuffle",
	"Xem ảnh": "Peek",
	"Gợi ý": "Hint",
	"Làm lại": "Restart",
	"Di chuyển ô đang sáng vào khoảng trống": "Move the glowing tile into the gap",
	"THỬ THÁCH NGÀY ": "DAILY CHALLENGE · ",
	"Trộn lại bàn?": "Shuffle the board?",
	"Tiến trình ván hiện tại sẽ bị mất.": "Your current progress will be lost.",
	"Hủy": "Cancel",
	"Tạm dừng": "Paused",
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
	"SLIDE PUZZLE · Phiên bản %s": "SLIDE PUZZLE · Version %s",
	"Đóng": "Close",
	"Xóa toàn bộ dữ liệu?": "Erase all data?",
	"Xóa tiến trình, thống kê, cài đặt và ảnh đã nhập trên thiết bị. Không thể hoàn tác.": "Removes progress, statistics, settings and imported pictures from this device. This cannot be undone.",
	"Xóa dữ liệu": "Erase data",
	"Giữ lại": "Keep",
	"Không mở được ảnh": "Couldn't open the picture",
	"Hãy thử một ảnh PNG, JPG hoặc WebP khác.": "Try another PNG, JPG or WebP picture.",
	"Icon: Font Awesome Free 6.7.2 · Fonticons (CC BY 4.0)\nIcon màu: vẽ riêng cho dự án · Microsoft Fluent Emoji (MIT) · Google Noto Emoji (Apache 2.0)\nTiếng gỗ: Board Game Wood Piece Slide · Jeff Final Boss (CC0)\nÂm thanh nút: Kenney Interface Sounds (CC0)\nNhạc: Exploration Theme · Cleyton Kauffman; Calm Theme · pebonius; Waiting II · Kistol (CC0) (CC0)\nFont: Nunito (OFL)": "Icons: Font Awesome Free 6.7.2 · Fonticons (CC BY 4.0)\nColour icons: drawn for this project · Microsoft Fluent Emoji (MIT) · Google Noto Emoji (Apache 2.0)\nWood sounds: Board Game Wood Piece Slide · Jeff Final Boss (CC0)\nButton sounds: Kenney Interface Sounds (CC0)\nMusic: Exploration Theme · Cleyton Kauffman; Calm Theme · pebonius; Waiting II · Kistol (CC0) (CC0)\nFont: Nunito (OFL)",
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
	"Gợi ý làm sáng ô cần di chuyển. Mỗi ván có 3 lượt. Hoàn tác không giới hạn. Làm lại đưa bàn về trạng thái ban đầu.": "Hint highlights the tile to move. You get 3 hints per game. Undo is unlimited. Restart resets the board.",
	"Chơi": "Play",
	# Daily
	"Thử thách hằng ngày": "Daily challenge",
	"Hôm nay, %s": "Today, %s",
	"Chơi lại thử thách": "Play again",
}

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

static func date(day: int, month: int, year: int) -> String:
	if language == "en":
		return "%s %d, %d" % [MONTHS[clampi(month - 1, 0, 11)], day, year]
	return "%d tháng %d, %d" % [day, month, year]
