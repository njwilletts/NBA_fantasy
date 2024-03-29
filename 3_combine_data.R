# Libraries
library(tidyverse)
library(readxl)
library(stringi)

# Import concordances
source(".\\src\\concordances.R")

# Import NBA data and schedule
df_nba_schedule <- readRDS(".\\output\\df_nba_schedule.rds")
df_nba_combined <- readRDS(".\\output\\df_nba_combined.rds")

# Drop these variables from the data
drop <- c("games_played", "minutes_per_game", "total")

# Merge NBA data with team codes and player name fixes
data2 <- df_nba_combined %>% 
        left_join(., team_codes, by = "team_code") %>%
        select(!all_of(drop)) %>% 
        left_join(., player_fix, b = "player_name") %>%
        mutate(., player_name = coalesce(.$new_name, .$player_name)) %>%
        select(!"new_name")

# Remove accents from player names
data2$player_name <- stri_trans_general(str = data2$player_name, id = "Latin-ASCII")

# Filter schedule down to the number of games played per week by each team
schedule2 <- df_nba_schedule[ , !(names(df_nba_schedule) %in% c("day", "against"))] %>%
          distinct(., schedule, team_name, .keep_all = TRUE) 

# Combine schedule with data and derive 
df_complete <- left_join(data2, schedule2, by = "team_name", relationship = "many-to-many") 

# Save data as permanent RDS files
saveRDS(df_complete, file=".\\output\\df_complete.RDS")

# Remove config objects used only in this script
rm(drop, data2, schedule2)