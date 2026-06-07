# cliproxy-manage

用于通过 CLIProxyAPI 管理 API 快速管理服务配置、密钥、日志、用量统计和运行时开关的 CodeBuddy Skill。

## 功能

- 查看服务版本、调试状态和运行配置
- 管理全局代理、重试、日志与用量统计开关
- 管理 API Key 与 Gemini、Claude、Codex、OpenAI 兼容提供商配置
- 支持原始 Management API 调用

## 环境要求

- `bash`
- `curl`
- `jq`（可选，用于格式化 JSON）

## 环境变量

```bash
export CLIPROXY_MGMT_PASSWORD="your-management-password"
export CLIPROXY_BASE_URL="http://127.0.0.1:8317"
```

`CLIPROXY_BASE_URL` 未设置时默认使用 `http://127.0.0.1:8317`。

## 使用方式

```bash
bash ./scripts/cliproxy.sh <command> [args...]
```

常用命令：

```bash
bash ./scripts/cliproxy.sh status
bash ./scripts/cliproxy.sh config
bash ./scripts/cliproxy.sh debug on
bash ./scripts/cliproxy.sh api-keys
bash ./scripts/cliproxy.sh openai-compat
bash ./scripts/cliproxy.sh raw GET /latest-version
```

完整命令说明见 [`SKILL.md`](./SKILL.md)，Management API 参考见 [`references/management-api.md`](./references/management-api.md)。

## 安全提示

请勿将管理密码或服务商 API Key 提交到仓库。连续认证失败可能触发服务端临时封禁。

## License

见 [`LICENSE`](./LICENSE)。
