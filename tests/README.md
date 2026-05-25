# tests/

Local + CI test harness.

## Layout

```
tests/
├── lint.sh                      # bash -n + shellcheck on every .sh
├── check_env_completeness.sh    # every INSTALL_*/$VAR in scripts is in .env.example
├── test_lib.bats                # bats unit tests for lib/common.sh
└── test_launcher.bats           # bats black-box tests for ./install.sh
```

## Run locally

```bash
# install deps (Ubuntu / Debian)
sudo apt-get install -y shellcheck bats

# install deps (macOS)
brew install shellcheck bats-core

# run everything
bash tests/lint.sh
bash tests/check_env_completeness.sh
bats tests/
```

## What each test covers

| Script                         | Catches                                              |
|--------------------------------|------------------------------------------------------|
| `lint.sh`                      | parse errors, unquoted vars, common shell footguns   |
| `check_env_completeness.sh`    | drift between `INSTALL_*` toggles in code and docs   |
| `test_lib.bats`                | `mutex_check`/`mutex_set` correctness, `load_env`    |
| `test_launcher.bats`           | `--help`/`--status`/unknown profile/mutex rejection  |

## CI

`.github/workflows/ci.yml` runs all four on every push and PR.
`.github/workflows/release.yml` runs CI first, then auto-creates a GH release
from the matching `.claude/CHANGELOG.md` entry when a `v*` tag is pushed.

## Adding tests

- New shared helper in `lib/` → add a `@test` block in `test_lib.bats`.
- New launcher flag → add to `test_launcher.bats`.
- New per-profile `.env` variable → already covered by
  `check_env_completeness.sh` if it appears in a script.
