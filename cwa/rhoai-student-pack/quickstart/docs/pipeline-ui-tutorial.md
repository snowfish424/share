# OpenShift AI 3.4｜Iris Pipeline Editor

> **文件格式**：本檔在 `docs/`（Markdown）。JupyterLab 對應檔在 `docs-ipynb/`。

> **前置**：建議先完成 [入門實作教學 **單元 A**](getting-started-ui-tutorial.md)（Iris 手動訓練與 Deploy）。  
> **本文用途**：單元 B — 用 **Pipeline Editor** 跑 **Iris**（開 `.pipeline` 或拖 `01`）→ Deploy → 驗證。  
> **一頁紙實操**：[00-hands-on-onepage.md](00-hands-on-onepage.md)  
> **資源包**：本包 [`quickstart/`](../README.md)

---

## 你會完成什麼？

| 路徑 | 做法 | 產出 |
|------|------|------|
| **Pipeline Editor（Iris）** | 開 `iris-train-pipeline.pipeline` 或拖 `01-train-sklearn-iris.ipynb` → Run → Deploy | `iris-classifier-elyra` |

> 預估約 25～40 分鐘。以 Dashboard + JupyterLab 為主，不需 CLI。

---

## 第 0 章：開始之前

### 0.1 名詞速查

| 名詞 | 白話解釋 |
|------|----------|
| **Pipeline Editor** | JupyterLab 內建的 **Elyra** 視覺化編輯器；拖放 Notebook 串流程 |
| **AI Pipeline / Run** | 提交到叢集執行的自動化流程；**Run** = 執行一次 |
| **Pipeline Server** | 執行 Pipeline 的後端；專案需先 **Configure** 一次 |
| **Runtime configuration** | Elyra 連到 Pipeline Server + S3 的設定（齒輪圖示） |
| **Node / Step** | 流程圖上的一個方塊（例如一個 Notebook） |

### 0.2 流程鳥瞰

**Pipeline Editor — Iris**

```
JupyterLab Pipeline Editor
  拖入 01-train-sklearn-iris.ipynb
         │
         ▼ Run Pipeline
  叢集自動執行訓練（產出 model.pkl）
         │
         ▼
Dashboard Deploy model（與單元 A 相同）
         │
         ▼
Workbench Terminal curl 驗證
```

### 0.3 重要前提（請講師強調）

| 順序 | 說明 |
|------|------|
| 1️⃣ 先 **Configure pipeline server** | Dashboard → 專案 → Configure pipeline server |
| 2️⃣ 再開 **Workbench** | 如此 JupyterLab 才會自動建立 **Runtime configuration** |
| 3️⃣ Workbench 映像 | **Jupyter \| Data Science \| CPU \| Python 3.12**（Version **3.4**；含 Elyra；Minimal / CUDA / RStudio 沒有 Pipeline Editor） |

若 Workbench 在 Pipeline Server **之前**建立，JupyterLab 可能沒有 Runtime → 見 [Q2 常見問題](#q2-jupyterlab-找不到-runtime-或-run-pipeline-失敗)。

### 0.4 管理員／講師需事先準備

| 項目 | 說明 |
|------|------|
| Data Science Pipelines 已啟用 | RHOAI 3.4 平台元件 |
| 專案 `rhoai-quickstart`、Workbench `iris-workbench` | 完成單元 A 即可 |
| S3 / MinIO 連線資訊 | Configure pipeline server 用 |
| （建議）`./scripts/deploy-pipeline.sh` | 代建 DSPA／RBAC（講師） |

---

## 第 1 章：設定 Pipeline Server（一次性）

> 完成本章後再進 JupyterLab。若 Dashboard **Pipelines** 頁已可正常 Import / 執行，代表可能已設定，可跳到第 2 章。

### 步驟 P-1：Configure pipeline server

> **主線**：此步驟已寫在 [入門教學 **A-2**](getting-started-ui-tutorial.md#步驟-a-2configure-pipeline-server建立-workbench-之前)，且必須在建立 Workbench **之前**完成。本章供複習／漏做補救。

1. **OpenShift AI Dashboard** → **Projects** → **`rhoai-quickstart`**
2. 點 **Configure pipeline server**
3. 填寫表單：

**Object storage（物件儲存）**

| 欄位 | 說明 |
|------|------|
| Bucket | 講師提供（Pipeline artifacts 存放處） |
| Access key / Secret key | S3 認證 |
| Endpoint | 例如 MinIO 位址 |
| Region | `us-east-1` 或講師指定 |

**Database**

| 選項 | 建議 |
|------|------|
| **Default database on the cluster** | 教學環境選這個 |
| External MySQL | 正式環境 |

4. 點 **Configure** / **Save**，等待數分鐘直到就緒

---

## 第 1.5 章：建立 `model-storage`（Dashboard UI）

Pipeline 訓練結果要寫到獨立 PVC，供稍後 **Deploy model** 使用。若你已完成入門教學 **單元 B 步驟 B-1**（或本教學 1.5 章），可跳過。

1. Dashboard → **Projects** → **`rhoai-quickstart`**  
2. **Cluster storage** → **Create cluster storage**  
3. 填寫：

| 欄位 | 值 |
|------|-----|
| Name | `model-storage` |
| Size | `10 GiB` |
| Access mode | **ReadWriteOnce (RWO)** |

4. **Create** → 列表出現 `model-storage`

> 詳細說明與 Pending 狀態見 [入門教學 B-1](getting-started-ui-tutorial.md#步驟-b-1建立模型儲存空間dashboard-ui)。

---

## 第 2 章：用 Pipeline Editor 跑 Iris

> 預估 30～40 分鐘  
> 產出：Pipeline 自動訓練的 `model.pkl` +（手動部署後）`iris-classifier-elyra` 推論 API

### 步驟 P-2：開啟 Workbench 與 Pipeline Editor

1. Dashboard → **Workbenches** → 開啟 **`iris-workbench`**（須為 **Jupyter | Data Science | CPU | Python 3.12** / Version **3.4**）
2. JupyterLab Launcher 出現後，找到 **Elyra** 區塊
3. 點 **Pipeline Editor**
4. 若詢問 Pipeline 類型，選 **Kubeflow Pipelines**（RHOAI 3.4 使用 KFP 2.x）

畫布為空白即表示 Pipeline Editor 已開啟。

> **找不到 Elyra / Pipeline Editor？** 確認 Workbench 映像為 **Jupyter | Data Science | CPU | Python 3.12**（勿選 Minimal / RStudio / code-server）。

### 步驟 P-3：建立訓練 Pipeline（拖放 Notebook）

1. 左側 **File Browser** 進入 `notebooks/`（或你上傳 Notebook 的路徑）
2. 將 **`01-train-sklearn-iris.ipynb`** **拖到畫布中央**
3. 畫布上出現一個節點（代表訓練步驟）

**可選 — 兩步驟 Pipeline（進階練習）**

若已熟悉單元 A，可再拖入 **`02-test-inference.ipynb`**，從訓練節點**拉線**連到測試節點。  
注意：`02` 預設測試 `iris-classifier`；若部署名稱不同，需先改 Notebook 內的 `MODEL` 變數，或訓練後改用手動 curl（步驟 P-7）。

### 步驟 P-4：設定節點屬性（Open Properties）

1. **右鍵**訓練節點 → **Open Properties**（或點節點後看右側面板）
2. 填寫：

| 屬性 | 建議值 | 說明 |
|------|--------|------|
| **Runtime Image** | **Jupyter \| Data Science \| CPU \| Python 3.12**（Version **3.4**） | 與 Workbench 相同映像 |
| **CPU** | `1` | Iris 訓練足夠 |
| **Memory** | `2`（或 UI 顯示 `2Gi`） | Iris 訓練足夠；`.pipeline` 檔內為數字 `2` |
| **GPU** | 留空 | 本單元不需 GPU |
| **Data Volumes** | 見下表 | 讓 `model.pkl` 寫入叢集 PVC，供步驟 P-8 部署 |

**Data Volumes（重要）**

Pipeline 在獨立 Pod 執行，預設不會寫入 Workbench PVC。請在節點 **Open Properties** → **Data Volumes** 新增：

| 欄位 | 值 |
|------|-----|
| Mount path | `/opt/app-root/src/models` |
| PVC name | `model-storage` |
| Sub path | `models`（UI 可填；KFP 2.x 可能整顆 PVC 掛載） |
| Read-only | 否 |

> **講師備註：** 若 Run 成功但 Dashboard 部署找不到檔案，**Model path** 改試 `.`（PVC 根目錄的 `model.pkl`）。驗證 Run `iris-train-pipeline-hpbz9` 已寫入掛載路徑並完成訓練。

3. **Environment Variables**（可選，一般可省略）

4. 右側 **Pipeline Properties** 可設定：
   - **Pipeline name**：`iris-train-pipeline`
   - **Description**：`Iris sklearn training via Elyra`

5. **File** → **Save Pipeline As…** → 存成 `iris-train-pipeline.pipeline`（建議放在 `notebooks/` 同目錄）

### 步驟 P-5：確認 Runtime configuration

1. JupyterLab **左側邊欄** → **Runtimes**（齒輪圖示）
2. 應看到至少一筆 runtime（專案內建立 Workbench 且 Pipeline Server 已設定時，通常**自動建立**）

若列表為空，點 **Create new runtime configuration**：

| 欄位 | 填寫方式 |
|------|----------|
| **API endpoint** | Pipeline Server 內部 URL（講師提供；或 Dashboard Pipelines 頁參考） |
| **Public API endpoint** | 對外 Route URL（Dashboard → Pipelines / Runs 可複製） |
| **Authentication Type** | `EXISTING_BEARER_TOKEN` |
| **Token** | OpenShift Console → 右上角使用者 → **Copy login command** → **Display token** → 複製 `--token=` 後的值 |
| **User namespace** | `rhoai-quickstart` |
| **S3 Endpoint / Bucket** | 與 Configure pipeline server 相同 |
| **S3 認證** | 依講師提供 |

3. **Save & Close**

### 步驟 P-6：Run Pipeline

1. 在 Pipeline Editor 工具列點 **Run Pipeline**（播放 ▶ 圖示）
2. 對話框：

| 欄位 | 建議 |
|------|------|
| Pipeline Name | `iris-train-run-1`（可自訂） |
| Runtime Configuration | 選剛才確認的 runtime |
| Parameters | 本教學可留預設 |

3. 點 **OK** 提交

### 步驟 P-7：Dashboard 監控 Run

1. **回到 OpenShift AI Dashboard**（Workbench 可保持開啟）
2. **Develop & train** → **Pipelines** → **Runs**（確認 Project 正確）
3. 點進剛提交的 Run → **Run details** 頁的 **graph**
4. **點某個 step** → 開啟 **Logs**（介面沒有獨立「DAG」分頁；graph = 舊文件說的 DAG）

| 預期 | 說明 |
|------|------|
| Run / step 狀態 **Succeeded** | 訓練完成 |
| Logs 含 `Test accuracy:` | 與單元 A Notebook 相同 |
| Logs 含 `Model saved` | `model.pkl` 已寫入 |

> 亦可：**Pipelines** → **Executions** 看各 task；**Experiments** 底下也會列出該實驗的 Runs。

> 首次執行約 **3～8 分鐘**（視叢集排隊情況）。

**小技巧 — 單一 Notebook 快速變 Pipeline**

開啟 `01-train-sklearn-iris.ipynb`，選單若有 **Run as Pipeline**，可跳過手動拖放，直接以該 Notebook 建立單節點 Pipeline 並執行。

### 步驟 P-8：Dashboard 部署模型（與單元 A 相同）

Pipeline 完成訓練後，用 Dashboard 發佈 API（Elyra 視覺化路徑**不包含**自動部署，這一步刻意保留讓你練習單元 A 技能）：

1. Dashboard → 專案 **`rhoai-quickstart`** → **Deploy model**
2. 填寫：

| 欄位 | 值 |
|------|-----|
| Model deployment name | `iris-classifier-elyra` |
| Model type | **Predictive** |
| Model framework | **Scikit-learn** |
| Source model location | **Existing cluster storage** |
| Cluster storage | `model-storage` |
| Model path | `.`（或 `models/`，視 PVC 內實際路徑） |
| Deployment mode | **Standard** |

3. **Deploy** → **Models** 頁等待 **Ready**

> 若 Pipeline 訓練 Pod 將模型寫入其他位置，請依 PVC 實際路徑調整 **Model path**（常見為 `.` 或 `models/`）。

### 步驟 P-9：驗證推論 API

1. **Models** → `iris-classifier-elyra` → 確認 **Ready**
2. 回到 **JupyterLab Terminal**（或依 [入門教學 A-8](getting-started-ui-tutorial.md)）：

```bash
NAMESPACE="rhoai-quickstart"
MODEL="iris-classifier-elyra"
URL="http://${MODEL}-predictor.${NAMESPACE}.svc.cluster.local:8080"
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

curl -s -X POST "${URL}/v2/models/${MODEL}/infer" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"inputs":[{"name":"input-0","shape":[1,4],"datatype":"FP32","data":[5.1,3.5,1.4,0.2]}]}' | python3 -m json.tool
```

**預期**：`outputs[0].data[0]` 為 `0`（setosa）。

---

## 第 4 章：介面對照速查表

| 我想… | 用哪個介面 | 路徑 |
|--------|------------|------|
| 視覺化編排 Pipeline | **JupyterLab** | Elyra → **Pipeline Editor** |
| 設定 Pipeline Server | OAI Dashboard | 專案 → Configure pipeline server |
| 管理 Elyra 連線 | JupyterLab | 左側 **Runtimes**（齒輪） |
| 執行視覺化 Pipeline | JupyterLab | Pipeline Editor → **Run Pipeline** |
| 看 Run 進度 / 日誌 | OAI Dashboard | **Pipelines → Runs** → 點 Run → graph → 點 step → **Logs** |
| 部署模型（C-Vis Iris） | OAI Dashboard | **Deploy model** |
| 測試 API | JupyterLab Terminal | curl（見步驟 P-9） |
| 除錯 Pod | OpenShift Console | Workloads → Pods → Logs |

---

## 第 5 章：常見問題

### Q1：找不到 Pipeline Editor？

- Workbench 須為 **Jupyter | Data Science | CPU | Python 3.12** Version **3.4**（或 PyTorch / TensorFlow 等含 Elyra 的 JupyterLab 映像）
- **不支援**：Minimal Python、CUDA 專用映像、RStudio、code-server
- 重新整理 JupyterLab 或重開 Workbench

### Q2：JupyterLab 找不到 Runtime，或 Run Pipeline 失敗？

- **最常見原因**：Workbench 比 Pipeline Server **更早**建立  
- **解法**：請講師先完成 **Configure pipeline server**，再重建 Workbench；或手動建立 Runtime（步驟 P-5）
- 確認 Token 未過期（重新 Copy login command）
- 確認 S3 連線與 Dashboard 設定一致

### Q3：Run 成功但 Deploy 找不到模型？

- File Browser 檢查 `/opt/app-root/src/models/model.pkl` 是否存在
- **Cluster storage** 選 Workbench 建立時的 PVC
- **Model path** 填 `models/`（相對路徑，非完整 `/opt/...`）

### Q4：想強制重跑訓練（不要快取）？

Pipeline Editor → 右鍵節點 → **Open Properties** → **Disable node caching** → `True`  
或 Pipeline Properties → Node Defaults 設為 `True`

### Q5b：Run Pipeline 失敗：Error 1366 / Incorrect string value（`\\xE2\\x86\\x92`）？

內建 MariaDB 存 `PipelineSpecManifest` 時，**Name／Description 請只用 ASCII**。  
`→`（UTF-8 `E2 86 92`）或中文都會觸發 500。改掉後重新 Run 即可。詳見入門教學 [Q8](getting-started-ui-tutorial.md#q8run-pipeline-出現-error-1366--incorrect-string-value--xe2x86x92)。

### Q6：和單元 A 的 `iris-classifier` 衝突嗎？

不會。Pipeline 路徑建議用 `iris-classifier-elyra`，與單元 A 的 `iris-classifier` 並存。

---

## 完成檢查清單

### Pipeline Editor（Iris）

- [ ] Pipeline Server 已設定  
- [ ] JupyterLab 可開啟 **Pipeline Editor**  
- [ ] Runtime configuration 存在  
- [ ] `iris-train-pipeline` 已儲存並 **Run** 成功  
- [ ] Dashboard Runs 顯示 **Succeeded**  
- [ ] `iris-classifier-elyra` 在 Models 頁 **Ready**  
- [ ] curl 回傳預測 `0`

---

## 附錄 A：給講師的準備清單

- [ ] **先** Configure pipeline server，**再** 讓學員開 Workbench（自動 Runtime）
- [ ] 執行 `./scripts/deploy-pipeline.sh`（ServingRuntime、RBAC）
- [ ] 確認 `notebooks/01-train-sklearn-iris.ipynb` 在 Workbench 可見
- [ ] 準備 S3 連線資訊給 Runtime 設定
- [ ] - [ ] 預跑 C-Vis Iris Pipeline 一次（約 5～10 分鐘）

---

## 附錄 C：何時才需要 CLI？

學員**不必學 CLI**。講師可能使用：

| 情境 | 指令 |
|------|------|
| 批次建立前置資源 | `./scripts/deploy-pipeline.sh` |
| 重新編譯 YAML | `make pipeline-compile` |

---

## 附錄 D：相關文件

| 文件 | 用途 |
|------|------|
| [入門實作教學（UI 操作版）](getting-started-ui-tutorial.md) | 單元 A / B |
| [RHOAI 官方：JupyterLab Pipelines](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/working_with_ai_pipelines/working-with-pipelines-in-jupyterlab_ai-pipelines) | Elyra 完整說明 |

---

*文件版本：RHOAI 3.4 quickstart · Pipeline UI 操作版（含 Pipeline Editor）*
