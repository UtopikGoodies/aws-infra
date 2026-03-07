# Prerequisites - Complete Setup Guide

This guide walks you through all the steps required **before** you can run the Terraform code, starting from zero AWS experience.

**TL;DR - What you MUST do manually:**
1. Create an AWS account
2. Create an IAM user with credentials for Terraform
3. (Optional if using Codespaces) Install Terraform and AWS CLI locally
4. (Optional if using Codespaces) Configure AWS CLI with your credentials

**Everything else is automated by Terraform!** (Including AWS Organizations and Control Tower)

**Using GitHub Codespaces?** You can skip steps 3-4 if you're using [UtopikGoodies/dotfiles](https://github.com/UtopikGoodies/dotfiles) with GitHub Codespaces secrets (see Phase 4).

---

## Phase 1: Create AWS Account

### Step 1.1: Create an AWS Account

1. Go to https://aws.amazon.com
2. Click **"Create an AWS Account"**
3. Enter your email address and choose an account name (e.g., "MyCompany-Management")
4. Complete the sign-up process:
   - Verify your email address
   - Create a strong password
   - Add contact information (address, phone)
   - Choose a support plan (Free tier is sufficient for initial setup)
5. Choose payment method (credit/debit card required)
6. Verify your phone number via SMS or call

Once complete, you'll have a management AWS account with root access.

---

## Phase 2: Create IAM User for Terraform

### Step 2.1: Create IAM User

Don't use the root account for Terraform - create a dedicated IAM user instead.

1. Sign in with your root account to AWS Console
2. Go to **IAM** → **Users** → **Create user**
3. Username: `terraform-admin`
4. **Do NOT** check "Provide user access to the AWS Management Console" (we only need API access)
5. Click **"Next"**
6. Click **"Attach policies directly"**
7. Search for `AdministratorAccess` and check it (needed for initial setup)
8. Click **"Next"** → **"Create user"**

### Step 2.2: Create Access Keys

1. Click on your newly created `terraform-admin`
2. Go to **Security credentials** tab
3. Scroll to **Access keys** section
4. Click **"Create access key"**
5. Choose **"Command Line Interface (CLI)"**
6. Click **"Create access key"**
7. **CRITICAL**: Download the CSV or copy these values immediately:
   - Access Key ID
   - Secret Access Key
   - **These are shown only once!**

---

## Phase 3: Install Tools Locally

### Step 3.1: Install AWS CLI

Check if you already have it:

```bash
aws --version
```

If not installed:
- **macOS**: `brew install awscli`
- **Linux**: 
  - Ubuntu/Debian: `sudo apt-get install awscli`
  - Or follow: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- **Windows**: Download from https://aws.amazon.com/cli/

### Step 3.2: Install Terraform

Check if you already have it:

```bash
terraform --version
```

If not installed (need v1.0+):
- **macOS**: `brew install terraform`
- **Linux**: 
  ```bash
  wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
  unzip terraform_1.6.0_linux_amd64.zip
  sudo mv terraform /usr/local/bin/
  ```
- **Windows**: Download from https://www.terraform.io/downloads.html

---

### What Terraform Will Automatically Create

When you run Terraform, it will automatically:
- ✅ Create AWS Organizations (if not already created)
- ✅ Deploy Control Tower landing zone (takes 30-40 minutes)
- ✅ Create Audit and Log Archive accounts
- ✅ Set up Core OUs (organizational units)
- ✅ Deploy Service Control Policies
- ✅ Enable IAM Identity Center
- ✅ Set up Account Factory for Terraform (AFT)
- ✅ Enable CloudTrail and AWS Config

You don't need to do anything manually for any of these!

---

## Phase 4: Configure AWS Credentials

### Step 4.1: Using GitHub Codespaces with Automated Setup (Recommended)

If you're using GitHub Codespaces with [UtopikGoodies/dotfiles](https://github.com/UtopikGoodies/dotfiles), AWS CLI is automatically configured with your credentials injected into the container via GitHub Codespaces secrets.

**Option A: Add AWS Credentials as Codespaces Secret (Automated)**

Create a GitHub Codespaces secret with your AWS credentials:

1. Go to your GitHub Settings → **Codespaces** → **Secrets** (or https://github.com/settings/codespaces)
2. Click **New secret**
3. Name: `aws_credentials_config`
4. Value: Paste the JSON configuration below (updated with YOUR values):

```json
{
   "name": "YourOrganizationName",
   "sso_region": "ca-central-1",
   "accounts": [
   {
      "id": "123456789012",
      "type": "access_key",
      "profile": "tfadmin",
      "access_key_id": "AKIAIOSFODNN7EXAMPLE",
      "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
   }
   ]
}
```

**Replace with your actual values:**
- `"YourOrganizationName"` → Your organization/company name
- `"id": "123456789012"` → Your AWS Management Account ID
- `"access_key_id"` → Access Key ID from Phase 2, Step 2.2
- `"secret_access_key"` → Secret Access Key from Phase 2, Step 2.2

5. Click **Add secret**
6. **Important**: Make sure this secret is available to your repository:
   - Go to your repo Settings → **Secrets and variables** → **Codespaces**
   - Verify the secret appears in "Repository secrets"

When you open Codespaces next time, the dotfiles will automatically:
- Create AWS profile `tfadmin` (based on prefix)
- Inject credentials into `~/.aws/credentials`
- Configure the profile for you

**No manual `aws configure` needed!**

### Step 4.2: Check Available Profiles

List all configured AWS profiles:

```bash
aws configure list-profiles
```

You should see:
- `tfadmin` (or similar, based on your secret configuration)
- `default` (if set)
- others you've configured

### Step 4.3: Using AWS Profiles

When you have multiple AWS profiles, specify which one to use:

**Option A: Set default profile (recommended)**

Set the `AWS_PROFILE` environment variable:

```bash
export AWS_PROFILE=tfadmin
```

To make it permanent, add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):
```bash
export AWS_PROFILE=tfadmin
```

**Option B: Use a specific profile for a single command**

```bash
aws sts get-caller-identity --profile tfadmin
```

**Option C: Set default profile in AWS config**

Edit `~/.aws/config` and set:
```ini
[default]
region = ca-central-1
output = json
```

Then run `aws` commands without `--profile` flag.

### Step 4.4: Verify Credentials

Test with your chosen profile:

```bash
# If you set a default profile
aws sts get-caller-identity

# Or specify a profile
aws sts get-caller-identity --profile tfadmin
```

You should see output like:
```json
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/terraform-admin"
}
```

✅ If you see this, the profile is working correctly!

### Step 4.5: Manual Configuration (if NOT using Codespaces secrets)

If you're **NOT** using GitHub Codespaces with automated secrets, manually configure AWS CLI:

Run this command:

```bash
aws configure --profile tfadmin
```

When prompted, enter:
- **AWS Access Key ID**: [paste from Phase 2, Step 2.2]
- **AWS Secret Access Key**: [paste from Phase 2, Step 2.2]
- **Default region name**: [choose one, e.g., `ca-central-1` or `us-east-1`]
- **Default output format**: `json`

This creates a profile named `tfadmin` in `~/.aws/credentials`.

Then set it as default:
```bash
export AWS_PROFILE=tfadmin
```

---

## Phase 5: Prepare Terraform Configuration

### Step 5.1: Choose Your Settings

Decide on:

1. **AWS Region**: Where your resources will live
   - Choose one close to you or your organization
   - Examples: `ca-central-1`, `us-east-1`, `eu-west-1`
   - **Tip**: This is where Control Tower will be deployed

2. **Email Domain**: For auto-generated account emails
   - Format: `yourcompany.com` (can be any domain you control)
   - AWS will create emails like: `log-archive+suffix@yourcompany.com`
   - You don't need a real mailbox, just a domain

### Step 5.2: Create terraform.tfvars

From your repository root directory:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit the new `terraform.tfvars` file and update these:

```hcl
# Update these with your choices from Step 5.1
primary_region       = "ca-central-1"      # Your chosen region
account_email_domain = "yourcompany.com"   # Your email domain

# Keep other values as defaults or customize as needed
organizational_units = { ... }
accounts = { ... }
```

---

## Phase 6: What Terraform Will Automatically Create

You don't need to do anything else - Terraform will automatically:

- ✅ Create AWS Organizations (if not already created)
- ✅ Deploy AWS Control Tower landing zone (automated, ~30-40 min)
- ✅ Create Audit and Log Archive accounts
- ✅ Set up Core Organizational Units (OUs)
- ✅ Deploy Service Control Policies
- ✅ Enable IAM Identity Center
- ✅ Set up Account Factory for Terraform (AFT)
- ✅ Enable CloudTrail for logging
- ✅ Enable AWS Config for compliance monitoring

---

## Phase 7: Ready to Deploy!

Verify you have completed:

- ✅ AWS account created
- ✅ IAM `terraform-admin` created with Access Keys
- ✅ AWS CLI installed with profile configured
- ✅ Terraform installed (version 1.0+)
- ✅ `aws sts get-caller-identity` returns your terraform-admin
- ✅ `terraform.tfvars` created with region and email domain
- ✅ Default AWS profile set (via `export AWS_PROFILE=tfadmin` or in `~/.aws/config`)

Then deploy:

```bash
cd terraform
terraform init
terraform plan
```

**If you're using a non-default profile**, set it before running Terraform:

```bash
export AWS_PROFILE=tfadmin
terraform init
terraform plan
```

Or pass it to each command:

```bash
AWS_PROFILE=tfadmin terraform init
AWS_PROFILE=tfadmin terraform plan
```

This will show you what Terraform will create. If it looks good:

```bash
terraform apply
# or with profile:
AWS_PROFILE=tfadmin terraform apply
```

**⏱️ Deployment time:** ~45-60 minutes (includes Control Tower deployment, which is automated)

---

## Troubleshooting

### "aws: command not found"
AWS CLI is not installed or not on your PATH:
```bash
which aws
```
If empty, reinstall AWS CLI for your OS (see Phase 3.1)

### "terraform: command not found"
Terraform is not installed or not on your PATH:
```bash
which terraform
```
If empty, reinstall Terraform for your OS (see Phase 3.2)

### "UnauthorizedOperation" error from Terraform
The `terraform-admin` doesn't have `AdministratorAccess` policy:
1. Go to IAM Console
2. Select the `terraform-admin`
3. Click **Add permissions** → **Attach policies directly**
4. Search for `AdministratorAccess` and select it
5. Click **Attach policies**
6. Wait 2-3 minutes, then try again

### "credentials not found" error
AWS credentials or profile not configured:

Check available profiles:
```bash
aws configure list-profiles
```

Set a default profile:
```bash
export AWS_PROFILE=tfadmin
```

Or verify your profile exists:
```bash
aws sts get-caller-identity --profile tfadmin
```

### "InvalidUserID.NotFound" when creating terraform-admin
The IAM user already exists. Either:
- Use an existing user that has `AdministratorAccess` policy, or
- Choose a different username

### "AWS profile not found" error
Terraform or AWS CLI can't find your profile:

1. Check available profiles:
   ```bash
   aws configure list-profiles
   ```

2. Set the default profile:
   ```bash
   export AWS_PROFILE=tfadmin
   ```

3. Verify the profile works:
   ```bash
   aws sts get-caller-identity --profile tfadmin
   ```

4. For Terraform, either set `AWS_PROFILE` environment variable or use the profile in your Terraform command:
   ```bash
   AWS_PROFILE=tfadmin terraform init
   ```

---

## Security Best Practices

1. **Protect your credentials**
   - Never commit `~/.aws/credentials` file to Git
   - Never share Access Keys
   - Rotate keys every 90 days

2. **Use least privilege later**
   - We gave `AdministratorAccess` for initial setup
   - After initial deployment, restrict the `terraform-admin` policy to only needed permissions

3. **Enable MFA on root account**
   - Go to IAM → Security credentials
   - Add MFA to root user
   - Store backup codes securely

4. **CloudTrail logs everything**
   - Terraform will enable CloudTrail automatically
   - All API calls are logged and auditable

---

## Next Steps

After deployment completes:

1. Read [README.md](../README.md) for overview
2. Review [docs/control-tower-aft.md](../docs/control-tower-aft.md) for operating model
3. Review [docs/organization-structure.md](../docs/organization-structure.md) for OU design
4. Create additional accounts via AFT (see [docs/workload-repo-strategy.md](../docs/workload-repo-strategy.md))

Good luck! 🚀
