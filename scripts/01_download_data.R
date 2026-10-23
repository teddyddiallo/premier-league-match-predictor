# 01_download_data.R
# Download Premier League results from football-data.co.uk
# and assemble them into a single clean file.

library(tidyverse)
library(lubridate)

seasons  <- c("1516", "1617", "1718", "1819", "1920",
              "2021", "2122", "2223", "2324", "2425")
base_url <- "https://www.football-data.co.uk/mmz4281"

download_season <- function(code) {
  url  <- sprintf("%s/%s/E0.csv", base_url, code)
  dest <- file.path("data", "raw", sprintf("E0_%s.csv", code))
  if (!file.exists(dest)) download.file(url, dest, mode = "wb", quiet = TRUE)
  read_csv(dest, col_types = cols(.default = col_character()),
           show_col_types = FALSE) %>%
    select(Date, HomeTeam, AwayTeam, FTHG, FTAG, FTR) %>%
    mutate(Season = code)
}

safe_download <- function(code) {
  tryCatch(
    download_season(code),
    error = function(e) {
      message("Failed for season ", code, ": ", conditionMessage(e))
      NULL
    }
  )
}

matches <- seasons %>%
  map(safe_download) %>%
  bind_rows() %>%
  filter(FTR %in% c("H", "D", "A")) %>%
  mutate(
    Date   = dmy(Date),
    FTHG   = as.integer(FTHG),
    FTAG   = as.integer(FTAG),
    Season = paste0("20", substr(Season, 1, 2), "-", substr(Season, 3, 4))
  ) %>%
  arrange(Date)

# Basic checks
print(count(matches, Season))
cat("Total matches:", nrow(matches), "\n")
cat("Missing dates:", sum(is.na(matches$Date)), "\n")
cat("Date range:", format(min(matches$Date)), "to", format(max(matches$Date)), "\n")
print(table(matches$FTR))
print(round(prop.table(table(matches$FTR)), 3))

write_csv(matches, "data/processed/matches.csv")
cat("Saved: data/processed/matches.csv\n")