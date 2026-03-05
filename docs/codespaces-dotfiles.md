# Codespaces Dotfiles Setup

## Using `.sso-config` with GitHub Codespaces

GitHub Codespaces supports [dotfiles repositories](https://docs.github.com/en/codespaces/customizing-your-codespace/personalizing-codespaces-with-dotfiles) to automatically configure environments.

### Quick Setup

1. **Create a dotfiles repo** (or add to existing one):
   ```
   your-org/dotfiles/
   └── .sso-config
   ```

2. **Copy the template**:
   ```bash
   cp .sso-config.example .sso-config
   ```

3. **Edit `.sso-config`** with your Identity Center details:
   ```bash
   SSO_START_URL="https://my-sso-xxx.awsapps.com/start"
   SSO_REGION="us-east-1"
   SSO_PROFILES="dev,prod"
   
   DEV_ACCOUNT_ID="123456789012"
   DEV_ROLE_NAME="dev-engineer"
   
   PROD_ACCOUNT_ID="234567890123"
   PROD_ROLE_NAME="prod-admin"
   ```

4. **Add to your Codespaces settings**:
   - Go to https://github.com/settings/codespaces
   - Under **Dotfiles**, set:
     - Repository: `your-org/dotfiles`
     - Branch: `main`
     - Devcontainer path: empty (unless you customize it)

5. **Next time you create a Codespace**:
   - Codespaces clones your dotfiles repo to `~/.dotfiles`
   - Your dotfile setup script runs automatically
   - When `scripts/setup-aws-sso.sh` is called during devcontainer init, it reads `~/.sso-config` and auto-configures profiles

### How it works

The `setup-aws-sso.sh` script checks for `~/.sso-config`:

- **If found** → Auto-configures profiles from the file (no prompts)
- **If not found** → Falls back to interactive mode

### Variable naming convention

For a profile `dev`, provide:
- `DEV_ACCOUNT_ID`
- `DEV_ROLE_NAME`

For a profile `prod`, provide:
- `PROD_ACCOUNT_ID`
- `PROD_ROLE_NAME`

(Profiles are converted to UPPERCASE for environment variable lookups)

### Security note

Store `.sso-config` in a **private** dotfiles repository. It contains AWS account IDs and role names, but not credentials (those come from SSO login).
