# GitHub Secrets Configuration

## Required Secrets

Navigate to: **Settings → Secrets and variables → Actions → New repository secret**

### 1. MLFLOW_TRACKING_URI (Optional)
- **Description**: MLflow tracking server URI
- **Example**: `https://mlflow.example.com` or `file:./mlruns` for local
- **Default**: Uses local file storage if not set

### 2. SLACK_WEBHOOK_URL (Optional)
- **Description**: Slack webhook for notifications
- **Setup**:
  1. Go to https://api.slack.com/messaging/webhooks
  2. Create new webhook for your workspace
  3. Copy webhook URL
- **Example**: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXX`

### 3. GITHUB_TOKEN (Automatic)
- **Description**: Automatically provided by GitHub Actions
- **No action required**

## Enable GitHub Pages

1. Go to **Settings → Pages**
2. Source: **GitHub Actions**
3. Save

Your reports will be available at:
`https://AkanimohOD19A.github.io/Named-Entity-Recognition/`

## Workflow Permissions

1. Go to **Settings → Actions → General**
2. Workflow permissions: **Read and write permissions**
3. Check "Allow GitHub Actions to create and approve pull requests"
4. Save

