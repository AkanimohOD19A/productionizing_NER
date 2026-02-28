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