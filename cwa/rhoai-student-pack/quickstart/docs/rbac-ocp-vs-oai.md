# OCP 與 OAI 的 RBAC：兩層權限怎麼分

> **文件格式**：本檔在 `docs/`（Markdown）。JupyterLab 對應檔在 `docs-ipynb/`。

> **目的**：釐清 **OpenShift（OCP）** 與 **OpenShift AI（OAI／RHOAI）** 的權限是**兩套、疊在一起**，不是同一件事換名字。  
> **對象**：講師、平台 Admin、要跟客戶說明「誰能幹嘛」的人  
> **搭配**：[Admin 與 User（教學職責）](rbac-admin-vs-user.md)（課堂誰做哪一步）

---

## 一句話

| 層級 | 管什麼 | 白話 |
|------|--------|------|
| **OCP RBAC** | 叢集／專案裡的 **K8s／OpenShift 資源** | 「能不能建 Pod、PVC、專案、看別人 namespace？」 |
| **OAI RBAC** | **OpenShift AI Dashboard** 與平台 AI 功能 | 「能不能進 Dashboard、看到 Settings、Import 映像、用 Data Science 專案？」 |

登入同一個 IdP 帳號，但：

- **OCP 有權 ≠ OAI Admin**（例如專案 `admin` 看不到 Dashboard **Settings**）  
- **OAI User ≠ 叢集隨意操作**（Workbench Terminal 也不能代替 `cluster-admin`）

```text
                    ┌─────────────────────────────┐
                    │  同一個人／同一個 IdP 帳號   │
                    └─────────────┬───────────────┘
                                  │
              ┌───────────────────┴───────────────────┐
              ▼                                       ▼
   ┌──────────────────────┐              ┌──────────────────────┐
   │  OCP RBAC            │              │  OAI RBAC            │
   │  RoleBinding／        │              │  群組／產品角色       │
   │  ClusterRoleBinding  │              │ （如 rhods-admins）   │
   │  → oc／Console 資源  │              │  → Dashboard 選單     │
   └──────────────────────┘              └──────────────────────┘
```

---

## 對照總表

| 面向 | **OCP** | **OAI（RHOAI）** |
|------|---------|------------------|
| **產品** | OpenShift Container Platform | OpenShift AI（Dashboard + Notebooks／Pipelines／Serving…） |
| **主要 UI** | OpenShift **Console**、`oc` | OpenShift AI **Dashboard**、Workbench（JupyterLab） |
| **授權單位** | User／Group + Role／ClusterRole + Binding | 產品群組／角色（常見 **`rhods-admins`**）+ 專案內權限 |
| **「Admin」常指** | `cluster-admin`、或某 Project 的 `admin` | 能開 Dashboard **Settings** 的平台管理員 |
| **「User」常指** | 一般開發者（常有 `edit`／可建專案） | Data Science **User**：可建／進 AI 專案、Workbench、Deploy |
| **作用範圍** | Namespace（Project）或整個叢集 | 平台設定（叢集級）＋各 Data Science Project |
| **典型資源** | Pod、Deployment、PVC、Route、Project | Workbench、Pipeline Server、Model、Hardware Profile、Workbench Image |
| **本教學學員** | 通常只需**自己專案**內的編輯權 | 需要是 **OAI User**（能進 Dashboard、Create project） |
| **本教學講師／平台** | 常另具較高 OCP 權（除錯／代建） | 需 **OAI Admin**（Import 映像、Hardware Profile、開元件） |

---

## OCP RBAC（平台底座）

OpenShift 沿用 Kubernetes RBAC，再加上 Project／SCC 等概念。

| 概念 | 說明 |
|------|------|
| **User／Group** | 人從 IdP（LDAP／OIDC…）登入後的身分 |
| **Role** | 一組 API 權限（get／list／create…），綁在**某個** namespace |
| **ClusterRole** | 同上，但可綁到**整個叢集**（或經 Binding 限於一專案） |
| **RoleBinding／ClusterRoleBinding** | 「誰」拿到「哪個 Role」 |
| **Project** | 大致＝ namespace；資源名只在**該專案內**唯一 |

常見角色（名稱以叢集為準）：

| 角色 | 典型能力 |
|------|----------|
| **`cluster-admin`** | 整叢集幾乎全能（慎給） |
| **專案 `admin`** | 管**該** Project：成員、Quota 內資源；**不是** OAI Settings |
| **`edit`** | 在專案內建／改工作負載、PVC 等，通常不能改角色綁定 |
| **`view`** | 唯讀 |
| **可 Create project** | 常與 self-provisioner 一類權限有關（由平台決定） |

**跟本課的關係**：學員在自己的 `rhoai-qs-<縮寫>` 裡建 Workbench／PVC／Deploy，背後都要過 **OCP** 對該 namespace 的允許。換專案就換 namespace，**同名 PVC 不衝突**。

---

## OAI RBAC（AI 產品層）

OAI 在 OCP 之上多一層「誰能用 AI Dashboard／平台功能」。實作常靠 **群組**（名稱因版本／客戶而異）：

| 口語 | 常見對應 | 典型能力 |
|------|----------|----------|
| **OAI Admin** | 群組 **`rhods-admins`**（或等價） | Dashboard **Settings**：元件、Workbench images Import／Enable、Hardware profiles… |
| **OAI User** | 可登入 Dashboard 的資料科學使用者 | **Projects**、Workbench、Cluster storage、Deploy model、Pipeline（專案內） |

| Dashboard 現象 | 多半代表 |
|----------------|----------|
| 左側有 **Settings** | **OAI Admin** |
| 只有 Projects／Applications，**沒有**平台 Settings | **OAI User**（學員正常樣貌） |
| 完全進不了 Dashboard／沒有 Projects | 尚未授 **OAI User**（或 IdP 未對上） |

**跟本課的關係**：

- 學員＝**OAI User** 即可跑單元 A／B  
- Import 自訂映像、建 `gpu-1` Hardware Profile＝**OAI Admin** 課前做  
- 詳細「誰做哪一步」見 [rbac-admin-vs-user.md](rbac-admin-vs-user.md)

---

## 最容易混的三點

### 1. 「我是 admin」——哪一種 Admin？

| 他說的 admin | 實際常是 | 能不能開 OAI Settings？ |
|--------------|----------|-------------------------|
| 某專案的 Project admin | **OCP** 專案 `admin` | **通常不能** |
| 叢集管理員 | **OCP** `cluster-admin` | 常**可以**（且權限過大） |
| AI 平台管理員 | **OAI** `rhods-admins` 等 | **可以**（這才是教學說的 Admin） |

### 2. 兩層都要「對」，功能才完整

| 情境 | OCP | OAI | 結果 |
|------|:---:|:---:|------|
| 理想學員 | 自己專案可編輯 | User | Dashboard 做事正常 |
| 只有 OCP 高權、沒進 OAI 群組 | ✅ | ❌／不足 | Console 很強，Dashboard 仍可能沒 Settings／不好用 |
| 有 OAI User、專案內 OCP 權被拿掉 | ❌ | ✅ | 看得到選單，Create workbench 失敗 |
| 講師除錯 | 常需較高 OCP | 常需 OAI Admin | 可代建 Pipeline server、看任意專案 Pod |

### 3. Workbench 裡的 Terminal ≠ 任一層的 Admin

那是 **Pod 內 shell**，權限跟該 Workbench 的 ServiceAccount／專案 RBAC 走，**不能**拿來 Import 映像或改叢集 Settings。

---

## 客戶落地怎麼切（建議說法）

| 角色 | OCP 建議 | OAI 建議 | 負責 |
|------|----------|----------|------|
| **平台組** | 足夠管理 RHOAI 運算子／節點（常含高權） | **OAI Admin** | 裝元件、映像、Hardware Profile、發帳號 |
| **資料科學家／學員** | **僅自己的 Project**（edit／admin 皆可，勿給 cluster-admin） | **OAI User** | 訓練、Deploy、Pipeline |
| **助教** | 可視需要加讀／進學員專案 | User 或有限 Admin | 幫卡關，仍避免人人 Settings |

**不要**為了「好教」把全班都加進 `rhods-admins` 或給 `cluster-admin`。

---

## 和本包文件怎麼分工

| 文件 | 讀什麼 |
|------|--------|
| **本頁** | OCP vs OAI **兩層差異**、名詞別混 |
| [rbac-admin-vs-user.md](rbac-admin-vs-user.md) | 課堂 **Admin vs User** 誰做哪步、檢查清單 |
| [getting-started 0.1](getting-started-ui-tutorial.md#01-admin-與-user先分清角色) | 學員開場一分鐘版 |

---

## 快速自測

1. 專案裡的 `admin` 是不是 OAI 平台 Admin？→ **不是**。  
2. 多人同名 `iris-workbench`／PVC 會不會因同名撞叢集？→ **不會**（OCP 以 Project 隔離）；會撞的是 **Project Resource name**。  
3. 學員要不要 `cluster-admin`？→ **不要**。要的是 **OAI User** + 自己專案的 OCP 編輯權。

---

*RHOAI 3.4 · 群組／Role 名稱以貴司 IdP 與安裝為準；本文講邊界，不綁死單一 ClusterRole 清單。*
