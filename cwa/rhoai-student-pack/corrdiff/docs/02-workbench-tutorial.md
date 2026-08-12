# 02 — Workbench 推論教學（Dashboard UI）

> **文件格式**：本檔在 `docs/`（Markdown）。JupyterLab 對應檔在 `docs-ipynb/`。

> **目標**：完成「資料 PVC + GPU CorrDiff Workbench + Notebook 推論」  
> **產出**：`/mnt/corrdiff/dtg/EC_S2S_AIPP/20260707/CorrdiffOutput_EC_RAW_20260707.nc`  
> **預估**：75～100 分鐘（含 GPU 等待）  
> **Notebook**：本包 [`notebooks/01-test-corrdiff-inference.ipynb`](../notebooks/01-test-corrdiff-inference.ipynb)

---

## 第 0 章：開始之前

### 名詞

| 名詞 | 白話 |
|------|------|
| 資料 PVC（`corrdiff-workspace`） | 放程式、權重、輸入／輸出；掛在 `/mnt/corrdiff` |
| Workbench PVC | Jupyter 家目錄（`/opt/app-root/src`）；notebook 常在 `notebooks/` |
| 自訂映像 | **CorrDiff \| PyTorch \| CUDA \| Modulus** |
| `SHOME` | 環境變數，應為 `/mnt/corrdiff` |

### 向講師確認

- [ ] Dashboard 選得到 **CorrDiff \| PyTorch \| CUDA \| Modulus**  
- [ ] 有 GPU Hardware Profile（例如 `gpu-1`）  
- [ ] （若你不跑 seed）`corrdiff-workspace` 已有資料  

### 權限

可登入 OpenShift AI Dashboard；從零練習需能 Create project／Cluster storage／Workbench。  
Seed 需本機 `oc` 與模型資料（見 [講師：seed](instructor/05-seed-scripts.md)）。

---

## 第 1 章：專案與資料 PVC

> 講師已備好專案並 seed 完成 → 跳到 [第 2 章](#第-2-章開啟-corrdiff-workbench)。

### 1.1 建立專案

1. Dashboard → **Projects** → **Create project**  
2. Resource name：`corrdiff-poc`（建立後不可改）  
3. **Create**

### 1.2 建立 PVC `corrdiff-workspace`

1. 專案內 **Cluster storage** → **Create cluster storage**  
2. 建議：

| 欄位 | 建議值 |
|------|--------|
| Name | `corrdiff-workspace` |
| Size | **100 GiB**（不建議低於 50Gi） |
| Access mode | **ReadWriteMany (RWX)**（若有） |
| Storage class | 講師指定（常見 cephfs） |

3. **Create** → 列表出現 `corrdiff-workspace`

> Pending：若 StorageClass 為 `WaitForFirstConsumer`，等第一個 Pod 掛載後才 Bound，屬正常。

Dashboard 無法選 RWX／class 時：Console → Import YAML → 貼本包 [`k8s/pvc.yaml`](../k8s/pvc.yaml)。

### 1.3 Seed 資料

空白 PVC 還不夠，需要 `bin/`、`etc/`、測試日資料。

| 情況 | 做法 |
|------|------|
| 課堂／僅有 Dashboard | **請講師代跑 seed** |
| 課後有 `oc`，且本機有同層 `corrdiff_for_ocp` | 見 [講師：seed](instructor/05-seed-scripts.md) |

成功後大致會有：

```text
/mnt/corrdiff/bin/
/mnt/corrdiff/etc/
/mnt/corrdiff/workdir/20260707/
```

---

## 第 2 章：開啟 CorrDiff Workbench

### 路徑 A：講師已建好

1. Projects → `corrdiff-poc` → **Workbenches**  
2. 找到 CorrDiff Workbench → **Start**（若 Stopped）→ 點名稱開 JupyterLab  
3. 進入 **`notebooks/`**，確認有 `01-test-corrdiff-inference.ipynb`

### 路徑 B：自行建立

1. **Create workbench**，填寫：

| 欄位 | 建議值 |
|------|--------|
| Name | `corrdiff-workbench` 或 `corrdiff-wb-<縮寫>` |
| Image | **CorrDiff \| PyTorch \| CUDA \| Modulus**（勿選 Data Science CPU） |
| Hardware profile | **`gpu-1`**（或含 `nvidia.com/gpu: 1` 的 profile） |
| 家目錄 storage | Create new（約 20Gi） |
| **Additional storage** | `corrdiff-workspace` → 掛載 **`/mnt/corrdiff`** |

2. Running 後開 JupyterLab  
3. 若無 notebook：上傳本包 `notebooks/01-test-corrdiff-inference.ipynb`

**檢查**

```bash
ls /mnt/corrdiff/bin /mnt/corrdiff/etc
ls /mnt/corrdiff/workdir/20260707/
```

---

## 第 3 章：執行推論 Notebook

開啟 `01-test-corrdiff-inference.ipynb`。  
用映像預設 Python（**不必**另建 venv／現場狂 pip）。  
建議依序執行，不要一次 Run All。

### 3.1 環境檢查

預期：`torch … cuda True`、GPU 名稱、`modulus OK`。

| 症狀 | 處置 |
|------|------|
| `cuda False` | 未掛 GPU；Stop 後改 Hardware Profile |
| `No module named 'modulus'` | 映像選錯；應為 CorrDiff 自訂映像 |

### 3.2 檔案檢查

各項應為 **`[OK]`**。若 `[MISSING]`：確認 `/mnt/corrdiff` 掛載與 seed；日期是否為 `20260707`。

### 3.3 預覽輸入 NC

應看到 dimensions、`fc` shape。

### 3.4 完整推論

數分鐘；成功見 `exit code: 0`。勿重複連按。

| 症狀 | 處置 |
|------|------|
| CUDA OOM | GPU 記憶體不足；錯開時段或看講師已產出的輸出 |
| import lib 失敗 | 確認 `/mnt/corrdiff/bin/lib`；請講師重 seed |

### 3.5 驗證輸出

路徑：

```text
/mnt/corrdiff/dtg/EC_S2S_AIPP/20260707/CorrdiffOutput_EC_RAW_20260707.nc
```

應能印 dimensions 並顯示一張預覽圖。

---

## 第 4 章（可選）：對照 Job

Workbench 與 Job 共用同一 PVC。請優先用 **OpenShift Console**：

1. Console → 專案 `corrdiff-poc` → **Workloads → Jobs**  
2. 查看 `corrdiff-smoke-test`／`corrdiff-inference` 的 **Logs**  
3. 若要重跑：Console → **+ → Import YAML**，貼本包 [`k8s/inference-job.yaml`](../k8s/inference-job.yaml)（勿多人同時搶 GPU）

> **講師／有 `oc`（學員可跳過）**：在含本包 `k8s/` 的目錄、已 `oc login` 後，可用 `oc apply -f k8s/inference-job.yaml` 與 `oc logs -f job/corrdiff-inference`。

---

## 完成檢查清單

- [ ] Cluster storage 可見 `corrdiff-workspace`（或講師已備）  
- [ ] `/mnt/corrdiff` 有 bin／etc／workdir  
- [ ] CorrDiff 映像 + GPU，`cuda True`、`modulus OK`  
- [ ] 推論 `exit code: 0`，輸出 NC 可繪圖  

---

## 疑難排解

| 問題 | 怎麼辦 |
|------|--------|
| 選不到 CorrDiff 映像 | 請 Admin Import／Enable（製作見 [講師：自訂映像](instructor/06-custom-workbench-image.md)） |
| 根目錄空空的 | 進入 **`notebooks/`** |
| `/mnt/corrdiff` 不存在 | Additional storage 未掛到此路徑 |
| GPU Pending 很久 | 資源被佔；錯開時段或只做到檔案檢查 |
| 沒有 Terminal | 請講師確認映像含 Terminal（重建／再 Import）；或用 Console → Pods → Terminal／Logs |

---

## 已知限制

- 本教材使用既有測試日 `20260707` 的 input NC（完整 GRIB 前處理不在此包主線）  
- 未涵蓋 Dashboard Deploy model／KServe  
- 多人同時 GPU 推論可能排隊失敗  
