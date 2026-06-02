# GoPay Workflow Orchestrator

[![GitHub](https://img.shields.io/badge/GitHub-Gopay__plus__automatic-blue?logo=github)](https://github.com/ywnd1144/Gopay_plus_automatic)
[![Stars](https://img.shields.io/github/stars/ywnd1144/Gopay_plus_automatic?style=social)](https://github.com/ywnd1144/Gopay_plus_automatic)

> 项目地址：<https://github.com/ywnd1144/Gopay_plus_automatic>

一个面向区域支付链路的轻量级流程编排框架，用于研究和调试多阶段支付提供方跳转、令牌化请求、验证挑战、异步轮询与最终状态确认等场景。

本项目关注的是复杂支付流程中的工程可靠性、接口衔接、状态观测和自动化测试。它将分散在不同系统中的步骤组织成一个可复现、可观察、可扩展的流程，方便开发者分析链路行为、定位异常状态并改进集成质量。

---

## 项目定位

在真实业务中，一个完整的支付流程通常并不是单次请求即可完成。它可能涉及：

- 应用侧会话状态
- 支付网关初始化
- 外部钱包或区域支付提供方跳转
- 令牌化请求与确认
- OTP、PIN 或其他验证挑战
- 异步回调与状态轮询
- 最终结果校验

本项目提供一个小型流程编排层，将上述步骤拆分为可观察、可替换、可调试的模块。

适合用于：

- 支付链路集成测试
- 区域支付提供方对接研究
- 钱包跳转与回调调试
- 验证挑战流程分析
- 网络代理环境下的稳定性测试
- 多阶段状态机行为复现
- 自动化回归测试与日志观测

---

## 核心能力

- HTTP 流程入口
- gRPC 支付流程服务
- 令牌化支付请求处理
- 外部提供方跳转与状态跟踪
- OTP / PIN 验证挑战处理
- 手动验证与接口辅助验证模式
- 配置驱动的运行方式
- 代理感知的网络请求层
- 结构化日志输出
- 状态轮询与最终结果确认
- Docker 友好的部署方式

---

## 架构概览

```text
Client / Test Harness
        |
        v
HTTP Orchestrator
        |
        v
Payment Workflow Engine
        |
        +--> Gateway Initialization
        |
        +--> Provider Handoff
        |
        +--> Verification Challenge
        |
        +--> Status Polling
        |
        v
Final State Validator
```

项目将流程编排逻辑与具体支付操作分离，便于后续替换不同提供方、验证方式或运行环境。

主要文件：

```text
orchestrator.py       # HTTP 流程入口
payment_core.py       # gRPC 支付流程服务
config.py             # 运行时配置
main.py               # 本地启动入口
start.sh              # 部署辅助脚本
Dockerfile            # 容器镜像定义
requirements.txt      # Python 依赖
```

---

## 工作流程

一次标准流程通常包含以下阶段：

1. 接收会话凭据或测试令牌
2. 初始化支付流程
3. 创建提供方跳转请求
4. 等待外部验证状态
5. 根据需要完成 OTP / PIN 挑战
6. 轮询提供方状态
7. 校验最终流程结果

每个阶段都可以独立观察和替换，方便调试不同环境下的链路表现。

---

## 验证模式

项目支持多种验证处理方式，便于适配不同测试环境：

```text
manual      # 手动完成验证挑战
sms_api     # 通过接口回传验证结果
whatsapp    # 通过消息通道回传验证结果
```

验证处理逻辑被封装在统一接口后，后续可以在不修改主流程的情况下增加新的处理器。

---

## 配置说明

运行参数可通过环境变量或本地配置文件提供。

常见配置项：

```text
PROXY_URL          网络代理地址
VERIFY_MODE        验证处理模式
POLL_INTERVAL      状态轮询间隔
REQUEST_TIMEOUT    请求超时时间
LOG_LEVEL          日志级别
```

示例：

```env
PROXY_URL=
VERIFY_MODE=manual
POLL_INTERVAL=3
REQUEST_TIMEOUT=30
LOG_LEVEL=INFO
```

请将敏感信息放在环境变量或密钥管理工具中，不要提交到仓库。

---

## 本地运行

安装依赖：

```bash
pip install -r requirements.txt
```

启动服务：

```bash
python main.py
```

或使用启动脚本：

```bash
bash start.sh
```

容器运行：

```bash
docker build -t gopay-workflow-orchestrator .
docker run --env-file .env gopay-workflow-orchestrator
```

---

## 请求示例

服务提供一个轻量级 HTTP 接口用于创建和跟踪流程任务。

示例请求结构：

```json
{
  "session_token": "example-session-token",
  "verification_mode": "manual",
  "proxy": "http://127.0.0.1:8080"
}
```

示例响应结构：

```json
{
  "job_id": "workflow_123",
  "status": "pending",
  "next_action": "provider_verification"
}
```

不同地区、不同提供方、不同网络环境下的返回状态可能不同，实际结果以运行日志和提供方响应为准。

---

## 日志与观测

项目会记录关键流程事件，便于定位链路问题：

- 请求初始化
- 网关响应状态
- 提供方跳转状态
- 验证挑战状态
- 轮询结果
- 最终流程结果
- 重试、超时与异常状态

日志设计目标是帮助分析状态变化，同时避免输出敏感凭据。

---

## 设计目标

本项目的核心目标是提供一个简单、可复现、便于调试的支付流程研究框架。

重点包括：

- 降低多阶段支付链路的调试成本
- 将复杂流程拆成清晰模块
- 改善提供方跳转与回调的可观测性
- 记录常见异常状态
- 支持重复运行的集成实验
- 让验证挑战处理逻辑更容易维护

---

## 路线图

- 改进提供方抽象层
- 增加结构化测试样例
- 增加 CI 检查
- 增加类型化配置校验
- 改进日志脱敏
- 增加流程回放模式
- 增加更多集成测试示例
- 完善状态转换文档

---

## 贡献

欢迎提交改进。

适合贡献的方向：

- 提供方适配器
- 验证处理器
- 重试与退避逻辑
- 测试样例
- 文档改进
- 日志与可观测性
- 容器部署体验

请不要提交密钥、会话凭据、验证码、PIN、代理凭据或任何私有运行数据。

---

## 安全说明

本项目可能涉及支付流程、验证挑战和外部提供方接口。

建议优先在隔离测试环境中运行。调试输出在分享前应进行脱敏处理。会话凭据、验证码、PIN、代理凭据和提供方私有数据应始终保存在仓库之外。

---

## License

MIT

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=ywnd1144/Gopay_plus_automatic&type=Date)](https://star-history.com/#ywnd1144/Gopay_plus_automatic&Date)
