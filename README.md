# Farm 動物探險島 (APK 參考重建版)

這是由使用者提供的 `AnimalAdventureIsland-signed (4).apk` **參考重建**的可編輯 Godot 專案，不是原始碼完整還原。

## APK 已確認的資訊

- 原 APK 版本：`0.6.404`
- 引擎：Godot `4.5.2.stable`
- Android package：`com.jimmy0933.animalisland`
- APK 內提供原始 JSON：43 筆動物、12 筆鳥類、12 筆怪獸與 43 筆學習關卡
- 13 隻寶可夢的重建索引（非原版官方圖片資料）
- 大部分 `.gd` 原始碼僅以編譯後的 `.gdc` 形式存在，無法直接修改

## 本專案提供的基礎功能

- 動物、鳥類、怪獸、寶可夢圖鑑與分區瀏覽
- 點選介紹、文字轉語音（支援裝置）、餵食與互動提示
- 私人農場收集角色及本機儲存
- 12 格簡易農田
- JSON 學習題庫
- 三車道簡易賽車、繪畫塗鴉
- Godot 4.5.2 Android arm64 簽章與 CI 發布工作流程

**限制**：目前 UI、動物繪圖、賽車與大部分互動均為重新實作的基礎版，**不是原 APK 的高精度場景、完整動畫、原版效果或遊戲規則**。原 APK 的 Godot 編譯後腳本無法直接以人可閱讀的原始碼移入本專案。不要用這個資料夾覆蓋未經檢查的現有 Farm 專案。

## 使用方法

1. 使用 Godot 4.5.2 開啟 `project.godot`。
2. 執行 `python3 tests/check_data.py` 確認資料。
3. GitHub Actions 工作流程位於 `.github/workflows/release-android.yml`。
4. `Actions → Run workflow` 可觸發 Android Release，成功後只保留最新一個 GitHub Release。

### GitHub Actions Secrets

設定在 **目標 Farm Repository 的 Actions Secrets**，金鑰絕不可提交到 Git：

| Secret | 用途 |
| --- | --- |
| `KEYSTORE_BASE64` | keystore 檔案的 Base64 |
| `KEYSTORE_PASSWORD` | keystore 密碼 |
| `KEY_ALIAS` | 簽章別名 |
| `KEY_PASSWORD` | 簽章私鑰密碼 |

Godot 4.5 的 Android Export 需要 `KEYSTORE_PASSWORD` 與 `KEY_PASSWORD` 相同。這項工作流程會在不相同時直接停止，避免錯誤簽署。

**Android 更新注意**：即使套件名稱與舊 APK 相同，若 Actions 新設的簽章金鑰與原 APK 不同，就無法直接覆蓋安裝舊版本。升級前要先確認原版簽章與資料備份。

## 整合到 `jimmy0933/farm` 的建議

本重建版以新建立的 `jimmy0933/farm` 專案為目標。預設 `main` 推送後由 GitHub Actions 執行 Android 簽章與 Release 發布；**只有新版成功才會刪掉舊的 GitHub Releases 和所屬 Tag**。如 Actions 建置失敗，可在 Actions 日誌檢查原因，舊版 Release 會保留。

> 原 APK 的畫面和圖像若由腳本程式動態繪製，不能只靠 APK 的 PNG 圖檔恢復；本專案的圖像是新的簡化替代版本。
