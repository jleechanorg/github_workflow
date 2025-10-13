#!/bin/bash
# Auto-configure GitHub repositories with allow_update_branch setting
# Runs periodically to catch repos created via web interface

set -e

LOG_FILE="$HOME/.github-repo-auto-config.log"
ORG="jleechanorg"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Get repos created in the last 48 hours
cutoff_date=$(date -u -v-48H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '48 hours ago' '+%Y-%m-%dT%H:%M:%SZ')

log "Starting auto-configuration check..."

# Get all repos and check their settings
repos=$(gh repo list "$ORG" --limit 100 --json name,createdAt,owner --jq '.[] | select(.createdAt > "'"$cutoff_date"'") | "\(.owner.login)/\(.name)"')

if [ -z "$repos" ]; then
    log "No recently created repos found."
    exit 0
fi

count=0
while IFS= read -r repo; do
    if [ -z "$repo" ]; then
        continue
    fi

    # Check if allow_update_branch is already enabled
    current_setting=$(gh api "/repos/$repo" --jq '.allow_update_branch' 2>/dev/null || echo "error")

    if [ "$current_setting" = "false" ]; then
        log "Configuring $repo..."
        if gh api --method PATCH "/repos/$repo" -f allow_update_branch=true > /dev/null 2>&1; then
            log "✓ Successfully enabled allow_update_branch for $repo"
            ((count++))
        else
            log "✗ Failed to enable allow_update_branch for $repo"
        fi
    elif [ "$current_setting" = "true" ]; then
        log "✓ $repo already configured"
    else
        log "⚠ Could not check status of $repo"
    fi
done <<< "$repos"

if [ $count -gt 0 ]; then
    log "Auto-configured $count repository(ies)"
else
    log "No repositories needed configuration"
fi

log "Check complete"
