from zenml import pipeline, step
from zenml.config import DockerSettings
import pandas as pd
from typing import Tuple
import sys

sys.path.append('src/python')
from ner_classifier import AdaptiveNERClassifier
import mlflow


@step
def load_data(data_path: str) -> pd.DataFrame:
    """Load transaction data"""
    df = pd.read_csv(data_path)
    print(f"Loaded {len(df)} transactions")
    return df


@step
def rule_based_classification(df: pd.DataFrame) -> pd.DataFrame:
    """Apply rule-based NER"""
    classifier = AdaptiveNERClassifier()
    classified = classifier.classify_batch(df)
    return classified


@step
def discover_categories(df: pd.DataFrame) -> dict:
    """Discover new categories from Unknown items"""
    classifier = AdaptiveNERClassifier()
    unknown_texts = df[df['category'] == 'Unknown']['narration'].tolist()
    new_cats = classifier.discover_new_categories(unknown_texts)
    return new_cats


@step
def train_classifier(df: pd.DataFrame) -> AdaptiveNERClassifier:
    """Train ML classifier"""
    classifier = AdaptiveNERClassifier()
    classifier.train_ml_model(df)
    return classifier


@step
def final_classification(df: pd.DataFrame, classifier: AdaptiveNERClassifier) -> pd.DataFrame:
    """Final classification with trained model"""
    final = classifier.classify_batch(df)
    return final


@step
def log_to_mlflow(classifier: AdaptiveNERClassifier, results: pd.DataFrame, new_cats: dict):
    """Log everything to MLflow"""
    mlflow.set_experiment("NER-ZenML-Pipeline")

    with mlflow.start_run():
        mlflow.log_metric("total_transactions", len(results))
        coverage = (results['category'] != 'Unknown').sum() / len(results)
        mlflow.log_metric("coverage", coverage)
        mlflow.log_dict(new_cats, "discovered_categories.json")

        # Save model
        classifier.save_model("models/ner_classifier.pkl")
        mlflow.log_artifact("models/ner_classifier.pkl")

        results.to_csv("data/processed/final_results.csv", index=False)
        mlflow.log_artifact("data/processed/final_results.csv")


@pipeline
def ner_classification_pipeline(data_path: str):
    """Complete NER classification pipeline"""
    df = load_data(data_path)
    classified = rule_based_classification(df)
    new_cats = discover_categories(classified)
    classifier = train_classifier(classified)
    final_results = final_classification(df, classifier)
    log_to_mlflow(classifier, final_results, new_cats)



if __name__ == "__main__":
    ner_classification_pipeline(data_path="data/sample_transactions.csv")