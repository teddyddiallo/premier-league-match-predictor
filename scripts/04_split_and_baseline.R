# 04_split_and_baseline.R
# Chronological train/test split and majority-class baseline.

library(tidyverse)

model_data <- read_csv("data/processed/model_data.csv", show_col_types = FALSE) %>%
  mutate(HomeWin = factor(HomeWin, levels = c("No", "Yes")))

train <- model_data %>% filter(Season <= "2022-23")
test  <- model_data %>% filter(Season >= "2023-24")

cat("Train:", nrow(train), "matches (", min(train$Season), "to", max(train$Season), ")\n")
cat("Test: ", nrow(test),  "matches (", min(test$Season),  "to", max(test$Season),  ")\n")
cat("Test starts after the end of train:", min(test$Date) > max(train$Date), "\n\n")

# Share of home wins in each set
shares <- bind_rows(
  train %>% summarise(set = "train", n = n(), home_win_rate = round(mean(HomeWin == "Yes"), 3)),
  test  %>% summarise(set = "test",  n = n(), home_win_rate = round(mean(HomeWin == "Yes"), 3))
)
print(shares)

# Majority-class baseline ("always No") on the TEST set
baseline_acc <- max(prop.table(table(test$HomeWin)))
cat("\nBaseline accuracy on the test set (always predict 'No'):",
    round(baseline_acc, 3), "\n")

saveRDS(train, "data/processed/train.rds")
saveRDS(test,  "data/processed/test.rds")
cat("Saved: data/processed/train.rds and test.rds\n")