# Football Match Predictor: Can Recent Form Predict Home Wins in the Premier League?

Binary classification project predicting whether the home team wins a Premier League match, using only information available before kick-off.

## Research question
Can recent team form (points and wins over the previous five matches) predict home wins better than a naive baseline?

## Data
Match results from football-data.co.uk, Premier League, seasons 2015-16 to 2024-25.

## Methods
Leak-free feature engineering, chronological train/test split, logistic regression, random forest, evaluation against a majority-class baseline (accuracy, ROC-AUC with confidence interval, confusion matrix).

## Status
Work in progress.