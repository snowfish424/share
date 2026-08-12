# CorrDiff 自訂 Workbench 映像

把 CorrDiff 推論所需套件（PyTorch 2.4、CUDA 11.8、NVIDIA Modulus 0.9、netCDF4、JupyterLab、Terminal）bake 進映像，供 OpenShift AI Dashboard **Import**。

**完整步驟說明（中文）**：[`docs/instructor/06-custom-workbench-image.md`](../docs/instructor/06-custom-workbench-image.md)

```bash
chmod +x scripts/*.sh
./scripts/build-and-push.sh          # 本機建置
./scripts/podman-local-test.sh       # 本機驗證
./scripts/build-and-push.sh --push   # 推到 Quay（需 login）
```

預設映像：`quay.io/cwa/rhoai/corrdiff-workbench:latest`
