# 雲端後端設定

1. 建立 Supabase 專案。
2. 開啟專案 Dashboard 的 SQL Editor，執行本資料夾的 `schema.sql` 全部內容。若你已經執行過舊版 schema，請改為執行 `migrations/20261121_security_hardening.sql`，不必刪除資料。
3. 到 Project Settings → API，複製 Project URL 與 Publishable Key。
4. 開啟遊戲 → 社交 → 星願雲端帳號，貼上 URL 和 Publishable Key，儲存連線設定。
5. 使用 Email 和密碼註冊；若啟用 Email 確認，先完成信箱驗證再登入。
6. 登入後按「上傳目前存檔」。換裝置時登入同一帳號，再按「載入雲端存檔」。

沒有設定後端時，遊戲仍可離線遊玩。瀏覽器端只使用 Publishable Key，資料存取由資料列安全政策（RLS）與最小權限資料庫授權共同保護。\n\n## 本輪安全更新\n\n- 公會建立時由資料庫自動加入會長，客戶端不能把自己升成會長或幹部。\n- 好友邀請只能由接收者修改狀態，且資料庫欄位權限限制只能更新狀態與時間。\n- 玩家不能直接寫入官方排行榜分數；目前排行榜是唯讀測試榜。\n- 對 `anon` 與 `authenticated` 撤銷寬泛資料表權限，再逐項授予必要權限。

## 正式上線前仍需完成

此初始資料庫提供帳號個人資料、雲端存檔、好友邀請、公會成員與排行榜資料表。目前戰鬥與抽卡經濟仍在瀏覽器端運算，修改過的客戶端仍可能偽造獎勵與進度。正式公開競技前，必須把抽卡結果、獎勵發放、進度驗證與排行榜計分移至可信任的 Edge Functions 或伺服器端驗證。絕不可把 Supabase Secret/Service Role Key 放進 GitHub Pages 前端。
