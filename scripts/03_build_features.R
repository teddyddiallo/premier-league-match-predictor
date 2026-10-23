# 03_build_features.R
# Build leak-free pre-match features: form over the previous 5 matches.

library(tidyverse)

matches <- read_csv("data/processed/matches.csv", show_col_types = FALSE) %>%
  mutate(HomeWin = factor(if_else(FTR == "H", "Yes", "No"),
                          levels = c("No", "Yes"))) %>%
  arrange(Date) %>%
  mutate(match_id = row_number())

# Mean of the 5 PREVIOUS values (the current match is never included).
roll5 <- function(x) {
  (lag(x, 1) + lag(x, 2) + lag(x, 3) + lag(x, 4) + lag(x, 5)) / 5
}

# One row per team per match (long format)
home_rows <- matches %>%
  transmute(match_id, Date, team = HomeTeam, venue = "home",
            gf = FTHG, ga = FTAG)
away_rows <- matches %>%
  transmute(match_id, Date, team = AwayTeam, venue = "away",
            gf = FTAG, ga = FTHG)

team_games <- bind_rows(home_rows, away_rows) %>%
  mutate(
    points = case_when(gf > ga ~ 3L, gf == ga ~ 1L, TRUE ~ 0L),
    gd     = gf - ga
  ) %>%
  arrange(team, Date, match_id) %>%
  group_by(team) %>%
  mutate(
    pts5 = roll5(points),
    gd5  = roll5(gd),
    # If the 5 previous matches span more than 300 days (promoted team,
    # return after relegation), the form is considered too old.
    span = as.numeric(Date - lag(Date, 5)),
    pts5 = if_else(span > 300, NA_real_, pts5),
    gd5  = if_else(span > 300, NA_real_, gd5)
  ) %>%
  ungroup()

# Attach home and away features back to each match
features <- matches %>%
  left_join(
    team_games %>% filter(venue == "home") %>%
      select(match_id, home_pts5 = pts5, home_gd5 = gd5),
    by = "match_id"
  ) %>%
  left_join(
    team_games %>% filter(venue == "away") %>%
      select(match_id, away_pts5 = pts5, away_gd5 = gd5),
    by = "match_id"
  )

model_data <- features %>%
  filter(!is.na(home_pts5), !is.na(away_pts5),
         !is.na(home_gd5), !is.na(away_gd5))

cat("Matches before filtering:", nrow(features), "\n")
cat("Matches kept (full 5-match history):", nrow(model_data), "\n")
cat("Matches dropped:", nrow(features) - nrow(model_data), "\n\n")
print(summary(model_data %>% select(home_pts5, away_pts5, home_gd5, away_gd5)))

# Leakage check on one team: the form at match 6 must equal the mean of
# points in matches 1-5, and be missing at match 5 (only 4 previous matches).
arsenal <- team_games %>% filter(team == "Arsenal") %>% arrange(Date)
cat("\nCheck 1 (form at match 6 = mean of matches 1-5):",
    isTRUE(all.equal(arsenal$pts5[6], mean(arsenal$points[1:5]))), "\n")
cat("Check 2 (form is missing at match 5):", is.na(arsenal$pts5[5]), "\n\n")

# Sanity check: is the home win rate higher when the home team is in better form?
sanity <- model_data %>%
  group_by(home_form_better = home_pts5 > away_pts5) %>%
  summarise(n = n(), home_win_rate = round(mean(HomeWin == "Yes"), 3),
            .groups = "drop")
print(sanity)

write_csv(model_data, "data/processed/model_data.csv")
cat("\nSaved: data/processed/model_data.csv\n")