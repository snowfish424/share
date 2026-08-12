# 00 — CorrDiff 路線｜學員一頁紙

> **文件格式**：本檔在 `docs/`（Markdown）。JupyterLab 對應檔在 `docs-ipynb/`。

> **階段**：本包 **階段 2**（建議先完成 [Quickstart](../../quickstart/docs/workshop-student-oneday.md)）  
> **時長**：約 75～100 分鐘（含 GPU 等待）  
> **目標**：在 OAI 上完成 CorrDiff GPU 推論（PVC + 自訂映像 + Notebook）  
> **範圍**：本包 `corrdiff/`（Dashboard + JupyterLab；不必本機 `oc`）  
> **詳細步驟**：[02 — Workbench 推論教學](02-workbench-tutorial.md)

---

## 今日你會完成什麼？

| 優先級 | 內容 | 你要做的事 |
|--------|------|------------|
| **必達** | Workbench 推論 | 開 CorrDiff GPU Workbench → 跑 `01-test-corrdiff-inference.ipynb` → 產出 output NC |

> 講師若已備好專案、PVC 與 seed → **直接從 [02 第 2 章](02-workbench-tutorial.md#第-2-章開啟-corrdiff-workbench) 開始**。  

---

## 三個介面（記得這就夠）

| 介面 | 今天主要用途 |
|------|----------------|
| **OpenShift AI Dashboard** | 建專案、Cluster storage、Workbench |
| **JupyterLab**（Workbench 內） | 跑推論 Notebook |
| **OpenShift Console** | 除錯（Pods／Jobs／Logs）；多數步驟用不到 |

今天**不必**在本機裝 `oc` CLI。Seed 大型權重由**講師**代跑。

### 你的帳號是 User，不是 Admin

| | **User**（你） | **Admin**（講師／平台） |
|--|----------------|------------------------|
| 建專案、PVC、Workbench、跑 Notebook | ✅ | ✅ |
| Import CorrDiff 映像、GPU Hardware Profile | ❌ | ✅ |
| Seed `/mnt/corrdiff`（`oc` + 本機模型） | ❌（課堂） | ✅ |

---

## 必做步驟索引

| 步驟 | 你要做什麼 | 章節 |
|------|------------|------|
| 1 | 向講師確認：CorrDiff 映像可選、GPU Profile、PVC 已有資料（或你要自己建） | [02 第 0 章](02-workbench-tutorial.md#第-0-章開始之前) |
| 2 | （若講師未備）Create project → Cluster storage `corrdiff-workspace` → 請講師 seed | [02 第 1 章](02-workbench-tutorial.md#第-1-章專案與資料-pvc) |
| 3 | Create workbench：CorrDiff 映像 + GPU Profile，掛 `/mnt/corrdiff` | [02 第 2 章](02-workbench-tutorial.md#第-2-章開啟-corrdiff-workbench) |
| 4 | 跑 `01-test-corrdiff-inference.ipynb`（建議逐步 Run） | [02 第 3 章](02-workbench-tutorial.md#第-3-章執行推論-notebook) |
| 5 | 確認輸出 NC 可讀／可繪圖 | [02 完成檢查](02-workbench-tutorial.md#完成檢查清單) |

**預期產出**：

```text
/mnt/corrdiff/dtg/EC_S2S_AIPP/20260707/CorrdiffOutput_EC_RAW_20260707.nc
```

---

## 完成檢查清單

- [ ] Workbench Running；`/mnt/corrdiff` 有 `bin/`、`etc/`、`workdir/`
- [ ] `cuda True`、`modulus OK`
- [ ] 推論 `exit code: 0`，輸出 NC 存在

---

## 課後閱讀

| 文件 | 適合 |
|------|------|
| [01-overview.md](01-overview.md) | 為什麼要 PVC + 自訂映像 |
| [instructor/06-custom-workbench-image.md](instructor/06-custom-workbench-image.md) | **講師**：映像建置與 Import |
| [instructor/05-seed-scripts.md](instructor/05-seed-scripts.md) | **講師**：seed 說明 |
