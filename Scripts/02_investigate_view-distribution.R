# PROJECT:  groundhogday
# AUTHOR:   A.Chafetz | USAID
# PURPOSE:  review Tableau Usage
# LICENSE:  MIT
# DATE:     2022-01-31
# UPDATED: 

# DEPENDENCIES ------------------------------------------------------------
  
  library(tidyverse)
  library(glitr)
  library(glamr)
  library(gophr)
  library(extrafont)
  library(scales)
  library(tidytext)
  library(patchwork)
  library(ggtext)
  library(glue)
  library(vroom)
  library(lubridate)
  library(zoo)
  library(janitor)

# GLOBAL VARIABLES --------------------------------------------------------
  
  #export from https://tableau.usaid.gov/#/projects/218
  path <- "../../../Downloads/Project Historical Event Data - Office of HIVAIDS.csv"
  
  #date accessed
  date_updated <- file.info(path)$ctime %>% as.Date()
  
# IMPORT ------------------------------------------------------------------
  
  df_usage <- vroom(path)
  

# MUNGE -------------------------------------------------------------------

  #clean up exported names to make machine readable
  df_usage <- clean_names(df_usage)
  
  #covert created_at to date
  df_usage <-  mutate(df_usage, created_at = mdy_hms(created_at))
  
  #identify workbook onwer in order to exclude from counts
  df_owner <- df_usage %>% 
    filter(action_type %in% c("Publish", "Update")) %>% 
    group_by(workbook_name) %>%
    filter(created_at == max(created_at, na.rm = TRUE)) %>% 
    ungroup() %>% 
    distinct(workbook_name, workbook_owner = user_name)  

  #flag developers in data
  df_usage <- left_join(df_usage, df_owner)  

  #
  glimpse(df_usage)
  
  df_usage %>% 
    count(action_type, event_type_name) %>% 
    prinf()
  
  df_access <- df_usage %>% 
    filter(event_type_name == "Access View") %>% 
    mutate(is_workbook_owner = user_name == workbook_owner) %>% 
    distinct(project_name, workbook_name, user_name, friendly_name, view_name, created_at, is_workbook_owner) %>% 
    arrange(workbook_name, user_name, created_at, view_name) %>%
    group_by(user_name, workbook_name, view_name) %>% 
    mutate(unique_view = created_at == min(created_at) | 
             created_at > (lag(created_at) + minutes(15))) %>% 
    ungroup() %>% 
    group_by(user_name) %>% 
    mutate(unique_session = created_at == min(created_at) | 
             created_at > (lag(created_at) + minutes(15))) %>% 
    ungroup() %>% 
    mutate(unique_session = ifelse(is.na(unique_session), TRUE, unique_session))

  
  #date range
  date_range <- df_access %>% 
    summarise(min_date = min(created_at, na.rm = TRUE),
              max_date = max(created_at, na.rm = TRUE)) %>% 
    mutate(range = glue("[{as.Date(min_date) %>% format('%B %d, %Y')} - {as.Date(max_date) %>% format('%B %d, %Y')}]")) %>% 
    pull()
  
  #full list of views
  df_full_views <- df_usage %>% 
    filter(event_type_name == "Publish View") %>% 
    distinct(workbook_name, view_name)
  
  #distinct views
  df_unique_views <- df_access %>% 
    filter(is_workbook_owner == FALSE) %>% 
    bind_rows(df_full_views) %>% 
    count(workbook_name, view_name, wt = unique_view, name = "n_unique_views")
  
  #distinct users
  df_unique_users <-df_access %>% 
    filter(is_workbook_owner == FALSE,
           unique_view == TRUE) %>%
    distinct(workbook_name, view_name, user_name) %>% 
    count(workbook_name, view_name, name = "n_unique_users")
  
  full_join(df_unique_views, df_unique_users) %>% 
    mutate(n_unique_users = ifelse(is.na(n_unique_users), 0, n_unique_users)) %>% 
    ggplot(aes(x = n_unique_users)) +
    geom_histogram(binwidth = 1)
  
  df_usage %>%
    # filter(user_name == 'achafetz',
    #        action_type == 'Publish',
    #        workbook_name == 'HFR Dashboard') %>% 
    count(action_type, event_type_name) %>% 
    prinf()
  

    