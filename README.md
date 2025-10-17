# ZAI-API

**OpenAI-Compatible API Server for Z.AI** | 完全兼容 OpenAI API 格式的 Z.AI 代理服务器

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-supported-blue.svg)](https://www.docker.com/)

---

## ✨ Features

- **🔌 Full OpenAI API Compatibility** - Drop-in replacement for OpenAI API
- **🤖 Multi-Model Support** - GLM-4.5, GLM-4.6, Thinking, Search, Air, Vision models
- **🛠️ Function Calling** - Complete tool calling support
- **🚀 Zero-Config Deploy** - Anonymous mode works out of the box
- **💾 Smart Token Management** - 3-tier fallback: Configured → Anonymous → Cached
- **🌊 Streaming Support** - Real-time SSE streaming responses
- **🎯 Claude Code & Cline Compatible** - Works with all major AI coding tools

---

## 🚀 Quick Start

```bash
# Clone and run
git clone https://github.com/Zeeeepa/zai-api.git
cd zai-api
bash scripts/all.sh
```

**That's it!** Server starts at `http://localhost:8080` with anonymous tokens - no configuration needed.

---

## 📦 Installation

### Docker (Recommended)

```bash
cp env_template.txt .env
docker-compose up -d
```

### Local

```bash
pip install -r requirements.txt
cp env_template.txt .env
python main.py
```

---

## 💡 Usage

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="sk-123456"
)

response = client.chat.completions.create(
    model="GLM-4.5",
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
```

---

## 🔧 Configuration

Minimal `.env` configuration:

```env
LISTEN_PORT=8080
AUTH_TOKEN=sk-123456
```

For advanced configuration, see [**Complete Documentation →**](DOCUMENTATION.md)

---

## 📚 Documentation

**→ [Complete Documentation](DOCUMENTATION.md)** - Full setup, configuration, API usage, troubleshooting, and more

### Quick Links

- [Quick Start Guide](DOCUMENTATION.md#quick-start) - Get running in 2 minutes
- [Configuration](DOCUMENTATION.md#configuration) - Environment variables and settings
- [Deployment Guide](DOCUMENTATION.md#deployment-guide) - Production deployment
- [Tool Calling](DOCUMENTATION.md#tool-calling-function-calling) - Function calling examples
- [FlareProx Integration](DOCUMENTATION.md#flareprox-integration) - Proxy rotation setup
- [Troubleshooting](DOCUMENTATION.md#troubleshooting) - Common issues and solutions
- [Compatibility](DOCUMENTATION.md#compatibility) - System requirements

---

## 🤝 Contributing

Contributions welcome! Please fork, create a feature branch, and submit a PR.

---

## 📄 License

See [LICENSE](LICENSE) file for details.

---

## 🙏 Credits

Inspired by:
- [z.ai2api_python](https://github.com/ZyphrZero/z.ai2api_python)
- [Toolify](https://github.com/funnycups/Toolify)

---

**Made with ❤️ by the Zeeeepa team**

