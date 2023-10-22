#--------HELPER FUNCTIONS--------

# 1 - Create parameter values in the Global Environment which are unique to each script
parameter_setup <- function(script_filter){
  temp_url <<- url$url[url$script==script_filter]
  temp_html <<- url$html_node[url$script==script_filter]
  temp_start <<- url$starting_row[url$script==script_filter]
  temp_replace <<- url$replace[url$script==script_filter]
  temp_with <<- url$with[url$script==script_filter]
  temp_remove <<- remove$remove[remove$script==script_filter]
  temp_selector <<- url$selector[url$script==script_filter]
  temp_value <<- url$value[url$script==script_filter]
  temp_variables <<- variables$variables[variables$script==script_filter]
  temp_call_output <<- scrape_call$output[scrape_call$script==script_filter]
  temp_call_dropdown <<- scrape_call$drop_down[scrape_call$script==script_filter]
  temp_call_dropdown2 <<- scrape_call$drop_down2[scrape_call$script==script_filter]
}

# 2 – Produce a list of each managers roster from the espn api
  # FORMALS
    # season    = fantasy season year
    # league_id = id of espn fantasy league
    # swid      = software identification tag from espn log in (found in cookies)
    # espn_s2   = encrypted espn log in information (found in cookies)

espn_pull_roster <- function(season, league_id, swid, espn_s2){
  # Establish object to connect to espn api
  conn <- ffscrapr::espn_connect(season = season, league_id = league_id, swid = swid, espn_s2 = espn_s2)
  # Retrieve data dump containing team names and rosters from ESPN api
  teams <- ffscrapr::espn_getendpoint_raw(conn, paste0("https://fantasy.espn.com/apis/v3/games/fba/seasons/", season, "/segments/0/leagues/44419657?view=mTeam"))
  players <- ffscrapr::espn_getendpoint_raw(conn, paste0("https://fantasy.espn.com/apis/v3/games/fba/seasons/", season, "/segments/0/leagues/44419657?view=mRoster"))
  
  # Filter team data down to id code and manager names
  id <- map(teams[["content"]][["teams"]], accessor = "id", function(x, accessor) pluck(x, accessor)) %>% as.character()
  name <- map(teams[["content"]][["teams"]], accessor = "name", function(x, accessor) pluck(x, accessor)) %>% as.character()
  team_names <- tibble(id = id, name = name)
  
  # Filter roster data down to id code and player names
  length_teams <- length(players[["content"]][["teams"]])
  roster <- vector("list", length_teams)
  id <- vector("character", length_teams)
  
  for (i in seq_along(1:length_teams)){
    length_players <- length(players[["content"]][["teams"]][[i]][["roster"]][["entries"]])
    roster[[i]] <- vector("character", length_players)
    id[[i]] <- players[["content"]][["teams"]][[i]][["id"]]
    for (j in seq_along(1:length_players)){
      roster[[i]][[j]] <- pluck(players[["content"]][["teams"]][[i]][["roster"]][["entries"]][[j]][["playerPoolEntry"]][["player"]][["fullName"]])
    }
  }
  roster <- roster %>% setNames(id) %>% as_tibble() %>% pivot_longer(cols = all_of(id), names_to = "id", values_to = "player_name")
  
  # Merge team names with players on roster using id
  manager_roster <- left_join(roster, team_names, by = "id") %>% select(!(id))
  return(manager_roster)
}

# 3 – Calculate the z score of x
  # FORMALS
    # x = input data
z_score <- function(x){
  zs <- (x - mean(x, na.rm=TRUE))/sd(x, na.rm=TRUE)
  return(zs)
}