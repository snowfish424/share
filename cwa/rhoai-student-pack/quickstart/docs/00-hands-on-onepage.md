# Quickstart 一頁式實操（照做即可）

> **文件格式**：本檔在 `docs/`（Markdown）。JupyterLab 對應檔在 `docs-ipynb/`。

> **介面**：OpenShift AI Dashboard + JupyterLab  
> **不必**本機 `oc`、不必懂背後原理  
> 卡住 → 舉手／看講師螢幕；細節見 [getting-started-ui-tutorial.md](getting-started-ui-tutorial.md)

**順序不能反**：先 Configure pipeline server，再 Create workbench。

| 單元 | 內容 | 優先 |
|------|------|------|
| **A** | Iris 手動訓練 → Deploy → curl | **必達** |
| **B** | Pipeline Editor（**Iris**） | **必達** |

---

## 單元 A — Iris 手動（必達）

### 1. 建專案

Dashboard → **Projects** → **Create project**

| 欄位 | 填什麼 |
|------|--------|
| Resource name | `rhoai-qs-<你的縮寫>`（建立後不能改） |

### 2. Configure pipeline server（先做）

專案頁 → **Configure pipeline server** → Database 選 **Default** → 其餘依講師 → **Configure** → 等到就緒。

### 3. Create workbench

| 欄位 | 填什麼 |
|------|--------|
| Name | `iris-workbench` |
| Image | **Jupyter \| Data Science \| CPU \| Python 3.12**，Version **3.4** |
| Hardware profile | **`default-profile`** |
| Storage | **Create new storage** |

→ **Create** → 等 **Running** → 點名稱開 JupyterLab。

### 4. 上傳 Notebook

上傳本包 `quickstart/notebooks/`：`00`、`01`、`02`（至少這三個）。

### 5. 訓練

1. 開 `00-setup-persistent-venv.ipynb` → Run All → Kernel 選 **Python (dev-venv)**  
2. 開 `01-train-sklearn-iris.ipynb` → Run All  
3. 確認有檔：`models/model.pkl`

### 6. Deploy model

Dashboard → 同專案 → **Deploy model**

| 欄位 | 填什麼 |
|------|--------|
| Name | `iris-classifier` |
| Framework | **Scikit-learn**（sklearn-1） |
| Storage | Workbench 那顆 PVC |
| Model path | **`models/`**（不要填 `/opt/...`） |
| Mode | **Standard** |

→ 等 **Ready**。

### 7. 測 API

JupyterLab → **File → New → Terminal**（`NAMESPACE` 改成你的專案名）：

```bash
NAMESPACE="rhoai-qs-<你的縮寫>"
MODEL="iris-classifier"
URL="http://${MODEL}-predictor.${NAMESPACE}.svc.cluster.local:8080"
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

curl -s -X POST "${URL}/v2/models/${MODEL}/infer" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"inputs":[{"name":"input-0","shape":[1,4],"datatype":"FP32","data":[5.1,3.5,1.4,0.2]}]}' | python3 -m json.tool
```

**成功**：預測值 **`0`**。（或跑 `02-test-inference.ipynb`。）

**A 完成**：`[ ]` Pipeline server　`[ ]` Workbench　`[ ]` model.pkl　`[ ]` Ready　`[ ]` curl=0

---

## 單元 B — Pipeline Editor（Iris，必達）

仍用**同一個** Data Science Workbench。

### 1. 建 model-storage

專案 → **Cluster storage** → **Create**

| 欄位 | 填什麼 |
|------|--------|
| Name | `model-storage` |
| Size | `10 GiB` |
| Access mode | **RWO** |

### 2. 開 Pipeline

上傳（若尚未有）：`01-train-sklearn-iris.ipynb`、`pipelines/elyra/iris-train-pipeline.pipeline`。

二選一：

- 開 **`iris-train-pipeline.pipeline`**，或  
- Launcher → **Pipeline Editor** → 拖入 **`01-train-sklearn-iris.ipynb`**

### 3. 節點 Properties

| 欄位 | 填什麼 |
|------|--------|
| Runtime Image | Data Science **CPU** 3.4 |
| CPU / Memory | `1` / `2` |
| GPU | 空 |
| Mount path | `/opt/app-root/src/models` |
| PVC name | `model-storage` |
| Sub path | `models`（若 UI 有；不行可留空，Deploy 改試 `.`） |

Pipeline name／description：**僅 ASCII**。

### 4. Run

**Save** → **Run Pipeline** → 選 Runtime → OK。  
Dashboard → **Pipelines → Runs** → **Succeeded**。

> 離線環境：官方 Data Science 通常**已有** sklearn，用**新版 `01`**（有套件就 skip pip）。

### 5. Deploy（Pipeline 產出）

Dashboard → **Deploy model**

| 欄位 | 填什麼 |
|------|--------|
| Name | `iris-classifier-elyra`（勿與單元 A 的 `iris-classifier` 撞名） |
| Framework | **Scikit-learn** |
| Storage | **`model-storage`** |
| Model path | **`models/`**（找不到再試 **`.`**） |

→ **Ready** → 用單元 A 的 curl，把 `MODEL` 改成 `iris-classifier-elyra`。

**B 完成**：`[ ]` model-storage　`[ ]` Run Succeeded　`[ ]` elyra Ready　`[ ]` curl=0

---

## 卡住時

| 現象 | 立刻做 |
|------|--------|
| 沒有 Runtime／Pipeline Editor | 映像 Data Science **3.4**；**先** pipeline server **再**建 Workbench |
| Deploy 找不到模型 | path 填 `models/` 或 `.`；確認 PVC 是 `model-storage` |
| Pending／不 Ready | 等幾分鐘；仍不行找講師 |
| 專案名撞名 | Resource name 加自己縮寫 |
