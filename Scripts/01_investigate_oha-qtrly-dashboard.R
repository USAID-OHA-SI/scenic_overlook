# PROJECT:  scenic_overlook
# AUTHOR:   A.Chafetz | USAID
# PURPOSE:  review tableau user data
# LICENSE:  MIT
# DATE:     2021-06-16
# UPDATED:

# DEPENDENCIES ------------------------------------------------------------

  library(tidyverse)
  library(glitr)
  library(glamr)
  library(ICPIutilities)
  library(extrafont)
  library(scales)
  library(tidytext)
  library(patchwork)
  library(ggtext)
  library(glue)
  library(vroom)
  library(lubridate)
  library(zoo)


# GLOBAL VARIABLES --------------------------------------------------------

  path <- "../Downloads/AIDS (OHA)_Custom SQL Query.csv"

  #https://sites.google.com/a/usaid.gov/gh-oha/home/oha-data-tools-resources/-oha-product-calendar?authuser=0
  updates_init <- c("2021-02-24", "2021-05-26") %>% as.Date()
  updates_clean <- c("2021-03-31") %>% as.Date()

# IMPORT ------------------------------------------------------------------

  df <- vroom(path)

  glimpse(df)

  df %>%
    distinct(action_type, event_type_name) %>%
    prinf()

  df_wkbk_cnt <- df %>%
    mutate(date_accessed = mdy_hms(created_at) %>% date) %>%
    filter(event_type_name  == "Access View",
           date_accessed >= "2020-10-01") %>%
    distinct(workbook_name, user_name, date_accessed) %>%
    count(workbook_name, date_accessed, name = "distinct_daily_users")


  tot_views <- df_wkbk_cnt %>%
    count(workbook_name, wt = distinct_daily_users, name = "total_views") %>%
    arrange(desc(total_views))

  df_wkbk_cnt %>%
    filter(workbook_name %in% (tot_views %>% slice_max(order_by = total_views, n = 20) %>% pull(workbook_name))) %>%
    ggplot(aes(date_accessed, distinct_daily_users)) +
    geom_col() +
    facet_wrap(~fct_reorder(workbook_name, distinct_daily_users, max, na.rm = TRUE, .desc = TRUE)) +
    si_style()


  df %>%
    distinct(workbook_name) %>%
    filter(str_detect(workbook_name, "Malawi COP"))

  df %>%
    filter(user_name == "achafetz") %>%
    distinct(workbook_name)


  df_tab_cnt <- df %>%
    mutate(date_accessed = mdy_hms(created_at) %>% date) %>%
    filter(event_type_name  == "Access View",
           date_accessed >= "2020-10-01") %>%
    distinct(workbook_name, view_name, user_name, date_accessed) %>%
    group_by(workbook_name, view_name) %>%
    mutate(distinct_total_users = n_distinct(user_name)) %>%
    count(workbook_name, view_name, date_accessed, distinct_total_users, name = "distinct_daily_users")

  df_tab_cnt %>%
    filter(workbook_name == "Quarterly OHA Tableau Dashboard",
           !view_name %in% c("Menu of Options", "Sheet 38")) %>%
    arrange(view_name, date_accessed) %>%
    group_by(workbook_name, view_name) %>%
    complete(date_accessed = seq.Date(min(date_accessed), max(date_accessed), by="day"),
             fill = list(distinct_daily_users = 0)) %>%
    fill(distinct_total_users, .direction = "downup") %>%
    ungroup() %>%
    mutate(view_name_lab = glue("{view_name}<br>disinct users={distinct_total_users}")) %>%
    group_by(workbook_name, view_name_lab) %>%
    mutate(rollingavg_7day = rollmean(distinct_daily_users, 7, fill = 0, align = c("right"))) %>%
    ungroup() %>%
    ggplot(aes(date_accessed, distinct_daily_users, group = view_name_lab)) +
    geom_vline(xintercept = updates_init, color = "black") +
    geom_col(alpha = .6) +
    geom_line(aes(y = rollingavg_7day), color = old_rose, size = 1) +
    facet_wrap(~fct_reorder(view_name_lab, distinct_total_users, max, na.rm = TRUE, .desc = TRUE)) +
    labs(x = NULL, y = NULL,
         subtitle = "count of distinct daily users accessing each sheet",
         title = "Quarterly OHA Tableau Dashboard | User Activity") +
    si_style() +
    theme(strip.text = element_markdown(),
          panel.spacing.x = unit(.5, "lines"),
          panel.spacing.y = unit(.5, "lines"))



