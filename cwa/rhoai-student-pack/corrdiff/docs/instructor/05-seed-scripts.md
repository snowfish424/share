# 05 — Seed 腳本說明（`oc`）

> **文件格式**：本檔在 `docs/`（Markdown）。JupyterLab 對應檔在 `docs-ipynb/`。

> **對象**：講師／助教，或課後有 `oc` 與本機模型資料的學員  
> **課堂學員**：通常**不必**自己跑；確認 Workbench 裡 `/mnt/corrdiff` 有檔即可。

## 發放目錄（只有兩個）

```text
（發放根目錄）/
├── corrdiff_for_ocp/          ← bin、etc、workdir（測試日 NC）…
└── rhoai-student-pack/
    └── corrdiff/
        ├── config/gen_config.yaml
        └── scripts/seed-data.sh
```

腳本預設找**與 `rhoai-student-pack` 同層**的 `corrdiff_for_ocp`。  
設定範本在本包：`corrdiff/config/gen_config.yaml`（也可用 `corrdiff_for_ocp/config/`）。

---

## 怎麼跑

在 **`rhoai-student-pack/corrdiff/`** 下（或包根 `./scripts/seed-data.sh` 轉呼叫）：

```bash
cd rhoai-student-pack/corrdiff
./scripts/seed-data.sh
```

若兩目錄不在同層：

```bash
CORRDIFF_SRC=/path/to/corrdiff_for_ocp ./scripts/seed-data.sh
```

可選環境變數：`NAMESPACE`（預設 `corrdiff-poc`）、`CORRDIFF_DATE`（預設 `20260707`）、`CORRDIFF_GEN_CONFIG`。

---

## 為什麼要 seed？

PVC 剛建立是**空的**。Seed = 把本機上的程式、權重、測試輸入拷進叢集硬碟，供 Job／Workbench 使用。

```text
本機（corrdiff_for_ocp）              叢集 PVC（/mnt/corrdiff）
──────────────────────              ────────────────────────
bin/                           ──►   bin/
lib/                           ──►   lib/  （修復 bin/lib symlink）
etc/（模型，約數百 MB）         ──►   etc/
CorrdiffInput_*.nc             ──►   workdir/...
```

瀏覽器不適合傳這種體積，所以用 `oc cp`。

---

## 為什麼要有 seed Pod？

OpenShift 不能直接對 PVC 下指令，必須有一個**已掛上該 PVC、正在跑的 Pod**，才能 `oc exec`／`oc cp`。

腳本會建立 Job `corrdiff-seed`（見 `k8s/seed-pod.yaml`）：輕量映像 + `sleep`，當「跳板」。

---

## `oc` 小辭典

| 概念 | 白話 |
|------|------|
| `oc apply -f …` | 依 YAML 建立／更新資源 |
| `oc cp 本機 專案/Pod:路徑` | 本機 → PVC（經由 Pod） |
| `oc exec … -- 指令` | 在 Pod 內執行 |
| `-n corrdiff-poc` | 指定專案 |

---

## 主流程概念（`seed-data.sh`）

1. 上傳 `bin/` 與 `lib/`（`bin/lib` 常為 symlink → `../lib`，必須另傳 `lib/`）  
2. 上傳設定範本 `gen_config.yaml`  
3. 上傳 `etc/`（最久）  
4. 上傳測試日 input NC（若有）  
5. 在 Pod 內產生 **`SHOME=/mnt/corrdiff`** 的 `config.yaml`（**不要**留下 HPC `/nwpr` 路徑）  
6. 檢查檔案存在  

預設測試日：`20260707`。

學員主線到此即可 → Workbench + `notebooks/01-test-corrdiff-inference.ipynb`。

---

## 選用：`seed-grib-smoke.sh`（非學員主線）

把 `corrdiff_for_ocp/dat/EC_S2S/<DATE>/` 少量 GRIB 拷進 PVC。  
**本發放不含 preprocess Job**；課堂請用已準備好的 `CorrdiffInput_*.nc`（`seed-data.sh`），不要依賴 GRIB→NC 流程。

---

## 常見問題

| 問題 | 說明 |
|------|------|
| `No module named 'lib'` | seed 未傳 `lib/`（`bin/lib` 是 symlink）；更新後 seed 或手動 `oc cp …/lib/.` |
| `app/bin/. doesn't exist` | 舊路徑假設；應從同層 `corrdiff_for_ocp/bin` 取 |
| 找不到 `corrdiff_for_ocp` | 放到與 `rhoai-student-pack` **同層**，或設 `CORRDIFF_SRC` |
| Workbench 裡路徑是 `/nwpr/...` | config 用了 HPC 版；需重跑 seed／config_gen，目標為 `/mnt/corrdiff` |
| PVC Terminating 刪不掉 | 常有 seed／Job Pod 仍掛著；先刪相關 Pod／Job |
| 學員沒有模型資料 | 請確認已發放 `corrdiff_for_ocp`，或由講師代 seed |

相關操作主線仍回到：[02-workbench-tutorial.md](../02-workbench-tutorial.md)
