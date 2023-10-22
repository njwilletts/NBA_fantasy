NBA Fantasy Tools
================

## Overview

This repository contains R scripts to scrape and present data from the
popular NBA fantasy site
[hashtagbasketball](https://hashtagbasketball.com/). The data is scraped
using the [rvest](https://github.com/tidyverse/rvest) package in
conjunction with [RSelenium](https://github.com/ropensci/RSelenium) to
interact with the dynamic content. The results are presented by an
[Rshiny](https://github.com/rstudio/shiny) app to assist NBA fantasy
managers in winning their 9-cat league.

## Shiny application

The app features:

- an **overall summary** of each managers per game average for each of
  the standard 9 categories.
- a **heads up comparison** between managers which is adjusted for games
  scheduled that week.
- option to adjust down the expected games played by each player to
  **account for injuries**.
- option to select data from either the **rest-of-season projection,
  current regular season, or the last 7 - 30 days**.

### Screenshots

*Figure 1 - summary table comparing manager averages* ![Fantasy NBA app
summary
table](https://raw.githubusercontent.com/njwilletts/NBA_fantasy/main/screenshots/ss_summary.png?raw=true)

*Figure 2 - matchup comparison options* ![Fantasy NBA app matchup
comparison
options](https://raw.githubusercontent.com/njwilletts/NBA_fantasy/main/screenshots/ss_matchup_select.png?raw=true)

*Figure 3 - matchup prediction* ![Fantasy NBA app matchup comparison
predictions](https://raw.githubusercontent.com/njwilletts/NBA_fantasy/main/screenshots/ss_matchup_compare.png?raw=true)

## Config files

The configuration files are found in the /data folder. When updating the
files it’s important to maintain the same formatting to what has been
used previously as that is what the scripts expect.

Note that the all star schedule is imported from excel manually as it is
a non-standard format when compared to other weeks due to the longer
duration.

| File         | Sheet          | Variable        | Description                                                                                  |
|--------------|----------------|-----------------|----------------------------------------------------------------------------------------------|
| all_star     | all_star       | schedule        | the week of the all star break e.g. week_18                                                  |
| all_star     | all_star       | team_name       | the name of the teams e.g. Atlanta Hawks                                                     |
| all_star     | all_star       | games_scheduled | the total number of games scheduled each team over all star week e.g. 4                      |
| all_star     | all_star       | day             | the day of the week e.g. monday                                                              |
| all_star     | all_star       | against         | the opponent team e.g. @CHA                                                                  |
| concordances | team_codes     | team_name       | the name of the teams e.g. Atlanta Hawks                                                     |
| concordances | team_codes     | team_code       | the code of the teams e.g. ATL                                                               |
| concordances | data_names     | table           | the reference name of each table of scraped data e.g. df_nba_ros                             |
| concordances | data_names     | name            | the display name of each table of data e.g. Rest-of-season projection                        |
| concordances | schedule_names | schedule        | the reference names for each weekly schedule e.g. week_1                                     |
| concordances | schedule_names | schedule        | the display names of that weekly schedule e.g. W1: 17 Oct - 23 Oct                           |
| concordances | player_fix     | player_name     | the player name to change e.g. OG Anunoby                                                    |
| concordances | player_fix     | new_name        | the player name to change to e.g. O.G. Anunoby                                               |
| parameters   | chrome_ver     | chrome_ver      | the version of Chrome WebDriver to be used by RSelenium                                      |
| parameters   | variables      | script          | the script which uses these parameters e.g. hashtag_data                                     |
| parameters   | variables      | variables       | the variables each script is scraping e.g. player_name                                       |
| parameters   | remove         | script          | the script which uses these parameters e.g. hashtag_data                                     |
| parameters   | remove         | remove          | text strings to remove from scraped data e.g. R#                                             |
| parameters   | url            | script          | the script which uses these parameters e.g. hashtag_data                                     |
| parameters   | url            | url             | the url to scrape data from e.g. <https://hashtagbasketball.com/fantasy-basketball-rankings> |
| parameters   | url            | starting_row    | the first row of useful information from scraped data e.g. 25                                |
| parameters   | url            | selector        | the selector to use for scraping data e.g. css_selector                                      |
| parameters   | url            | value           | the type of the selector e.g. option                                                         |
| parameters   | url            | html_node       | the type of html node to scrape e.g. td                                                      |
| parameters   | url            | replace         | text strings to be replaced by something else e.g. “                                         |
| parameters   | url            | with            | text strings to replace the strings above e.g. “”                                            |
| parameters   | scrape_call    | script          | the script which uses these parameters e.g. hashtag_data                                     |
| parameters   | scrape_call    | output          | the name of the tables which contain the scraped data e.g. df_nba_ros                        |
| parameters   | scrape_call    | drop_down       | the option to select before scraping e.g. 59                                                 |
| parameters   | scrape_call    | drop_down2      | a second option to select before scraping e.g. 5                                             |
| parameters   | espn_api       | season          | the year of the fantasy season e.g. 2023                                                     |
| parameters   | espn_api       | league_id       | the id number in the url when accessing the espn fantasy page for your league e.g. 44419657  |
| parameters   | espn_api       | swid            | the swid string found under the espn cookies which relates to your login details             |
| parameters   | espn_api       | espn_s2         | the espn_s2 string found under the espn cookies which relates to your login details          |

## Common problems

#Updating the ChromeDriver version for windows

Step 1: navigate to https://googlechromelabs.github.io/chrome-for-testing/#stable
Step 2: navigate to the url under the following section to download the zip file: Stable -> chromedriver -> win32
Step 3: copy the zip file into: C:\Users\*insert your user*\AppData\Local\binman\binman_chromedriver\win32
Step 4: create a folder named after the version number and extract the chromedriver exe into it (delete/ignore the other files such as licence)
Step 5: run the following in R to check that the latest version is there: binman::list_versions("chromedriver") 
Step 6: go into the parameters excel file and update the chrome_ver variable to the latest version

RSelenium will now run on that latest version.

#Obtaining the league_ID, swid, and espn_2 parameter values

Step 1: open up Chrome
Step 2: log into your espn fantasy league 
Step 3: check the league number in the url as this is what you'll need for league_ID
Step 4: right click on the page and select inspect
Step 5: click the >> (More tabs) in the top bar and select Application
Step 6: navigate to Storage -> Cookies -> https://fantasy.espn.com
Step 7: find the values for SWID and espn_s2 and put them into the parameters excel file

The RShiny app will now update your league details automatically. 