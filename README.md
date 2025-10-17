# GitHub Workflow Automation Tools

Automation tools and scripts for GitHub workflow management, including automatic repository configuration and settings management.

## 🚀 Features

### 1. Auto-Configure Repository Settings

Automatically enables the "Always suggest updating pull request branches" setting (`allow_update_branch`) for:
- New repositories created via GitHub web interface
- New repositories created via CLI
- Existing repositories (one-time batch update)

## 📦 Installation

### Quick Install

```bash
# Clone the repository
git clone https://github.com/jleechanorg/github_workflow.git
cd github_workflow

# Run the install script
./install.sh
```

### Rebuild the Codex Web Container Environment

Use the dedicated replication script when you need a fresh workstation that matches the Codex Web container toolchain (Ubuntu 24.04 base image, language runtimes, and CLI helpers).

```bash
# Run as root or with sudo
sudo TARGET_USER="$(whoami)" ./bin/setup-codex-web.sh
```

What the script configures:

- System dependencies (build-essential, git, ripgrep, jq, etc.) via `apt`
- `pyenv` with CPython 3.10.17, 3.11.12, 3.12.10, and 3.13.3 (global default `3.12.10`)
- `pipx` packages: `clang-format`, `clang-tidy`, `cmakelang`, `cpplint`, `poetry`, and `uv`
- `nvm` with Node.js 20.19.4 plus Corepack-managed `pnpm 10.5.2` and `yarn 4.9.4`
- `rustup` pinned to Rust 1.89.0
- `mise` with Bun 1.2.14, Erlang 27.1.2, Elixir 1.18.3-otp-27, Go 1.24.3, golangci-lint 2.1.6, Gradle 8.14.3, Java 21.0.2, Maven 3.9.10, PHP 8.4.12, Ruby 3.4.4, and Swift 6.1
- Shell exports mirroring the Codex Web container (`CODEX_ENV_*` variables, PATH hooks for pyenv/nvm/rust/mise)

Set the optional `TARGET_USER` environment variable when invoking the script to install everything for a specific non-root account.

#### Verify the replication matches Codex Web

The environment manifest that drives the installer lives in [`bin/codex-web-manifest.sh`](bin/codex-web-manifest.sh). After running the installer, execute the verification helper (inside a Codex Web shell or a fresh login after installation) to compare your machine against the reference Codex Web container:

```bash
bin/verify-codex-web.sh
```

The script checks the OS fingerprint, apt packages, pyenv runtimes, pipx utilities, Node/Corepack, rustup, mise-managed toolchains, and the Codex-specific shell exports. A passing run confirms you are matching the Codex Web environment byte-for-byte.

### Manual Installation

1. **Copy scripts to your bin directory:**
   ```bash
   cp bin/gh-create-repo-auto ~/bin/
   cp bin/github-repo-auto-config.sh ~/bin/
   chmod +x ~/bin/gh-create-repo-auto
   chmod +x ~/bin/github-repo-auto-config.sh
   ```

2. **Install LaunchAgent for automatic monitoring:**
   ```bash
   cp launchd/com.github.repo-auto-config.plist ~/Library/LaunchAgents/
   # Update the path in the plist if your username differs
   launchctl load ~/Library/LaunchAgents/com.github.repo-auto-config.plist
   ```

3. **Add alias to your shell config:**
   ```bash
   echo 'alias gh-create="gh create-repo-auto"' >> ~/.zshrc
   source ~/.zshrc
   ```

## 🔧 Usage

### Creating New Repositories with Auto-Config

**Option 1: Using the wrapper script directly**
```bash
gh-create-repo-auto jleechanorg/my-new-repo --public --description "My awesome project"
```

**Option 2: Using the alias (after installation)**
```bash
gh-create my-new-repo --public --description "My awesome project"
```

This automatically:
- ✅ Creates the repository
- ✅ Enables `allow_update_branch` setting
- ✅ Shows confirmation

### Creating Repositories via GitHub Web

Just create repositories normally on GitHub.com! The background monitoring service will automatically:
- 🤖 Detect new repos within 30 minutes
- ⚙️ Enable the `allow_update_branch` setting
- 📝 Log all actions to `~/.github-repo-auto-config.log`

### Batch Update Existing Repositories

To enable the setting for all existing repositories:

```bash
~/bin/github-repo-auto-config.sh
```

## 📁 Repository Structure

```
github_workflow/
├── bin/
│   ├── gh-create-repo-auto          # CLI wrapper for repo creation
│   ├── github-repo-auto-config.sh   # Background monitoring script
│   ├── codex-web-manifest.sh        # Shared Codex Web toolchain manifest
│   ├── setup-codex-web.sh           # Rebuild the Codex Web container toolchain
│   └── verify-codex-web.sh          # Validate a machine against Codex Web
├── launchd/
│   └── com.github.repo-auto-config.plist  # macOS LaunchAgent config
├── install.sh                        # Quick installation script
└── README.md                         # This file
```

## 🔍 Monitoring and Logs

### Check LaunchAgent Status
```bash
launchctl list | grep github
```

### View Activity Log
```bash
cat ~/.github-repo-auto-config.log
```

### Manual Run (for testing)
```bash
~/bin/github-repo-auto-config.sh
```

## ⚙️ Configuration

### Monitoring Frequency

The LaunchAgent runs every **30 minutes** by default. To change this:

1. Edit `~/Library/LaunchAgents/com.github.repo-auto-config.plist`
2. Modify the `StartInterval` value (in seconds):
   - 900 = 15 minutes
   - 1800 = 30 minutes (default)
   - 3600 = 1 hour
3. Reload the LaunchAgent:
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.github.repo-auto-config.plist
   launchctl load ~/Library/LaunchAgents/com.github.repo-auto-config.plist
   ```

### Detection Window

The script checks repositories created in the last **48 hours**. To change this, edit the `cutoff_date` line in `github-repo-auto-config.sh`.

### Organization

By default, scripts are configured for the `jleechanorg` organization. To use with a different organization:

1. Edit `bin/github-repo-auto-config.sh`
2. Change the `ORG="jleechanorg"` line to your organization name

## 🛠️ Technical Details

### `gh-create-repo-auto`
- Wrapper around `gh repo create`
- Accepts all standard `gh repo create` arguments
- Automatically enables `allow_update_branch` after creation
- Provides color-coded success/failure feedback

### `github-repo-auto-config.sh`
- Queries GitHub API for recently created repositories
- Checks current `allow_update_branch` status
- Updates setting only if needed
- Logs all actions with timestamps
- Safe to run multiple times (idempotent)

### LaunchAgent
- Runs scripts automatically in the background
- Starts on user login
- Configurable run interval
- Logs stdout/stderr to separate files

## 📋 Requirements

- macOS (for LaunchAgent functionality)
- [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated
- Bash shell
- GitHub account with repository creation permissions

## 🤝 Contributing

Feel free to open issues or submit pull requests for improvements!

## 📄 License

MIT License - feel free to use and modify as needed.

## 🔗 Related

- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub API - Update Repository](https://docs.github.com/en/rest/repos/repos#update-a-repository)
- [LaunchAgent Reference](https://www.launchd.info/)
