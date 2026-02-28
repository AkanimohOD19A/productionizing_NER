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