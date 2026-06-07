---
name: cliproxy-manage
description: "通过管理 API 管理 CLIProxyAPI 服务：配置、API 密钥、提供商、日志、使用统计和运行时设置。"
metadata: {"openclaw": {"emoji":"🎛️","requires":{"env":["CLIPROXY_MGMT_PASSWORD", "CLIPROXY_BASE_URL"], "bins":["jq", "cat"]}}} 
---

# CLIProxyAPI 管理 Skill

通过其管理 API (`/v0/management`) 管理 CLIProxyAPI 实例。

## 环境变量说明

- `CLIPROXY_MGMT_PASSWORD`：用于管理 API 身份验证的密码凭证。
- `CLIPROXY_BASE_URL`：用于指定 CLIProxyAPI 服务运行的基础地址（默认值为 `http://127.0.0.1:8317`）。

## 快速参考

使用辅助脚本进行所有操作：

```bash
bash ./scripts/cliproxy.sh <command> [args...]
```

### 命令

| 命令 | 描述 |
|---------|-------------|
| `status` | 健康检查 + 版本 + 调试状态 |
| `config` | 获取完整 JSON 配置 |
| `config-yaml` | 获取原始 YAML 配置 |
| `debug [on\|off]` | 获取/设置调试模式 |
| `proxy [url]` | 获取/设置代理 URL（无参数 = 获取，空 = 删除） |
| `retry [n]` | 获取/设置请求重试次数 |
| `max-retry-interval [sec]` | 获取/设置最大重试间隔时间 |
| `request-log [on\|off]` | 获取/设置请求日志记录 |
| `file-log [on\|off]` | 获取/设置文件日志记录 |
| `logs [after_ts]` | 获取日志行（可选的 Unix 时间戳过滤） |
| `clear-logs` | 清除所有日志 |
| `error-logs` | 列出错误日志文件 |
| `usage-stats [on\|off]` | 获取/设置使用情况统计 |
| `usage-queue [count]` | 从队列中弹出使用记录 |
| `api-keys` | 列出代理 API 密钥 |
| `api-key-usage` | 显示各提供商的 API 密钥使用情况 |
| `api-keys-set <json>` | 替换 API 密钥列表 |
| `api-keys-add <key>` | 添加一个 API 密钥 |
| `api-keys-del <key>` | 按值删除一个 API 密钥 |
| `gemini-keys` | 列出 Gemini API 密钥条目 |
| `gemini-keys-set <json>` | 替换 Gemini 密钥 |
| `claude-keys` | 列出 Claude API 密钥条目 |
| `claude-keys-set <json>` | 替换 Claude 密钥 |
| `codex-keys` | 列出 Codex API 密钥条目 |
| `codex-keys-set <json>` | 替换 Codex 密钥 |
| `openai-compat` | 列出 OpenAI 兼容的提供商 |
| `openai-compat-set <json>` | 替换 OpenAI 兼容的提供商 |
| `quota-switch-project [on\|off]` | 获取/设置额度超限切换项目（quota-exceeded switch-project） |
| `quota-switch-preview [on\|off]` | 获取/设置额度超限切换预览模型（quota-exceeded switch-preview-model） |
| `ws-auth [on\|off]` | 获取/设置 WebSocket 认证 |
| `raw <method> <path> [body]` | 原始 API 调用（路径相对于 /v0/management） |

### 示例

```bash
# 检查服务健康状态
bash ./scripts/cliproxy.sh status

# 获取当前配置
bash ./scripts/cliproxy.sh config

# 开启调试模式
bash ./scripts/cliproxy.sh debug on

# 添加一个 OpenAI 兼容的提供商（内联 JSON）
bash ./scripts/cliproxy.sh openai-compat-set '[
  {"name":"openrouter","base-url":"https://openrouter.ai/api/v1","api-key-entries":[{"api-key":"sk-xxx","proxy-url":""}],"models":[{"name":"ai/xx","alias":"xx"}]}
]'

# 原始 API 调用
bash ./scripts/cliproxy.sh raw GET latest-version
```

## 提供商密钥管理

提供商密钥（Gemini、Claude、Codex、OpenAI-compat）使用具有以下常用字段的对象数组：
- `api-key` — 凭证
- `base-url` — 上游端点（Codex 必填）
- `proxy-url` — 针对每个密钥的代理重写
- `headers` — 自定义请求头（对象）
- `excluded-models` — 禁用的模型（字符串数组）

PATCH 支持使用 `index`/`value` 或 `match`/`value` 进行有针对性的更新。
DELETE 支持 `?api-key=` or `?index=` 查询参数。

## 安全提示

- 切勿在脚本中记录或回显密码或密钥
- 认证失败：连续失败 5 次将触发约 30 分钟的 IP 封禁
- `remote-management.secret-key` 和 `remote-management.allow-remote` 只能在配置文件中修改，不能通过 API 修改

## API 参考

完整本地文档：[references/management-api.md](references/management-api.md)
