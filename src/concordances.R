#--------CONCORDANCE FILES--------

# Map team names to team codes
team_codes <- read_excel(".\\data\\concordances.xlsx", sheet = "team_codes")

# The NBA players in each fantasy team
fantasy_teams <- read_excel(".\\data\\concordances.xlsx", sheet = "fantasy_teams")

# Display name of each scraped data set
data_names <- read_excel(".\\data\\concordances.xlsx", sheet = "data_names")

# Display name of each scraped schedule 
schedule_names <- read_excel(".\\data\\concordances.xlsx", sheet = "schedule_names")
