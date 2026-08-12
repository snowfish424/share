# 01 — CorrDiff 遷到 OpenShift AI：你要先懂什麼

> **文件格式**：本檔在 `docs/`（Markdown）。JupyterLab 對應檔在 `docs-ipynb/`。

> **對象**：學員（課堂／課後）  
> **前提**：建議已完成本包 [Quickstart（階段 1）](../../quickstart/docs/workshop-student-oneday.md)  
> **手把手操作**：[02-workbench-tutorial.md](02-workbench-tutorial.md)

---

## 一句話

CorrDiff 不是「把 notebook 丟上叢集」就結束，而是把既有可執行資產拆成：

- **程式與權重** → 資料 PVC（`/mnt/corrdiff`）  
- **執行期依賴** → 自訂 Workbench 映像（PyTorch + CUDA + Modulus）  
- **批次驗證** → Job（Console／講師）  
- **互動驗證** → GPU Workbench + Notebook（學員主線）  

---

## 路徑總覽

```text
既有腳本（bin / etc / 輸入 NC）
        │
        ▼
PVC seed（程式、權重、測試輸入）
        │
        ▼
自訂映像（套件 bake-in，不要現場狂 pip）
        │
        ├─► Workbench：逐步跑 Notebook 推論（學員主線）
        └─► Job：批次 smoke／inference（對照／講師）
```

| 形態 | 解決什麼 |
|------|----------|
| 資料 PVC `corrdiff-workspace` | 權重大、可給 Job／Workbench 共用 |
| CorrDiff 自訂映像 | Modulus／CUDA 版本鎖定 |
| GPU Workbench | 互動檢查與演示 |

本路線**不做** KServe「Deploy model」線上 API；重點是**推論在叢集上可重現**。

---

## 與預設 Data Science Workbench 的差異

| 預設 Data Science（CPU） | CorrDiff |
|--------------------------|----------|
| 官方映像、可臨時 pip | **自訂映像**，套件已 bake-in |
| 資料常在家目錄 PVC | 程式／權重／輸入在 **`/mnt/corrdiff`** |
| 常見：訓練小模型 + Deploy | **推論**既有模型 |
| CPU 即可 | **需要 GPU** |
| 常有 Pipeline Editor（Elyra） | 本映像以推論套件為主 |

---

## 誰做什麼

| 項目 | 通常誰做 |
|------|----------|
| Import CorrDiff 映像、GPU Hardware Profile | Admin／講師（映像製作見 [06-custom-workbench-image.md](instructor/06-custom-workbench-image.md)） |
| 建專案、PVC、Workbench、跑 Notebook | 學員（User） |
| Seed 大型 `etc/` 進 PVC | 講師（`oc` + 本機資料） |

課堂若講師已備好專案與資料，你可從 [02-workbench-tutorial.md](02-workbench-tutorial.md) **第 2 章**開始。
