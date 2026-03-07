# GitHub Codespaces Setup

## AWS Credentials in Codespaces

To use AWS credentials in GitHub Codespaces, configure AWS credentials via environment variables or AWS profile in your `.devcontainer/devcontainer.json`.

### Option 1: AWS Profile (Recommended)

1. **Mount AWS credentials** into the container:
   ```json
   {
     "mounts": [
       "source=${localEnv:HOME}/.aws,target=/root/.aws,type=bind,readonly"
     ]
   }
   ```

2. **Set AWS_PROFILE** environment variable in your shell:
   ```bash
   export AWS_PROFILE=management
   aws sts get-caller-identity  # Verify credentials
   ```

### Option 2: Federated Identity (GitHub OIDC)

For CI/CD workflows, use GitHub OIDC to assume AWS roles without long-lived credentials:

```bash
aws sts assume-role-with-web-identity \
  --role-arn arn:aws:iam::ACCOUNT-ID:role/github-actions-role \
  --role-session-name github-session \
  --web-identity-token $GITHUB_TOKEN
```

### Security Best Practices

- Never commit AWS credentials to version control
- Use IAM Identity Center for human access when possible
- Prefer time-limited session credentials over long-lived access keys
- For automation, use IAM roles with trust policies
