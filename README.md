<div align="center">

# codex-image

**一个给 Codex 使用的本地图片生成与编辑 skill。**

它适合需要把图片保存到本地文件、指定输出路径、使用多张参考图、批量生成，或通过 API key 和自定义 `OPENAI_BASE_URL` 调用第三方 OpenAI-compatible 图片接口的场景。

[飞书详细教程](https://mcn724t9vlfu.feishu.cn/wiki/PKulwF8m9ip22Ukevn9cKkl9nXe?fromScene=spaceOverview)

</div>

## 这是什么

`codex-image` 是一个 Codex skill。它让 Codex 在需要生成或编辑图片时调用本地脚本，再通过 OpenAI-compatible Images API 发起请求，并把结果保存成真实的 PNG/JPEG/WebP 文件。

它不是把 `gpt-image-2` 变成 Codex 的主模型，也不是替换 Codex 的代码模型。Codex 仍然负责对话、读代码、改文件和执行命令；`codex-image` 只是在图片任务中作为工具被调用。

这个 fork 在上游基础上增加了请求头兼容处理：默认发送 `User-Agent: curl/8.0`，并支持通过 `CODEX_IMAGE_USER_AGENT` 覆盖。这个改动用于兼容部分带 Cloudflare 或浏览器签名过滤的第三方图片网关。

## 适合什么场景

- 在 Codex Desktop 里让 Codex 生成图片，并保存到当前工作区。
- 使用第三方 OpenAI-compatible 图片接口，例如自定义 `OPENAI_BASE_URL`。
- 指定输出尺寸、比例、文件名或输出目录。
- 对本地图片做编辑、局部重绘或多参考图合成。
- 用 JSONL 批量生成多张图片。
- 需要明确的本地文件路径，而不是只在聊天窗口里显示图片。

## 不适合什么场景

- 想把 Codex 的主对话模型切换成图片模型。
- 只想用 Codex 内置的原生图片对话能力，并且不关心保存路径。
- 想用 SVG、HTML/CSS、Canvas 等代码方式生成图形。

## 安装到 Codex Desktop

### PowerShell 安装

如果你在 Windows 上使用 Codex Desktop，推荐用一键安装/更新命令：

```powershell
iwr -UseBasicParsing https://raw.githubusercontent.com/lgdy88/codex-image/main/scripts/install-codex-image.ps1 -OutFile "$env:TEMP\install-codex-image.ps1"; powershell -ExecutionPolicy Bypass -File "$env:TEMP\install-codex-image.ps1"
```

这条命令可以重复执行：未安装时会安装，已安装时会备份旧版本并同步 GitHub 最新版本。安装或更新后会检查私有配置文件；未配置会进入配置向导，已配置会询问是否更新配置。

安装脚本会在私有配置确认完成后自动清理旧的用户级图片环境变量残留：`OPENAI_BASE_URL`、`OPENAI_API_KEY`、`CODEX_IMAGE_MODEL`。脚本不会打印旧变量值。

安装完成后重启 Codex Desktop，让新 skill 进入可见能力列表。

如果你只想更新 skill 文件、不进入配置向导，可以下载脚本后加 `-SkipConfigure`：

```powershell
powershell -ExecutionPolicy Bypass -File "$env:TEMP\install-codex-image.ps1" -SkipConfigure
```

### macOS / Linux 安装

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-installer/scripts/install-skill-from-github.py" \
  --repo lgdy88/codex-image \
  --path skills/codex-image
```

也可以用 GitHub URL 安装：

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-installer/scripts/install-skill-from-github.py" \
  --url https://github.com/lgdy88/codex-image/tree/main/skills/codex-image
```

### 手动安装

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
git clone https://github.com/lgdy88/codex-image.git /tmp/codex-image
cp -R /tmp/codex-image/skills/codex-image "${CODEX_HOME:-$HOME/.codex}/skills/"
```

## 配置第三方生图模型

推荐使用 `codex-image configure` 写入 Codex 用户目录下的私有配置文件，避免污染全局 `OPENAI_BASE_URL` / `OPENAI_API_KEY` 环境变量。

配置文件默认位置：

```text
%USERPROFILE%\.codex\codex-image\config.json
```

### Windows PowerShell

```powershell
& "$env:USERPROFILE\.codex\skills\codex-image\scripts\codex-image.cmd" configure
```

按提示依次输入：

```text
OPENAI-compatible base URL:
API key:
Model [gpt-image-2]:
```

`Model [gpt-image-2]:` 直接回车会使用默认模型 `gpt-image-2`。

`configure` 会在完成后明文打印 API key 供核对。请不要把终端截图、日志或复制内容发到公开位置。

如果你之前手动设置过旧版用户级环境变量，可以用下面命令立即清理；新安装脚本也会在配置完成后自动执行等价清理：

```powershell
[Environment]::SetEnvironmentVariable("OPENAI_BASE_URL", $null, "User")
[Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $null, "User")
[Environment]::SetEnvironmentVariable("CODEX_IMAGE_MODEL", $null, "User")
Remove-Item Env:OPENAI_BASE_URL -ErrorAction SilentlyContinue
Remove-Item Env:OPENAI_API_KEY -ErrorAction SilentlyContinue
Remove-Item Env:CODEX_IMAGE_MODEL -ErrorAction SilentlyContinue
```

### macOS / Linux

```bash
bash "${CODEX_HOME:-$HOME/.codex}/skills/codex-image/scripts/codex-image" configure
```

### 可选：环境变量兼容方式

`codex-image` 仍兼容环境变量和 Codex 配置。第三方 OpenAI-compatible 图片网关通常需要配置：

- `OPENAI_BASE_URL`
- `OPENAI_API_KEY`
- `CODEX_IMAGE_MODEL`
- 可选：`CODEX_IMAGE_USER_AGENT`

如果要避免影响其他 OpenAI-compatible 工具，优先使用专属变量：

```powershell
[Environment]::SetEnvironmentVariable("CODEX_IMAGE_BASE_URL", "https://api.example.com/v1", "User")
[Environment]::SetEnvironmentVariable("CODEX_IMAGE_API_KEY", "your-new-api-key", "User")
[Environment]::SetEnvironmentVariable("CODEX_IMAGE_MODEL", "gpt-image-2", "User")
```

旧版通用变量仍可使用，但可能影响其他工具：


```powershell
[Environment]::SetEnvironmentVariable("OPENAI_BASE_URL", "https://api.example.com/v1", "User")
[Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "your-new-api-key", "User")
[Environment]::SetEnvironmentVariable("CODEX_IMAGE_MODEL", "gpt-image-2", "User")
```

如果第三方网关会拦截 Python 默认请求头，可以设置：

```powershell
[Environment]::SetEnvironmentVariable("CODEX_IMAGE_USER_AGENT", "curl/8.0", "User")
```

修改用户级环境变量后，重启 Codex Desktop。

### 安全提醒

不要把真实 API key 写进：

- README
- prompt
- issue / PR
- 截图
- commit
- shell 历史中会公开的命令

如果 API key 已经发到聊天、仓库或截图里，应当去服务商后台撤销并重新生成。

## 让 Codex 调用 codex-image

安装并配置完成后，可以直接在 Codex Desktop 里这样说：

```text
用 codex-image 生成一张 16:9 的未来城市图，保存到当前工作区。
```

英文也可以：

```text
Use codex-image to generate a 16:9 futuristic city image and save it to the current workspace.
```

Codex 应当把这个请求路由到本地 `codex-image` skill，调用已配置的 OpenAI-compatible 图片接口，然后返回保存后的文件路径。

## 手动测试

### Windows

```powershell
& "$env:USERPROFILE\.codex\skills\codex-image\scripts\codex-image.cmd" generate `
  --model gpt-image-2 `
  --size 16:9 `
  --out-dir .\generated-images `
  "A cinematic futuristic city skyline at night, wide 16:9 composition, no readable text, no watermark"
```

### macOS / Linux

```bash
bash "${CODEX_HOME:-$HOME/.codex}/skills/codex-image/scripts/codex-image" generate \
  --model gpt-image-2 \
  --size 16:9 \
  --out-dir ./generated-images \
  "A cinematic futuristic city skyline at night, wide 16:9 composition, no readable text, no watermark"
```

## 常用命令

### 按比例生成

```bash
bash "${CODEX_HOME:-$HOME/.codex}/skills/codex-image/scripts/codex-image" generate \
  --model gpt-image-2 \
  --size 16:9 \
  "Draw a clean futuristic AI wallpaper"
```

### 指定输出尺寸

```bash
bash "${CODEX_HOME:-$HOME/.codex}/skills/codex-image/scripts/codex-image" generate \
  --model gpt-image-2 \
  --size 3840x2160 \
  "Draw a cinematic futuristic city skyline, no readable text, no watermark"
```

### 编辑本地图片

```bash
bash "${CODEX_HOME:-$HOME/.codex}/skills/codex-image/scripts/codex-image" edit \
  --model gpt-image-2 \
  --image ./input.png \
  --prompt "Keep the subject and change the background to a bright blue futuristic scene"
```

### 多参考图合成

```bash
bash "${CODEX_HOME:-$HOME/.codex}/skills/codex-image/scripts/codex-image" edit \
  --image ./person.png \
  --image ./product.png \
  --size 16:9 \
  "Input image 1 role: person reference. Input image 2 role: product reference. Create a polished commercial image showing the person holding the product. No logos, no readable text, no watermark."
```

### 批量生成

```bash
bash "${CODEX_HOME:-$HOME/.codex}/skills/codex-image/scripts/codex-image" generate-batch \
  --input ./prompts.jsonl \
  --out-dir ./output/batch
```

## 功能概览

- `generate`：通过 `POST /v1/images/generations` 生成新图片。
- `edit`：通过 `POST /v1/images/edits` 编辑一张或多张本地图片。
- `generate-batch`：从 JSONL 批量生成图片。
- 支持 `OPENAI_API_KEY`、`OPENAI_BASE_URL`、`$CODEX_HOME/auth.json`、`$CODEX_HOME/config.toml`。
- 支持 `16:9`、`9:16`、`9:16@1k`、`3840x2160` 等尺寸写法。
- 支持 `--out`、`--out-dir`、`--name` 指定保存位置。
- 支持多图输入、mask、`input_fidelity`。
- 支持 `[Last Output]`、`[Image #N]`、`[Turn -K Image #N]` 等 Codex 线程内图片引用。
- 返回真实本地文件路径，便于继续编辑、上传或纳入项目资产。

## 环境变量参考

| 变量 | 说明 |
| --- | --- |
| `CODEX_IMAGE_API_KEY` | 图片接口 API key，优先于通用 `OPENAI_API_KEY` |
| `CODEX_IMAGE_BASE_URL` | OpenAI-compatible API base URL，例如 `https://api.example.com/v1`，优先于通用 `OPENAI_BASE_URL` |
| `CODEX_IMAGE_MODEL` | 图片模型，例如 `gpt-image-2` |
| `CODEX_IMAGE_SIZE` | 默认尺寸，例如 `1024x1024` 或 `16:9` |
| `CODEX_IMAGE_QUALITY` | 默认质量，例如 `low`、`medium`、`high`、`auto` |
| `CODEX_IMAGE_BACKGROUND` | 背景策略，例如 `auto`、`opaque`、`transparent` |
| `CODEX_IMAGE_FORMAT` | 输出格式，例如 `png`、`jpeg`、`webp` |
| `CODEX_IMAGE_COMPRESSION` | JPEG/WebP 压缩参数 |
| `CODEX_IMAGE_OUTPUT_DIR` | 默认输出目录 |
| `CODEX_IMAGE_TIMEOUT` | 请求超时时间 |
| `CODEX_IMAGE_USER_AGENT` | 自定义 HTTP `User-Agent`，用于兼容部分第三方网关 |
| `CODEX_IMAGE_MODEL_PROVIDER` | 从 Codex `config.toml` 选择指定 provider |
| `CODEX_IMAGE_CONFIG` | 覆盖私有配置文件路径，默认是 `%USERPROFILE%\.codex\codex-image\config.json` |
| `OPENAI_API_KEY` | 兼容旧版的通用 API key，可能影响其他工具 |
| `OPENAI_BASE_URL` | 兼容旧版的通用 API base URL，可能影响其他工具 |

## 输出位置

- 在 Codex 线程内，默认输出到 `${CODEX_HOME:-~/.codex}/generated_images/<thread-or-session-id>/`。
- 在手动 CLI 调用中，默认输出到 `${CODEX_HOME:-~/.codex}/generated_images/manual/`。
- 使用 `--out` 可以指定单个输出文件。
- 使用 `--out-dir` 可以指定输出目录。
- 使用 `--name` 可以指定输出文件名前缀。

## 常见问题

### 这是 Codex 的图片主模型吗？

不是。它是一个本地 skill。Codex 仍然使用自己的主模型完成对话和编码任务；只有当你要求生成或编辑图片时，Codex 才调用这个 skill。

### 为什么要设置 `CODEX_IMAGE_USER_AGENT`？

有些第三方 OpenAI-compatible 网关会根据请求头或客户端特征做过滤。这个 fork 默认发送 `curl/8.0` 作为 `User-Agent`，必要时可以用 `CODEX_IMAGE_USER_AGENT` 覆盖。

### 能不能直接使用真实第三方地址写进 README？

不建议。README 应使用 `https://api.example.com/v1` 这类占位地址。真实地址和 API key 应放在 `codex-image configure` 创建的私有配置文件中，或放在本机专属环境变量 `CODEX_IMAGE_BASE_URL` / `CODEX_IMAGE_API_KEY` 中。

### 提示词里要不要写 `codex-image`？

建议写。比如：

```text
用 codex-image 生成一张 16:9 的未来城市图，保存到当前工作区。
```

这样 Codex 更容易选择这个 skill，而不是走其他图片路径。

## 项目结构

```text
codex-image/
├── README.md
├── LICENSE
├── tests/
└── skills/
    └── codex-image/
        ├── SKILL.md
        ├── agents/openai.yaml
        ├── assets/
        ├── references/
        └── scripts/
```

## 测试

从仓库根目录运行：

```bash
python -m unittest discover -s ./tests -p 'test_*.py'
```

Windows 上如果全量测试遇到路径转义或控制台编码问题，可以先跑与 transport/header 相关的测试：

```bash
python -m unittest tests.test_transport_regressions
```

## 参考文档

- 主 skill 入口：[`skills/codex-image/SKILL.md`](./skills/codex-image/SKILL.md)
- 工作流比较：[`docs/image-workflows.md`](./docs/image-workflows.md)
- CLI 参考：[`skills/codex-image/references/cli.md`](./skills/codex-image/references/cli.md)
- Images API 参数参考：[`skills/codex-image/references/image-api.md`](./skills/codex-image/references/image-api.md)
- 提示词参考：[`skills/codex-image/references/prompting.md`](./skills/codex-image/references/prompting.md)
- 示例提示词：[`skills/codex-image/references/sample-prompts.md`](./skills/codex-image/references/sample-prompts.md)
- 运行时与认证说明：[`skills/codex-image/references/codex-network.md`](./skills/codex-image/references/codex-network.md)
