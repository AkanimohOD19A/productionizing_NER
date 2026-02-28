#!/bin/bash
# setup_cicd.sh
# Automated setup script for CI/CD pipeline

set -e  # Exit on error

echo "🚀 Setting up NER Classification CI/CD Pipeline"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "ℹ $1"
}

# Check if running in Git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not a Git repository. Please run 'git init' first."
    exit 1
fi

print_success "Git repository detected"

# Create necessary directories
echo ""
echo "📁 Creating directory structure..."

directories=(
    ".github/workflows"
    "data/raw"
    "data/processed"
    "models"
    "reports"
    "scripts"
    "tests"
    "docs/reports"
    "src/python"
    "src/R"
    "src/pipelines"
    "src/api"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
    print_success "Created $dir"
done

# Create .gitignore if it doesn't exist
echo ""
echo "📝 Configuring Git..."

if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
venv/
ENV/
env/

# R
.Rproj.user
.Rhistory
.RData
.Ruserdata
*.Rproj

# MLflow
mlruns/
mlartifacts/

# Data
data/raw/*.csv
data/processed/*.csv
*.pkl
*.h5
*.joblib

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Environment
.env
.env.local

# Reports (keep templates, ignore generated)
reports/*.html
!reports/assessment_report.Rmd

# Temporary files
tmp/
temp/
*.tmp
EOF
    print_success "Created .gitignore"
else
    print_warning ".gitignore already exists, skipping"
fi

# Create GitHub Actions secrets configuration guide
echo ""
echo "🔐 GitHub Secrets Configuration"
echo "================================"

cat > GITHUB_SECRETS.md << 'EOF'
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

EOF

print_success "Created GITHUB_SECRETS.md - Review this file for setup instructions"

# Create environment template
echo ""
echo "🔧 Creating environment template..."

cat > .env.template << 'EOF'
# Environment Variables Template
# Copy this to .env and fill in your values

# MLflow Configuration
MLFLOW_TRACKING_URI=file:./mlruns
MLFLOW_EXPERIMENT_NAME=NER-Classification

# Data Configuration
DATA_PATH=data/sample_transactions.csv
MODEL_PATH=models/ner_classifier.pkl

# Pipeline Configuration
BATCH_SIZE=1000
UNKNOWN_THRESHOLD=0.3
REVIEW_THRESHOLD=0.5

# Notification Configuration (Optional)
SLACK_WEBHOOK_URL=
EMAIL_NOTIFICATIONS=false

# R Configuration
R_LIBS_USER=~/R/library
EOF

print_success "Created .env.template"

# Check for required tools
echo ""
echo "🔍 Checking required tools..."

check_tool() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

all_tools_installed=true

if ! check_tool "python3"; then all_tools_installed=false; fi
if ! check_tool "pip"; then all_tools_installed=false; fi
if ! check_tool "git"; then all_tools_installed=false; fi

# Optional tools
check_tool "docker" || print_warning "Docker not installed (optional for containerization)"
check_tool "R" || print_warning "R not installed (required for report generation)"

if [ "$all_tools_installed" = false ]; then
    print_error "Some required tools are missing. Please install them before continuing."
    exit 1
fi

# Install Python dependencies
echo ""
echo "📦 Installing Python dependencies..."

if [ -f "requirements.txt" ]; then
    if [ -d "venv" ]; then
        print_warning "Virtual environment already exists"
    else
        python3 -m venv venv
        print_success "Created virtual environment"
    fi

    source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null
    pip install --upgrade pip > /dev/null 2>&1
    pip install -r requirements.txt > /dev/null 2>&1
    print_success "Installed Python dependencies"
else
    print_warning "requirements.txt not found, skipping Python dependency installation"
fi

# Initialize Git LFS for large files (optional)
echo ""
echo "📦 Configuring Git LFS (optional)..."

if command -v git-lfs &> /dev/null; then
    git lfs install
    git lfs track "*.pkl"
    git lfs track "*.h5"
    git lfs track "*.joblib"
    print_success "Configured Git LFS"
else
    print_warning "Git LFS not installed. Large model files may cause issues."
    print_info "Install with: brew install git-lfs (Mac) or apt-get install git-lfs (Linux)"
fi

# Create sample configuration files
echo ""
echo "⚙️  Creating sample configuration..."

# Only create if doesn't exist
if [ ! -f "models/keyword_rules.yaml" ]; then
    cat > models/keyword_rules.yaml << 'EOF'
categories:
  Baby Items:
    keywords: [pampers, diapers, baby powder, baby lotion, wipes, formula]
    weight: 1.0
    aliases: [infant products, nursery]

  Groceries:
    keywords: [supermarket, grocery, bread, milk, eggs, walmart, costco]
    weight: 1.0
    aliases: [food shopping]

  Healthcare:
    keywords: [doctor, pharmacy, cvs, walgreens, medicine, prescription]
    weight: 1.5
    aliases: [medical]

  Transportation:
    keywords: [uber, lyft, taxi, fuel, gas, parking]
    weight: 1.0
    aliases: [travel]

matching:
  min_confidence: 0.3
  partial_match_penalty: 0.5
  multi_word_bonus: 1.2

unknown_threshold: 0.3
review_threshold: 0.5
EOF
    print_success "Created keyword_rules.yaml"
else
    print_warning "keyword_rules.yaml already exists, skipping"
fi

# Generate initial test data
echo ""
echo "🎲 Generating sample data..."

if [ -f "scripts/generate_sample_data.py" ]; then
    python scripts/generate_sample_data.py --size 100 --output data/sample_transactions.csv
    print_success "Generated sample transaction data"
else
    print_warning "Data generator script not found, skipping sample data generation"
fi

# Create README for CI/CD
echo ""
echo "📚 Creating CI/CD documentation..."

cat > CI_CD_README.md << 'EOF'
# CI/CD Pipeline Documentation

## Overview

This repository includes a fully automated CI/CD pipeline that:

1. **Generates** synthetic transaction data on a schedule
2. **Trains** NER classification model
3. **Evaluates** model performance
4. **Generates** R Markdown reports
5. **Deploys** reports to GitHub Pages
6. **Notifies** team via Slack (optional)

## Workflow Triggers

### Automatic Triggers
- **Daily Schedule**: Runs at 2 AM UTC every day
- **Push to Main**: Runs on every push to main branch
- **Pull Request**: Runs tests on all PRs

### Manual Trigger
```bash
# Via GitHub UI: Actions → NER Classification Pipeline → Run workflow
# Or via GitHub CLI:
gh workflow run ner_pipeline.yml
```

## Pipeline Stages

### 1. Generate Data
- Creates synthetic transaction data
- Configurable size (default: 1000 transactions)
- Realistic distribution across categories

### 2. Test
- Runs unit tests
- Generates coverage report
- Uploads to Codecov

### 3. Train Model
- Trains NER classifier
- Logs metrics to MLflow
- Saves model artifacts

### 4. Generate Report
- Creates R Markdown report
- Interactive visualizations
- Comprehensive metrics

### 5. Deploy
- Publishes report to GitHub Pages
- Updates report index
- Creates GitHub release (scheduled runs)

## Viewing Results

### Reports
- **URL**: `https://AkanimohOD19A.github.io/Named-Entity-Recognition/`
- **Format**: Interactive HTML dashboards
- **Retention**: Last 50 reports kept

### Artifacts
- Model files: 90 days
- Test results: 30 days
- Transaction data: 30 days

### MLflow Tracking
- Access MLflow UI locally: `mlflow ui`
- Or configure remote tracking server

## Customization

### Change Schedule
Edit `.github/workflows/ner_pipeline.yml`:
```yaml
schedule:
  - cron: '0 2 * * *'  # Change to your preferred schedule
```

### Adjust Data Size
Manual run with custom size:
```yaml
workflow_dispatch:
  inputs:
    data_size: '5000'  # Generate 5000 transactions
```

### Modify Categories
Edit `models/keyword_rules.yaml` and push to trigger retrain.

## Monitoring

### Pipeline Status
- Check: **Actions** tab in GitHub
- Badge: Add to README (see badge code below)

### Notifications
- Configure Slack webhook in secrets
- Email notifications via GitHub settings

## Troubleshooting

### Pipeline Fails
1. Check Actions logs
2. Verify secrets are configured
3. Ensure GitHub Pages is enabled

### Reports Not Deploying
1. Check Pages settings (Settings → Pages)
2. Verify workflow permissions (Settings → Actions)
3. Review deployment logs

### Tests Failing
1. Run tests locally: `pytest tests/`
2. Check for dependency issues
3. Verify data format

## Local Development

Run pipeline locally:
```bash
# Generate data
python scripts/generate_sample_data.py

# Train model
python src/python/train_model.py data/sample_transactions.csv

# Generate report
Rscript -e "source('src/R/generate_report.R'); generate_assessment_report()"
```

## Badge Code

Add to README.md:
```markdown
[![NER Pipeline](https://github.com/AkanimohOD19A/Named-Entity-Recognition/actions/workflows/ner_pipeline.yml/badge.svg)](https://github.com/AkanimohOD19A/Named-Entity-Recognition/actions/workflows/ner_pipeline.yml)
```
EOF

print_success "Created CI_CD_README.md"

# Create a quick test script
echo ""
echo "🧪 Creating test script..."

cat > test_pipeline.sh << 'EOF'
#!/bin/bash
# Quick test script to verify setup

echo "Running pipeline tests..."

# Generate small dataset
python scripts/generate_sample_data.py --size 50 --output data/test_transactions.csv

# Run classifier
python src/python/train_model.py data/test_transactions.csv

# Check outputs
if [ -f "data/processed/classified_transactions.csv" ]; then
    echo "✓ Classification successful"
else
    echo "✗ Classification failed"
    exit 1
fi

if [ -f "data/processed/metrics.json" ]; then
    echo "✓ Metrics generated"
    cat data/processed/metrics.json
else
    echo "✗ Metrics generation failed"
    exit 1
fi

echo "✓ All tests passed!"
EOF

chmod +x test_pipeline.sh
print_success "Created test_pipeline.sh"

# Summary
echo ""
echo "================================================"
echo "✅ CI/CD Setup Complete!"
echo "================================================"
echo ""
print_info "Next steps:"
echo ""
echo "1. Review and configure GitHub Secrets:"
echo "   📖 See GITHUB_SECRETS.md for instructions"
echo ""
echo "2. Enable GitHub Pages:"
echo "   🌐 Settings → Pages → Source: GitHub Actions"
echo ""
echo "3. Test the pipeline locally:"
echo "   🧪 ./test_pipeline.sh"
echo ""
echo "4. Push to GitHub:"
echo "   git add ."
echo "   git commit -m 'feat: add CI/CD pipeline'"
echo "   git push origin main"
echo ""
echo "5. Monitor first run:"
echo "   👀 Check Actions tab in GitHub"
echo ""
print_success "Your automated NER pipeline is ready! 🚀"
echo ""
echo "📊 Reports will be available at:"
echo "   https://AkanimohOD19A.github.io/Named-Entity-Recognition/"
echo ""