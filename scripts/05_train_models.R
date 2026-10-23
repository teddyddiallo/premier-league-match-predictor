# 05_train_models.R
# Train logistic regression and random forest on the training set only.

library(tidyverse)
library(randomForest)

train <- readRDS("data/processed/train.rds")
test  <- readRDS("data/processed/test.rds")

# "No" must be the first level and "Yes" the second: glm models the probability
# of the SECOND level, and ROC curves later treat it as the event of interest.
stopifnot(identical(levels(train$HomeWin), c("No", "Yes")))

features   <- c("home_pts5", "away_pts5", "home_gd5", "away_gd5")
model_form <- HomeWin ~ home_pts5 + away_pts5 + home_gd5 + away_gd5

# ---- 1. Logistic regression ----
log_model <- glm(model_form, data = train, family = binomial)
print(summary(log_model))

cat("\nOdds ratios with 95% confidence intervals (Wald):\n")
print(round(exp(cbind(OR = coef(log_model), confint.default(log_model)))[-1, ], 3))

# ---- 2. Random forest ----
set.seed(42)
rf_model <- randomForest(model_form, data = train, ntree = 500, importance = TRUE)
print(rf_model)

# ---- 3. Predicted probabilities of a home win on the test set ----
test_pred <- test %>%
  mutate(
    p_lr = predict(log_model, newdata = test, type = "response"),
    p_rf = predict(rf_model,  newdata = test, type = "prob")[, "Yes"]
  )

# Direction check: matches that ended in a home win should get HIGHER
# predicted probabilities than the others.
cat("\nMean predicted probability of a home win, by actual outcome:\n")
print(test_pred %>%
        group_by(HomeWin) %>%
        summarise(mean_p_lr = round(mean(p_lr), 3),
                  mean_p_rf = round(mean(p_rf), 3), .groups = "drop"))

saveRDS(test_pred, "data/processed/test_pred.rds")
saveRDS(list(logistic = log_model, random_forest = rf_model), "results/models.rds")
cat("\nSaved: data/processed/test_pred.rds and results/models.rds\n")