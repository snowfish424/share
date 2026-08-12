# CorrDiff 路線（學員版）— 階段 2

> **文件格式**：Markdown 在 [`docs/`](docs/)；JupyterLab 在 [`docs-ipynb/`](docs-ipynb/)（內容相同）。

建議先完成 [Quickstart 路線（階段 1）](../quickstart/README.md)，再走本路線。

這條路線聚焦在 CorrDiff 推論遷移：PVC、自訂映像、GPU Workbench + Notebook。  
**學員主線只用 OpenShift AI Dashboard + JupyterLab**（必要時 Console 看 Jobs／Logs）；不必本機 `oc`。

## 建議順序

1. [`docs/00-oneday.md`](docs/00-oneday.md)（先看一頁紙）
2. [`docs/01-overview.md`](docs/01-overview.md)
3. [`docs/02-workbench-tutorial.md`](docs/02-workbench-tutorial.md)（必達）

## 講師／Admin

- [`docs/instructor/06-custom-workbench-image.md`](docs/instructor/06-custom-workbench-image.md)（**自訂映像製作／Import**）
- [`docs/instructor/05-seed-scripts.md`](docs/instructor/05-seed-scripts.md)（PVC seed）
- [`custom-image/`](custom-image/)（Containerfile 與建置腳本）
- [`scripts/`](scripts/)、[`k8s/`](k8s/)（seed／Job）

## 資產位置

- 實作 Notebook：`notebooks/01-test-corrdiff-inference.ipynb`
- 自訂映像建置：`custom-image/`
- 進階腳本與 YAML：`scripts/`、`k8s/`（PVC、seed、smoke／inference Job）

## 注意

- 模型權重與測試檔在同層的 **`corrdiff_for_ocp/`**（發放時與此包一併提供）；課堂也可由講師先 seed。
- 學員**不必**自己建映像；由講師／Admin Import 後即可選用。
- 與 Quickstart 路線資產請勿混用。
