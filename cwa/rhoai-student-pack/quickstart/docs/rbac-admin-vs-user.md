# OpenShift AI：Admin 與 User 權限差異（RBAC）

> **文件格式**：本檔在 `docs/`（Markdown）。JupyterLab 對應檔在 `docs-ipynb/`。

> **對象**：客戶環境常見兩種身分——**Admin（管理員）**與 **User（資料科學使用者）**  
> **目的**：上課與落地時分清「誰做平台事、誰做專案內 AI 事」，避免學員卡在看不到選單、或誤以為人人都能 Import 映像  
> **對應**：RHOAI 3.4 · 本包 `quickstart/` 以 **User 手作**為主，**Admin 課前準備**  
> **先讀**：[OCP 與 OAI 的 RBAC 差異](rbac-ocp-vs-oai.md)（兩層權限別混；本文偏課堂職責）

---

## 一句話

| 角色 | 白話 |
|------|------|
| **Admin** | 管**平台與叢集級**設定：開元件、Import 映像、Hardware Profile、給帳號權限 |
| **User** | 在**自己的 Data Science 專案**裡做事：Workbench、訓練、Deploy、PVC、Pipeline |

本教學（單元 A／B）預設學員是 **User**；標成「管理員／講師」的步驟請 **Admin** 先做完。

這裡的 Admin／User 主要指 **OAI（Dashboard）** 角色。同一帳號在 **OCP** 上還有另一套 RoleBinding——詳見 [OCP vs OAI](rbac-ocp-vs-oai.md)。

---

## 客戶常見兩種帳號怎麼對

實際叢集上的群組／角色名稱可能因 IdP 與安裝略有不同，對客戶說明時可用下表：

| 客戶口語 | OpenShift AI（OAI）常見對應 | OpenShift（OCP）常見對應 | 注意 |
|----------|----------------------------|--------------------------|------|
| **Admin** | 例如群組 **`rhods-admins`** → 有 Dashboard **Settings** | 常另具 **`cluster-admin`** 或足夠叢集權（除錯用） | OCP 很強 **≠** 自動就是 OAI Admin |
| **User** | Data Science 使用者（可進 Dashboard、建專案） | 專案內 **`admin` / `edit`** 即可 | 專案 `admin` **仍不是** OAI Settings |

> 若貴司命名不同（例如「平台組／業務組」），OAI 側可對齊「能不能進 **Dashboard → Settings**」；OCP 側對齊「能不能動哪些 Project／叢集資源」。

---

## 能做／不能做對照（教學相關）

| 操作 | Admin | User（學員） | 本包哪裡用到 |
|------|:-----:|:------------:|------------------|
| 登入 **OpenShift AI Dashboard** | ✅ | ✅ | 全部單元 |
| 建立／進入 **自己的 Project** | ✅ | ✅ | 單元 A |
| **Create workbench**、Cluster storage、Deploy model | ✅ | ✅（在有權專案內） | 單元 A／B |
| 跑 Notebook、Workbench Terminal `curl` | ✅ | ✅ | 單元 A／B |
| **Configure pipeline server**（專案內） | ✅ | ✅（若被授權） | **單元 A-2**（建 Workbench **之前**） |
| Dashboard **Settings**（平台設定） | ✅ | ❌ | — |
| **Import Workbench image**（自訂映像目錄） | ✅ | ❌ | 離線／自訂映像（若使用） |
| 啟用 KServe、Pipelines 等元件 | ✅ | ❌ | 課前 |
| 建立／管理 **Hardware Profile** | ✅ | ❌（通常） | 課前；見 [講師：Hardware Profile](instructor/hardware-profiles-ui-tutorial.md) |
| 為其他使用者**綁定角色／群組** | ✅ | ❌ | 課前發帳號 |
| 刪除他人專案、叢集級資源 | ✅ | ❌ | 清理環境 |
| 本機 `oc` 操作任意 namespace | 視 OCP 權限 | 通常僅自己的專案 | 講師除錯（學員主線不用） |

---

## Dashboard 怎麼一眼分辨

| 現象 | 多半是 |
|------|--------|
| 左側有 **Settings**（Environment setup、Workbench images、Hardware profiles…） | **Admin** |
| 只有 **Home / Projects / Applications** 等，**沒有**平台 Settings | **User**（正常） |
| 看不到 **Projects** 或無法 **Create project** | 帳號尚未授 Data Science 使用者權限 → 找 **Admin** |
| 建 Workbench 時**選不到**自訂映像 | 映像尚未被 Admin **Import／Enable** |
| 選不到 GPU／Hardware Profile | Admin 尚未設定，或專案未開放該 Profile |

---

## 建議的職責切分（客戶落地）

```
Admin（課前／平台）
  ├── 安裝／確認 RHOAI 元件
  ├── 建立學員帳號並授 User 權限
  ├── Import 自訂 Workbench 映像（若需要）
  └── Hardware Profile（CPU；見 instructor/hardware-profiles-ui-tutorial.ipynb）

User（學員／資料科學家）
  ├── Create project
  ├── Create cluster storage / workbench
  └── 訓練、Deploy、測 API、Pipeline Editor（Iris）
```

**不要**要求每位 User 都具備 Admin：自訂映像、叢集元件、權限綁定應集中在 Admin，避免誤改平台設定。

---

## 本教學各步驟「誰該做」

| 步驟 | 角色 |
|------|------|
| 發 Dashboard URL、開通帳號 | Admin |
| 單元 A：建專案 → **Configure pipeline server** → Workbench → 訓練 → Deploy → curl | **User** |
| 單元 B：Pipeline Editor（Iris）→ Deploy | **User** |

細節步驟見：

- [入門實作教學（UI）](getting-started-ui-tutorial.md)  
- [Iris Pipeline Editor](pipeline-ui-tutorial.md)  

---

## 常見問題

### Q1：學員說「我是 admin 但 Settings 還是沒有」？

OCP 的 **project admin** ≠ OpenShift AI 的 **平台 Admin**。  
要進 Dashboard **Settings**，通常需加入 **`rhods-admins`**（或貴司等價的 OAI 管理員群組），而不只是某個專案的 `admin`。  
完整兩層說明見 [OCP vs OAI RBAC](rbac-ocp-vs-oai.md)。

### Q2：能不能給學員臨時 Admin 方便 Import 映像？

可以，但不建議作為常態。教學環境請 Admin **事先 Import**；正式環境應維持最小權限。

### Q3：User 可以刪掉整個專案嗎？

若對該 Project 有刪除權，通常可以刪**自己的**專案。無法刪別人的專案或平台命名空間（如 `redhat-ods-applications`）。

### Q4：Workbench 裡的 Terminal 算 Admin 嗎？

不算。那只是 Pod 內的 shell，權限仍受限於該專案的 ServiceAccount／RBAC，**不能**代替平台 Admin。

---

## 講師課前檢查（RBAC）

- [ ] 學員帳號可登入 Dashboard，且為 **User**（無須人人都是 Admin）  
- [ ] 至少一名 **Admin** 可 Import 映像、調 Hardware Profile  
- [ ] 單元 A／B 可用 CPU-only 的 **`default-profile`**  

---

*RHOAI 3.4 · 角色名稱以貴司實際 IdP／群組為準；本文件強調職責邊界而非單一 ClusterRole 名稱。*
