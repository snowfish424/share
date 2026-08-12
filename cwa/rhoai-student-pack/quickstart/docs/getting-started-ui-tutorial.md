# OpenShift AI 3.4 入門實作教學（UI 操作版）

> **文件格式**：本檔在 `docs/`（Markdown）。JupyterLab 對應檔在 `docs-ipynb/`。

> **對象**：未曾使用 OpenShift Container Platform（OCP）或 OpenShift AI（OAI）的學員  
> **目標**：在瀏覽器內完成「訓練模型 → 部署推論 → 驗證 API」  
> **資源包**：本包 [`quickstart/`](../README.md)（Console／Dashboard 優先，不必本機 `oc`）  
> **課程定稿（2026-08）**：Pipeline Editor **必達用 Iris**。實操請先跟 [00-hands-on-onepage.md](00-hands-on-onepage.md)。

---

## 你將完成什麼？

| 單元 | 模型 | 優先 | 你會學到 |
|------|------|------|----------|
| **A. Iris 手動** | scikit-learn | **必達** | Workbench、手動訓練、Dashboard 部署、curl |
| **B. Pipeline Editor（Iris）** | scikit-learn | **必達** | 拖放／開 `.pipeline`、Run、Deploy（見一頁紙單元 B） |

完成 **A + B（Iris Pipeline）** 即涵蓋手動與 Pipeline Editor 兩種主路徑。

---

## 第 0 章：開始之前

### 0.1 Admin 與 User（先分清角色）

客戶環境通常就兩種人，本教學預設你是 **User**：

| 角色 | 你能做什麼 | 你通常**不能**做什麼 |
|------|------------|----------------------|
| **User**（學員／資料科學家） | 建專案、Workbench、PVC、訓練、Deploy、Pipeline | 平台 **Settings**、Import 自訂映像、開叢集元件 |
| **Admin**（平台管理員） | 上列全部 + 開元件、Import 映像、Hardware Profile、發帳號權限 | — |

完整對照見 **[OCP vs OAI RBAC](rbac-ocp-vs-oai.md)**、課堂職責見 **[Admin 與 User](rbac-admin-vs-user.md)**。

若看不到 **Projects**／無法 **Create project** → 請 **Admin** 開通 Data Science 使用者權限。  
若建 Workbench 選不到自訂映像或 GPU Profile → 多半是 **Admin** 尚未 Import／設定。

### 0.2 管理員需事先準備

向平台 **Admin** 確認下列項目已就緒：

| 項目 | 說明 |
|------|------|
| OpenShift 叢集 | 4.16 以上，已安裝 **OpenShift AI 3.4** |
| 你的帳號 | 具備 **Data Science 使用者（User）** 權限，可建立專案 |
| 登入網址 | **OpenShift AI Dashboard** URL（通常由 Admin 提供） |
| （單元 A-2／B）Pipeline | Data Science Pipelines 已啟用；**建立 Workbench 前** Configure（或講師代建 DSPA） |
| （選用）Hardware Profile | 單元 A／B 用 **`default-profile`** 即可 |

你**不需要**在本機安裝 OpenShift CLI（`oc`）。學員主線只靠 Dashboard + JupyterLab。

### 0.3 兩個你會用到的網頁介面

| 介面 | 用途 | 何時使用 |
|------|------|----------|
| **OpenShift AI Dashboard** | 專案、Workbench、PVC、Deploy、Pipeline Runs | **本教學主要介面** |
| **JupyterLab**（Workbench 內） | Notebook、Terminal、**Pipeline Editor** | 單元 A 手動訓練；單元 B 拖放編排 |

```
瀏覽器
  ├── OpenShift AI Dashboard  ← 專案、Workbench、PVC、Deploy、Runs
  ├── JupyterLab              ← 00/01（單元 A）；Pipeline Editor（Iris，單元 B）
  └── OpenShift Console       ← 除錯（Pods／Logs）；多數步驟用不到
```

### 0.4 名詞速查（第一次看請先讀）

| 名詞 | 白話解釋 |
|------|----------|
| **OCP** | Red Hat 的 Kubernetes 容器平台；叢集「底層」 |
| **OAI / RHOAI** | 跑在 OCP 上的 AI 平台；提供 Workbench、模型部署等 |
| **Admin / User** | 平台管理員 vs 資料科學使用者；見 [OCP vs OAI](rbac-ocp-vs-oai.md)、[課堂職責](rbac-admin-vs-user.md) |
| **Hardware profile** | 決定 CPU／記憶體／是否要 GPU；取代舊「Deployment size」。本叢集 **`default-profile`＝CPU-only**（見 [講師：Hardware Profile](instructor/hardware-profiles-ui-tutorial.md)） |
| **Project（專案）** | 你的 AI 工作空間，資源彼此隔離；類似一個「資料科學資料夾」 |
| **Workbench** | 雲端 JupyterLab 開發環境，檔案存在持久化儲存 |
| **Cluster storage（PVC）** | 持久化硬碟；Notebook 檔案、模型權重都放這裡 |
| **Notebook（.ipynb）** | 可逐步執行的教學／實驗文件 |
| **Deploy model** | 把訓練好的模型檔發佈成 **線上 API** |
| **InferenceService / Model deployment** | 已部署的推論服務；對外提供 REST API |
| **Standard 部署模式** | KServe RawDeployment；RHOAI 3.4 推薦的推論方式 |
| **AI Pipeline / Run** | 自動化 ML 流程；**Run** 是一次完整執行 |
| **Pipeline Editor（Elyra）** | JupyterLab 內拖放 Notebook 畫流程圖（**單元 B：Iris**；細節見 [pipeline-ui-tutorial.md](pipeline-ui-tutorial.md)） |

### 0.5 整體流程鳥瞰

```
┌─────────────┐   ┌──────────────────┐   ┌──────────────┐   ┌─────────────┐   ┌──────────┐
│ 建立專案     │──▶│ Configure        │──▶│ 建立 Workbench│──▶│ Notebook    │──▶│ Deploy + │
│ (Dashboard) │   │ pipeline server  │   │ (Dashboard)  │   │ 訓練        │   │ curl     │
└─────────────┘   └──────────────────┘   └──────────────┘   └─────────────┘   └──────────┘
                         ▲
                         └── 必須在 Workbench **之前**（單元 B Pipeline Editor 才有 Runtime）
```

### 0.6 Cluster storage（PVC）何時要用 UI 建？

本教學**全部用 Dashboard UI** 建立儲存，不必先跑 `oc apply`。

| 儲存 | 何時建立 | 怎麼建 |
|------|----------|--------|
| Workbench 家目錄 PVC | 單元 A 建 Workbench 時 | **Create workbench** 勾選 **Create new storage**（步驟 A-3） |
| **`model-storage`** | 單元 B（Iris Pipeline）訓練前建立 | 專案 → **Cluster storage** → **Create**（步驟 [B-1](#步驟-b-1建立模型儲存空間dashboard-ui)） |

**通用 UI 路徑（建立獨立 PVC）：**

1. Dashboard → **Projects** → 進入你的專案  
2. 左側或專案內 **Cluster storage**（有的版本在 **Settings** 下）  
3. **Create cluster storage**  
4. 填 **Name**、**Size**、**Access mode** → **Create**

> **Pending 很常見**：StorageClass 若為 `WaitForFirstConsumer`，要等第一個 Pod 掛載後才會變 **Bound**，不一定是失敗。

---

## 第 1 章：登入 OpenShift AI Dashboard

1. 開啟 **Admin** 提供的 **OpenShift AI Dashboard** 網址  
2. 使用你的帳號登入（通常與 OpenShift 帳號相同）  
3. 登入後左側應可見：**Home**、**Projects**、**Applications** 等選單  

若看不到 **Projects** 或無法 **Create project**，請聯絡 **Admin** 確認 Data Science **User** 角色權限（見 [RBAC 說明](rbac-admin-vs-user.md)）。

---

## 第 2 章：單元 A — Iris 分類（CPU 入門）

> 預估時間：45～60 分鐘  
> 產出：`iris-classifier` 線上推論 API

### 步驟 A-1：建立專案

1. 左側選單 → **Projects**  
2. 點 **Create project**  
3. 填寫：

| 欄位 | 建議值 | 備註 |
|------|--------|------|
| Name | `RHOAI Quickstart` | 顯示名稱，可自訂 |
| Resource name | `rhoai-quickstart` | **建立後不可改**；部署 API 會用到 |

4. 點 **Create**  
5. 進入剛建立的專案頁面  

### 步驟 A-2：Configure pipeline server（建立 Workbench **之前**）

> **務必先做這步再建立 Workbench。**  
> JupyterLab 的 Pipeline **Runtime** 通常在「Pipeline Server 已就緒之後」才建立的 Workbench 裡自動出現。順序反了，單元 B 常會找不到 Runtime。

1. 仍在專案 **`rhoai-quickstart`** 頁面  
2. 點 **Configure pipeline server**  
3. 教學環境建議：

| 區塊 | 建議 |
|------|------|
| **Database** | **Default database on the cluster** |
| **Object storage** | 依講師提供填 Bucket／金鑰／Endpoint；或由講師用 CLI 代建（見下方） |

4. **Configure** / **Save** → 等待就緒（數分鐘；Pods 會起 MariaDB／MinIO／pipeline API 等）

**講師／Admin 替代（等同 UI，學員可跳過）**：專案已存在時，講師可執行 `./scripts/deploy-pipeline.sh`（套用本包 `k8s/dspa.yaml`）。學員請用 Dashboard **Configure pipeline server**；就緒後專案頁不再一直顯示 Configure。

**完成檢查**

- [ ] 專案上 Pipeline server 已就緒（Dashboard 不再一直顯示 Configure）

### 步驟 A-3：建立 Workbench

> 請確認 [A-2](#步驟-a-2configure-pipeline-server建立-workbench-之前) 已完成；否則單元 B 可能沒有 Pipeline Runtime。

1. 在專案頁面 → **Workbenches** 分頁  
2. 點 **Create workbench**  
3. 填寫表單：

| 欄位 | 建議值 | 說明 |
|------|--------|------|
| Name | `iris-workbench` | 顯示名稱 |
| Image selection | **Jupyter \| Data Science \| CPU \| Python 3.12** | CPU 資料科學環境（內部名 `s2i-generic-data-science-notebook`；舊文件常寫 Standard Data Science） |
| Version | **3.4** | 請選 3.4；勿選標示 deprecated 的 2025.x |
| Hardware profile | **`default-profile`** | RHOAI 3.4 `default-profile` 為 **CPU-only** |
| Cluster storage | **Create new storage** | 勾選建立新儲存（約 20Gi）；這就是用 **UI** 建 Workbench PVC，名稱稍後 Deploy 會用到 |

4. 點 **Create workbench**  
5. 等待狀態由 **Starting** 變為 **Running**（可能需要數分鐘）  
6. 狀態為 Running 後，**點擊 Workbench 名稱** → 瀏覽器開啟 **JupyterLab**  

> **提示**：Cluster storage 建立後會有一個 PVC 名稱（例如 `iris-workbench-storage`），後續部署模型時要選這個。

### 步驟 A-4：匯入教學 Notebook

在 JupyterLab 中取得 Notebook 檔案，擇一方式：

**方式 1 — 上傳（最簡單）**

1. 左側 **File Browser**  
2. 進入 `/opt/app-root/src/`  
3. 建立資料夾 `notebooks`（若尚無）  
4. 上傳本包 `quickstart/notebooks/*.ipynb`  

**方式 2 — Git clone**（若資源包可存取）

1. JupyterLab 上方 → **File** → **New** → **Terminal**  
2. 執行：
   ```bash
   cd /opt/app-root/src
   git clone <你的-repo-url> rhoai-student-pack
   ```
3. Notebook 位於 `rhoai-student-pack/quickstart/notebooks/`

### (可跳過) 步驟 A-5：設定 Python 環境（Notebook `00`）

1. 開啟 `00-setup-persistent-venv.ipynb`  
2. 依序 **Run** 所有 Cell（Kernel 選預設 Python 即可）  
3. 完成後，右上角 Kernel 切換為 **Python (dev-venv)**  

此步驟在 Workbench 儲存空間建立持久化虛擬環境，之後 `pip install` 的套件不會因 Workbench 重啟而消失。

### 步驟 A-6：訓練 Iris 模型（Notebook `01`）

1. 開啟 `01-train-sklearn-iris.ipynb`  
2. 依序執行所有 Cell  

訓練成功後，終端機應顯示類似：

```
Model saved: /opt/app-root/src/models/model.pkl
Test accuracy: 1.0000
```

**驗證檔案是否存在**（可選）：

1. JupyterLab File Browser → `/opt/app-root/src/models/`  
2. 應看到 `model.pkl`  

### 步驟 A-7：Dashboard 部署模型

1. **回到 OpenShift AI Dashboard**（另開分頁即可，Workbench 可保持開啟）  
2. **Projects** → 進入 `rhoai-quickstart`  
3. 點 **Deploy model**（或 **Models** 分頁 → Create / Deploy）  
4. 填寫部署表單：

| 欄位 | 值 |
|------|-----|
| Model deployment name | `iris-classifier` |
| Model type | **Predictive** |
| Model framework | **Scikit-learn**（選 **sklearn-1** 若 UI 有版本子選項） |
| Source model location | **Existing cluster storage** |
| Cluster storage | 選 Workbench 的 PVC（如 `iris-workbench-storage`） |
| Model path | `models/` |
| Serving runtime | **MLServer**（通常自動選取） |
| Deployment mode | **Standard** |

5. 點 **Deploy**  
6. 在 **Models** 列表等待 Status 變為 **Ready** 或 **Started**  

> **常見錯誤**：Model path 填 `models/` 即可，**不要**填完整路徑 `/opt/app-root/src/models/`。

### 步驟 A-8：Dashboard 確認部署

1. **Models** → 點 **`iris-classifier`**  
2. 確認 Status 為 **Ready**  
3. 若有顯示 **Inference endpoint / URL**，可先記下（稍後測試用）  

若 Status 長時間非 Ready：

- **OpenShift Console** → 切換專案 `rhoai-quickstart`  
- **Workloads** → **Pods** → 篩選 `iris-classifier`  
- 點 Pod → **Logs** 查看錯誤訊息  

### 步驟 A-9：Terminal 測試推論 API

推論測試需在 **Workbench Terminal** 執行 HTTP 請求（Dashboard 目前無內建 KServe 測試表單）。

1. 回到 **JupyterLab**  
2. **File** → **New** → **Terminal**  
3. 貼上並執行：

```bash
NAMESPACE="rhoai-quickstart"
MODEL="iris-classifier"
URL="http://${MODEL}-predictor.${NAMESPACE}.svc.cluster.local:8080"
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

curl -s -X POST "${URL}/v2/models/${MODEL}/infer" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"inputs":[{"name":"input-0","shape":[1,4],"datatype":"FP32","data":[5.1,3.5,1.4,0.2]}]}' | python3 -m json.tool
```

**預期結果**：JSON 回應中 `outputs[0].data[0]` 為 `0`（代表預測為 setosa）。

也可開啟 `02-test-inference.ipynb` 照步驟操作（內容與上述相同，為操作指引）。

### 單元 A 完成檢查清單

- [ ] 專案 `rhoai-quickstart` 已建立  
- [ ] **Pipeline server 已在建立 Workbench 前設定完成**（A-2）  
- [ ] Workbench `iris-workbench` 狀態 Running  
- [ ] `/opt/app-root/src/models/model.pkl` 存在  
- [ ] Dashboard 上 `iris-classifier` Status 為 Ready  
- [ ] curl 測試回傳預測結果  

---

## 第 3 章：介面對照速查表

| 我想… | 用哪個介面 | 路徑 |
|--------|------------|------|
| 建立 AI 專案 | OAI Dashboard | Projects → Create project |
| 開 Jupyter | OAI Dashboard | Workbenches → 點名稱 |
| 上傳 / 執行 Notebook | JupyterLab | File Browser |
| 部署 sklearn 模型 | OAI Dashboard | Deploy model |
| 看推論服務狀態 | OAI Dashboard | Models |
| 建立額外 PVC（如 `model-storage`） | OAI Dashboard | **Cluster storage** → Create（見 [0.5](#05-cluster-storagepvc何時要用-ui-建)、一頁紙單元 B） |
| Pipeline Editor（Iris） | JupyterLab | 開 `iris-train-pipeline.pipeline` 或拖 `01` → Run |
| 監控 Pipeline Run | OAI Dashboard | **Pipelines → Runs** → 點 Run → **graph** → 點 step 看 **Logs** |
| 看 Pod 日誌（除錯） | OpenShift Console | Workloads → Pods → Logs |
| 測試推論 API | JupyterLab | `02-test-inference.ipynb` 或 Terminal curl |

---

## 第 4 章：常見問題

### Q1：Workbench 一直 Starting？

- 等 3～5 分鐘；叢集資源不足時會更久  
- Console → Pods → 找 workbench 相關 Pod → 看 Events / Logs  

### Q2：Deploy model 時找不到模型檔？

- 確認 Notebook 訓練已成功，`model.pkl` 在 File Browser 可見  
- **Model path** 填相對路徑 `models/`，不是 `/opt/app-root/src/models/`  
- **Cluster storage** 選 Workbench 建立時的那個 PVC  

### Q3：推論 Status 不是 Ready？

- Console → Pods → 找 `iris-classifier`／`iris-classifier-elyra` predictor Pod  
- 常見原因：模型路徑錯誤、模型格式不符、資源不足  

### Q3b：Notebook／curl 出現 `Connection refused`？

- 確認 Service port（sklearn 常見 **8080**；也可在 Console 看 Service）  
- 確認部署 Status 已是 **Ready**  

### Q4：curl 回 401 / 403？

- 請求需帶 `Authorization: Bearer <token>`  
- Workbench 內可用：`cat /var/run/secrets/kubernetes.io/serviceaccount/token`  

### Q5：Workbench 重開後 pip 裝的套件不見？

- 請先跑 `00-setup-persistent-venv.ipynb`，並用 **Python (dev-venv)** Kernel  

### Q6：Version 該選 3.4 還是 2025.x？

- RHOAI 3.4 請選 **3.4**；2025.x 為舊版標籤，已 deprecated  

### Q7：Dashboard 找不到 DAG／Logs？

RHOAI 3.4 不叫「DAG」。請走：

**Develop & train → Pipelines → Runs** → 點 Run 名稱 → 頁面中的 **graph** → **點 step** 才看得到 **Logs**。

若 Runs 列表是空的：確認 Project；或從 **Experiments**／**Pipelines → Executions** 找。

---

## 第 5 章：Notebook 與文件索引

| 檔案 | 用途 |
|------|------|
| `notebooks/00-setup-persistent-venv.ipynb` | 建立持久化 Python 環境 |
| `notebooks/01-train-sklearn-iris.ipynb` | Iris 訓練（Jupyter／Pipeline 節點） |
| `notebooks/02-test-inference.ipynb` | Iris 推論驗證指引 |
| `pipelines/elyra/iris-train-pipeline.pipeline` | 單元 B 預建 Elyra 流程 |
| [pipeline-ui-tutorial.md](./pipeline-ui-tutorial.md) | Iris Pipeline Editor 細節 |

---

## 附錄 A：Iris 預測類別對照

| 輸出值 | 品種 |
|--------|------|
| 0 | setosa |
| 1 | versicolor |
| 2 | virginica |

測試用特徵 `[5.1, 3.5, 1.4, 0.2]` 預期預測 **0（setosa）**。

---

## 附錄 B：何時才需要 CLI？

本教學以 UI 為主。學員**不必**安裝本機 `oc`。下列情況僅講師或 MLOps 可能使用：

| 情境 | 做法 |
|------|------|
| 代建 Pipeline server | Dashboard Configure，或 `scripts/deploy-pipeline.sh` |
| 除錯 Pod／PVC | OpenShift Console → Pods → Logs（優先）；必要時再用 `oc` |

---

*文件版本：RHOAI 3.4 student-pack · UI 操作版*
