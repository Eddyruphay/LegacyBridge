# 🌉 LegacyBridge

> Run modern ARM64 binaries on legacy ARMv8.0 hardware — automatically.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## The Problem

Modern tools like **Antigravity CLI** (Google's replacement for Gemini CLI) are compiled with **LSE (Large System Extensions)** — an ARMv8.1+ feature. On older hardware like Raspberry Pi 3, Cortex-A53, or budget ARM VPS, you get:

```
FATAL ERROR: This binary was compiled with lse enabled,
but this feature is not available on this processor (go/sigill-fail-fast).
Illegal instruction
```

Google's official installer crashes **before even installing the binary**. The binary inside the tar.gz also uses LSE. You're stuck.

## The Solution

LegacyBridge automatically:

1. Fetches the **latest version** dynamically from Google's manifest API
2. Detects whether your CPU needs QEMU (ARMv8.0) or can run natively (ARMv8.1+)
3. Installs `qemu-user` if needed
4. Creates a **transparent wrapper** — you just type `agy` like normal

## Install (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/Eddyruphay/LegacyBridge/main/install.sh | sudo bash
```

## Tested On

| Hardware | CPU | Result |
|---|---|---|
| VPS ARM budget | Cortex-A53 (ARMv8.0) | ✅ Works via QEMU |
| Raspberry Pi 3 | Cortex-A53 (ARMv8.0) | ✅ Works via QEMU |
| Raspberry Pi 4 | Cortex-A72 (ARMv8.0) | ✅ Works via QEMU |
| Apple M1/M2 (Linux) | ARMv8.6+ | ✅ Native |

## Why not just use the official installer?

The official `install.sh` from Google uses a bootstrapper binary that itself is compiled with LSE — so it crashes before it can even download the real binary. LegacyBridge bypasses this by fetching the tarball directly from Google's GCS bucket.

## Roadmap

| Version | Feature |
|---|---|
| **V1 (now)** | QEMU wrapper — works everywhere |
| **V2** | Selective instruction patching (LSE → LDREX/STREX) for near-native performance |
| **V3** | Generic support for any binary, not just `agy` |

## Contributing

PRs welcome! Especially for:
- Testing on more ARM hardware
- V2 binary patching engine
- Support for other distros (Alpine, Arch, Fedora)

## License

MIT — free to use, modify, and distribute.

---

*Discovered during the June 18, 2026 Gemini CLI → Antigravity CLI migration rush.*
