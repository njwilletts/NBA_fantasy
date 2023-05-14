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
}

# 2 - For scraping web pages that require interaction
  # FORMALS
      # selector   = sheet language selector to use
      # value      = selector element object to click on
      # chrome_ver = version of chrome driver
      # url        = web page to scrape data
      # drop_down  = element number of drop down box to click
      # html       = html nodes to extract data from
      # browser    = web driver to use
    
web_scrape <- function(selector, value, chromever, url, drop_down, html, browser = "chrome"){
  client_server <- rsDriver(browser = browser, chromever = chromever, port = free_port(), verbose = FALSE)
  driver <- client_server$client
  driver$open()
  driver$navigate(url)
  Sys.sleep(1)
  driver$findElements(using = selector, value = value)[[drop_down]]$clickElement()
  Sys.sleep(2)
  return(read_html(driver$getPageSource()[[1]]) %>% html_nodes(html))
  driver$quit()
  client_server$server$stop()
}

# 3 - Clean scraped XML data
  # FORMALS
    # start     = first row which contains data to keep
    # replace   = string to replace
    # with      = what to replace the string with
    # remove    = strings to remove

clean_xml <- function(x, start = FALSE, replace = FALSE, with = FALSE, remove){
  clean <- x %>% html_text2() %>% 
    {if (start[[1]] == FALSE) . else .[-1:-start]} %>% 
    {if (replace[[1]] == FALSE) . else str_replace_all(., replace, with)} %>% 
    str_trim(.) %>% 
    {if (remove[[1]] == FALSE) . else .[!(. %in% remove)]}
  return(clean)
}

# 4 - Create a list containing lists to store data in wider table format
  # Example: input data of length 30 & 5 variables outputs a list length 5 containing 5 lists of length 6
    # FORMALS
      # x         = data vector to widen
      # variables = variable names

create_list_lists <- function(x, variables){
  temp <- vector("list", length(variables)) %>% setNames(variables)
  
  for (i in seq_along(variables)){
    temp[[i]] <- vector("list", (length(x))/length(variables)) 
  }
  return(temp)
}

# 5 - Write observations from a vector into an empty list
  # FORMALS
    # x           = data vector to write to empty list 
    # empty_shell = empty list

write_obs <- function(x, empty_shell){
  cycle_pos <- 1
  cycle <- 1
  for (i in seq_along(x)) {
    empty_shell[[cycle_pos]][[cycle]] <- x[[i]]
    cycle_pos <- cycle_pos + 1
    if (i %% length(empty_shell) == 0) {
      cycle <- cycle + 1
      cycle_pos <- 1
    }
  }
  return(empty_shell)
}

# 6 - Convert list of lists to a list of numeric or character vectors
  # character is the default if numeric isn't possible
  # FORMALS
    # x = list containing lists to convert to atomic vectors

convert_to_atomic_vector <- function(x){
  for (i in seq_along(x)){
    if (suppressWarnings(all(!is.na(as.numeric(x[[i]]))))) {
      x[[i]] <- as.numeric(unlist(x[[i]]))
    } else {
      x[[i]] <- unlist(x[[i]])
    }
  }
  return(x)
}

#--------MASTER FUNCTION---------

# 7 - Master function to scrape data, clean, and format using helper functions above
  # FORMALS - check helper functions above for descriptions
    # selector  = #2 web_scrape
    # value     = #2 Web_scrape
    # chromever = #2 web_scrape
    # drop_down = #2 web_scrape
    # url       = #2 web_scrape
    # html      = #2 web_scrape
    # start     = #3 clean_xml
    # replace   = #3 clean_xml
    # with      = #3 clean_xml
    # remove    = #3 clean_xml
    # variables = #4 create_list_lists

scrape_clean_format <- function(selector, value, chromever = "latest", drop_down, url, html, start, replace, with, remove, variables){
  
  # Helper function 2
  # Scrape data from webpage
  html_extract <- web_scrape(selector = selector,
                             value = value, 
                             chromever = chromever, 
                             drop_down =  drop_down, 
                             url = url, 
                             html = html)
  
  # Helper function 3
  # Clean the scraped XML data
  clean <- clean_xml(x = html_extract, 
                     start = start, 
                     replace = replace, 
                     with = with, 
                     remove = remove)
  
  # Helper function 4
  # Create empty list of lists to store data by variable
  empty <- create_list_lists(x = clean, variables = variables)
  
  # Helper function 5
  # Widen clean data by writing observations to list variables
  full <- write_obs(x = clean, empty_shell = empty)
  
  # Helper function 6
  # Convert list variables to numeric or character
  final <- convert_to_atomic_vector(x = full)
  
  return(final)
}