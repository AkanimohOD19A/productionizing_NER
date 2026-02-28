library(tidyverse)
library(reticulate)

# Configure Python
use_python("/usr/bin/python3", required = TRUE)

prepare_transaction_data <- function(input_path, output_path) {
  # Load and clean data
  df <- read_csv(input_path) %>%
    mutate(
      narration = str_trim(tolower(narration)),
      amount = as.numeric(amount)
    ) %>%
    filter(!is.na(narration), !is.na(amount))

  # Save for Python processing
  write_csv(df, output_path)

  return(df)
}

