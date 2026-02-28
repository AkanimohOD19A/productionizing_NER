# Complete CI/CD Setup Guide
## Automated NER Classification Pipeline with GitHub Actions

This guide will walk you through setting up a fully automated CI/CD pipeline that:
- 🎲 Generates synthetic transaction data on schedule
- 🤖 Trains NER classification models automatically
- 📊 Generates R Markdown reports
- 🌐 Deploys reports to GitHub Pages
- 🔔 Sends notifications on completion

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Setup (5 Minutes)](#quick-setup-5-minutes)
3. [GitHub Configuration](#github-configuration)
4. [Workflow Overview](#workflow-overview)
5. [Customization](#customization)
6. [Monitoring & Troubleshooting](#monitoring--troubleshooting)
7. [Local Testing](#local-testing)
8. [Docker Deployment](#docker-deployment)

---

## Prerequisites

### Required
- ✅ GitHub account
- ✅ Git installed locally
- ✅ Python 3.9+
- ✅ R 4.0+ (for report generation)

### Optional
- 🐳 Docker & Docker Compose (for containerized deployment)
- 💬 Slack workspace (for notifications)
- 📧 Email configured (for GitHub notifications)

---

## Quick Setup (5 Minutes)

### Step 1: Clone and Setup

```bash
# Clone your repository
git clone https://github.com/yourusername/Local_NER.git
cd Local_NER

# Run automated setup script
chmod +x setup_cicd.sh
./setup_cicd.sh
```

The setup script will:
- ✓ Create directory structure
- ✓ Generate .gitignore
- ✓ Create sample configurations
- ✓ Install dependencies
- ✓ Generate test data

### Step 2: Configure GitHub

```bash
# Add all files
git add .

# Commit
git commit -m "feat: add CI/CD pipeline"

# Push to GitHub
git push origin main
```

### Step 3: Enable GitHub Pages

1. Go to **Settings → Pages**
2. Under "Source", select **GitHub Actions**
3. Click **Save**

### Step 4: Set Workflow Permissions

1. Go to **Settings → Actions → General**
2. Scroll to "Workflow permissions"
3. Select **Read and write permissions**
4. Check ✅ "Allow GitHub Actions to create and approve pull requests"
5. Click **Save**

### Step 5: Watch Your First Run! 🎉

1. Go to **Actions** tab
2. You should see "NER Classification Pipeline" running
3. Wait 5-10 minutes for completion
4. Visit `https://yourusername.github.io/Local_NER/` to see your report!

---

## GitHub Configuration

### Required Secrets

Navigate to: **Settings → Secrets and variables → Actions**

#### 1. MLFLOW_TRACKING_URI (Optional)

```
Name: MLFLOW_TRACKING_URI
Value: file:./mlruns
```

For remote MLflow server:
```
Value: https://your-mlflow-server.com
```

#### 2. SLACK_WEBHOOK_URL (Optional)

**Setup Instructions:**

1. Go to https://api.slack.com/messaging/webhooks
2. Click "Create New App" → "From scratch"
3. Name: "NER Pipeline Notifications"
4. Select your workspace
5. Click "Incoming Webhooks" → Enable
6. Click "Add New Webhook to Workspace"
7. Select channel (e.g., #data-science)
8. Copy webhook URL

```
Name: SLACK_WEBHOOK_URL
Value: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXX
```

#### 3. POSTGRES_PASSWORD (For Docker Deployment)

```
Name: POSTGRES_PASSWORD
Value: your_secure_password_here
```

---

## Workflow Overview

### Pipeline Jobs

```
┌─────────────────┐
│  Generate Data  │  ← Creates synthetic transactions
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Run Tests     │  ← Unit tests, coverage
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Train Model    │  ← NER classifier training
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Generate Report │  ← R Markdown report
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     Deploy      │  ← GitHub Pages deployment
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     Notify      │  ← Slack/Email notifications
└─────────────────┘
```

### Trigger Conditions

**Automatic Triggers:**

1. **Daily Schedule** (2 AM UTC)
   ```yaml
   schedule:
     - cron: '0 2 * * *'
   ```

2. **Push to Main**
   ```yaml
   push:
     branches: [main]
   ```

3. **Pull Requests**
   ```yaml
   pull_request:
     branches: [main]
   ```

**Manual Trigger:**

Via GitHub UI:
1. Go to **Actions** tab
2. Select "NER Classification Pipeline"
3. Click **Run workflow**
4. Optionally set parameters:
   - Data size: Number of transactions (default: 1000)
   - Run training: true/false

Via GitHub CLI:
```bash
# Install GitHub CLI
brew install gh  # Mac
# or
apt install gh   # Linux

# Trigger workflow
gh workflow run ner_pipeline.yml

# With custom parameters
gh workflow run ner_pipeline.yml \
  -f data_size=5000 \
  -f run_training=true
```

### Artifacts Retention

| Artifact | Retention | Size Limit |
|----------|-----------|------------|
| Transaction Data | 30 days | 1 GB |
| Model Files | 90 days | 2 GB |
| Test Results | 30 days | 100 MB |
| HTML Reports | 90 days | 500 MB |

---

## Customization

### Change Schedule

Edit `.github/workflows/ner_pipeline.yml`:

```yaml
on:
  schedule:
    # Every 6 hours
    - cron: '0 */6 * * *'
    
    # Every Monday at 9 AM
    - cron: '0 9 * * 1'
    
    # First day of month
    - cron: '0 0 1 * *'
```

Cron syntax: `minute hour day month weekday`

**Examples:**
- `0 2 * * *` - Daily at 2 AM
- `0 */4 * * *` - Every 4 hours
- `0 9 * * 1-5` - Weekdays at 9 AM
- `0 0 1,15 * *` - 1st and 15th of month

### Adjust Data Generation

**Default Configuration:**
```python
# scripts/generate_sample_data.py
n_transactions = 1000
days_back = 30
```

**Custom via Workflow Input:**
```yaml
workflow_dispatch:
  inputs:
    data_size:
      description: 'Number of transactions'
      default: '1000'
```

**Modify Category Distribution:**

Edit `scripts/generate_sample_data.py`:

```python
self.templates = {
    'Groceries': {
        'frequency': 0.35  # Increase to 35%
    },
    'Healthcare': {
        'frequency': 0.05  # Decrease to 5%
    }
}
```

### Add New Categories

1. **Update Keyword Rules:**

```yaml
# models/keyword_rules.yaml
Pet Care:
  keywords: [petco, petsmart, vet, veterinary, dog food]
  weight: 1.0
  aliases: [veterinary, animal care]
```

2. **Add to Data Generator:**

```python
# scripts/generate_sample_data.py
'Pet Care': {
    'merchants': ['petco', 'petsmart', 'vet clinic'],
    'items': ['dog food', 'cat litter', 'vet visit'],
    'amount_range': (20, 200),
    'frequency': 0.08
}
```

3. **Commit and Push:**

```bash
git add models/keyword_rules.yaml scripts/generate_sample_data.py
git commit -m "feat: add Pet Care category"
git push origin main
```

Pipeline will automatically retrain with new category!

### Customize Report Template

Edit `reports/assessment_report.Rmd`:

```r
---
title: "Your Custom Title"
subtitle: "Your Subtitle"
output: 
  html_document:
    theme: flatly  # Change theme: cerulean, journal, flatly, darkly
    toc_depth: 4   # Increase depth
---
```

Add custom sections:

```r
## Custom Analysis Section

{r custom-analysis}
# Your custom R code
results %>%
  filter(amount > 100) %>%
  ggplot(aes(x = category, y = amount)) +
  geom_boxplot()
```

---

## Monitoring & Troubleshooting

### Monitor Pipeline Status

**GitHub Actions Badge:**

Add to README.md:
```markdown
[![NER Pipeline](https://github.com/yourusername/Local_NER/actions/workflows/ner_pipeline.yml/badge.svg)](https://github.com/yourusername/Local_NER/actions/workflows/ner_pipeline.yml)
```

**View Logs:**

1. Go to **Actions** tab
2. Click on workflow run
3. Click on job (e.g., "train-model")
4. Expand steps to see detailed logs

**Download Artifacts:**

1. Scroll to bottom of workflow run
2. Click on artifact name (e.g., "model-artifacts-20260123_140530")
3. ZIP file will download

### Common Issues

#### ❌ Issue: Pipeline fails at "Generate Report"

**Error:**
```
Error: R package 'tidyverse' not found
```

**Solution:**

The R setup step may have timed out. Increase timeout:

```yaml
- name: Install R dependencies
  timeout-minutes: 30  # Increase from default 10
  uses: r-lib/actions/setup-r-dependencies@v2
```

#### ❌ Issue: GitHub Pages not deploying

**Error:**
```
Error: HttpError: Resource not accessible by integration
```

**Solution:**

1. Check workflow permissions (see Step 4 in Quick Setup)
2. Enable GitHub Pages (see Step 3 in Quick Setup)
3. Ensure "Build and deployment" source is "GitHub Actions"

#### ❌ Issue: Tests failing

**Error:**
```
ModuleNotFoundError: No module named 'src.python.ner_classifier'
```

**Solution:**

Add to workflow:

```yaml
- name: Add src to PYTHONPATH
  run: |
    echo "PYTHONPATH=$PYTHONPATH:$(pwd)" >> $GITHUB_ENV
```

#### ❌ Issue: Out of disk space

**Error:**
```
Error: No space left on device
```

**Solution:**

Clean up old artifacts:

```yaml
- name: Clean up old artifacts
  uses: c-hive/gha-remove-artifacts@v1
  with:
    age: '7 days'
```

### Debug Mode

Enable debug logging:

1. Go to **Settings → Secrets → Actions**
2. Add secret:
   - Name: `ACTIONS_STEP_DEBUG`
   - Value: `true`

This provides verbose output for all steps.

---

## Local Testing

### Test Complete Pipeline Locally

```bash
# Run setup script
./setup_cicd.sh

# Run test script
./test_pipeline.sh
```

**Manual Steps:**

```bash
# 1. Generate data
python scripts/generate_sample_data.py --size 100

# 2. Train model
python src/python/train_model.py data/sample_transactions.csv

# 3. Generate report
Rscript -e "
rmarkdown::render(
  'reports/assessment_report.Rmd',
  params = list(
    results_path = 'data/processed/classified_transactions.csv',
    metrics_path = 'data/processed/metrics.json'
  )
)
"

# 4. View report
open reports/assessment_report.html  # Mac
xdg-open reports/assessment_report.html  # Linux
```

### Simulate GitHub Actions Locally

Using [act](https://github.com/nektos/act):

```bash
# Install act
brew install act  # Mac
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run workflow
act -W .github/workflows/ner_pipeline.yml

# Run specific job
act -j train-model

# With secrets
act --secret-file .secrets
```

`.secrets` file:
```
MLFLOW_TRACKING_URI=file:./mlruns
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
```

---

## Docker Deployment

### Quick Start with Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f ner-pipeline

# Stop services
docker-compose down

# Clean up volumes
docker-compose down -v
```

### Services Included

| Service | Port | Description |
|---------|------|-------------|
| **postgres** | 5432 | MLflow backend database |
| **mlflow** | 5000 | MLflow tracking server |
| **ner-pipeline** | - | Classification pipeline |
| **api** | 8000 | REST API endpoint |
| **scheduler** | - | Cron-based automation |
| **reports** | 8080 | Nginx report server |

### Access Points

**MLflow UI:**
```
http://localhost:5000
```

**API Documentation:**
```
http://localhost:8000/docs
```

**Reports Dashboard:**
```
http://localhost:8080/reports/
```

### Environment Variables

Create `.env` file:

```bash
# Database
POSTGRES_PASSWORD=secure_password_here

# MLflow
MLFLOW_TRACKING_URI=postgresql://mlflow:secure_password_here@postgres:5432/mlflow

# Pipeline
SCHEDULE_CRON=0 2 * * *
DATA_SIZE=1000

# Optional: Monitoring
GRAFANA_PASSWORD=admin
```

### Production Deployment

**Docker Compose with Traefik (reverse proxy):**

```yaml
# docker-compose.prod.yml
services:
  traefik:
    image: traefik:v2.10
    command:
      - --api.insecure=true
      - --providers.docker=true
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

  api:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.yourdomain.com`)"
      - "traefik.http.routers.api.entrypoints=websecure"
      - "traefik.http.routers.api.tls.certresolver=letsencrypt"
```

Deploy:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Advanced Features

### Conditional Execution

Run training only if coverage drops:

```yaml
- name: Check coverage
  id: check
  run: |
    COVERAGE=$(python scripts/check_coverage.py)
    echo "coverage=$COVERAGE" >> $GITHUB_OUTPUT

- name: Train model
  if: steps.check.outputs.coverage < 0.85
  run: |
    python src/python/train_model.py data/transactions.csv
```

### Matrix Builds

Test multiple configurations:

```yaml
strategy:
  matrix:
    python-version: [3.9, 3.10, 3.11]
    data-size: [1000, 5000, 10000]

steps:
  - uses: actions/setup-python@v5
    with:
      python-version: ${{ matrix.python-version }}
  
  - name: Generate data
    run: |
      python scripts/generate_sample_data.py \
        --size ${{ matrix.data-size }}
```

### Slack Rich Notifications

```yaml
- name: Send detailed Slack notification
  run: |
    METRICS=$(cat data/processed/metrics.json)
    COVERAGE=$(echo $METRICS | jq -r '.coverage')
    
    curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
      -H 'Content-Type: application/json' \
      -d "{
        \"blocks\": [
          {
            \"type\": \"header\",
            \"text\": {
              \"type\": \"plain_text\",
              \"text\": \"📊 NER Pipeline Complete\"
            }
          },
          {
            \"type\": \"section\",
            \"fields\": [
              {\"type\": \"mrkdwn\", \"text\": \"*Coverage:*\n${COVERAGE}%\"},
              {\"type\": \"mrkdwn\", \"text\": \"*Status:*\n✅ Success\"}
            ]
          },
          {
            \"type\": \"actions\",
            \"elements\": [
              {
                \"type\": \"button\",
                \"text\": {\"type\": \"plain_text\", \"text\": \"View Report\"},
                \"url\": \"https://yourusername.github.io/Local_NER/\"
              }
            ]
          }
        ]
      }"
```

---

## Best Practices

### 1. Version Control

- ✅ Commit generated reports to a separate branch
- ✅ Use `.gitignore` for large data files
- ✅ Tag releases for model versions

### 2. Security

- ✅ Never commit secrets to repository
- ✅ Use GitHub Secrets for sensitive data
- ✅ Rotate credentials regularly
- ✅ Use least-privilege access

### 3. Performance

- ✅ Cache dependencies between runs
- ✅ Use artifacts for intermediate results
- ✅ Parallelize independent jobs
- ✅ Set appropriate timeouts

### 4. Monitoring

- ✅ Set up status badges
- ✅ Configure failure notifications
- ✅ Track pipeline metrics over time
- ✅ Regular log review

---

## Resources

### Documentation

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [MLflow Documentation](https://mlflow.org/docs/latest/)
- [R Markdown Guide](https://rmarkdown.rstudio.com/)

### Support

- **Issues**: https://github.com/yourusername/Local_NER/issues
- **Discussions**: https://github.com/yourusername/Local_NER/discussions
- **Email**: your.email@example.com

---

## Conclusion

You now have a fully automated CI/CD pipeline that:

✅ Runs on schedule (daily)
✅ Generates synthetic data
✅ Trains models automatically
✅ Produces beautiful reports
✅ Deploys to GitHub Pages
✅ Sends notifications

**Your automated ML pipeline is ready!** 🚀

View your live reports at:
```
https://yourusername.github.io/Local_NER/
```

---

*Last updated: February 2026*
*Questions? Open an issue!*