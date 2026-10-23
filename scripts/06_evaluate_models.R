# 06_evaluate_models.R
# Evaluate both models on the chronological test set.

library(tidyverse)
library(pROC)
library(randomForest)

train     <- readRDS("data/processed/train.rds")
test_pred <- readRDS("data/processed/test_pred.rds")
models    <- readRDS("results/models.rds")

actual   <- test_pred$HomeWin
n        <- length(actual)
baseline <- max(prop.table(table(actual)))
cat("Test set:", n, "matches | baseline accuracy:", round(baseline, 3), "\n")

# Two decision thresholds, both chosen WITHOUT looking at the test set:
# 0.5, and the share of home wins in the training set.
thr_train <- mean(train$HomeWin == "Yes")
cat("Thresholds: 0.5 and", round(thr_train, 3), "(training prevalence)\n\n")

evaluate <- function(p, thr, model, thr_label) {
  pred <- p >= thr
  yes  <- actual == "Yes"
  tp <- sum(pred & yes);  fp <- sum(pred & !yes)
  fn <- sum(!pred & yes); tn <- sum(!pred & !yes)
  precision <- tp / (tp + fp)
  recall    <- tp / (tp + fn)
  tibble(
    model = model, threshold = thr_label,
    accuracy  = (tp + tn) / n,
    precision = precision,
    recall    = recall,
    f1        = 2 * precision * recall / (precision + recall),
    TP = tp, FP = fp, FN = fn, TN = tn,
    p_vs_baseline = binom.test(tp + tn, n, p = baseline,
                               alternative = "greater")$p.value
  )
}

results <- bind_rows(
  evaluate(test_pred$p_lr, 0.5,       "Logistic regression", "0.5"),
  evaluate(test_pred$p_lr, thr_train, "Logistic regression", "training prevalence"),
  evaluate(test_pred$p_rf, 0.5,       "Random forest",       "0.5"),
  evaluate(test_pred$p_rf, thr_train, "Random forest",       "training prevalence")
)
print(results %>% mutate(across(where(is.numeric), ~ round(.x, 3))), width = Inf)

# ROC and AUC (levels fixed: "No" = control, "Yes" = event; higher score = event)
roc_lr <- roc(actual, test_pred$p_lr, levels = c("No", "Yes"),
              direction = "<", quiet = TRUE)
roc_rf <- roc(actual, test_pred$p_rf, levels = c("No", "Yes"),
              direction = "<", quiet = TRUE)

cat("\nAUC logistic regression:", round(auc(roc_lr), 3), "\n")
print(ci.auc(roc_lr))
cat("AUC random forest:", round(auc(roc_rf), 3), "\n")
print(ci.auc(roc_rf))
cat("\nDeLong test, difference between the two AUCs:\n")
print(roc.test(roc_lr, roc_rf, method = "delong"))

# Plots
p_roc <- ggroc(list("Logistic regression" = roc_lr, "Random forest" = roc_rf),
               legacy.axes = TRUE) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(title = "ROC curves on the test set (2023-24 and 2024-25)",
       x = "1 - Specificity", y = "Sensitivity", colour = "Model")
print(p_roc)
ggsave("results/roc_curves.png", p_roc, width = 7, height = 5, dpi = 150)

imp <- as.data.frame(importance(models$random_forest)) %>%
  rownames_to_column("feature")
p_imp <- ggplot(imp, aes(x = reorder(feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
  geom_col() + coord_flip() +
  labs(title = "Random forest: variable importance",
       x = NULL, y = "Mean decrease in Gini impurity")
print(p_imp)
ggsave("results/rf_importance.png", p_imp, width = 7, height = 4, dpi = 150)

write_csv(results, "results/model_evaluation.csv")
cat("\nSaved: results/model_evaluation.csv, roc_curves.png, rf_importance.png\n")