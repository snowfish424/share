# 06 — CorrDiff 自訂 Workbench 映像（製作與 Import）

> **文件格式**：本檔在 `docs/`（Markdown）。JupyterLab 對應檔在 `docs-ipynb/`。

> **對象**：Admin／講師（課前準備）  
> **學員**：通常**不必**自己建映像；建立 Workbench 時選已 Import 的  
> **CorrDiff \| PyTorch \| CUDA \| Modulus** 即可。  
> **建置資產**：本包 [`custom-image/`](../../custom-image/)  
> 官方參考：[Creating custom workbench images（RHOAI 3.4）](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/managing_openshift_ai/creating-custom-workbench-images)

---

## 為什麼要自訂映像？

CorrDiff 推論需要 **PyTorch 2.4 + CUDA 11.8 + NVIDIA Modulus 0.9 + netCDF4**，以及 JupyterLab **Terminal**。  
現場在 Workbench 裡狂 `pip` 既慢又易失敗（氣隙／版本漂移），所以把套件 **bake-in** 進映像，再經 Dashboard **Import**。

| 項目 | 說明 |
|------|------|
| 公開映像（範例） | `quay.io/cwa/rhoai/corrdiff-workbench:latest` |
| Dashboard 顯示名 | `CorrDiff \| PyTorch \| CUDA \| Modulus` |
| 本路線用途 | GPU Workbench + `01-test-corrdiff-inference.ipynb` |
| 不含 | Elyra |

套件安裝進 **`/opt/conda`**（不要裝進 `$HOME`）：OpenShift 會把 Workbench PVC 掛在 `/opt/app-root/src`，會蓋掉家目錄裡的內容。

---

## 本包建置檔

| 檔案 | 用途 |
|------|------|
| [`custom-image/Containerfile`](../../custom-image/Containerfile) | podman／docker 建置 |
| [`custom-image/requirements.txt`](../../custom-image/requirements.txt) | 套件清單 |
| [`custom-image/scripts/build-and-push.sh`](../../custom-image/scripts/build-and-push.sh) | 建置／推送 Quay |
| [`custom-image/scripts/podman-local-test.sh`](../../custom-image/scripts/podman-local-test.sh) | 本機驗證 |
| [`custom-image/k8s/imagestream.yaml`](../../custom-image/k8s/imagestream.yaml) | 可選：CLI 註冊（偏好 Dashboard Import） |

---

## 步驟 1：本機建置

需求：`podman`（或設 `CONTAINER_ENGINE=docker`）、可拉 `pytorch/pytorch:2.4.0-cuda11.8-cudnn9-runtime`。

```bash
cd corrdiff/custom-image
chmod +x scripts/*.sh

# 建置（強制 linux/amd64）
./scripts/build-and-push.sh

# 本機驗證（inspect + save/load；Apple Silicon 會略過 run）
./scripts/podman-local-test.sh
```

**Apple Silicon**：映像為 **linux/amd64**。`build`／`save`／`load` 可以；`podman run` 經 qemu 常會 segfault，屬本機模擬限制，不代表映像壞掉。完整驗證請在 Linux amd64，或 Import 後於叢集 Workbench 執行。

### 磁碟不足（Mac Podman VM）

```bash
podman machine ssh 'df -h /'
# 若空間不足：
podman machine set --disk-size 100
podman machine ssh 'sudo growpart /dev/vda 4 && sudo xfs_growfs /'
podman image prune -f
podman builder prune -af
```

---

## 步驟 2：推送到 registry

需已 `podman login quay.io`（帳號需有目標 org 寫入權限）。預設推到 `quay.io/cwa/rhoai/corrdiff-workbench:latest`；可用環境變數改：

```bash
export QUAY_ORG=quay.io/<your-org>   # 選用
./scripts/build-and-push.sh --push
# 或只推既有本地映像：
# SKIP_BUILD=1 ./scripts/build-and-push.sh --push
```

---

## 步驟 3：Dashboard Import（Admin UI）

1. **Settings** → **Environment setup** → **Workbench images**  
2. **Import image**  
3. 建議填寫：

| 欄位 | 建議值 |
|------|--------|
| Image location | `quay.io/cwa/rhoai/corrdiff-workbench:latest`（或你的 registry） |
| Name | `CorrDiff \| PyTorch \| CUDA \| Modulus` |
| Description | CorrDiff GPU 推論；Modulus／netCDF／Terminal 已 bake-in |
| Packages（選填） | PyTorch 2.4、nvidia-modulus 0.9、netCDF4、Terminal |

4. **Import** → 確認 **Enable**

學員建立 Workbench 時選此映像，並掛資料 PVC 到 `/mnt/corrdiff`（見 [02-workbench-tutorial.md](../02-workbench-tutorial.md)）。

### 可選：CLI 刷新 ImageStream

Dashboard Import 後，ImageStream 名稱通常來自顯示名（`corrdiff-pytorch-cuda-modulus`），**不是** repo 名 `corrdiff-workbench`。

```bash
oc get is -n redhat-ods-applications | grep -i corrdiff

oc import-image corrdiff-pytorch-cuda-modulus \
  -n redhat-ods-applications \
  --from=quay.io/cwa/rhoai/corrdiff-workbench:latest \
  --confirm
```

推送新 tag 後：Workbench **Stop → Start**（或刪 Pod），`imagePullPolicy: Always` 才會拉到新 digest。  
也可 `oc apply -f custom-image/k8s/imagestream.yaml`。

---

## 常見問題

| 問題 | 怎麼辦 |
|------|--------|
| 沒有 Terminal | 需 `jupyter-server-terminals` + `terminado` + `bash`（本映像已含）。舊 tag 請重建再 Import |
| Import 後選不到映像 | 確認 Enable；學員是 User，映像需 Admin 先 Import |
| Workbench 裡 `import modulus` 失敗 | 映像選錯，或 PVC 蓋掉錯誤安裝路徑；應使用本自訂映像 |
| Apple Silicon `podman run` segfault | 略過本機 run；以叢集 Workbench 驗證 |

---

## 與學員主線的關係

```text
講師：build → push → Dashboard Import → Enable
學員：Create workbench（選 CorrDiff 映像）→ 掛 /mnt/corrdiff → 跑 01 notebook
```

Seed 資料仍見 [05-seed-scripts.md](05-seed-scripts.md)。
