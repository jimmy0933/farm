# 寶可夢小小探險隊

4 歲幼兒專用、**繁體中文語音優先**的 Godot 4.5.2 Android 親子遊戲。這是從零重建的全新遊戲，不是前一版 Farm APK 的介面修改。

## 遊戲內容

- **認識朋友**：12 隻寶可夢的大圖片卡，點圖片直接語音介紹。包含屬性、身高（以公分唸出）、體重、特性及招式說明，按一下就能重聽。
- **聽聲音找朋友**：聽問題後從 3 隻寶可夢選對答案；答錯只會鼓勵再試一次，不會扣分或淘汰。
- **照顧朋友**：吃點心、玩耍、休息、打招呼。每次互動獲得愛心。
- **愛心貼紙館**：儲存 12 位朋友的互動愛心數，資料只存在手機本機。
- 全程無廣告、無付費、無遊戲內帳號。設計給橫向手機／平板；主要按鈕大型化。

## 十二隻角色

皮卡丘（25）、耿鬼（94）、伊布（133）、椰蛋樹（103）、敲音猴（810）、傑尼龜（7）、呆呆獸（79）、哥德寶寶（574）、小火龍（4）、水箭龜（9）、可達鴨（54）、長尾怪手（190，對應口語所說的「怪尾猴」）。資料中的身高、體重、屬性、一般特性參照 [台灣寶可夢官方圖鑑](https://tw.portal-pokemon.com/play/pokedex/)，招式以常見招式作簡化語音解說；不同世代／遊戲版本的可習得招式可能不同。

## 圖片、字型與版權

- 寶可夢立繪由 `tools/download_assets.py` 在**本機或 CI 建置時**下載，來源為 [PokéAPI sprites](https://github.com/PokeAPI/sprites) 的 official-artwork 路徑。官方圖鑑作為外觀核對參考。
- 繁體中文介面字型由 [Noto CJK](https://github.com/googlefonts/noto-cjk) 取得，採用其個別開源字型授權。
- 角色／名稱／官方圖像屬其權利人。僅供家中私人使用、未經寶可夢官方授權。不在商店上架**不等於**自動沒有著作權；若要公開散布，應先確認使用授權。
- 官方圖片與字型不提交到 Git 原始碼庫。建置後的 APK 如包含官方圖片，也應注意其散布權限。

## GitHub Actions

每次推送 `main` 或手動啟動 workflow：Python 資料驗證 → 下載圖片及繁體字型 → 安裝 Godot 4.5.2 與 Android SDK → 驗證 Godot 場景 → 從 Repository Secrets 使用固定 keystore 匯出簽章 APK → `apksigner verify` 驗證 → 發布新版 Release → 刪除舊 Release 和舊 tag。

所需 Repository Secrets：`KEYSTORE_BASE64`、`KEYSTORE_PASSWORD`、`KEY_ALIAS`、`KEY_PASSWORD`。不可將金鑰與密碼提交至版本庫。已安裝的舊 APK 使用相同 package name `com.jimmy0933.animalisland` 以盡量支援覆蓋更新，實際還需簽章相同。

在本機執行 `python3 tools/download_assets.py` 後可用 Godot 4.5.2 開啟 `project.godot`。語音使用 Android 系統 `TextToSpeech`，**需要手機已安裝／啟用繁體中文語音引擎**；語音不可用時仍有字幕，但不能保證語音可正常播出。沒有在 Android 實機測試前，不應宣稱語音通過驗收。
