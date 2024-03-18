#!/bin/sh

# Set the path to your Obsidian vault
VAULTS_PATH="/Users/wilfriedago/Documents/Vaults"

# Check if the vaults path is valid
if [ ! -d "$VAULTS_PATH" ]; then
    echo "❌ Invalid vaults path. Please check the path and try again."
    exit 1
fi

# Check if the script has read and write permissions to the vaults directory
if [ ! -r "$VAULTS_PATH" ] || [ ! -w "$VAULTS_PATH" ]; then
    echo "❌ Insufficient permissions. Please ensure the script has read and write permissions to the vaults directory."
    exit 1
fi

# Navigate to the vault directory
cd "$VAULTS_PATH" || exit

# Check if there are any changes
if git diff-index --quiet HEAD --; then
    # No changes, exit without committing
    echo "No changes to commit in your vaults. Exiting..."
    exit
fi

# Get the current hostname
HOSTNAME=$(hostname)

# Get the current date
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")

# Add all changes, commit, and push
git add .
git commit -m "vault backup: $HOSTNAME - $CURRENT_DATE"
git push origin main

echo "✅ Vault backup completed successfully!"
