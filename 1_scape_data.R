# Setup libraries, parameters, and helper functions
source(".\\src\\libraries.R")
source(".\\src\\parameters.R")
source(".\\src\\helper_functions.R")
source(".\\src\\web_scraper.R")

# Create parameter values unique to this script from config file
parameter_setup(script_filter = "hashtag_data")

# Create a list to store each scraped table of data
temp <- vector("list", length(temp_call_output)) %>% setNames(temp_call_output)

# Open RSelenium driver
client_server <- rsDriver(browser = "chrome", chromever = chrome_ver[[1]], port = free_port(), verbose = FALSE)
driver <- client_server$client
driver$open()

# Call the scraping function for each page and store data as a tibble inside a list
for (i in seq_along(temp)) {
  temp[[i]] <- scrape_clean_format(selector = temp_selector[[1]], 
                                    value = temp_value[[1]], 
                                    drop_down = temp_call_dropdown[[i]], 
                                    drop_down2 = temp_call_dropdown2[[i]],
                                    url = temp_url[[1]], 
                                    html = temp_html[[1]],
                                    driver = driver,
                                    start = temp_start[[1]],
                                    replace = temp_replace[[1]],
                                    with = temp_with[[1]],
                                    remove = temp_remove, 
                                    variables = temp_variables) %>% as_tibble(.) 
}

# Close RSelenium driver
driver$quit()
client_server$server$stop()

# Combine data into one tibble and split out attempts and makes for field goals and free throws
df_nba_combined <- bind_rows(temp, .id = "table") %>%
  mutate(field_goal_made = as.numeric(str_extract(.$field_goal, "(?<=\\().*(?=\\/)")),
            field_goal_attempt = as.numeric(str_extract(.$field_goal, "(?<=\\/).*(?=\\))")),
            free_throw_made = as.numeric(str_extract(.$free_throw, "(?<=\\().*(?=\\/)")),
            free_throw_attempt = as.numeric(str_extract(.$free_throw, "(?<=\\/).*(?=\\))")))

# Save data as permanent RDS file
saveRDS(df_nba_combined, file=".\\output\\df_nba_combined.RDS")

# Remove config objects used only in this script
rm(driver, i, temp, temp_call_dropdown, temp_call_dropdown2, temp_call_output, temp_html, temp_remove, temp_replace, 
   temp_selector, temp_start, temp_url, temp_value, temp_variables, temp_with)
