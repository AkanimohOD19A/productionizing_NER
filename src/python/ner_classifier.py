import pandas as pd
import numpy as np
import yaml
import re
from typing import Dict, List, Tuple
import mlflow
import mlflow.sklearn
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import DBSCAN
from sklearn.ensemble import RandomForestClassifier
import pickle

class AdaptiveNERClassifier:
    def __init__(self, rules_path: str = "models/keyword_rules.yaml"):
        with open(rules_path, 'r') as f:
            self.rules = yaml.safe_load(f)

        self.categories = self.rules['categories']
        self.unknown_threshold = self.rules['unknown_threshold']
        self.vectorizer = TfidfVectorizer(max_features=500, ngram_range=(1, 3))
        self.ml_classifier = None
        self.discovered_categories = {}

    def keyword_match(self, text: str) -> Tuple[str, float]:
        """Rule-based keyword matching"""
        text_lower = text.lower()
        matches = {}

        for category, info in self.categories.items():
            score = sum(1 for kw in info['keywords'] if kw in text_lower)
            if score > 0:
                matches[category] = score * info.get('weight', 1.0)

        if matches:
            best_category = max(matches, key=matches.get)
            confidence = matches[best_category] / len(text.split())
            return best_category, confidence

        return "Unknown", 0.0

    def classify_batch(self, df: pd.DataFrame) -> pd.DataFrame:
        """Classify a batch of narrations"""
        results = []

        for idx, row in df.iterrows():
            category, confidence = self.keyword_match(row['narration'])
            results.append({
                'narration': row['narration'],
                'amount': row['amount'],
                'category': category,
                'confidence': confidence,
                'method': 'rule-based'
            })

        result_df = pd.DataFrame(results)

        # Use ML for low-confidence items if model exists
        if self.ml_classifier is not None:
            low_conf_mask = result_df['confidence'] < self.unknown_threshold
            if low_conf_mask.sum() > 0:
                result_df = self._ml_classify(result_df, low_conf_mask)

        return result_df

    def _ml_classify(self, df: pd.DataFrame, mask: pd.Series) -> pd.DataFrame:
        """Use ML model for classification"""
        low_conf_df = df[mask].copy()

        X = self.vectorizer.transform(low_conf_df['narration'])
        predictions = self.ml_classifier.predict(X)
        probabilities = self.ml_classifier.predict_proba(X).max(axis=1)

        df.loc[mask, 'category'] = predictions
        df.loc[mask, 'confidence'] = probabilities
        df.loc[mask, 'method'] = 'ml-based'

        return df

    def discover_new_categories(self, unknown_texts: List[str]) -> Dict:
        """Use clustering to discover potential new categories"""
        if len(unknown_texts) < 5:
            return {}

        X = self.vectorizer.fit_transform(unknown_texts)

        # DBSCAN clustering
        clustering = DBSCAN(eps=0.3, min_samples=2, metric='cosine')
        labels = clustering.fit_predict(X.toarray())

        new_categories = {}
        for label in set(labels):
            if label == -1:  # Noise
                continue

            cluster_texts = [unknown_texts[i] for i, l in enumerate(labels) if l == label]
            new_categories[f"NewCategory_{label}"] = cluster_texts

        return new_categories

    def train_ml_model(self, df: pd.DataFrame):
        """Train ML classifier on labeled data"""
        # Filter out Unknown categories
        train_df = df[df['category'] != 'Unknown'].copy()

        if len(train_df) < 10:
            print("Not enough labeled data for training")
            return

        X = self.vectorizer.fit_transform(train_df['narration'])
        y = train_df['category']

        # Weight by amount
        sample_weights = train_df['amount'].abs() / train_df['amount'].abs().sum()

        self.ml_classifier = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
        self.ml_classifier.fit(X, y, sample_weight=sample_weights)

        print(f"Model trained on {len(train_df)} samples")

    def save_model(self, path: str):
        """Save model artifacts"""
        with open(path, 'wb') as f:
            pickle.dump({
                'vectorizer': self.vectorizer,
                'classifier': self.ml_classifier,
                'rules': self.rules
            }, f)