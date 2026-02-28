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