#!/usr/bin/env bash

# Shared manifest describing the Codex Web container toolchain.
# The setup and verification scripts source this file so the expected
# versions live in a single place.

# Operating system fingerprint.
declare -gr CODEX_WEB_OS_PRETTY_NAME="Ubuntu 24.04.2 LTS"
declare -gr CODEX_WEB_OS_VERSION_ID="24.04"

# Base apt packages installed in the container.
declare -gra CODEX_WEB_APT_PACKAGES=(
  build-essential
  ca-certificates
  curl
  wget
  git
  git-lfs
  jq
  ripgrep
  unzip
  zip
  xz-utils
  libssl-dev
  zlib1g-dev
  libbz2-dev
  libreadline-dev
  libsqlite3-dev
  libffi-dev
  liblzma-dev
  tk-dev
  libncurses-dev
  libgdbm-dev
  libnss3-dev
  pkg-config
  software-properties-common
  python3-pip
  pipx
)

# CPython runtimes managed by pyenv.
declare -gra CODEX_WEB_PYTHON_VERSIONS=(
  3.10.17
  3.11.12
  3.12.10
  3.13.3
)
declare -gr CODEX_WEB_PYTHON_GLOBAL="3.12.10"

# Pipx packages keyed by package name -> version string.
declare -gr CODEX_WEB_PIPX_PYTHON="3.12.10"
declare -grA CODEX_WEB_PIPX_PACKAGES=(
  [clang-format]="20.1.8"
  [clang-tidy]="20.1.0"
  [cmakelang]="0.6.13"
  [cpplint]="2.0.2"
  [poetry]="2.1.4"
  [uv]="0.7.22"
)

# Node.js / Corepack configuration.
declare -gr CODEX_WEB_NODE_VERSION="20.19.4"
declare -grA CODEX_WEB_COREPACK_TOOLS=(
  [pnpm]="10.5.2"
  [yarn]="4.9.4"
)

# Rust toolchain version.
declare -gr CODEX_WEB_RUST_VERSION="1.89.0"

# Tools managed by mise (tool -> version).
declare -grA CODEX_WEB_MISE_TOOLS=(
  [bun]="1.2.14"
  [erlang]="27.1.2"
  [go]="1.24.3"
  [golangci-lint]="2.1.6"
  [gradle]="8.14.3"
  [java]="21.0.2"
  [maven]="3.9.10"
  [php]="8.4.12"
  [ruby]="3.4.4"
  [swift]="6.1"
  [elixir]="1.18.3-otp-27"
)

# Exported environment markers in ~/.bashrc.
declare -grA CODEX_WEB_ENV_EXPORTS=(
  [CODEX_ENV_PYTHON_VERSION]="3.12"
  [CODEX_ENV_NODE_VERSION]="20"
  [CODEX_ENV_RUBY_VERSION]="3.4.4"
  [CODEX_ENV_RUST_VERSION]="1.89.0"
  [CODEX_ENV_GO_VERSION]="1.24.3"
  [CODEX_ENV_BUN_VERSION]="1.2.14"
  [CODEX_ENV_PHP_VERSION]="8.4"
  [CODEX_ENV_JAVA_VERSION]="21"
  [CODEX_ENV_SWIFT_VERSION]="6.1"
)
