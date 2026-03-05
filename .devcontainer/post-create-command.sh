#!/bin/bash
# Initialize devcontainer environment
# Run automatically on postCreateCommand

set -e

# Make setup script executable
chmod +x /workspaces/aws-infra/scripts/setup-aws-sso.sh

# Print tool versions
echo "Tool versions:"
terraform -version | head -1
aws --version | head -1
gh --version | head -1

# Success message
echo ""
echo "✨ devcontainer ready!"
echo ""
echo "Verify your setup:"
echo "  aws sts get-caller-identity --profile <your-profile>"
echo "  terraform plan"
echo ""
