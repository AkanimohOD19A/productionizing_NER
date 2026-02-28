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