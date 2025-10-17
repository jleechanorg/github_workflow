#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/codex-web-manifest.sh"

mapfile -t CODEX_WEB_PIPX_PACKAGE_NAMES < <(printf '%s\n' "${!CODEX_WEB_PIPX_PACKAGES[@]}" | sort)
mapfile -t CODEX_WEB_COREPACK_TOOL_NAMES < <(printf '%s\n' "${!CODEX_WEB_COREPACK_TOOLS[@]}" | sort)
mapfile -t CODEX_WEB_MISE_TOOL_NAMES < <(printf '%s\n' "${!CODEX_WEB_MISE_TOOLS[@]}" | sort)
mapfile -t CODEX_WEB_ENV_EXPORT_KEYS < <(printf '%s\n' "${!CODEX_WEB_ENV_EXPORTS[@]}" | sort)

if [[ ${EUID:-0} -ne 0 ]]; then
  echo "This script must be run with sudo or as root because it installs system packages." >&2
  exit 1
fi

TARGET_USER="${TARGET_USER:-${SUDO_USER:-root}}"
TARGET_HOME=$(eval echo "~${TARGET_USER}")

run_as_user() {
  local cmd="$1"
  su - "$TARGET_USER" -c "$cmd"
}

run_as_user "touch ~/.bashrc"

apt-get update
apt-get install -y "${CODEX_WEB_APT_PACKAGES[@]}"

python3 -m pip install --upgrade pip setuptools wheel

if [[ ! -d "$TARGET_HOME/.pyenv" ]]; then
  run_as_user "git clone https://github.com/pyenv/pyenv.git ~/.pyenv"
fi

if ! run_as_user "grep -q 'codex-web pyenv setup' ~/.bashrc"; then
  run_as_user "cat <<'PYENV_BLOCK' >> ~/.bashrc
# >>> codex-web pyenv setup >>>
export PYENV_ROOT=\"\$HOME/.pyenv\"
export PATH=\"\$PYENV_ROOT/bin:\$PATH\"
if command -v pyenv >/dev/null 2>&1; then
  eval \"\$(pyenv init -)\"
fi
# <<< codex-web pyenv setup <<<
PYENV_BLOCK"
fi

PYENV_EXPORTS="export PYENV_ROOT=\"$TARGET_HOME/.pyenv\"; export PATH=\"$TARGET_HOME/.pyenv/bin:\$PATH\"; eval \"\$(pyenv init -)\""
for version in "${CODEX_WEB_PYTHON_VERSIONS[@]}"; do
  run_as_user "$PYENV_EXPORTS; pyenv install -s $version"
done
run_as_user "$PYENV_EXPORTS; pyenv global $CODEX_WEB_PYTHON_GLOBAL"

run_as_user "pipx ensurepath"
PYENV_PYTHON="$TARGET_HOME/.pyenv/versions/$CODEX_WEB_PIPX_PYTHON/bin/python"
for package in "${CODEX_WEB_PIPX_PACKAGE_NAMES[@]}"; do
  version="${CODEX_WEB_PIPX_PACKAGES[$package]}"
  run_as_user "pipx install --force --python $PYENV_PYTHON $package==$version"
done

if [[ ! -d "$TARGET_HOME/.nvm" ]]; then
  run_as_user "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
fi

if ! run_as_user "grep -q 'codex-web nvm setup' ~/.bashrc"; then
  run_as_user "cat <<'NVM_BLOCK' >> ~/.bashrc
# >>> codex-web nvm setup >>>
export NVM_DIR=\"\$HOME/.nvm\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
[ -s \"\$NVM_DIR/bash_completion\" ] && . \"\$NVM_DIR/bash_completion\"
# <<< codex-web nvm setup <<<
NVM_BLOCK"
fi

run_as_user "export NVM_DIR=$TARGET_HOME/.nvm; . \$NVM_DIR/nvm.sh; nvm install $CODEX_WEB_NODE_VERSION; nvm use $CODEX_WEB_NODE_VERSION; nvm alias default $CODEX_WEB_NODE_VERSION; corepack enable"
for tool in "${CODEX_WEB_COREPACK_TOOL_NAMES[@]}"; do
  version="${CODEX_WEB_COREPACK_TOOLS[$tool]}"
  run_as_user "export NVM_DIR=$TARGET_HOME/.nvm; . \$NVM_DIR/nvm.sh; corepack prepare $tool@$version --activate"
done

if [[ ! -x "$TARGET_HOME/.cargo/bin/rustup" ]]; then
  run_as_user "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
fi
run_as_user "$TARGET_HOME/.cargo/bin/rustup toolchain install $CODEX_WEB_RUST_VERSION"
run_as_user "$TARGET_HOME/.cargo/bin/rustup default $CODEX_WEB_RUST_VERSION"

if ! run_as_user "grep -q 'codex-web cargo env' ~/.bashrc"; then
  run_as_user "cat <<'CARGO_BLOCK' >> ~/.bashrc
# >>> codex-web cargo env >>>
. \"\$HOME/.cargo/env\"
# <<< codex-web cargo env <<<
CARGO_BLOCK"
fi

if [[ ! -d "$TARGET_HOME/.local/share/mise" ]]; then
  run_as_user "curl https://mise.jdx.dev/install.sh | sh"
fi

run_as_user "mkdir -p ~/.config/mise"
mise_tools_block=""
for tool in "${CODEX_WEB_MISE_TOOL_NAMES[@]}"; do
  version="${CODEX_WEB_MISE_TOOLS[$tool]}"
  mise_tools_block+=$(printf '%s = "%s"\n' "$tool" "$version")
done
mise_tools_block=${mise_tools_block%$'\n'}

mise_config_cmd=$(cat <<EOF
cat <<'MISE_CFG' > ~/.config/mise/config.toml
[settings]
experimental = true
override_tool_versions_filenames = ["none"]
idiomatic_version_file_enable_tools = []

[tools]
$mise_tools_block
MISE_CFG
EOF
)
run_as_user "$mise_config_cmd"

if ! run_as_user "grep -q 'codex-web mise setup' ~/.bashrc"; then
  run_as_user "cat <<'MISE_BLOCK' >> ~/.bashrc
# >>> codex-web mise setup >>>
export PATH=\"\$HOME/.local/bin:\$PATH\"
if command -v mise >/dev/null 2>&1; then
  eval \"\$(mise env --shell bash)\"
fi
# <<< codex-web mise setup <<<
MISE_BLOCK"
fi

for tool in "${CODEX_WEB_MISE_TOOL_NAMES[@]}"; do
  version="${CODEX_WEB_MISE_TOOLS[$tool]}"
  run_as_user "~/.local/bin/mise install $tool@$version"
done
run_as_user "~/.local/bin/mise reshim"

env_exports_block=""
for key in "${CODEX_WEB_ENV_EXPORT_KEYS[@]}"; do
  env_exports_block+="export $key=${CODEX_WEB_ENV_EXPORTS[$key]}"$'\n'
done
env_exports_block=${env_exports_block%$'\n'}

if ! run_as_user "grep -q 'codex-web version exports' ~/.bashrc"; then
  export_block_cmd=$(cat <<EOF
cat <<'EXPORT_BLOCK' >> ~/.bashrc
# >>> codex-web version exports >>>
$env_exports_block
# <<< codex-web version exports <<<
EXPORT_BLOCK
EOF
  )
  run_as_user "$export_block_cmd"
fi

echo "Codex web environment replication complete for user $TARGET_USER."
