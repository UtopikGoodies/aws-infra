#!/bin/bash
# Initialize devcontainer environment
# Run automatically on postCreateCommand

set -e

# Print tool versions
echo "Tool versions:"
terraform -version | head -1
aws --version | head -1
gh --version | head -1

# Success message
echo ""
echo "✨ devcontainer ready!"
echo ""
