# src/python/train_model.py
import mlflow
import mlflow.sklearn
import pandas as pd
from ner_classifier import AdaptiveNERClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
import json


def train_and_log_model(data_path: str, experiment_name: str = "NER-Classification"):
    # Set MLflow experiment
    mlflow.set_experiment(experiment_name)

    # Load data
    df = pd.read_csv(data_path)

    with mlflow.start_run():
        # Initialize classifier
        classifier = AdaptiveNERClassifier()

        # Initial rule-based classification
        classified_df = classifier.classify_batch(df)

        # Log parameters
        mlflow.log_param("total_records", len(df))
        mlflow.log_param("unknown_threshold", classifier.unknown_threshold)

        # Calculate metrics on rule-based classification
        rule_based_coverage = (classified_df['category'] != 'Unknown').sum() / len(classified_df)
        mlflow.log_metric("rule_based_coverage", rule_based_coverage)

        # Discover new categories from Unknown
        unknown_texts = classified_df[classified_df['category'] == 'Unknown']['narration'].tolist()
        new_categories = classifier.discover_new_categories(unknown_texts)

        mlflow.log_metric("discovered_clusters", len(new_categories))

        # Train ML model on known categories
        classifier.train_ml_model(classified_df)

        # Re-classify with ML model
        if classifier.ml_classifier is not None:
            final_classified = classifier.classify_batch(df)

            # Calculate final coverage
            final_coverage = (final_classified['category'] != 'Unknown').sum() / len(final_classified)
            mlflow.log_metric("final_coverage", final_coverage)

            # Log category distribution
            category_dist = final_classified['category'].value_counts().to_dict()
            mlflow.log_dict(category_dist, "category_distribution.json")

        # Save and log model
        model_path = "models/ner_classifier.pkl"
        classifier.save_model(model_path)
        mlflow.log_artifact(model_path)

        # Log discovered categories
        if new_categories:
            mlflow.log_dict(new_categories, "discovered_categories.json")

        # Save classified results
        output_path = "data/processed/classified_transactions.csv"
        final_classified.to_csv(output_path, index=False)
        mlflow.log_artifact(output_path)

        print(f"Model logged to MLflow. Run ID: {mlflow.active_run().info.run_id}")

        return classifier, final_classified


if __name__ == "__main__":
    train_and_log_model("data/sample_transactions.csv")