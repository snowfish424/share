# Quickstart scripts／k8s（進階參考）

本目錄供講師或進階自學使用；一般課堂學員可先不執行。

## 主要用途

- `deploy-pipeline.sh`：準備 Pipeline Server 相關前置（DSPA / RBAC 等）
- `run-elyra-pipeline.sh`：從 Workbench 端觸發 Elyra pipeline（示範）  
  （讀取 `pipelines/elyra/iris-train-pipeline.pipeline`）

## 前提

- 在 **`rhoai-student-pack/quickstart/`** 下執行
- 已 `oc login`
- 具有對應 namespace 權限（預設 `rhoai-quickstart`；專案請先在 Dashboard 建立）
- 叢集 Pipeline Server 已就緒

> 若只是跟著學員主線，請直接照 `quickstart/docs/` 進行，不必先跑這些腳本。
