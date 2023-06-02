#--------CONFIG PARAMETERS--------

# Contains the URL to scrape from and metadata for selecting and cleaning what has been scraped 
url <- read_excel(".\\data\\parameters.xlsx",sheet = "url")

# Variables of scraped data
variables <- read_excel(".\\data\\parameters.xlsx",sheet = "variables") 

# Strings to delete from scraped data
remove <- read_excel(".\\data\\parameters.xlsx",sheet = "remove")

# Chrome version for ChromeDriver
chrome_ver <- read_excel(".\\data\\parameters.xlsx",sheet = "chrome_ver")

# Function calls for each drop down menu 
scrape_call <- read_excel(".\\data\\parameters.xlsx",sheet = "scrape_call")

# Contains metadata to access league information from the espn api
espn_api <- read_excel(".\\data\\parameters.xlsx",sheet = "espn_api")