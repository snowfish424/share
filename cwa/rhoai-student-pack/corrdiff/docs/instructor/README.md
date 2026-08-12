# 講師文件（CorrDiff）

> **文件格式**：本檔在 `docs/`（Markdown）。JupyterLab 對應檔在 `docs-ipynb/`。

本目錄僅供 **Admin／講師** 課前準備；學員主線請看上一層 `docs/`（從 [`00-oneday.md`](../00-oneday.md) 開始）。

| 文件 | 用途 |
|------|------|
| [05-seed-scripts.md](05-seed-scripts.md) | 用 `oc` 將 bin／etc／測試日寫入 PVC；含 `seed-grib-smoke` 說明 |
| [06-custom-workbench-image.md](06-custom-workbench-image.md) | **自訂 Workbench 映像**：建置、推送 Quay、Dashboard Import |

建置資產：[`../../custom-image/`](../../custom-image/)（Containerfile、requirements、腳本）。  
Seed／腳本：[`../../scripts/`](../../scripts/)、[`../../k8s/`](../../k8s/)、[`../../config/gen_config.yaml`](../../config/gen_config.yaml)。  
發放只有 **`corrdiff_for_ocp` + `rhoai-student-pack`（同層）**；在 `corrdiff/` 下跑 `./scripts/seed-data.sh`。
