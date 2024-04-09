# PROJECT:  scenic_overlook
# PURPOSE:  identify top users and workbook/sheets
# AUTHOR:   A.Chafetz | USAID
# REF ID:   c5540397
# LICENSE:  MIT
# DATE:     2024-04-08
# UPDATED:  2024-04-09

# DEPENDENCIES ------------------------------------------------------------

  #general
  library(tidyverse)
  library(vroom)
  library(glue)
  #oha
  library(gagglr) ##install.packages('gagglr', repos = c('https://usaid-oha-si.r-universe.dev', 'https://cloud.r-project.org'))
  #viz extensions
  library(scales, warn.conflicts = FALSE)
  library(systemfonts)
  library(tidytext)
  library(patchwork)
  library(ggtext)
  #GDrive
  library(googlesheets4)


# GLOBAL VARIABLES --------------------------------------------------------

  ref_id <- "c5540397"  #a reference to be places in viz captions

  groups_id <- as_sheets_id("1qbWro_x_QwxavUsPrzUWfhouDF6NUff7VwVJzkn9jvo")

  wkbks_id <- as_sheets_id("1-9U7EVKDXwWH_iSSp0BGnhEdPzuBEqC1CcgRDvBAtGQ")

  load_secrets("email")

# IMPORT ------------------------------------------------------------------

  #tableau user data
  #run 00_import to get data first
  df_usage <- vroom("Data/Project-Historical-Event-Data_Office-of-HIVAIDS_20240408.zip")

  #user groups
  df_users <- c("data_comm", "siei") %>%
    set_names() %>%
    map_dfr(~read_sheet(groups_id,
                        sheet = .x),
            .id = "type")

  #OHA analytic products
  df_analytic_products <- read_sheet(wkbks_id)

# MUNGE -------------------------------------------------------------------

  #user groups
  df_users <- df_users %>%
    mutate(email = str_remove(email, "@usaid.gov"))

  data_comm <- df_users %>%
    filter(type == "data_comm") %>%
    pull()

  siei <- df_users %>%
    filter(type == "siei") %>%
    pull()

  #workbooks
  products <- df_analytic_products$workbook_name

  #convert to date/time type
  df_usage <- df_usage %>%
    mutate(across(c(created_at, user_login_at, user_logout_at),
                  \(x) mdy_hms(x, quiet = TRUE)))


  #remove unnecessary columns
  df_usage <- df_usage %>%
    select(-c(grant_allowed_by, is_failure, worker,
              datasource_id, duration_in_ms, project_id,
              type_id, user_id, view_id, workbook_id,
              user_or_group_name, permissions_granted))

  #remove duplication caused by user_or_group_name
  df_usage <- distinct(df_usage)

  #reorder
  df_usage <- df_usage %>%
    relocate(created_at, hist_event_id, action_type, event_type_name,
             project_name, workbook_name, view_name, datasource_name,
             friendly_name, user_name, user_login_at, user_logout_at,
             .after = 1) %>%
    arrange(created_at)

  #clean up friendly names -> make friendlier
  df_usage <- df_usage %>%
    mutate(friendly_name = str_replace(friendly_name, "(.*?),(.*?)(,)", "\\1\\2"), #remove extra comma for last name extaction
           has_comma = str_detect(friendly_name, ","),
           has_org = str_detect(friendly_name, "\\("),
           name_first = case_when(has_comma == FALSE ~ str_extract(friendly_name, "^\\w+"),
                                  has_org ~ str_extract(friendly_name, "(?<=, ).*(?=\\()") %>% str_trim(),
                                  has_comma ~ str_extract(friendly_name, "(?<=, ).*")),
           # name_first = str_remove(name_first, " [:alpha:]{1}\\.$"),
           name_last = case_when(has_comma ~ str_extract(friendly_name, "^.*(?=\\,)"),
                                 has_org ~ str_extract(friendly_name, "(?<= ).*(?=\\()"),
                                 has_comma == FALSE & has_org == FALSE ~ str_extract(friendly_name, "(?<= ).*")),
           name_full = glue("{name_first} {name_last}"),
           org_unit = str_extract(friendly_name, "(?<=\\().*(?=\\))"),
           .after = friendly_name) %>%
    select(-c(friendly_name, has_comma, has_org))

  #identify workbook owner in order to exclude from counts
  df_owner <- df_usage %>%
    filter(action_type %in% c("Publish", "Update")) %>%
    group_by(workbook_name) %>%
    filter(created_at == max(created_at, na.rm = TRUE)) %>%
    ungroup() %>%
    distinct(workbook_name, workbook_owner = user_name)

  #flag developers in data
  df_usage <- df_usage %>%
    left_join(df_owner, by = "workbook_name") %>%
    mutate(is_workbook_owner = user_name == workbook_owner) %>%
    select(-workbook_owner)

  #identify publish times to drop automatic views
  df_publish_view_exclude <- df_usage %>%
    filter(event_type_name == "Publish Workbook") %>%
    arrange(created_at) %>%
    distinct(workbook_name, name_full, pd_start = created_at) %>%
    mutate(pd_end = pd_start + minutes(1),
           pd_start = pd_start - seconds(2),
           is_publish_view = TRUE)

  #identify qc windows to exclude for SI/data community usage
  df_qc <- pepfar_data_calendar %>%
    select(msd_release) %>%
    mutate(qc_close = msd_release + days(7),
           msd_release = msd_release + days(1),
           across(c(msd_release, qc_close), as_datetime),
           is_qc_window = TRUE)

  #create flags - auto view, cover page, membership
  df_usage <- df_usage %>%
    left_join(df_publish_view_exclude,
              join_by(workbook_name, name_full,
                      between(created_at, pd_start, pd_end))) %>%
    select(-starts_with("pd")) %>%
    mutate(is_publish_view = ifelse(is.na(is_publish_view), FALSE, is_publish_view),
           is_cover_page = str_detect(view_name,
                                 "^Cover |^Cover$|CoverPage|Intro|Contents|0\\.Home|Country Overview|Introduction|Notes|$Title"),
           is_cover_page = ifelse(is.null(is_cover_page), FALSE, is_cover_page) %>%
           is_data_comm = user_name %in% data_comm,
           is_siei = user_name %in% siei,
           is_key_wkbk = workbook_name %in% products)

  #create flags - qc window
  df_usage <- df_usage %>%
    left_join(df_qc,
              join_by(between(created_at, msd_release, qc_close))) %>%
    select(-c(msd_release, qc_close)) %>%
    mutate(is_qc_window = ifelse(is.na(is_qc_window), FALSE, is_qc_window))



# VIZ ---------------------------------------------------------------------

  #what are the highest visited workbooks?
  df_usage %>%
    filter(event_type_name == "Access View",
           is_key_wkbk,
           !is_publish_view,
           !is_cover_page,
           !(is_data_comm & is_qc_window),) %>%
    distinct(hist_event_id, name_full, workbook_name, created_at) %>%
    count(workbook_name, sort = TRUE) %>%
    mutate(share = n/sum(n),
           share_cum = cumsum(share))

  #what are the highest visited workbooks?
  df_usage %>%
    filter(event_type_name == "Access View",
           is_key_wkbk,
           !is_publish_view,
           !is_cover_page,
           !(is_data_comm & is_qc_window)) %>%
    distinct(hist_event_id, name_full, workbook_name, view_name, created_at) %>%
    count(workbook_name, view_name, sort = TRUE) %>%
    mutate(share = n/sum(n),
           share_cum = cumsum(share))

  #who are the top users?
  df_usage %>%
    filter(event_type_name == "Access View",
           is_key_wkbk,
           !is_publish_view,
           !is_cover_page,
           !(is_data_comm & is_qc_window),
           # !is_siei
    ) %>%
    distinct(hist_event_id, name_full, is_data_comm, workbook_name, view_name, created_at) %>%
    count(name_full, is_data_comm, sort = TRUE, name = "views") %>%
    mutate(share = views/sum(views),
           share_cum = cumsum(share)) %>%
    print(n = 25)

   df_top <- df_usage %>%
     filter(event_type_name == "Access View",
            is_key_wkbk,
            !is_publish_view,
            !is_cover_page,
            !(is_data_comm & is_qc_window),
            # !is_siei
     ) %>%
     distinct(hist_event_id, name_full, is_data_comm, workbook_name, created_at) %>%
     count(workbook_name, name_full, is_data_comm, sort = TRUE, name = "views")

   # df_top <- df_top %>%
   #   group_by(workbook_name) %>%
   #   mutate(views_wkbk = sum(views)) %>%
   #   ungroup() %>%
   #   group_by(name_full) %>%
   #   mutate(views_user = sum(views)) %>%
   #   ungroup()

   df_top <- df_top %>%
     mutate(workbook_name = fct_lump(workbook_name, 25, w = views),
            name_full = name_full %>%
              as.character() %>%
              str_trim %>%
              fct_lump(25, w = views)) %>%
     count(workbook_name, name_full, wt = views, name = "views")

   df_top %>%
     count(workbook_name, wt = views)

   df_top %>%
     count(name_full, wt = views) %>%
     arrange(name_full)

   levels(df_top$workbook_name)
   df_top %>%
     # filter(workbook_name != "Other",
     #        name_full != "Other"
     #   ) %>%
     mutate(name_full = fct_reorder(name_full, views, sum),
            workbook_name = fct_reorder(workbook_name, views, sum)
            ) %>%
     ggplot(aes(workbook_name, name_full)) +
     geom_tile(aes(fill = views)) +
     geom_text(aes(label = views)) +
     scale_x_discrete(position = "top") +
     labs(x = NULL, y = NULL) +
     si_style_nolines() +
     theme(axis.text.x = element_text(angle = 90,
                                      hjust = 0))
