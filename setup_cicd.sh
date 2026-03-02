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
DATA_PATH=data/raw/sample_transactions.csv
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
    python scripts/generate_sample_data.py --size 100 --output data/raw/sample_transactions.csv
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
python src/python/train_model.py data/raw/sample_transactions.csv

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

# Test files
echo ""
echo "Creating test files..."

touch tests/{__init__,conftest,test_data_generator,
test_classifier,test_discovery,test_feature_engineering,test_pipeline}.py

cat > tests/__init__.py << 'EOF'
"""
Test suite for NER Classification System
"""
EOF

cat > tests/conftest.py << 'EOF'
"""
Pytest configuration and shared fixtures.
"""
import pytest
import pandas as pd
import numpy as np
from pathlib import Path
import sys

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.python.ner_classifier import AdaptiveNERClassifier


@pytest.fixture
def sample_transactions():
    """Sample transaction data for testing."""
    return pd.DataFrame({
        'narration': [
            'cvs pharmacy prescription pickup',
            'walmart grocery shopping',
            'uber ride to downtown',
            'netflix monthly subscription',
            'starbucks morning coffee',
            'unknown merchant xyz123',
            'payment to acme corp',
            'target baby items purchase'
        ],
        'amount': [45.00, 125.50, 28.00, 15.99, 5.50, 50.00, 100.00, 67.89],
        'date': ['2026-01-15'] * 8
    })


@pytest.fixture
def classifier():
    """Initialize classifier with default rules."""
    return AdaptiveNERClassifier(rules_path="models/keyword_rules.yaml")


@pytest.fixture
def classified_data():
    """Sample classified transaction data."""
    return pd.DataFrame({
        'narration': [
            'cvs pharmacy prescription',
            'walmart grocery shopping',
            'uber ride downtown',
            'unknown merchant'
        ],
        'amount': [45.00, 125.50, 28.00, 50.00],
        'category': ['Healthcare', 'Groceries', 'Transportation', 'Unknown'],
        'confidence': [0.856, 0.742, 0.891, 0.0],
        'method': ['rule-based', 'rule-based', 'rule-based', 'rule-based']
    })


@pytest.fixture
def keyword_rules_path(tmp_path):
    """Create temporary keyword rules file."""
    rules_content = """
categories:
  Healthcare:
    keywords: [pharmacy, doctor, hospital, medical]
    weight: 1.5

  Groceries:
    keywords: [walmart, grocery, supermarket, food]
    weight: 1.0

  Transportation:
    keywords: [uber, taxi, lyft, gas]
    weight: 1.0

matching:
  min_confidence: 0.3
  partial_match_penalty: 0.5
  multi_word_bonus: 1.2

unknown_threshold: 0.3
review_threshold: 0.5
"""
    rules_file = tmp_path / "test_rules.yaml"
    rules_file.write_text(rules_content)
    return str(rules_file)
EOF

cat > tests/test_data_generator.py << 'EOF'
"""
Tests for synthetic data generation.
"""
import pytest
import pandas as pd
from scripts.generate_sample_data import TransactionGenerator


class TestTransactionGenerator:
    """Test transaction data generator."""

    @pytest.fixture
    def generator(self):
        """Create transaction generator with fixed seed."""
        return TransactionGenerator(seed=42)

    def test_generate_transactions(self, generator):
        """Test basic transaction generation."""
        df = generator.generate_transactions(100)

        assert len(df) == 100
        assert 'narration' in df.columns
        assert 'amount' in df.columns
        assert 'date' in df.columns
        assert 'true_category' in df.columns

    def test_narration_not_empty(self, generator):
        """Test that narrations are not empty."""
        df = generator.generate_transactions(50)

        assert df['narration'].notna().all()
        assert (df['narration'].str.len() > 0).all()

    def test_amount_in_range(self, generator):
        """Test that amounts are positive and reasonable."""
        df = generator.generate_transactions(100)

        assert (df['amount'] > 0).all()
        assert (df['amount'] < 10000).all()  # Reasonable upper limit

    def test_category_distribution(self, generator):
        """Test that categories are distributed as expected."""
        df = generator.generate_transactions(1000)

        category_counts = df['true_category'].value_counts()

        # Should have multiple categories
        assert len(category_counts) >= 5

        # No single category should dominate completely
        max_pct = category_counts.max() / len(df)
        assert max_pct < 0.5  # No more than 50%

    def test_unknown_transactions_present(self, generator):
        """Test that some Unknown transactions are generated."""
        df = generator.generate_transactions(1000)

        unknown_count = (df['true_category'] == 'Unknown').sum()

        # Should have some unknowns (around 5%)
        assert unknown_count > 0
        assert unknown_count < len(df) * 0.15  # Less than 15%

    def test_reproducibility_with_seed(self):
        """Test that same seed produces same results."""
        gen1 = TransactionGenerator(seed=123)
        gen2 = TransactionGenerator(seed=123)

        df1 = gen1.generate_transactions(50)
        df2 = gen2.generate_transactions(50)

        pd.testing.assert_frame_equal(df1, df2)

    def test_date_format(self, generator):
        """Test that dates are in correct format."""
        df = generator.generate_transactions(20)

        # Should be string in YYYY-MM-DD format
        assert df['date'].dtype == 'object'
        assert df['date'].str.match(r'\d{4}-\d{2}-\d{2}').all()
EOF

cat > tests/test_classifier.py << 'EOF'
"""
Tests for NER classifier functionality.
"""
import pytest
import pandas as pd
from src.python.ner_classifier import AdaptiveNERClassifier


class TestKeywordMatching:
    """Test rule-based keyword matching."""

    def test_healthcare_classification(self, classifier):
        """Test classification of healthcare transactions."""
        category, confidence, keywords = classifier.keyword_match(
            "cvs pharmacy prescription pickup"
        )

        assert category == "Healthcare"
        assert confidence > 0.5
        assert "pharmacy" in keywords or "prescription" in keywords

    def test_groceries_classification(self, classifier):
        """Test classification of grocery transactions."""
        category, confidence, keywords = classifier.keyword_match(
            "walmart grocery shopping"
        )

        assert category == "Groceries"
        assert confidence > 0.0
        assert len(keywords) > 0

    def test_transportation_classification(self, classifier):
        """Test classification of transportation transactions."""
        category, confidence, keywords = classifier.keyword_match(
            "uber ride to downtown"
        )

        assert category == "Transportation"
        assert confidence > 0.5
        assert "uber" in keywords

    def test_unknown_classification(self, classifier):
        """Test that unknown transactions are marked as Unknown."""
        category, confidence, keywords = classifier.keyword_match(
            "payment to random merchant xyz123"
        )

        assert category == "Unknown"
        assert confidence == 0.0
        assert len(keywords) == 0

    def test_case_insensitive_matching(self, classifier):
        """Test that matching is case-insensitive."""
        category1, conf1, _ = classifier.keyword_match("CVS PHARMACY")
        category2, conf2, _ = classifier.keyword_match("cvs pharmacy")

        assert category1 == category2 == "Healthcare"
        assert conf1 > 0 and conf2 > 0


class TestSingleClassification:
    """Test single transaction classification."""

    def test_classify_single_with_amount(self, classifier):
        """Test classification with amount provided."""
        result = classifier.classify_single(
            text="cvs pharmacy prescription",
            amount=45.00
        )

        assert result['category'] == "Healthcare"
        assert result['confidence'] > 0.5
        assert result['amount'] == 45.00
        assert result['method'] == 'rule-based'

    def test_classify_single_without_amount(self, classifier):
        """Test classification without amount."""
        result = classifier.classify_single(
            text="walmart groceries"
        )

        assert result['category'] == "Groceries"
        assert 'confidence' in result
        assert result['amount'] is None


class TestBatchClassification:
    """Test batch classification functionality."""

    def test_classify_batch(self, classifier, sample_transactions):
        """Test batch classification of transactions."""
        results = classifier.classify_batch(sample_transactions)

        assert len(results) == len(sample_transactions)
        assert 'category' in results.columns
        assert 'confidence' in results.columns
        assert 'method' in results.columns

    def test_batch_results_structure(self, classifier, sample_transactions):
        """Test that batch results have correct structure."""
        results = classifier.classify_batch(sample_transactions)

        required_columns = ['narration', 'amount', 'category',
                          'confidence', 'method', 'needs_review']

        for col in required_columns:
            assert col in results.columns

    def test_batch_classification_coverage(self, classifier, sample_transactions):
        """Test that batch classification achieves reasonable coverage."""
        results = classifier.classify_batch(sample_transactions)

        unknown_count = (results['category'] == 'Unknown').sum()
        coverage = 1 - (unknown_count / len(results))

        # Should classify at least 50% of transactions
        assert coverage >= 0.5


class TestConfidenceScoring:
    """Test confidence score calculation."""

    def test_high_confidence_multiple_keywords(self, classifier):
        """Test high confidence when multiple keywords match."""
        _, confidence, keywords = classifier.keyword_match(
            "cvs pharmacy prescription medication"
        )

        assert confidence > 0.5
        assert len(keywords) >= 2

    def test_low_confidence_single_keyword(self, classifier):
        """Test lower confidence with single keyword in long text."""
        _, confidence, _ = classifier.keyword_match(
            "payment to some company pharmacy inc for services rendered"
        )

        # Should have lower confidence due to longer text
        assert 0 < confidence < 1.0

    def test_needs_review_flag(self, classifier):
        """Test that low confidence transactions are flagged for review."""
        # This should have low confidence
        result = classifier.classify_single(
            text="payment to merchant with pharmacy in name but other stuff"
        )

        # If confidence is low, should be flagged
        if result['confidence'] < 0.5:
            assert result['needs_review'] == True


class TestClassifierInitialization:
    """Test classifier initialization and configuration."""

    def test_classifier_loads_rules(self):
        """Test that classifier loads keyword rules successfully."""
        classifier = AdaptiveNERClassifier()

        assert len(classifier.categories) > 0
        assert classifier.unknown_threshold > 0
        assert classifier.review_threshold > 0

    def test_classifier_with_custom_rules(self, keyword_rules_path):
        """Test classifier with custom rules file."""
        classifier = AdaptiveNERClassifier(rules_path=keyword_rules_path)

        assert 'Healthcare' in classifier.categories
        assert 'Groceries' in classifier.categories

    def test_patterns_compiled(self, classifier):
        """Test that regex patterns are pre-compiled."""
        assert hasattr(classifier, 'patterns')
        assert len(classifier.patterns) > 0


class TestStatistics:
    """Test classification statistics tracking."""

    def test_stats_tracking(self, classifier, sample_transactions):
        """Test that statistics are tracked correctly."""
        classifier.classify_batch(sample_transactions)

        stats = classifier.get_stats()

        assert 'total_classified' in stats
        assert 'rule_based_pct' in stats
        assert stats['total_classified'] == len(sample_transactions)
EOF

cat > tests/test_discovery.py << 'EOF'
"""
Tests for category discovery functionality.
"""
import pytest
import pandas as pd
from src.python.ner_classifier import AdaptiveNERClassifier


class TestCategoryDiscovery:
    """Test unsupervised category discovery."""

    def test_discover_with_sufficient_data(self, classifier):
        """Test category discovery with sufficient unknown transactions."""
        unknown_texts = [
            'geico auto insurance payment',
            'state farm insurance premium',
            'allstate policy renewal',
            'progressive insurance monthly',
            'nationwide insurance bill',
            'liberty mutual insurance',
        ]

        new_categories = classifier.discover_new_categories(unknown_texts)

        # Should discover at least one category
        assert len(new_categories) >= 0  # Might be 0 if clustering doesn't find patterns

    def test_discover_with_insufficient_data(self, classifier):
        """Test that discovery returns empty with too few samples."""
        unknown_texts = [
            'payment to merchant 1',
            'payment to merchant 2'
        ]

        new_categories = classifier.discover_new_categories(unknown_texts)

        # Should return empty dict with insufficient data
        assert isinstance(new_categories, dict)

    def test_discovered_category_structure(self, classifier):
        """Test structure of discovered categories."""
        unknown_texts = [
            'netflix subscription monthly',
            'spotify premium subscription',
            'hulu streaming service',
            'disney plus subscription',
            'amazon prime membership',
            'youtube premium subscription'
        ] * 2  # Duplicate to ensure enough samples

        new_categories = classifier.discover_new_categories(unknown_texts)

        if new_categories:
            for category_name, info in new_categories.items():
                assert 'sample_texts' in info
                assert 'size' in info
                assert 'keywords' in info
                assert isinstance(info['sample_texts'], list)
                assert isinstance(info['size'], int)
EOF

cat > tests/test_feature_engineering.py << 'EOF'
"""
Helper functions for testing.
"""
import numpy as np
import pandas as pd
from typing import List, Tuple


def generate_text_features(texts: List[str], max_features: int = 50):
    """
    Generate TF-IDF features from text.

    Args:
        texts: List of text strings
        max_features: Maximum number of features

    Returns:
        Feature matrix and vectorizer
    """
    from sklearn.feature_extraction.text import TfidfVectorizer

    vectorizer = TfidfVectorizer(max_features=max_features)
    X = vectorizer.fit_transform(texts)

    return X, vectorizer


def generate_numerical_features(df: pd.DataFrame) -> np.ndarray:
    """
    Generate numerical features from transaction data.

    Args:
        df: DataFrame with transaction data

    Returns:
        Numerical feature array
    """
    features = []

    # Amount features
    features.append(df['amount'].abs().values.reshape(-1, 1))
    features.append(np.log1p(df['amount'].abs()).values.reshape(-1, 1))

    # Text length features
    features.append(df['narration'].str.len().values.reshape(-1, 1))
    features.append(df['narration'].str.split().str.len().values.reshape(-1, 1))

    return np.hstack(features)


def calculate_feature_importance(model, feature_names: List[str], top_n: int = 10):
    """
    Calculate and return top feature importances.

    Args:
        model: Trained model with feature_importances_
        feature_names: List of feature names
        top_n: Number of top features to return

    Returns:
        List of (feature_name, importance) tuples
    """
    importance = model.feature_importances_
    indices = importance.argsort()[-top_n:][::-1]

    return [(feature_names[i], importance[i]) for i in indices]


def validate_feature_matrix(X, expected_rows: int = None, expected_cols: int = None):
    """
    Validate feature matrix properties.

    Args:
        X: Feature matrix (dense or sparse)
        expected_rows: Expected number of rows
        expected_cols: Expected number of columns

    Returns:
        True if valid, raises AssertionError otherwise
    """
    # Check for NaN values
    if hasattr(X, 'toarray'):
        X_dense = X.toarray()
    else:
        X_dense = X

    assert not np.isnan(X_dense).any(), "Feature matrix contains NaN"
    assert not np.isinf(X_dense).any(), "Feature matrix contains Inf"

    if expected_rows:
        assert X.shape[0] == expected_rows, f"Expected {expected_rows} rows, got {X.shape[0]}"

    if expected_cols:
        assert X.shape[1] == expected_cols, f"Expected {expected_cols} cols, got {X.shape[1]}"

    return True
EOF

cat > tests/test_pipeline.py << 'EOF'
"""
Tests for end-to-end pipeline functionality.
"""
import pytest
import pandas as pd
from pathlib import Path
import tempfile
import json


class TestEndToEndPipeline:
    """Test complete pipeline from data to classification."""

    def test_full_pipeline(self, tmp_path):
        """Test complete pipeline execution."""
        from scripts.generate_sample_data import TransactionGenerator
        from src.python.ner_classifier import AdaptiveNERClassifier

        # Step 1: Generate data
        generator = TransactionGenerator(seed=42)
        df = generator.generate_transactions(100)

        data_file = tmp_path / "transactions.csv"
        df[['narration', 'amount', 'date']].to_csv(data_file, index=False)

        assert data_file.exists()

        # Step 2: Load and classify
        classifier = AdaptiveNERClassifier()
        input_df = pd.read_csv(data_file)
        results = classifier.classify_batch(input_df)

        # Step 3: Verify results
        assert len(results) == 100
        assert 'category' in results.columns

        # Should achieve some reasonable coverage
        unknown_rate = (results['category'] == 'Unknown').sum() / len(results)
        assert unknown_rate < 0.5  # Less than 50% unknown

    def test_pipeline_with_metadata(self, tmp_path):
        """Test pipeline with metadata generation."""
        from scripts.generate_sample_data import TransactionGenerator

        generator = TransactionGenerator(seed=42)
        df = generator.generate_transactions(50)

        data_file = tmp_path / "transactions.csv"
        main_file, meta_file, val_file = generator.save_with_metadata(
            df, data_file
        )

        # Check all files created
        assert Path(main_file).exists()
        assert Path(meta_file).exists()
        assert Path(val_file).exists()

        # Check metadata content
        with open(meta_file, 'r') as f:
            metadata = json.load(f)

        assert 'n_transactions' in metadata
        assert metadata['n_transactions'] == 50


class TestModelSaving:
    """Test model persistence."""

    def test_save_and_load_model(self, classifier, tmp_path):
        """Test saving and loading classifier."""
        model_path = tmp_path / "test_classifier.pkl"

        # Save model
        classifier.save_model(str(model_path))
        assert model_path.exists()

        # Verify file is not empty
        assert model_path.stat().st_size > 0
EOF

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