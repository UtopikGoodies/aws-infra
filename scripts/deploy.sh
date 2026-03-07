#!/usr/bin/env bash
set -euo pipefail

# AWS Infrastructure Deployment - Root Module
# Deploys entire stack (bootstrap → control-tower → org → aft) via single root module
# This replaces the multi-stage sequential deployment with a unified Terraform apply

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_ROOT="${REPO_ROOT}/terraform"
CONFIG_FILE="${REPO_ROOT}/.env"

# Configuration
AUTO_APPROVE="${AUTO_APPROVE:-false}"
DESTROY="${DESTROY:-false}"
PLAN_ONLY="${PLAN_ONLY:-false}"

# Function to print colored output
print_header() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

print_step() {
  echo ""
  echo "▶ $1"
}

print_success() {
  echo "✓ $1"
}

# Load config if exists
if [[ -f "${CONFIG_FILE}" ]]; then
  echo "Loading configuration from ${CONFIG_FILE}"
  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"
fi

# Set defaults
AWS_PROFILE="${AWS_PROFILE:-management}"

export AWS_PROFILE

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto-approve)
      AUTO_APPROVE="true"
      shift
      ;;
    --destroy)
      DESTROY="true"
      shift
      ;;
    --plan-only)
      PLAN_ONLY="true"
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/deploy.sh [OPTIONS]

Deploys complete AWS infrastructure using root Terraform module.
All stages deploy atomically (bootstrap → control-tower → org → aft).

OPTIONS:
  --auto-approve       Skip terraform plan approval
  --plan-only          Run plan but do not apply
  --destroy            Destroy all resources (DANGEROUS)
  -h, --help           Show this help message

CONFIGURATION:
  Terraform variables: ${REPO_ROOT}/terraform.tfvars
    - Copy from terraform.tfvars.example
    - Contains all stack configuration (region, accounts, OUs, SCPs, etc.)
  
  AWS credentials (via .env, environment variables, or AWS config):
    - AWS_PROFILE        AWS profile to use (default: management)

EXAMPLES:
  # Full interactive deployment
  ./scripts/deploy.sh

  # Fully automated
  ./scripts/deploy.sh --auto-approve

  # Plan only (no apply)
  ./scripts/deploy.sh --plan-only

  # With custom AWS profile
  AWS_PROFILE=prod ./scripts/deploy.sh

NOTES:
  - Terraform automatically loads terraform.tfvars from repo root
  - All modules (bootstrap, control-tower, org, aft) share config
  - Control Tower deployment takes 30-45 minutes
  - All stages must complete successfully before proceeding

FIRST RUN:
  1. cp terraform.tfvars.example terraform.tfvars
  2. Edit terraform.tfvars with your organization details
  3. Optionally create .env with AWS_PROFILE
  4. Run: ./scripts/deploy.sh
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# Helper function to validate requirements
check_requirements() {
  local missing=0
  for cmd in terraform aws jq; do
    if ! command -v "$cmd" &> /dev/null; then
      echo "❌ Required command not found: $cmd"
      missing=1
    fi
  done
  
  if [[ $missing -eq 1 ]]; then
    echo "Please install missing dependencies"
    exit 1
  fi
  
  # Check AWS credentials
  if ! aws sts get-caller-identity --profile "${AWS_PROFILE}" > /dev/null 2>&1; then
    echo "❌ AWS credentials not configured for profile: ${AWS_PROFILE}"
    exit 1
  fi
}

main() {
  print_header "AWS Infrastructure Deployment (Root Module)"
  
  echo "Configuration:"
  echo "  AWS Profile:              ${AWS_PROFILE}"
  echo ""
  echo "Terraform variables configured in:"
  echo "  ${REPO_ROOT}/terraform.tfvars (auto-loaded)"
  echo ""
  
  check_requirements
  
  # Initialize Terraform
  print_step "Initializing Terraform root module..."
  terraform -chdir="${TERRAFORM_ROOT}" init
  print_success "Terraform initialization complete"
  
  # Plan
  print_header "Terraform Plan"
  print_step "Generating execution plan..."
  
  # Terraform auto-loads ../terraform.tfvars from repo root
  if [[ "${DESTROY}" == "true" ]]; then
    terraform -chdir="${TERRAFORM_ROOT}" plan -destroy -out=tfplan
  else
    terraform -chdir="${TERRAFORM_ROOT}" plan -out=tfplan
  fi
  
  # Show summary
  echo ""
  echo "───────────────────────────────────────────────────────────────────────────"
  terraform -chdir="${TERRAFORM_ROOT}" show -no-color tfplan | grep -E "^(Terraform|No changes|Plan:|  [+-])" || true
  echo "───────────────────────────────────────────────────────────────────────────"
  echo ""
  
  # Exit if plan-only
  if [[ "${PLAN_ONLY}" == "true" ]]; then
    echo "Plan saved as tfplan. Run with --auto-approve to apply."
    rm -f "${TERRAFORM_ROOT}/tfplan"
    exit 0
  fi
  
  # Apply
  if [[ "${AUTO_APPROVE}" == "true" ]]; then
    print_step "Applying infrastructure (auto-approved)..."
    terraform -chdir="${TERRAFORM_ROOT}" apply tfplan
  else
    print_step "Review the plan above"
    if [[ "${DESTROY}" == "true" ]]; then
      read -p "⚠️  This will DESTROY all resources. Continue? (type 'destroy' to confirm): " confirmation
      if [[ "${confirmation}" != "destroy" ]]; then
        echo "Cancelled"
        rm -f "${TERRAFORM_ROOT}/tfplan"
        exit 1
      fi
    else
      read -p "Apply infrastructure? (yes/no): " approval
      if [[ "${approval}" != "yes" ]]; then
        echo "Cancelled"
        rm -f "${TERRAFORM_ROOT}/tfplan"
        exit 0
      fi
    fi
    terraform -chdir="${TERRAFORM_ROOT}" apply tfplan
  fi
  
  # Clean up plan
  rm -f "${TERRAFORM_ROOT}/tfplan"
  
  # Show outputs
  print_header "Deployment Complete"
  print_success "Infrastructure successfully deployed!"
  echo ""
  echo "Outputs:"
  terraform -chdir="${TERRAFORM_ROOT}" output -json | jq . || true
  echo ""
  echo "Configuration source:"
  echo "  terraform.tfvars: ${REPO_ROOT}/terraform.tfvars"
  echo ""
  echo "Next steps:"
  echo "1. Verify Control Tower status in AWS Console"
  echo "2. Configure IAM Identity Center with users/groups"
  echo "3. Review account structure in AWS Organizations"
  echo "4. Enable AFT customization pipeline (optional)"
  echo ""
}

main "$@"
