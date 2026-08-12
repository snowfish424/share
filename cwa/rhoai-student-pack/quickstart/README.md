# Quickstart 路線（學員版）— 階段 1

> **文件格式**：Markdown 在 [`docs/`](docs/)；JupyterLab 在 [`docs-ipynb/`](docs-ipynb/)（內容相同）。

**入門階段**：RHOAI 3.4  
**必達**：Iris 手動（單元 A）＋ Pipeline Editor 用 **Iris**（單元 B）

完成後再進入 [CorrDiff 路線（階段 2）](../corrdiff/README.md)。

**主線只用 OpenShift AI Dashboard + JupyterLab**（必要時 Console 看 Pods／Logs）；不必本機 `oc`。

## 建議順序

1. **[`docs/00-hands-on-onepage.md`](docs/00-hands-on-onepage.md)**（一頁式實操）
2. [`docs/workshop-student-oneday.md`](docs/workshop-student-oneday.md)（半天目標一覽）
3. [`docs/getting-started-ui-tutorial.md`](docs/getting-started-ui-tutorial.md)（卡關時看完整步驟）
4. [`docs/pipeline-ui-tutorial.md`](docs/pipeline-ui-tutorial.md)（Iris Pipeline Editor 細節）
5. [`docs/rbac-ocp-vs-oai.md`](docs/rbac-ocp-vs-oai.md)（OCP vs OAI 兩層權限）
6. [`docs/rbac-admin-vs-user.md`](docs/rbac-admin-vs-user.md)（課堂 Admin／User 職責）

## 講師／Admin

- [`docs/instructor/hardware-profiles-ui-tutorial.md`](docs/instructor/hardware-profiles-ui-tutorial.md)
- [`docs/instructor/workshop-half-day-4h.md`](docs/instructor/workshop-half-day-4h.md)
- [`scripts/`](scripts/)（進階／代建 Pipeline server）

## 資產位置

- 實作 Notebook：`notebooks/`（`00`–`02`）
- Elyra：`pipelines/elyra/iris-train-pipeline.pipeline`
- 進階：`scripts/`、`k8s/`

## 注意

- Pipeline Editor 練習用 **Iris**。
- 與 CorrDiff 路線請勿混用資產。
