# GoPay Workflow Orchestrator

[![GitHub](https://img.shields.io/badge/GitHub-Gopay__plus__automatic-blue?logo=github)](https://github.com/ywnd1144/Gopay_plus_automatic)
[![Stars](https://img.shields.io/github/stars/ywnd1144/Gopay_plus_automatic?style=social)](https://github.com/ywnd1144/Gopay_plus_automatic)

> Project URL: <https://github.com/ywnd1144/Gopay_plus_automatic>

A lightweight workflow orchestration framework oriented towards regional payment links, used for researching and debugging scenarios such as multi-stage payment provider handoffs, tokenization requests, verification challenges, asynchronous polling, and final state confirmations.

This project focuses on engineering reliability, interface integration, state observability, and automated testing in complex payment workflows. It organizes steps scattered across different systems into a reproducible, observable, and extensible process, making it easier for developers to analyze link behavior, locate abnormal states, and improve integration quality.

---

## Project Positioning

In real-world business, a complete payment flow is usually not completed with a single request. It may involve:

- Application-side session state
- Payment gateway initialization
- External wallet or regional payment provider handoffs
- Tokenization requests and confirmations
- OTP, PIN, or other verification challenges
- Asynchronous callbacks and state polling
- Final result validation

This project provides a small workflow orchestration layer that breaks down the above steps into observable, replaceable, and debuggable modules.

Suitable for:

- Payment link integration testing
- Regional payment provider integration research
- Wallet handoff and callback debugging
- Verification challenge workflow analysis
- Stability testing under network proxy environments
- Multi-stage state machine behavior reproduction
- Automated regression testing and log observation

---

## Core Capabilities

- HTTP workflow entry point
- gRPC payment workflow service
- Tokenized payment request processing
- External provider handoffs and state tracking
- OTP / PIN verification challenge processing
- Manual verification and API-assisted verification modes
- Configuration-driven execution
- Proxy-aware network request layer
- Structured log output
- State polling and final result confirmation
- Docker-friendly deployment

---

## Architecture Overview

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

The project separates the workflow orchestration logic from specific payment operations, making it easy to replace different providers, verification methods, or running environments later.

Main files:

```text
orchestrator.py       # HTTP workflow entry point
payment_core.py       # gRPC payment workflow service
config.py             # Runtime configuration
main.py               # Local startup entry point
start.sh              # Deployment helper script
Dockerfile            # Container image definition
requirements.txt      # Python dependencies
```

---

## Workflow

A standard workflow usually includes the following stages:

1. Receive session credentials or test tokens
2. Initialize the payment flow
3. Create a provider handoff request
4. Wait for external verification state
5. Complete OTP / PIN challenge as needed
6. Poll provider status
7. Validate the final workflow result

Each stage can be independently observed and replaced, facilitating the debugging of link performance across different environments.

---

## Verification Modes

The project supports various verification handling methods, making it adaptable to different testing environments:

```text
manual      # Manually complete the verification challenge
sms_api     # Return the verification result via API
whatsapp    # Return the verification result via messaging channel
```

The verification handling logic is encapsulated behind a unified interface, allowing new handlers to be added later without modifying the main workflow.

---

## Configuration Instructions

Running parameters can be provided via environment variables or a local configuration file.

Common configuration items:

```text
PROXY_URL          Network proxy address
VERIFY_MODE        Verification handling mode
POLL_INTERVAL      State polling interval
REQUEST_TIMEOUT    Request timeout duration
LOG_LEVEL          Log level
```

Example:

```env
PROXY_URL=
VERIFY_MODE=manual
POLL_INTERVAL=3
REQUEST_TIMEOUT=30
LOG_LEVEL=INFO
```

Please keep sensitive information in environment variables or key management tools, and do not commit them to the repository.

---

## Local Execution

Install dependencies:

```bash
pip install -r requirements.txt
```

Start the service:

```bash
python main.py
```

Or use the startup script:

```bash
bash start.sh
```

Run in container:

```bash
docker build -t gopay-workflow-orchestrator .
docker run --env-file .env gopay-workflow-orchestrator
```

---

## Request Example

The service provides a lightweight HTTP interface to create and track workflow tasks.

Example request structure:

```json
{
  "session_token": "example-session-token",
  "verification_mode": "manual",
  "proxy": "http://127.0.0.1:8080"
}
```

Example response structure:

```json
{
  "job_id": "workflow_123",
  "status": "pending",
  "next_action": "provider_verification"
}
```

Return states may vary under different regions, providers, and network environments. The actual result is subject to the runtime logs and provider responses.

---

## Logging and Observation

The project records key workflow events to help locate link issues:

- Request initialization
- Gateway response status
- Provider handoff status
- Verification challenge status
- Polling result
- Final workflow result
- Retry, timeout, and exception states

The logging design aims to help analyze state changes while avoiding the output of sensitive credentials.

---

## Design Goals

The core goal of this project is to provide a simple, reproducible, and easy-to-debug research framework for payment workflows.

Highlights include:

- Reducing the debugging cost of multi-stage payment links
- Breaking complex workflows into clear modules
- Improving the observability of provider handoffs and callbacks
- Recording common abnormal states
- Supporting repeatable integration experiments
- Making verification challenge handling logic easier to maintain

---

## Roadmap

- Improve the provider abstraction layer
- Add structured test cases
- Add CI checks
- Add typed configuration validation
- Improve log redaction
- Add workflow replay mode
- Add more integration test examples
- Improve state transition documentation

---

## Contributing

Improvements are welcome.

Suitable areas for contribution:

- Provider adapters
- Verification handlers
- Retry and backoff logic
- Test cases
- Documentation improvements
- Logging and observability
- Container deployment experience

Please do not commit keys, session credentials, verification codes, PINs, proxy credentials, or any private operational data.

---

## Security Instructions

This project may involve payment flows, verification challenges, and external provider interfaces.

It is recommended to run this primarily in an isolated testing environment. Debugging output should be redacted before sharing. Session credentials, verification codes, PINs, proxy credentials, and provider private data should always be kept outside the repository.

---

## License

MIT

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=ywnd1144/Gopay_plus_automatic&type=Date)](https://star-history.com/#ywnd1144/Gopay_plus_automatic&Date)
