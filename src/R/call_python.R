library(reticulate)

run_ner_pipeline <- function(data_path) {
  # Source Python module
  py_run_file("src/python/train_model.py")

  # Call training function
  result <- py$train_and_log_model(data_path)

  return(result)
}

# Load results back to R
load_classified_results <- function(results_path = "data/processed/classified_transactions.csv") {
  read_csv(results_path)
}