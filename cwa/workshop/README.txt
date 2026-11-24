中央氣象署 OCP Quickstart / Podman 實作包

本次課堂請先閱讀同一教材資料夾中的「06_學員精簡操作手順.pdf」。
課程總長 180 分鐘，與八月原簡報搭配使用。

精簡主線（約 60 分鐘）：
  講師先依 quickstart-instructor.txt 完成準備，提供各人的 quickstart.env。
  學員在 workshop/ 目錄依 quickstart-steps.txt 五步操作：
  確認環境 → Podman 建置 → 推送 Registry → 部署 OCP → HTTPS 驗證。
  建置段落包含 Containerfile、requirements.txt、pip 安裝、映像檢查與 podman tag。
  本主線推送及拉取皆使用 quay.io/cwa/ocp/cwa-weather:1.0，並建立全新 1Gi PVC。
  講師填妥 quickstart.env 的 Quay 帳號與個人 Project，密碼／Token 另外配發。
  Private Quay Repository 的 OCP 拉取認證由講師課前備妥。
  每一步核對成功檢查點，再繼續下一步；原完整版講義保持不變。

Python 套件已整合於同一流程：
  app/Containerfile 讀取 app/requirements.txt，在 /opt/venv 安裝 requests。
  一律使用 localhost/cwa-weather:1.0 建置、驗證，再標記成指定 Quay 位址。
  套件來源、快取與離線方式在同一份手順的最後一頁。
  OCP 驗收會檢查 requests 版本；建置時需連線 PyPI／組織套件來源。

範例使用模擬氣象資料，不需要 CWA API 金鑰、資料庫或 GPU。
示範伺服器僅供教學；正式服務請改用組織核准的應用框架與伺服器。

完整實作／課後延伸（依原「01_學員實作講義.pdf」選用）：
原完整講義保留作參考；課堂操作與最新版 Containerfile 以 06 手順為準。
1. 在 Linux 練習主機解壓縮教材，切換到 workshop/。
2. 先依 podman-local-only.txt 完成純本機備課，不需要 OCP 與 Registry 帳號。
3. 有部署環境後，cp workshop.env.example workshop.env。
4. 編輯 Project、Registry、Repository、ARCH，執行 source workshop.env。
5. 再依學員講義 Lab 3-9 操作；Windows/macOS 建議 SSH 至相同 Linux 主機。

主要檔案：
  app/app.py                 氣象觀測 API，Python 標準函式庫
  app/Containerfile          UBI 9 / Python 3.12 映像建置檔
  app/requirements.txt      Python 套件清單，建置時透過 pip 安裝
  app/.containerignore       限制建置內容
  k8s/serviceaccount.yaml    專用 ServiceAccount
  scripts/render.py          預設產生 PVC、ConfigMap、Deployment、Service、Route
  scripts/preflight.sh       --local 檢查本機，--ocp 檢查部署權限
  commands.txt              與講義一致的完整操作指令
  podman-local-only.txt      不需要 OCP 的本機備課完整指令
  quickstart-steps.txt       課堂五步精簡操作指令
  quickstart.env.example    講師填寫的學員環境參數範本
  quickstart-instructor.txt 精簡手順的講師準備清單與授課時程

三個容易混淆的重點：
  - 本機 podman login 與 OCP Pod 拉取映像使用不同的認證。
  - podman load 只匯入本機映像儲存區，OCP 節點仍需從 Registry 拉取映像。
  - ConfigMap 以環境變數載入時，更新資料後需要重新啟動 Pod。

清理範圍僅為 workshop=cwa-podman 標籤的本課程資源，不刪除 Project。
共用環境中每位學員使用獨立 Project；本次 Quay 共用固定 1.0 Tag，由講師安排推送順序。

OCP 內建 Registry 已有額外實測路徑：ocp-integrated-registry.txt。
以相同 app、Containerfile 與 render.py 於 OCP 4.20.39 / amd64 通過驗證。

儲存增補：
  請先看 storage-lab.txt，容器與 OCP 使用相同 /opt/app/data 路徑。
  render.py 預設建立 1Gi PVC，StorageClass 動態供應 PV，Deployment 使用 Recreate。
  --storage emptydir 為暫存對照；--storage-class 指定類別；--maintenance 產生維護 Pod。
  範例保留資料，不自動刪除 PVC 或 named volume。
