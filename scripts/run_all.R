# run_all.R: reproduce the full analysis from scratch.
scripts <- c("01_download_data.R", "02_explore_data.R", "03_build_features.R",
             "04_split_and_baseline.R", "05_train_models.R", "06_evaluate_models.R")

for (s in scripts) {
  cat("\n=== Running", s, "===\n")
  source(file.path("scripts", s))
}

rmarkdown::render("reports/final_report.Rmd", quiet = TRUE)
cat("\nDone: reports/final_report.html\n")