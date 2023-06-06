#--------WEB SCRAPER FUNCTIONS--------

# 1 - For scraping web pages that require interaction
  # FORMALS
      # selector    = sheet language selector to use
      # value       = selector element object to click on
      # chrome_ver  = version of chrome driver
      # url         = web page to scrape data
      # drop_down   = element number of drop down box to click
      # drop_down2  = optional second element to click
      # html        = html nodes to extract data from
      # browser     = web driver to use
    
web_scrape <- function(selector, value, chromever, url, drop_down, drop_down2 = NA, html, browser = "chrome"){
  client_server <- rsDriver(browser = browser, chromever = chromever, port = free_port(), verbose = FALSE)
  driver <- client_server$client
  driver$open()
  driver$navigate(url)
  Sys.sleep(1)
  if (is.na(drop_down2)) {
    driver$findElements(using = selector, value = value)[[drop_down]]$clickElement()
  } else {
    options <- driver$findElements(using = selector, value = value)
    options[[drop_down]]$clickElement()
    options[[drop_down2]]$clickElement()
  }
  Sys.sleep(3)
  return(read_html(driver$getPageSource()[[1]]) %>% html_nodes(html))
  driver$quit()
  client_server$server$stop()
}

# 2 - Clean scraped XML data
  # FORMALS
    # start       = first row which contains data to keep
    # replace     = string to replace
    # with        = what to replace the string with
    # remove      = strings to remove

clean_xml <- function(x, start = FALSE, replace = FALSE, with = FALSE, remove){
  clean <- x %>% html_text2() %>% 
    {if (start[[1]] == FALSE) . else .[-1:-start]} %>% 
    {if (replace[[1]] == FALSE) . else str_replace_all(., replace, with)} %>% 
    str_trim(.) %>% 
    {if (remove[[1]] == FALSE) . else .[!(. %in% remove)]}
  return(clean)
}

# 3 - Create a list containing lists to store data in wider table format
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

# 4 - Write observations from a vector into an empty list
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

# 5 - Convert list of lists to a list of numeric or character vectors
  # character is the default if numeric isn't possible
  # FORMALS
    # x           = list containing lists to convert to atomic vectors

convert_to_atomic_vector <- function(x){
  for (i in seq_along(x)){
    num_test <- suppressWarnings(as.numeric(gsub(" ", "", x[[i]]))) # Remove white space as it is interpreted as a character
    if (all(!is.na(num_test))) {
      x[[i]] <- as.numeric(unlist(word(x[[i]])))
    } else {
      x[[i]] <- unlist(x[[i]])
    }
  }
  return(x)
}

#--------MASTER FUNCTION---------

# 6 - Master function to scrape data, clean, and format using helper functions above
  # FORMALS - check helper functions above for descriptions
    # selector    = #1 web_scrape
    # value       = #1 Web_scrape
    # chromever   = #1 web_scrape
    # drop_down   = #1 web_scrape
    # drop_down2  = #1 web_scrape
    # url         = #1 web_scrape
    # html        = #1 web_scrape
    # start       = #2 clean_xml
    # replace     = #2 clean_xml
    # with        = #2 clean_xml
    # remove      = #2 clean_xml
    # variables   = #3 create_list_lists

scrape_clean_format <- function(selector, value, chromever = "latest", drop_down, drop_down2, url, html, start, replace, with, remove, variables){
  
  # Function 1
  # Scrape data from webpage
  html_extract <- web_scrape(selector = selector,
                             value = value, 
                             chromever = chromever, 
                             drop_down =  drop_down,
                             drop_down2 = drop_down2,
                             url = url, 
                             html = html)
  
  # Function 2
  # Clean the scraped XML data
  clean <- clean_xml(x = html_extract, 
                     start = start, 
                     replace = replace, 
                     with = with, 
                     remove = remove)
  
  # Function 3
  # Create empty list of lists to store data by variable
  empty <- create_list_lists(x = clean, variables = variables)
  
  # Function 4
  # Widen clean data by writing observations to list variables
  full <- write_obs(x = clean, empty_shell = empty)
  
  # Function 5
  # Convert list variables to numeric or character
  final <- convert_to_atomic_vector(x = full)
  
  return(final)
}