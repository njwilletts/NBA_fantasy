#----------SETUP-------------
# LIBRARIES
library(tidyverse)
library(shiny)
library(shinydashboard)
library(shinythemes)
library(shinyWidgets)
library(DT)
library(readxl)

# INPUT DATA
input_data <- readRDS(".\\output\\df_complete.rds") %>% relocate(points, .after = turnovers)
source(".\\src\\concordances.R")

# SELECTION PARAMETERS
sum_drop <- c("num", "position", "team_code", "field_goal", "free_throw", "team_name", "schedule", "games_scheduled") # Variables to drop from summary table
compare_drop <- c("field_goal_attempt", "field_goal_made", "free_throw_attempt", "free_throw_made") # Variables to drop from comparison table
lineup_drop <- c("num", "position", "team_code", "field_goal_attempt", "field_goal_made", "free_throw_attempt", "free_throw_made", "team_name") # Variables to drop from lineup selection
data_from <- data_names$table %>% setNames(data_names$name) # Display name of each table of data
schedule_from <- schedule_names$schedule %>% setNames(schedule_names$name) #Display name of schedule data
name_from <- input_data %>% select("name") %>% unique() # Name of each fantasy manager
scale_vars <- c("threes", "points", "rebounds", "assists", "steals", "blocks", "turnovers", 
                "field_goal_made", "field_goal_attempt", "free_throw_made", "free_throw_attempt") # Variables to scale by the number of games played in the selected week
date_lookup <- as.double(difftime(Sys.Date(), "2022-10-11", units = "days")) %/% 7 # Check the current NBA week to use as the default schedule selection

# FORMAT OUTPUT
format_sum <- c("Manager", "FG%", "FT%", "3PM", "REB", "AST", "STL", "BLK", "TO", "PTS") # Names to display for variables in summary table
# Names to display for variables in match up tables
format_matchup1 <- c("Player Name", "Games", "Missed")
format_matchup2 <- c("Manager", "FG%", "FT%", "3PM", "REB", "AST", "STL", "BLK", "TO", "PTS", "Games")
format_matchup3 <- c("Player Name", "FG%", "FT%", "3PM", "REB", "AST", "STL", "BLK", "TO", "PTS", "Games")


#----------APP-------------

# USER INTERFACE
ui <- fluidPage(theme = shinytheme("sandstone"), useShinydashboard(),
  column(1),
  column(10,
    titlePanel("NBA Fantasy Tools"),
    tabsetPanel(id = "tabset",
      tabPanel("Summary", id = "panel_1",
        h3("Per game averages by manager"),
        selectInput("table1", "Data", data_from),
        DT::dataTableOutput("sum_table")
      ),
      tabPanel("Matchup comparison", id = "panel_2",
        h3("Weekly matchup comparison"),
        fluidRow(
          column(3, selectInput("table2", "Data", data_from)),
          column(3, offset = 1, selectInput("schedule1", "Schedule", schedule_from, selected = schedule_from[date_lookup]))
        ),
        fluidRow(
          column(3, selectInput("manager1", "You", name_from, selected = "Nick")),
          column(3, offset = 1, selectInput("manager2", "Opponent", name_from))
        ),
        fluidRow(
          column(3, DT::dataTableOutput("you_missing")),
          column(3, offset = 1, DT::dataTableOutput("opp_missing")),
          column(6),
        ),
        headerPanel(""),
        actionButton("compare", "Compare"),
        headerPanel(""),
        h2(textOutput("you_name")),
        fluidRow(
          splitLayout(
            shinydashboard::valueBoxOutput("you_fg", width = NULL),
            shinydashboard::valueBoxOutput("you_ft", width = NULL),
            shinydashboard::valueBoxOutput("you_3pm", width = NULL),
            shinydashboard::valueBoxOutput("you_reb", width = NULL),
            shinydashboard::valueBoxOutput("you_ast", width = NULL),
            shinydashboard::valueBoxOutput("you_stl", width = NULL),
            shinydashboard::valueBoxOutput("you_blk", width = NULL),
            shinydashboard::valueBoxOutput("you_to", width = NULL),
            shinydashboard::valueBoxOutput("you_pts", width = NULL)
          )
        ),
        h2(textOutput("opp_name")),
        fluidRow(
          splitLayout(
            shinydashboard::valueBoxOutput("opp_fg", width = NULL),
            shinydashboard::valueBoxOutput("opp_ft", width = NULL),
            shinydashboard::valueBoxOutput("opp_3pm", width = NULL),
            shinydashboard::valueBoxOutput("opp_reb", width = NULL),
            shinydashboard::valueBoxOutput("opp_ast", width = NULL),
            shinydashboard::valueBoxOutput("opp_stl", width = NULL),
            shinydashboard::valueBoxOutput("opp_blk", width = NULL),
            shinydashboard::valueBoxOutput("opp_to", width = NULL),
            shinydashboard::valueBoxOutput("opp_pts", width = NULL)
          )
        ),
        headerPanel(""),
        fluidRow(
          shinydashboard::tabBox(title = "Matchup results", id = "tabset2", width = 12, height = "600px",
            tabPanel("Prediction", DT::dataTableOutput("comparison_table")),
            tabPanel(textOutput("header_you"), DT::dataTableOutput("you_lineup")),
            tabPanel(textOutput("header_opp"), DT::dataTableOutput("opp_lineup"))
          )
        ),
        headerPanel(""),
      )
    )
  ),
  column(1)
)
# SERVER
server <- function(input, output, session){
  
  # TAB ONE SUMMARY TABLE
  
  # Combine player stats to calculate average per game stats by manager 
  sum_clean <- input_data %>% select(!all_of(sum_drop)) %>%
    unique() %>%
    group_by(table, name) %>% 
    summarise(threes = sum(threes),
              rebounds = sum(rebounds),
              assists = sum(assists),
              steals = sum(steals),
              blocks = sum(blocks),
              turnovers = sum(turnovers),
              points = sum(points),
              field_goal_made = sum(field_goal_made),
              field_goal_attempt = sum(field_goal_attempt),
              free_throw_made = sum(free_throw_made),
              free_throw_attempt = sum(free_throw_attempt)
              ) %>%
    mutate(field_goal = round(field_goal_made/field_goal_attempt, digits = 3),
           free_throw = round(free_throw_made/free_throw_attempt, digits = 3)) %>%
    select(!c("field_goal_attempt", "field_goal_made", "free_throw_attempt", "free_throw_made")) %>%
    ungroup() %>%
    relocate(c("field_goal", "free_throw"), .after = name)
  
  # Capture reactive user supplied value to specify what data to use for summary
  sum_data <- reactive(input$table1)
  
  # Output averages to data table showing the data specified by the reactive variable above
  output$sum_table <- DT::renderDataTable(options = list(dom = "t"), rownames = FALSE, colnames = format_sum,
    {sum_clean %>% 
      .[.$table %in% sum_data(),] %>%
      select(!c("table"))
    }
  )
  
  # TAB 2 MATCHUP COMPARISON
    # NOTE: this page is only updated when the compare action button is clicked or when the tab is opened
  
  # Create reactive variables from user supplied input
  compare_you <- eventReactive(list(input$compare, input$panel_2), {input$manager1}) # Your name
  compare_opp <- eventReactive(list(input$compare, input$panel_2), {input$manager2}) # Your opponents name
  compare_data <- eventReactive(list(input$compare, input$panel_2), {input$table2}) # Data to use for comparison
  compare_schedule <- eventReactive(list(input$compare, input$panel_2), {input$schedule1}) # Weekly schedule to use for comparison
  
  # Create a comparison table using the user supplied input whenever the compare button is pushed or the panel is opened
  compare_table <- eventReactive(list(input$compare, input$panel_2), {
    # Compile two vectors containing the user supplied number of games each player is expected to miss this week
      # if no number is supplied (null data) then a value of 0 is imputed
    you_missed_games <- vector("double", length=length(you_lineup$player_name))
    for (i in seq_along(you_lineup$player_name)){
      you_missed_games[i] <- as.double(
        ifelse(is_null(input[[paste0("you_select_missed_", i)]]), 
               0, 
               input[[paste0("you_select_missed_", i)]]
        )
      )
    }
    opp_missed_games <- vector("double", length=length(opp_lineup$player_name))
    for (i in seq_along(opp_lineup$player_name)){
      opp_missed_games[i] <- as.double(
        ifelse(is_null(input[[paste0("opp_select_missed_", i)]]), 
               0, 
               input[[paste0("opp_select_missed_", i)]]
        )
      )
    }
    
    # The two vectors containing the expected number of missed games are combined into a single tibble to merge with the input data
    df_you <- tibble(player_name = you_lineup$player_name, missed = you_missed_games)
    df_opp <- tibble(player_name = opp_lineup$player_name, missed = opp_missed_games)
    df_combined <- rbind(df_you, df_opp)
    
    # Merge expected missed games for each player with input data
    df_data <- left_join(input_data, df_combined, by = "player_name") %>%
      # Filter data down to what the user has selected
      .[.$table %in% compare_data() & .$schedule %in% compare_schedule() & .$name %in% c(compare_you(),compare_opp()),] %>%
      # Subtract the missed games off the games scheduled
      mutate(games_expected = games_scheduled - missed) %>%
      # Scale up the per game stats by the number of expected games
      mutate(across(all_of(scale_vars), ~ .x * games_expected)) %>%
      # Summarise across players
      group_by(name) %>%
      summarise(threes = sum(threes),
                rebounds = sum(rebounds),
                assists = sum(assists),
                steals = sum(steals),
                blocks = sum(blocks),
                turnovers = sum(turnovers),
                points = sum(points),
                games_expected = sum(games_expected),
                field_goal_made = sum(field_goal_made),
                field_goal_attempt = sum(field_goal_attempt),
                free_throw_made = sum(free_throw_made),
                free_throw_attempt = sum(free_throw_attempt)
      ) %>%
      # Calculate the field goal and free throw percentages and format for easy display
      mutate(field_goal = round(field_goal_made/field_goal_attempt, 3) * 100,
             free_throw = round(free_throw_made/free_throw_attempt, 3) * 100) %>%
      # Clean data for output
      select(!all_of(compare_drop)) %>%
      ungroup() %>%
      relocate(c("field_goal", "free_throw"), .after = name)
    return(df_data)
    }
  )
  
  # Create a table containing the first managers data whenever the compare button is pushed or the panel is opened
  you_table <- eventReactive(list(input$compare, input$panel_2), {
    input_data %>% select(!all_of(lineup_drop)) %>%
      .[.$table %in% compare_data() & .$schedule %in% compare_schedule() & .$name %in% c(compare_you()),] %>%
      select(!c("table", "schedule", "name"))
    }
  )
  
  # Create a table containing the second managers data whenever the compare button is pushed or the panel is opened
  opp_table <- eventReactive(list(input$compare, input$panel_2), {
    input_data %>% select(!all_of(lineup_drop)) %>%
      .[.$table %in% compare_data() & .$schedule %in% compare_schedule() & .$name %in% c(compare_opp()),] %>%
      select(!c("table", "schedule", "name"))
    }
  )

  # Render table output and headings with the reactive tables and variables created earlier
  output$comparison_table <- renderDataTable({compare_table()}, options = list(dom = "t"), colnames = format_matchup2, rownames = FALSE)
  
  output$header_you <- renderText({paste0(compare_you(), "'s lineup")})
  
  output$you_lineup <- DT::renderDataTable(options = list(dom = "t", pageLength = 14), rownames = FALSE, colnames = format_matchup3, {you_table()})
  
  output$header_opp <- renderText({paste0(compare_opp(), "'s lineup")})
  
  output$opp_lineup <- DT::renderDataTable({opp_table()}, options = list(dom = "t", pageLength = 14), rownames = FALSE, colnames = format_matchup3)
  
  # HELPER FUNCTIONS
  # Create two functions for rendering value boxes
    # FORMALS
      # Value = category/variable name
      # Subtitle = abbreviation of the category/variable name
      # icon = which icon to use from font-awesome repository
  
  you_valuebox <- function(value, subtitle, icon){
    
    # Conditional color formatting which shows green if the manager is ahead in a stat or red if they are behind
    shinydashboard::renderValueBox({
      color <- if (value != c("turnovers")) { 
        ifelse({compare_table() %>% .[.$name == compare_you(), value] > compare_table() %>% .[.$name == compare_opp(), value]}, "green", "red")
      } else {
        ifelse({compare_table() %>% .[.$name == compare_you(), value] < compare_table() %>% .[.$name == compare_opp(), value]}, "green", "red")
      }
      
      shinydashboard::valueBox(
        value = compare_table() %>% .[.$name == compare_you(), value],
        subtitle = subtitle,
        icon = icon(icon, lib="font-awesome"),
        color = color
      )
    })
  }
  
  opp_valuebox <- function(value, subtitle, icon){
    
    # Conditional color formatting which shows green if the manager is ahead in a stat or red if they are behind
    shinydashboard::renderValueBox({
      color <- if (value != c("turnovers")) { 
        ifelse({compare_table() %>% .[.$name == compare_opp(), value] > compare_table() %>% .[.$name == compare_you(), value]}, "green", "red")
      } else {
        ifelse({compare_table() %>% .[.$name == compare_opp(), value] < compare_table() %>% .[.$name == compare_you(), value]}, "green", "red")
      }
      
      shinydashboard::valueBox(
        value = compare_table() %>% .[.$name == compare_opp(), value],
        subtitle = subtitle,
        icon = icon(icon, lib="font-awesome"),
        color = color
      )
    })
  }
  
  # Render value boxes for each manager and each variable being compared
  observeEvent(list(input$compare, input$panel_2), {
  
    output$you_name <- renderText({paste0(compare_you())})
    
    output$you_fg <- you_valuebox(value="field_goal", subtitle = "FG%", icon = NULL)
    output$you_ft <- you_valuebox(value="free_throw", subtitle = "FT%", icon = NULL)
    output$you_3pm <- you_valuebox(value="threes", subtitle = "3PM", icon = NULL)
    output$you_reb <- you_valuebox(value="rebounds", subtitle = "REB", icon = NULL)
    output$you_ast <- you_valuebox(value="assists", subtitle = "AST", icon = NULL)
    output$you_stl <- you_valuebox(value="steals", subtitle = "STL", icon = NULL)
    output$you_blk <- you_valuebox(value="blocks", subtitle = "BLK", icon = NULL)
    output$you_to <- you_valuebox(value="turnovers", subtitle = "TO", icon = NULL)
    output$you_pts <- you_valuebox(value="points", subtitle = "PTS", icon = NULL)
    
    output$opp_name <- renderText({paste0(compare_opp())})
    
    output$opp_fg <- opp_valuebox(value="field_goal", subtitle = "FG%", icon = NULL)
    output$opp_ft <- opp_valuebox(value="free_throw", subtitle = "FT%", icon = NULL)
    output$opp_3pm <- opp_valuebox(value="threes", subtitle = "3PM", icon = NULL)
    output$opp_reb <- opp_valuebox(value="rebounds", subtitle = "REB", icon = NULL)
    output$opp_ast <- opp_valuebox(value="assists", subtitle = "AST", icon = NULL)
    output$opp_stl <- opp_valuebox(value="steals", subtitle = "STL", icon = NULL)
    output$opp_blk <- opp_valuebox(value="blocks", subtitle = "BLK", icon = NULL)
    output$opp_to <- opp_valuebox(value="turnovers", subtitle = "TO", icon = NULL)
    output$opp_pts <- opp_valuebox(value="points", subtitle = "PTS", icon = NULL)
   }
  )
  
  # Render two tables which display the player names for each manager and have input controls to specify the number of games each player is expected to miss that week 
    # Use callback option to allow javascript code to be compiled that allows the select input widgets to be added directly into the table rows
  output$you_missing <- DT::renderDataTable(
    {you_lineup}, 
    escape=FALSE,
    colnames = format_matchup1,
    selection = "none",
    options = list(
      pageLength = 14,
      info = FALSE, 
      dom="t",
      preDrawCallback = JS('function() { Shiny.unbindAll(this.api().table().node()); }'),
      drawCallback = JS('function() { Shiny.bindAll(this.api().table().node()); } ')
    )
  )

  output$opp_missing <- DT::renderDataTable(
    {opp_lineup}, 
    escape=FALSE, 
    colnames = format_matchup1,
    selection = "none",
    options = list(
      pageLength = 14, 
      info = FALSE, 
      dom="t",
      preDrawCallback = JS('function() { Shiny.unbindAll(this.api().table().node()); }'),
      drawCallback = JS('function() { Shiny.bindAll(this.api().table().node()); } ')
    )
  )
  
  # Observe whether the user supplies new selections and update the missed games tables accordingly
  observe({
    # START with the FIRST managers lineup
    you_lineup <<- input_data %>% 
      .[.$name %in% c(input$manager1) & .$schedule %in% input$schedule1 & .$table %in% input$table2,] %>% 
      select("player_name", "games_scheduled")
    
    # Create a vector and fill it with the code which is used to create the select input widgets 
    select_missed <- vector(mode = "character", length = length(you_lineup$games_scheduled))
    for(i in seq_along(you_lineup$games_scheduled)){
      select_missed[i] <- as.character(
        selectInput(
        inputId=paste0("you_select_missed_", i), 
        label=NULL,
        width = "40px",
        choices=c(paste0(seq(from=0, to=max(you_lineup[["games_scheduled"]][[i]]))))
        )
      )
    }
    
  # Add the select input widgets to the first managers table
  you_lineup <<- tibble(you_lineup, missed_games = select_missed)
  you_proxy <- dataTableProxy("you_missing")
  replaceData(you_proxy, you_lineup)
  
  # REPEAT for the SECOND managers lineup
  opp_lineup <<- input_data %>% 
    .[.$name %in% c(input$manager2) & .$schedule %in% input$schedule1 & .$table %in% input$table2,] %>% 
    select("player_name", "games_scheduled")
  
  select_missed <- vector(mode = "character", length = length(opp_lineup$games_scheduled))
  for(i in seq_along(opp_lineup$games_scheduled)){
    select_missed[i] <- as.character(
      selectInput(
        inputId=paste0("opp_select_missed_", i), 
        label=NULL, 
        width = "40px",
        choices=c(paste0(seq(from=0, to=max(opp_lineup[["games_scheduled"]][[i]]))))
        )
    )
  }
  
  opp_lineup <<- tibble(opp_lineup, missed_games = select_missed)
  opp_proxy <- dataTableProxy("opp_missing")
  replaceData(opp_proxy,opp_lineup)
  })
}

# RUN APP
shinyApp(ui = ui, server = server)

