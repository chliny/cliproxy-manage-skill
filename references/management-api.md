# CLIProxyAPI 管理 API (Management API) 详细文档

该 API 用于管理 CLIProxyAPI 的运行时配置与认证文件，所有的配置变更会持久化写入 YAML 配置文件并由服务自动热重载。

---

### **基本信息与源信息**
* **基础路径**：`http://localhost:8317/v0/management`
* **来源**：Router-For.ME 官方文档

---

### **认证机制 (Authentication)**
所有请求（包括本地 localhost 访问）必须提供有效的管理密钥。
* **远程访问**：须在配置文件中开启：`remote-management.allow-remote: true`。
* **提供方式**（任选其一，发送明文）：
  * 请求头 `Authorization: Bearer <plaintext-key>`
  * 请求头 `X-Management-Key: <plaintext-key>`
* **临时封禁**：任何 IP 连续 5 次认证失败将触发约 30 分钟的临时封禁。
* **注意**：以下两项配置**不能**通过 API 修改，必须直接在配置文件中设置：
  * `remote-management.allow-remote`
  * `remote-management.secret-key`（若启动时为明文，服务会自动使用 bcrypt 加密并写回配置文件）

---

### **通用错误响应**
* **400 Bad Request**: `{ "error": "invalid body" }`
* **401 Unauthorized**: `{ "error": "missing management key" }` 或 `{ "error": "invalid management key" }`
* **403 Forbidden**: `{ "error": "remote management disabled" }`
* **404 Not Found**: `{ "error": "item not found" }` 或 `{ "error": "file not found" }`
* **422 Unprocessable Entity**: `{ "error": "invalid_config", "message": "..." }`
* **500 Internal Server Error**: `{ "error": "failed to save config: ..." }`
* **503 Service Unavailable**: `{ "error": "core auth manager unavailable" }`

---

### **API 端点详细说明**

#### **1. 基础配置与调试 (Config & Debug)**

| 端点路径 | 方法 | 参数/请求体 | 说明与响应 |
| :--- | :--- | :--- | :--- |
| `/config` | `GET` | 无 | 获取完整的 JSON 格式配置（不含遗留的 `generative-language-api-key`）。若未加载配置则返回 `{}`。 |
| `/config.yaml` | `GET` | 无 | 原样下载持久化的 YAML 配置文件。返回流保留注释与格式。 |
| `/config.yaml` | `PUT` | **Body (Content-Type: `application/yaml`)**: 原始 YAML 数据 | 整体替换配置文件。验证失败返回 422；成功写入返回 `{ "ok": true, "changed": ["config"] }`。 |
| `/debug` | `GET` | 无 | 获取当前 debug 状态，响应 `{ "debug": false }`。 |
| `/debug` | `PUT`/`PATCH` | **Body**: `{"value": true/false}` | 设置 debug 状态。成功返回 `{ "status": "ok" }`。 |
| `/latest-version` | `GET` | 无 | 从 GitHub 查询最新发行版本号。响应 `{ "latest-version": "v1.2.3" }`。 |

---

#### **2. 用量统计队列 (Usage Queue)**

| 端点路径 | 方法 | 参数/请求体 | 说明与响应 |
| :--- | :--- | :--- | :--- |
| `/usage-statistics-enabled` | `GET` | 无 | 查看是否启用了请求统计，响应 `{ "usage-statistics-enabled": true }`。 |
| `/usage-statistics-enabled` | `PUT`/`PATCH` | **Body**: `{"value": true/false}` | 启用或关闭用量统计服务。 |
| `/usage-queue` | `GET` | **Query**: `count` (可选，默认 1，必须为正整数) | 从队列中弹出并拉取最多 `count` 条 JSON 格式用量记录（弹出后记录会从队列中移除）。队列为空返回 `[]`。 |

---

#### **3. 日志管理 (Logs)**

| 端点路径 | 方法 | 参数/请求体 | 说明与响应 |
| :--- | :--- | :--- | :--- |
| `/logging-to-file` | `GET` | 无 | 查看是否启用文件日志，响应 `{ "logging-to-file": true }`。 |
| `/logging-to-file` | `PUT`/`PATCH` | **Body**: `{"value": true/false}` | 开启或关闭文件日志。 |
| `/logs` | `GET` | **Query**: `after` (可选，Unix 时间戳) | 获取最新的日志行（仅返回 `after` 时间之后的日志）。若无文件日志或未启用，会返回 400 错误。 |
| `/logs` | `DELETE` | 无 | 删除轮换日志并清空主日志。 |
| `/request-error-logs` | `GET` | 无 | 当 `request-log` 为 false 时，列出错误请求日志文件列表。 |
| `/request-error-logs/:name` | `GET` | **Path**: `:name` (日志文件名) | 下载指定的错误请求日志文件（防路径穿越校验）。 |
| `/request-log` | `GET` | 无 | 获取请求日志开关状态（布尔值）。 |
| `/request-log` | `PUT`/`PATCH` | **Body**: `{"value": true/false}` | 设置是否记录请求日志。 |

---

#### **4. 网络与重试代理设置 (Network & Retry)**

| 端点路径 | 方法 | 参数/请求体 | 说明与响应 |
| :--- | :--- | :--- | :--- |
| `/proxy-url` | `GET` | 无 | 获取当前全局代理 URL，如 `{ "proxy-url": "socks5://..." }`。 |
| `/proxy-url` | `PUT`/`PATCH` | **Body**: `{"value": "socks5://..."}` | 设置代理服务器 URL。 |
| `/proxy-url` | `DELETE` | 无 | 清空全局代理配置。 |
| `/request-retry` | `GET` | 无 | 获取请求重试次数（整数）。 |
| `/request-retry` | `PUT`/`PATCH` | **Body**: `{"value": 5}` | 设置请求最大重试次数。 |
| `/max-retry-interval` | `GET` | 无 | 获取最大重试间隔时间（秒）。 |
| `/max-retry-interval` | `PUT`/`PATCH` | **Body**: `{"value": 60}` | 设置最大重试间隔时间（秒）。 |

---

#### **5. 超出配额行为 (Quota Exceeded)**

| 端点路径 | 方法 | 参数/请求体 | 说明与响应 |
| :--- | :--- | :--- | :--- |
| `/quota-exceeded/switch-project` | `GET` | 无 | 查询配额超限时是否切换项目。 |
| `/quota-exceeded/switch-project` | `PUT`/`PATCH` | **Body**: `{"value": true/false}` | 设置配额超限时是否切换项目。 |
| `/quota-exceeded/switch-preview-model` | `GET` | 无 | 查询配额超限时是否切换预览模型。 |
| `/quota-exceeded/switch-preview-model` | `PUT`/`PATCH` | **Body**: `{"value": true/false}` | 设置配额超限时是否切换预览模型。 |

---

#### **6. API Keys (代理服务客户端身份验证)**

| 端点路径 | 方法 | 参数/请求体 | 说明与响应 |
| :--- | :--- | :--- | :--- |
| `/api-keys` | `GET` | 无 | 获取完整的 API 密钥列表。 |
| `/api-keys` | `PUT` | **Body**: `["k1", "k2", "k3"]` | 完整改写 API 密钥列表。 |
| `/api-keys` | `PATCH` | **Body**: `{"old":"k2","new":"k2b"}` 或 `{"index":0,"value":"k1b"}` | 修改指定的某个 API 密钥。 |
| `/api-keys` | `DELETE` | **Query**: `value` 或 `index` | 删除其中一个指定的 API 密钥。 |
| `/api-key-usage` | `GET` | 无 | 按提供商与 API Key 分组，返回最近请求的统计桶数据。 |

---

#### **7. 服务商 API 密钥配置 (Provider Keys)**

以下端点分别针对 **Gemini**, **Codex**, **Claude**, 和 **OpenAI 兼容提供商** 的 API 密钥进行 CRUD 管理：

* **共同更新规范**：
  * 支持数组 `PUT`（完整改写）。
  * 支持通过索引 `index` 或特征匹配 `match` 传入对象体进行 `PATCH`（局部修改）。
  * 支持通过 `api-key`、`name` 或 `index` 进行 `DELETE`。

| 提供商路径 | 对象结构体核心字段 (用于 PUT / PATCH) | 说明 |
| :--- | :--- | :--- |
| `/gemini-api-key` | `api-key`, `base-url`, `headers`, `proxy-url`, `excluded-models` | 管理 Gemini 原生 API Key，`excluded-models` 支持屏蔽特定模型。 |
| `/codex-api-key` | `api-key`, `base-url` (必填), `proxy-url`, `headers`, `excluded-models` | 管理 Codex 服务提供商。若 `base-url` 在 PUT/PATCH 中留空则会删除条目。 |
| `/claude-api-key` | `api-key`, `base-url`, `proxy-url`, `headers` (自定义请求头), `excluded-models` | 管理 Claude (Anthropic) 服务提供商。 |
| `/openai-compatibility` | `name` (必填), `disabled` (布尔值), `base-url` (必填), `api-key-entries` (数组), `models`, `headers` | 管理 OpenAI 兼容类提供商。`disabled: true` 可临时禁用该渠道而不删除。 |

* **OAuth 排除模型 (`/oauth-excluded-models`)**：
  * 用于为基于 OAuth 的提供商配置需要排除的模型列表（如限制 openai、claude 等）。
  * 支持 `GET`（获取映射）、`PUT`（完整替换）、`PATCH`（更新单个提供商排除的模型列表，如 `{"provider":"claude","models":["claude-3-5-haiku-20241022"]}`）以及 `DELETE`（清空指定提供商的排除模型）。

---

#### **8. WebSocket 鉴权 (WS-Auth)**

| 端点路径 | 方法 | 参数/请求体 | 说明与响应 |
| :--- | :--- | :--- | :--- |
| `/ws-auth` | `GET` | 无 | 查看 WebSocket 网关是否启用鉴权。 |
| `/ws-auth` | `PUT`/`PATCH` | **Body**: `{"value": true/false}` | 切换 `/ws/*` 路由强制鉴权。切换为 `true` 时，服务将强制断开现有所有连接以要求客户端重连。 |

---

#### **9. 运行时认证凭据文件管理 (Auth Files)**
用于管理服务运行在 `auth-dir` 下的 JSON 格式账号凭证文件。

| 端点路径 | 方法 | 参数/请求体 | 说明与响应 |
| :--- | :--- | :--- | :--- |
| `/auth-files` | `GET` | 无 | 列出所有认证文件的运行时状态。返回列表中，`runtime_only=true` 表示仅保存在内存或远程存储（不可下载），`source=file` 包含磁盘实体。 |
| `/auth-files/download` | `GET` | **Query**: `name` (文件名) | 下载特定的 `.json` 认证文件（无法导出 `runtime_only` 凭据）。 |
| `/auth-files` | `POST` | **Body**: `multipart/form-data` (file) 或 **原始 JSON 配合 Query** `?name=acc1.json` | 上传认证文件。文件必须以 `.json` 结尾，会即时注册到运行时。 |
| `/auth-files` | `DELETE` | **Query**: `name=<filename>` 或 `all=true` | 删除单个或清空所有磁盘认证文件，并从运行时管理器中注销。 |

---

#### **10. Google Vertex 凭据导入**

| 端点路径 | 方法 | 参数/请求体 | 说明与响应 |
| :--- | :--- | :--- | :--- |
| `/vertex/import` | `POST` | **Multipart Body**: <br>• `file` (必须是 Google 服务账号 JSON)<br>• `location` (可选，默认 `us-central1`) | 导入 Google Cloud 服务账号 JSON 并在 `auth-dir` 下生成规范命名的 `vertex-<project>.json`。 |

---

#### **11. OAuth 登录与授权 URL (用于终端用户授权)**
部分提供商支持通过浏览器跳转进行 OAuth 登录流程。
* **回调参数**：可以附加 `?is_webui=true`，使 Web UI 能够自动承接本地回调转发。

| 端点路径 | 方法 | 参数 (Query) | 响应格式 (JSON) | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| `/anthropic-auth-url` | `GET` | `is_webui` | `{ "status": "ok", "url": "https://...", "state": "anth-..." }` | 获取 Claude 登录授权 URL。 |
| `/codex-auth-url` | `GET` | `is_webui` | `{ "status": "ok", "url": "https://...", "state": "codex-..." }` | 获取 Codex 登录授权 URL。 |
| `/gemini-cli-auth-url`| `GET` | `project_id` (可选), `is_webui` | `{ "status": "ok", "url": "https://...", "state": "gem-..." }` | 获取 Google Gemini CLI 登录 URL。不传项目 ID 会自动枚举并选取第一个项目。 |
| `/antigravity-auth-url`| `GET`| `is_webui` | `{ "status": "ok", "url": "https://...", "state": "ant-..." }` | 获取 Antigravity 登录授权 URL。 |
| `/get-auth-status` | `GET` | `state` (必须提供上述流程返回的 state) | `{ "status": "wait" / "ok" / "error" }` | 轮询当前的 OAuth 登录及令牌交换进度。 |
