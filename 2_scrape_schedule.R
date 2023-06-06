# Setup libraries, parameters, and helper functions
source(".\\src\\libraries.R")
source(".\\src\\parameters.R")
source(".\\src\\helper_functions.R")
source(".\\src\\web_scraper.R")

# Create parameter values unique to this script from config file
parameter_setup(script_filter = "hashtag_schedule")

# Create a list to store each scraped table of data
temp <- vector("list", length(temp_call_output)) %>% setNames(temp_call_output)

# Call the scraping function for each page and store data as a tibble inside a list
for (i in seq_along(temp)) {
  temp[[i]] <- scrape_clean_format(selector = temp_selector[[1]], 
                                   value = temp_value[[1]], 
                                   chromever = chrome_ver[[1]], 
                                   drop_down = temp_call_dropdown[[i]],
                                   url = temp_url[[1]], 
                                   html = temp_html[[1]], 
                                   start = temp_start[[1]],
                                   replace = temp_replace[[1]],
                                   with = temp_with[[1]],
                                   remove = temp_remove, 
                                   variables = temp_variables) %>% as_tibble(.) 
}

# Combine schedules into one tibble
combine_schedule <- bind_rows(temp, .id = "schedule")

# Transpose table to longer format
combine_schedule_long <- pivot_longer(data = combine_schedule,
                                      cols = c("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "next_monday", "next_tuesday"),
                                      names_to = "day",
                                      values_to = "against")

# Import all star schedule
all_star <- read_excel(".\\data\\all_star.xlsx", sheet = "all_star") %>% replace(., is.na(.), "")

# Combine regular schedules with all star schedule
df_nba_schedule <- bind_rows(combine_schedule_long, all_star)

# Save data as permanent RDS file
saveRDS(df_nba_schedule, file=".\\output\\df_nba_schedule.RDS")

# Remove config objects used only in this script
rm(i, temp, temp_call_dropdown, temp_call_output, temp_html, temp_remove, temp_replace, 
   temp_selector, temp_start, temp_url, temp_value, temp_variables, temp_with)