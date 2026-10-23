# 02_explore_data.R
# Explore the assembled Premier League matches.

library(tidyverse)

# The factor levels are set explicitly (No first, Yes second), so that models
# and ROC curves treat "Yes" (home win) as the event of interest.
matches <- read_csv("data/processed/matches.csv", show_col_types = FALSE) %>%
  mutate(HomeWin = factor(if_else(FTR == "H", "Yes", "No"),
                          levels = c("No", "Yes")))

# 1. Outcomes and goals by season
by_season <- matches %>%
  group_by(Season) %>%
  summarise(
    n              = n(),
    home_win_rate  = round(mean(HomeWin == "Yes"), 3),
    draw_rate      = round(mean(FTR == "D"), 3),
    away_win_rate  = round(mean(FTR == "A"), 3),
    avg_home_goals = round(mean(FTHG), 2),
    avg_away_goals = round(mean(FTAG), 2)
  )
print(by_season)

# 2. Majority-class baseline (always predict "No")
baseline <- max(prop.table(table(matches$HomeWin)))
cat("\nMajority-class baseline accuracy:", round(baseline, 3), "\n")

# 3. Plot: home win rate by season
p <- ggplot(by_season, aes(x = Season, y = home_win_rate, group = 1)) +
  geom_hline(yintercept = mean(matches$HomeWin == "Yes"), linetype = "dashed") +
  geom_line() +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::percent, limits = c(0.3, 0.6)) +
  labs(
    title    = "Share of home wins by season",
    subtitle = "Premier League, 2015-16 to 2024-25 (dashed line = overall rate)",
    x = "Season", y = "Home win rate"
  )
print(p)
ggsave("results/home_win_rate_by_season.png", p, width = 8, height = 5, dpi = 150)