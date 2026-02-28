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