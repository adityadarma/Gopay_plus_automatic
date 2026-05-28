# GoPay Plus Automatic Subscription Tool

[![GitHub](https://img.shields.io/badge/GitHub-Gopay__plus__automatic-blue?logo=github)](https://github.com/ywnd1144/Gopay_plus_automatic)
[![Stars](https://img.shields.io/github/stars/ywnd1144/Gopay_plus_automatic?style=social)](https://github.com/ywnd1144/Gopay_plus_automatic)

> Project URL: <https://github.com/ywnd1144/Gopay_plus_automatic>

A fully automated ChatGPT Plus subscription tool. Given a ChatGPT `access_token`, this project can complete a 0 IDR first-month subscription in **about 20 seconds** through the Stripe → Midtrans → GoPay tokenized payment flow.

> ⚠️ **This project will no longer be updated. It is provided for research, entertainment, and learning only. Fork and modify it yourself if you are able to.**

**Statement**: The project author is not affiliated with any channel provider and does not provide related services. This project is only for open-source sharing and discussion, and the research is purely a personal interest. This project is **free and open source**; do not resell it. For questions, email `links-to@outlook.com`. The author is not responsible for any user behavior. This project is for learning and discussion only.

**Users without basic technical knowledge are not advised to deploy this by themselves.** Use advanced GPT / Claude models to assist with deployment and adjust it for your specific scenario. If you only want to see whether it works, it is recommended to run one account in `manual` mode first, confirm the full flow works, and only then consider batch usage.

---

## Table of Contents

1. [What It Can Do](#what-it-can-do)
2. [Current Risk-Control Status (Read First)](#current-risk-control-status-read-first)
3. [Prerequisites](#prerequisites)
4. [Architecture](#architecture)
5. [Installation Steps (From Scratch)](#installation-steps-from-scratch)
6. [Docker Compose Quick Start](#docker-compose-quick-start)
7. [Configuration](#configuration)
8. [Usage](#usage)
9. [Three OTP Receiving Options](#three-otp-receiving-options)
10. [Production Deployment (systemd Autostart)](#production-deployment-systemd-autostart)
11. [FAQ](#faq)
12. [Project Structure](#project-structure)
13. [Disclaimer](#disclaimer)

---

## What It Can Do

- Accept a ChatGPT `access_token`
- Automatically create an IDR subscription order
- Automatically complete payment through Stripe + Midtrans + GoPay tokenization
- Automatically receive and fill in the OTP verification code
- Automatically enter the GoPay PIN
- Automatically verify the subscription status
- Final result: the account becomes ChatGPT Plus with a 0 IDR first-month trial

The entire process takes about 20 seconds and requires no manual intervention after configuration. It supports single-account debugging, batch processing, and concurrent subscriptions.

---

## Current Risk-Control Status (Read First)

Read this section first. Otherwise, when risk-control blocks occur, you may mistake them for code bugs.

### 1. CDN-level "There's a technical error"

If you see `There's a technical error. Don't worry, we're working on it. Please try again.`, this is Cloudflare rate limiting the Midtrans linking endpoint.

**Workaround**: The `429/` folder in the project root provides a bypass script based on a Chrome fingerprint browser. It runs linking directly through the browser to avoid SDK fingerprinting. In many cases, **clicking retry multiple times** can also trigger CDN allowlisting.

> Note: This script is not part of the main repository flow and is only a fallback tool.

### 2. Midtrans anti-fraud (`fraud_status=deny`)

When the subscription returns `charge: fraud_status=deny` or `Failed to proceed to GoPay. Please place your order again`:

- This is **Midtrans anti-fraud blocking virtual numbers or repeated linking from the same user in a short time**
- After it is triggered, **that number can no longer be used for GoPay payment**; use another number
- Normal use, meaning one number for one subscription, does not trigger it
- Repeatedly testing the same number during debugging can trigger it; it may recover after several hours to one day

### 3. Multiple bindings per number are now limited

As of 2026-05-12, binding multiple Plus accounts to a single GoPay number is no longer practical. Current testing shows that one number can bind at most 1 to 3 accounts. There are two strategies:

- **One number, one binding (recommended)**: each GoPay number binds only one ChatGPT account. WhatsApp is not required; SMS receiving is enough
- **Multiple bindings per number**: receive codes multiple times and bind multiple accounts while the virtual number is still valid, usually 10 to 60 minutes on SMS platforms, or register WhatsApp and use WhatsApp OTP. However, WhatsApp has a higher account-ban risk

### 4. IP exit requirements

- The exit IP **must** be in Japan, which has been tested to pass ChatGPT region eligibility 100% of the time, or in Taiwan, China
- Proxies from other regions cannot obtain Plus subscription eligibility

### 5. Account email requirements

Known email types that can currently obtain Plus eligibility:

- Outlook / Hotmail
- Domain email, provided that the subdomain has an `edu` prefix. For example, if the original domain is `abc.com`, use an email under `edu.abc.com`

### 6. You must register GoPay / Gojek accounts yourself

This project does **not** automate GoPay/Gojek registration because automated registration is too difficult. You need to:

1. Buy an Indonesian virtual number from an SMS receiving platform
2. Manually register Gojek / GoPay, or use an emulator
3. Set a 6-digit PIN
4. Use the "phone number + PIN" as input for this project

### 7. Payment flow status

- **The payment flow is fully functional** and has been verified many times in production.
- Payment failures, when they are not script errors, are almost always caused by an abnormal number state, IP risk control, or account-side anti-fraud.

---

## Prerequisites

| Item | Description | How to get it |
|---|---|---|
| Linux server | Debian / Ubuntu recommended; 1 CPU and 1 GB RAM is enough | Any cloud provider |
| Python | 3.10 or later | `apt install python3 python3-pip` |
| Node.js | 18+ (**only required for `whatsapp` mode**) | NodeSource repository |
| SOCKS5 proxy | **Japan** exit IP | Self-hosted / purchased |
| GoPay account | Indonesian number + 6-digit PIN (**PIN must already be enabled**, otherwise payment will fail) | Virtual number + Gojek app registration |
| ChatGPT access_token | Credential for the account to subscribe | See below |

### How to obtain an access_token

1. Log in to <https://chatgpt.com> in a browser
2. Visit <https://chatgpt.com/api/auth/session> in the address bar
3. The page returns JSON; find the `accessToken` field
4. Copy its value, a long string usually starting with `eyJ` and often 1000+ characters long
5. This is the `access_token`

> The `access_token` is valid for about 24 hours and must be obtained again after expiration.

### How to register a GoPay account

1. Buy an Indonesian phone number from an SMS receiving platform such as HeroSMS, 5sim, or sms-activate
2. Download the Gojek app, or use an emulator such as MuMu or LDPlayer
3. Register a Gojek account with that Indonesian number
4. During registration, you will receive an SMS verification code from the SMS platform
5. Set a GoPay PIN in the app. It must be 6 digits. **It is strongly recommended to use the same PIN for all numbers** for easier batching
6. Record the `phone number + PIN`

For batch subscriptions, repeat the steps above and prepare multiple `phone number + PIN` pairs.

---

## Architecture

The project consists of three services:

```text
                    User request
                       |
                       v
+--------------------------------------------------+
|  orchestrator                    listens on :8800 |
|  Receives /subscribe requests and coordinates     |
|  the whole flow                                   |
+--------------------------------------------------+
           |                           |
           v                           v
+-------------------+        +-------------------+
| plus_gopay_links  |        |  OTP source        |
| Payment core      |        |  (choose one)      |
| (gRPC)            |        |                   |
| listens on :50051 |        |  1. manual        |
| Runs the full     |        |  2. sms_api       |
| payment flow      |        |  3. whatsapp      |
+-------------------+        +-------------------+
```

You do not need to care about the internal flow. You only need to:

1. Configure `config.json`
2. Start two services, or three when using WhatsApp mode
3. Call `/subscribe` through HTTP

---

## Installation Steps (From Scratch)

### Step 1: Prepare the server

```bash
# Log in to the Linux server as root
apt update && apt upgrade -y

# Install Python
apt install -y python3 python3-pip curl git

# Optional: only required for whatsapp mode
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
```

### Step 2: Clone the project

```bash
cd /opt
git clone https://github.com/ywnd1144/Gopay_plus_automatic.git gopay-plus
cd gopay-plus
```

### Step 3: Install Python dependencies

```bash
pip install -r requirements.txt
```

If you get `externally-managed-environment`:

```bash
pip install --break-system-packages -r requirements.txt
```

### Step 4: Install Node.js dependencies (WhatsApp mode only)

```bash
cd to_whatsapp && npm install && cd ..
```

### Step 5: Copy the configuration template

```bash
cp config.example.json config.json
nano config.json     # or vim / vi
```

Field descriptions are in the next section.

### Step 6: Start the services

One-click script for Linux:

```bash
chmod +x start.sh
./start.sh
```

Or start manually, which is convenient for debugging:

```bash
# Terminal 1: payment core
cd plus_gopay_links
python3 payment_server.py --config ../config.json --listen :50051

# Terminal 2: orchestrator
cd /opt/gopay-plus
python3 orchestrator.py

# Terminal 3 (whatsapp mode only): WhatsApp Relay
cd to_whatsapp
WA_PAIRING_PHONE=62xxxxxxxxxx WA_PROXY_URL=socks5://127.0.0.1:1080 WA_GRPC_PORT=50056 node index.js
```

### Step 7: Health check

```bash
curl http://localhost:8800/health
# {"ok": true, "service": "gopay-plus", "otp_mode": "manual"}
```

---

## Docker Compose Quick Start

If you want to run everything with Docker, use the included `Dockerfile` and `docker-compose.yml`. This runs the payment service and orchestrator in one container so the existing `127.0.0.1` service addresses keep working.

### 1. Prepare the config

```bash
cp config.example.json config.json
nano config.json     # or vim / vi
```

At minimum, update:

- `gopay.phone_number`
- `gopay.pin`
- `proxy`
- `orchestrator.auth_token`
- `otp.mode`

If your SOCKS5 proxy runs on the Docker host, do not use `127.0.0.1` inside `config.json`; use `host.docker.internal` on Docker Desktop or the host gateway address on Linux.

### 2. Start with Docker Compose

```bash
docker compose up --build
```

### 3. Health check

```bash
curl http://localhost:8800/health
# {"ok": true, "service": "gopay-plus", "otp_mode": "manual"}
```

### Optional: WhatsApp relay

Only enable this when `otp.mode` is set to `"whatsapp"` in `config.json`:

```bash
START_WHATSAPP=true \
WA_PAIRING_PHONE=62xxxxxxxxxx \
WA_PROXY_URL=socks5://127.0.0.1:1080 \
docker compose up --build
```

The first run will print the WhatsApp pairing code in the container logs.

---

## Configuration

Open `config.example.json`, **copy it to `config.json`**, and edit the copy. Editing only the example file will not run the app.

> JSON does not support comments. Do not keep the `//` explanation lines below in the actual `config.json`.

```jsonc
{
  "gopay": {
    "country_code": "62",
    // Indonesian country code, fixed at 62

    "phone_number": "81234567890",
    // Default GoPay phone number, without country code
    // In batch mode, put a placeholder here and override phone_number in each /subscribe request

    "pin": "123456",
    // Default 6-digit PIN. Using the same PIN for batches is recommended

    "browser_locale": "zh-CN",
    "pin_locale": "id",

    "otp_channel": "whatsapp",
    // "whatsapp" (default) | "sms"
    // When set to "sms", the script waits for the countdown after consent and then switches to the SMS channel
    // This must be set to "sms" when using sms_api receiving platforms, otherwise the platform will not receive the code

    "sms_switch_countdown_sec": 30,
    // Seconds to wait before switching to SMS, matching the countdown on GoPay web

    "sms_switch_endpoint": "",
    // HTTP endpoint for switching channels. Leave empty to use the built-in default
    // If GoPay changes the API, capture a HAR once when clicking "use SMS instead" and put the URL here

    "sms_switch_body_extra": {}
    // Extra body fields required by the switch request. Leave empty to use the built-in default
  },

  "proxy": "socks5://127.0.0.1:1080",
  // SOCKS5 proxy. Japan exit IP is required

  "orchestrator": {
    "port": 8800,
    "otp_timeout": 90,
    // Maximum seconds to wait for OTP. sms_api mode should use ≥ 120
    "auth_token": "my-secret-token-123"
    // Custom random string. Calls to /subscribe must include Authorization: Bearer <this value>
  },

  "otp": {
    "mode": "manual",
    // "manual" | "sms_api" | "whatsapp"

    "sms_api": {
      "provider": "herosms",
      "api_key": "",
      "base_url": "https://api.herosms.com",
      "country": "id",
      "service": "gopay",
      "poll_interval_sec": 3,
      "poll_timeout_sec": 90
    },

    "whatsapp": {
      "grpc_addr": "127.0.0.1:50056"
    }
  }
}
```

---

## Usage

### Single subscription (basic)

```bash
curl -X POST http://localhost:8800/subscribe \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer my-secret-token-123" \
  -d '{"session_token": "eyJhbGciOiJSUzI1NiIs..."}'
```

Success:

```json
{"ok": true, "charge_ref": "A1xxxxxxxxxxxxxxxxxxxxxxx", "elapsed_ms": 19928}
```

Failure:

```json
{"ok": false, "error": "otp_timeout", "detail": "timeout waiting for OTP after 90s", "elapsed_ms": 91000}
```

### Multi-number subscription (specify different phone number / PIN each time)

```bash
curl -X POST http://localhost:8800/subscribe \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer my-secret-token-123" \
  -d '{
    "session_token": "eyJ...",
    "phone_number": "82222222222",
    "pin": "123456"
  }'
```

`phone_number` and `pin` are optional. If omitted, the defaults in `config.json` are used.

### Concurrent subscriptions

The orchestrator supports concurrency. Send multiple `/subscribe` requests concurrently, with different `session_token` and `phone_number` values for each request.

> In `manual` mode, concurrent requests share the same OTP inbox, so OTPs can be mixed up easily. Use `sms_api` for batch scenarios.

---

## Three OTP Receiving Options

GoPay linking sends a 6-digit verification code to the phone owner. There are three ways to feed this OTP back to the tool.

### Option 1: `manual` mode (manual / ADB)

The simplest option, suitable for beginner debugging and small-scale usage.

Principle: after you or a script sees the verification code, manually send an HTTP request to tell the orchestrator the code.

Configuration: set `otp.mode` to `"manual"` in `config.json`.

Flow:

```text
1. POST /subscribe
2. About 10 seconds later, GoPay sends a verification code to the phone owner, usually through WhatsApp by default
3. After seeing the code, run this within 90 seconds:
   curl -X POST http://server:8800/otp \
     -H "Content-Type: application/json" \
     -d '{"otp": "123456"}'
4. The orchestrator receives it and continues the flow
5. The subscription result is returned
```

If you have an Android emulator such as MuMu or LDPlayer, you can use `otp_forwarder.py` to automate forwarding:

```bash
# Edit the top of the script:
#   OTP_URL = "http://your-server:8800/otp"
#   AUTH    = "Bearer my-secret-token-123"

adb connect 127.0.0.1:7555    # or your emulator ADB port
adb devices

python3 otp_forwarder.py      # keep this window open
```

> **Important**: Do not open WhatsApp notification messages, otherwise ADB cannot capture them.

### Option 2: `sms_api` mode (automatic SMS receiving platform)

Suitable for fully automated unattended batch production.

Principle: GoPay sends the verification code via **SMS** to the virtual phone number, and the orchestrator automatically queries the SMS platform API to retrieve it.

**Important prerequisite: GoPay linking sends OTP to WhatsApp by default, so SMS platforms will not receive it.** You must configure all of the following:

1. `otp.mode` = `"sms_api"`
2. `gopay.otp_channel` = `"sms"`, so the script switches to SMS after consent
3. `orchestrator.otp_timeout` ≥ **120**, because it needs to wait for the 30-second countdown plus SMS delivery

Key fields, excerpted and combined:

```json
{
  "gopay": {
    "otp_channel": "sms",
    "sms_switch_countdown_sec": 30,
    "sms_switch_endpoint": ""
  },
  "orchestrator": { "otp_timeout": 120 },
  "otp": {
    "mode": "sms_api",
    "sms_api": {
      "api_key": "your-key",
      "base_url": "https://api.your-platform.com"
    }
  }
}
```

> When `sms_switch_endpoint` is empty, the built-in default is used. If GoPay changes the API, capture a HAR once when clicking "receive via SMS instead" on the GoPay web page, put the URL into `sms_switch_endpoint`, and put any extra fields into `sms_switch_body_extra`.

SMS platform integration:

The orchestrator requests this by default:

```text
GET {base_url}?action=get_sms&api_key={your-key}&phone={phone-number}&country=id
```

It then automatically extracts a 6-digit number from the response text using `\b\d{6}\b`.

If your platform uses a different URL format, modify the URL construction in the `_wait_sms_api_otp` function in `orchestrator.py`. The response parsing is generic.

Common platform references:

```text
HeroSMS:
  GET https://api.herosms.com/api/get_sms?api_key=KEY&phone=PHONE
  Response: {"sms": "Your verification code is 123456"}

5sim:
  GET https://5sim.net/v1/user/check/{order_id}
  Header: Authorization: Bearer KEY
  Response: {"sms": [{"text": "123456 is your code"}]}

sms-activate:
  GET https://api.sms-activate.org/stubs/handler_api.php?api_key=KEY&action=getStatus&id=ORDER_ID
  Response: STATUS_OK:123456
```

Batch flow example:

```text
1. Buy an Indonesian number from the SMS platform, for example 81234567890
2. Use that number to register GoPay in Gojek and set the PIN to 123456
3. curl -X POST http://localhost:8800/subscribe \
     -H "Authorization: Bearer my-secret-token-123" \
     -d '{"session_token":"eyJ...","phone_number":"81234567890","pin":"123456"}'
4. The orchestrator automatically retrieves the verification code from the SMS platform and completes the subscription
5. Move to the next phone number + access_token pair and continue
```

> The author has not personally tested every SMS receiving platform one by one, but the principle is the same: fetch SMS messages and extract the 6-digit code. Users need to make small adjustments based on their own platform.

### Option 3: `whatsapp` mode (automatic WhatsApp receiving)

Suitable for long-term use with **one fixed** GoPay number.

Principle: log in to WhatsApp on the server with Baileys and listen for messages from GoPay.

Configuration: set `otp.mode` to `"whatsapp"` in `config.json`.

First pairing:

```bash
cd to_whatsapp
export WA_PAIRING_PHONE=62xxxxxxxxxx   # Your WhatsApp main number, including 62
export WA_PROXY_URL=socks5://127.0.0.1:1080
export WA_GRPC_PORT=50056
node index.js
```

The terminal will show an 8-character pairing code, for example `WN2XQNLB`.

On your phone:

1. Open WhatsApp
2. Tap the three dots in the upper-right corner → Linked devices → Link a device
3. Enter the 8-character pairing code

After pairing succeeds, keep the service running. It will automatically receive GoPay verification codes.

**Known issue**: WhatsApp **linked devices** may block financial messages such as GoPay verification codes with `MASK_LINKED_DEVICES`, causing the server not to receive them. If this happens, switch to `manual` or `sms_api`.

### Comparison of the three options

|  | manual | sms_api | whatsapp |
|---|---|---|---|
| Fully automated | Manual / ADB required | Fully automated | Fully automated |
| Multi-number support | Supported | Supported | Single number only |
| Extra cost | None | SMS platform fees | None |
| Stability | Depends on user / ADB | High | May be blocked |
| Suitable for | Debugging / small scale | Batch production | Long-term fixed number |

---

## Production Deployment (systemd Autostart)

Make the services start on boot and restart automatically after crashes:

```bash
# 1. Payment core
cat > /etc/systemd/system/plus-gopay-links.service << 'EOF'
[Unit]
Description=GoPay Payment Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/gopay-plus
ExecStart=/usr/bin/python3 plus_gopay_links/payment_server.py --config config.json --listen :50051
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# 2. Orchestrator
cat > /etc/systemd/system/gopay-orchestrator.service << 'EOF'
[Unit]
Description=GoPay Orchestrator
After=plus-gopay-links.service

[Service]
Type=simple
WorkingDirectory=/opt/gopay-plus
ExecStart=/usr/bin/python3 orchestrator.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
systemctl daemon-reload
systemctl enable --now plus-gopay-links gopay-orchestrator

# Check status / logs
systemctl status plus-gopay-links
systemctl status gopay-orchestrator
journalctl -u gopay-orchestrator -f
```

---

## FAQ

### Q: It returns `otp_timeout`

No verification code was received within `otp_timeout`. Check:

- `manual`: Did you POST `/otp` before the timeout?
- `sms_api`: Are `api_key` and `base_url` correct? Is `gopay.otp_channel` set to `"sms"`? Is the number still within the SMS platform's active window?
- `whatsapp`: Is the relay running? Is it blocked by `MASK_LINKED_DEVICES`?

### Q: It returns `start_gopay_failed`

Usually, the `access_token` is invalid or expired. Get a new one from `https://chatgpt.com/api/auth/session`.

In rare cases, Stripe confirm is risk-controlled due to IP or account characteristics. Try a different number or IP.

### Q: PIN verification failed / rate limited

- The PIN is not a 6-digit number → update `config.json`
- The same number had multiple wrong PIN attempts in a short time → temporarily rate limited by GoPay, with a cooldown of about 1 hour
- Make sure the PIN length in the config is correct. There have been cases where a 6-digit PIN was mistakenly copied as 7 digits, causing repeated failures

### Q: Midtrans charge returns `fraud_status=deny`

The same number was linked too many times in a short time and triggered Midtrans anti-fraud. This number is no longer usable; use another one. One-number-one-subscription usage should not encounter this.

### Q: It returns `midtrans linking exhausted retries: account already linked`

This GoPay number has recently been linked to another ChatGPT account. Due to the multiple-binding limit, the number may have reached its cap. Try another number.

### Q: How do I subscribe multiple accounts at the same time?

Send multiple `/subscribe` requests concurrently. Note that the OTP inbox is shared in `manual` mode, so concurrent use can easily mix up OTPs. Use `sms_api` for batches.

### Q: Proxy requirements

- SOCKS5 protocol
- Japan exit IP, or Taiwan, China. Other regions cannot obtain Plus eligibility
- The IP must not be blacklisted by GoPay / Midtrans
- Self-hosted or residential proxies are recommended

### Q: Can it run locally on Windows?

`start.sh` is a Bash script. Windows users can run it in WSL, or manually start the two Python processes.

---

## Project Structure

```text
Gopay_plus_automatic/
├── README.md                # This file
├── Dockerfile               # Docker image definition
├── docker-compose.yml       # Docker Compose runtime
├── docker/
│   └── start.sh             # Container startup script
├── config.example.json      # Configuration template. Copy to config.json before use
├── requirements.txt         # Top-level Python dependencies
├── start.sh                 # One-click startup script for Linux / WSL
├── orchestrator.py          # Orchestrator HTTP API + three OTP modes
├── otp_forwarder.py         # ADB OTP auto-forwarder, helper script for manual mode
├── .gitignore
├── plus_gopay_links/        # Payment core
│   ├── gopay.py             # Full Stripe / Midtrans / GoPay payment flow
│   ├── payment_server.py    # gRPC wrapper
│   ├── requirements.txt
│   ├── proto/
│   │   ├── payment.proto
│   │   └── otp.proto
│   ├── payment_pb2.py / payment_pb2_grpc.py
│   └── otp_pb2.py / otp_pb2_grpc.py
└── to_whatsapp/             # WhatsApp OTP receiving, optional module
    ├── index.js             # Baileys client
    ├── package.json
    ├── wa_relay.py          # Node process wrapper
    └── proto/otp.proto
```

---

## Disclaimer

This project is for learning and research only. Users must assume all risks themselves, comply with relevant terms of service, and must not violate OpenAI terms or applicable laws and regulations. By using this project, users are deemed to understand and agree that all consequences are borne by the user personally and have nothing to do with the author.

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=ywnd1144/Gopay_plus_automatic&type=Date)](https://star-history.com/#ywnd1144/Gopay_plus_automatic&Date)
