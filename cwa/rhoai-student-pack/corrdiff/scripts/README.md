# scripts／k8s — 進階參考

本目錄腳本與 YAML 供有 `oc`、且本機已有 **`corrdiff_for_ocp`（與學員包同層）** 時使用。

## 發放布局

```text
corrdiff_for_ocp/          ← 權重、bin、測試 NC（等）
rhoai-student-pack/
└── corrdiff/scripts/      ← 在此目錄執行
```

## 學員課堂

一般**不需要**執行這些腳本。請依 `docs/00-oneday.md`（或 `.ipynb`）→ `docs/02-workbench-tutorial.md` 用 Dashboard／JupyterLab。

## 檔案

| 檔案 | 用途 |
|------|------|
| `deploy.sh` | 套用 `k8s/namespace.yaml` + PVC |
| `seed-data.sh` | 從同層 `corrdiff_for_ocp` 寫入 PVC（主線） |
| `seed-grib-smoke.sh` | 選用：GRIB → PVC（**無** preprocess；非學員主線） |
| `run-test.sh` | `smoke`／`inference`／`all` |
| `../config/gen_config.yaml` | 產生 PVC 內 `config.yaml` |

說明：[`docs/instructor/05-seed-scripts.md`](../docs/instructor/05-seed-scripts.md)（同內容另有 `.ipynb`）
