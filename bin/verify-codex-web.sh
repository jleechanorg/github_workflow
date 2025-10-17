#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/codex-web-manifest.sh"

mapfile -t CODEX_WEB_PIPX_PACKAGE_NAMES < <(printf '%s\n' "${!CODEX_WEB_PIPX_PACKAGES[@]}" | sort)
mapfile -t CODEX_WEB_COREPACK_TOOL_NAMES < <(printf '%s\n' "${!CODEX_WEB_COREPACK_TOOLS[@]}" | sort)
mapfile -t CODEX_WEB_MISE_TOOL_NAMES < <(printf '%s\n' "${!CODEX_WEB_MISE_TOOLS[@]}" | sort)
mapfile -t CODEX_WEB_ENV_EXPORT_KEYS < <(printf '%s\n' "${!CODEX_WEB_ENV_EXPORTS[@]}" | sort)

SCRIPT_PATH=$(realpath "$0")
TARGET_USER="${TARGET_USER:-$(whoami)}"
CURRENT_USER=$(whoami)

if [[ "$TARGET_USER" != "$CURRENT_USER" ]]; then
  if [[ ${EUID:-0} -ne 0 ]]; then
    echo "Run this script as $TARGET_USER or with sudo TARGET_USER=$TARGET_USER $SCRIPT_PATH" >&2
    exit 1
  fi
  exec su - "$TARGET_USER" -c "TARGET_USER=$TARGET_USER '$SCRIPT_PATH'"
fi

PASS_SYMBOL="✔"
FAIL_SYMBOL="✘"
INFO_SYMBOL="➜"

pass() {
  local label="$1"
  local detail="${2:-}"
  if [[ -n "$detail" ]]; then
    printf '%s %s (%s)\n' "$PASS_SYMBOL" "$label" "$detail"
  else
    printf '%s %s\n' "$PASS_SYMBOL" "$label"
  fi
}

fail() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  printf '%s %s\n    expected: %s\n    actual:   %s\n' "$FAIL_SYMBOL" "$label" "$expected" "$actual"
  ERRORS+=("$label")
}

info() {
  printf '\n%s %s\n' "$INFO_SYMBOL" "$1"
}

declare -a ERRORS=()
TARGET_HOME="$HOME"

# Prime the environment so version checks match an interactive Codex Web shell.
if [[ -d "$TARGET_HOME/.pyenv" ]]; then
  export PYENV_ROOT="$TARGET_HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

if [[ -d "$TARGET_HOME/.nvm" ]]; then
  export NVM_DIR="$TARGET_HOME/.nvm"
  # shellcheck disable=SC1090
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
fi

if [[ -f "$TARGET_HOME/.cargo/env" ]]; then
  # shellcheck disable=SC1091
  . "$TARGET_HOME/.cargo/env"
fi

if [[ -x "$TARGET_HOME/.local/bin/mise" ]]; then
  export PATH="$TARGET_HOME/.local/bin:$PATH"
  eval "$("$TARGET_HOME/.local/bin/mise" env --shell bash)"
fi

info "Operating system"
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ -n "${PRETTY_NAME:-}" ]]; then
    if [[ "$PRETTY_NAME" == "$CODEX_WEB_OS_PRETTY_NAME" ]]; then
      pass "PRETTY_NAME" "$PRETTY_NAME"
    else
      fail "PRETTY_NAME" "$CODEX_WEB_OS_PRETTY_NAME" "$PRETTY_NAME"
    fi
  else
    fail "PRETTY_NAME" "$CODEX_WEB_OS_PRETTY_NAME" "missing"
  fi
  if [[ -n "${VERSION_ID:-}" ]]; then
    if [[ "$VERSION_ID" == "$CODEX_WEB_OS_VERSION_ID" ]]; then
      pass "VERSION_ID" "$VERSION_ID"
    else
      fail "VERSION_ID" "$CODEX_WEB_OS_VERSION_ID" "$VERSION_ID"
    fi
  else
    fail "VERSION_ID" "$CODEX_WEB_OS_VERSION_ID" "missing"
  fi
else
  fail "/etc/os-release" "readable" "missing"
fi

info "APT packages"
for pkg in "${CODEX_WEB_APT_PACKAGES[@]}"; do
  if dpkg -s "$pkg" &>/dev/null; then
    pass "apt:$pkg" "installed"
  else
    fail "apt:$pkg" "installed" "missing"
  fi
done

info "pyenv runtimes"
if command -v pyenv >/dev/null 2>&1; then
  pass "pyenv" "$(pyenv --version)"
  pyenv_versions=$(pyenv versions --bare)
  for version in "${CODEX_WEB_PYTHON_VERSIONS[@]}"; do
    if grep -qx "$version" <<<"$pyenv_versions"; then
      pass "pyenv $version" "present"
    else
      fail "pyenv $version" "present" "missing"
    fi
  done
  actual_global=$(pyenv global 2>/dev/null | head -n1 | tr -d '[:space:]')
  if [[ -n "$actual_global" ]]; then
    if [[ "$actual_global" == "$CODEX_WEB_PYTHON_GLOBAL" ]]; then
      pass "pyenv global" "$actual_global"
    else
      fail "pyenv global" "$CODEX_WEB_PYTHON_GLOBAL" "$actual_global"
    fi
  else
    fail "pyenv global" "$CODEX_WEB_PYTHON_GLOBAL" "unset"
  fi
else
  fail "pyenv" "installed" "missing"
fi

info "pipx toolchain"
if command -v pipx >/dev/null 2>&1; then
  if ! command -v jq >/dev/null 2>&1; then
    fail "jq" "installed" "missing"
  else
    pipx_json=$(pipx list --json)
    for package in "${CODEX_WEB_PIPX_PACKAGE_NAMES[@]}"; do
      expected="${CODEX_WEB_PIPX_PACKAGES[$package]}"
      actual=$(jq -r --arg pkg "$package" '.venvs[$pkg].metadata.main_package.package_version // empty' <<<"$pipx_json")
      if [[ -n "$actual" ]]; then
        if [[ "$actual" == "$expected" ]]; then
          pass "pipx $package" "$actual"
        else
          fail "pipx $package" "$expected" "$actual"
        fi
      else
        fail "pipx $package" "$expected" "missing"
      fi
    done
  fi
else
  fail "pipx" "installed" "missing"
fi

info "Node.js and Corepack"
if command -v node >/dev/null 2>&1; then
  node_version=$(node -v | sed 's/^v//')
  if [[ "$node_version" == "$CODEX_WEB_NODE_VERSION" ]]; then
    pass "node" "$node_version"
  else
    fail "node" "$CODEX_WEB_NODE_VERSION" "$node_version"
  fi
else
  fail "node" "$CODEX_WEB_NODE_VERSION" "missing"
fi

for tool in "${CODEX_WEB_COREPACK_TOOL_NAMES[@]}"; do
  expected="${CODEX_WEB_COREPACK_TOOLS[$tool]}"
  if command -v "$tool" >/dev/null 2>&1; then
    case "$tool" in
      yarn)
        actual=$(yarn --version 2>/dev/null | tr -d '\r')
        ;;
      *)
        actual=$("$tool" --version 2>/dev/null | tr -d '\r')
        ;;
    esac
    if [[ "$actual" == "$expected" ]]; then
      pass "$tool" "$actual"
    else
      fail "$tool" "$expected" "$actual"
    fi
  else
    fail "$tool" "$expected" "missing"
  fi
done

info "Rust toolchain"
if command -v rustc >/dev/null 2>&1; then
  rust_version=$(rustc --version | awk '{print $2}')
  if [[ "$rust_version" == "$CODEX_WEB_RUST_VERSION" ]]; then
    pass "rustc" "$rust_version"
  else
    fail "rustc" "$CODEX_WEB_RUST_VERSION" "$rust_version"
  fi
else
  fail "rustc" "$CODEX_WEB_RUST_VERSION" "missing"
fi

info "mise tool versions"
if command -v mise >/dev/null 2>&1; then
  declare -A MISE_CURRENT=()
  while IFS=' ' read -r tool version _; do
    [[ -z "$tool" || -z "$version" ]] && continue
    MISE_CURRENT[$tool]="$version"
  done < <(mise current)
  for tool in "${CODEX_WEB_MISE_TOOL_NAMES[@]}"; do
    expected="${CODEX_WEB_MISE_TOOLS[$tool]}"
    actual="${MISE_CURRENT[$tool]:-}"
    if [[ -n "$actual" ]]; then
      if [[ "$actual" == "$expected" ]]; then
        pass "mise $tool" "$actual"
      else
        fail "mise $tool" "$expected" "$actual"
      fi
    else
      fail "mise $tool" "$expected" "missing"
    fi
  done
else
  fail "mise" "installed" "missing"
fi

info "Environment exports"
BASHRC_PATH="$TARGET_HOME/.bashrc"
for key in "${CODEX_WEB_ENV_EXPORT_KEYS[@]}"; do
  expected="${CODEX_WEB_ENV_EXPORTS[$key]}"
  env_value="${!key:-}"
  if [[ -n "$env_value" ]]; then
    if [[ "$env_value" == "$expected" ]]; then
      pass "$key" "$env_value"
      continue
    else
      fail "$key" "$expected" "$env_value"
      continue
    fi
  fi

  if [[ -f "$BASHRC_PATH" ]] && grep -Fq "export $key=$expected" "$BASHRC_PATH"; then
    pass "$key" "$expected (bashrc)"
  else
    fail "$key" "$expected" "missing"
  fi
done

if [[ ${#ERRORS[@]} -eq 0 ]]; then
  printf '\n%s Codex Web environment verified for %s.\n' "$PASS_SYMBOL" "$TARGET_USER"
else
  printf '\n%s Verification failed for %s (%d issues).\n' "$FAIL_SYMBOL" "$TARGET_USER" "${#ERRORS[@]}"
  exit 1
fi
