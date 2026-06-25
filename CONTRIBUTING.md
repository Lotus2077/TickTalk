# Contributing to TickTalk

Thanks for your interest. TickTalk is a native macOS app over the
[TradingAgents](https://github.com/TauricResearch/TradingAgents) engine; the
repo holds both the SwiftUI app (`macos/TickTalk/`) and the Python engine +
backend (`tradingagents/`, `cli/`, `desk_adapter/`, `desk_server/`).

## Where changes should go

- **App / backend (TickTalk-specific):** the macOS app, `desk_server`, and
  `desk_adapter` are TickTalk's own — open a PR here.
- **Engine (`tradingagents`, `cli`):** these are vendored from TradingAgents
  with only minor host-adaptation changes. If you fix or improve the engine
  itself, please also send it **upstream** to
  [TauricResearch/TradingAgents](https://github.com/TauricResearch/TradingAgents)
  so the wider community benefits.

## Building and testing

```bash
# macOS app
cd macos/TickTalk
swift build                      # headless build
bash scripts/make-preview-app.sh # assemble and sign the .app
open .build/TickTalk.app

# Engine + backend (Python ≥ 3.10)
pip install ".[server]"
pytest                           # unit + integration tests
ruff check .                     # lint (E, W, F, I, B, UP, C4, SIM)

# Backend image
docker compose build desk-server
```

Please keep `ruff check .` and `pytest` green before opening a PR.

## Dev signing note

`macos/TickTalk/scripts/dev-signing-setup.sh` creates a **throwaway, self-signed**
code-signing identity in a dedicated keychain. The keychain password in that
script (`ticktalk-dev`) is a local development convenience only — it protects
nothing sensitive and must never be reused for a real keychain or secret.

## License

By contributing you agree that your contributions are licensed under the
[Apache License 2.0](LICENSE), consistent with the rest of the project.
