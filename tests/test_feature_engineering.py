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