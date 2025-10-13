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
│   └── github-repo-auto-config.sh   # Background monitoring script
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
