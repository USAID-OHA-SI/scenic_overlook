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

  load_secrets("email")
  data_comm <- c("achafetz@usaid.gov", "ayansaneh@usaid.gov", "alerichardson@usaid.gov", "aiqudus@usaid.gov", "aschmale@usaid.gov", "amakulec@usaid.gov", "adjapovicscholl@usaid.gov", "abuschur@usaid.gov", "amompe@usaid.gov", "bkagniniwa@usaid.gov", "bbetz@usaid.gov", "cmanoukian@usaid.gov", "cloukas@usaid.gov", "cargonzalez@usaid.gov", "cnichols@usaid.gov", "chknight@usaid.gov", "dsong@usaid.gov", "dcollison@usaid.gov", "damin@usaid.gov", "elcallahan@usaid.gov", "elhart@usaid.gov", "erdunlap@usaid.gov", "fabarcarealegeno@usaid.gov", "gsarfaty@usaid.gov", "gmorgan@usaid.gov", "iborces@usaid.gov", "ivferrer@usaid.gov", "jmontespenaloza@usaid.gov", "jbuttolph@usaid.gov", "jehoover@usaid.gov", "jrose@usaid.gov", "jstephens@usaid.gov", "jwun@usaid.gov", "jmungurerebaker@usaid.gov", "jodavis@usaid.gov", "jkamunyori@usaid.gov", "jflores@usaid.gov", "jkohler@usaid.gov", "ksrikanth@usaid.gov", "kfertakis@usaid.gov", "kabuelgasim@usaid.gov", "kkarimovahashkes@usaid.gov", "kobradley@usaid.gov", "laavery@usaid.gov", "lbaraki@usaid.gov", "lkovacevic@usaid.gov", "mzendt@usaid.gov", "mschneider@usaid.gov", "mau@usaid.gov", "marsbailey@usaid.gov", "marsbailey@usaid.gov", "msattah@usaid.gov", "medouglas@usaid.gov", "meapeterson@usaid.gov", "mdessie@usaid.gov", "mhartig@usaid.gov", "myep@usaid.gov", "npetrovic@usaid.gov", "nmcdavid@usaid.gov", "nmaina@usaid.gov", "nagbodo@usaid.gov", "rbricenorobaugh@usaid.gov", "reross@usaid.gov", "rbhattacharjee@usaid.gov", "rgriffin@usaid.gov", "rakter@usaid.gov", "smahadevan@usaid.gov", "tessam@usaid.gov", "tmukherjee@usaid.gov", "vbiryukova@usaid.gov", "wjose@usaid.gov")
  data_comm <- str_remove(data_comm, "@usaid.gov")

  siei <- c("achafetz@usaid.gov", "araji@usaid.gov", "aiqudus@usaid.gov", "amakulec@usaid.gov", "adjapovicscholl@usaid.gov", "aanandhapriya@usaid.gov", "abuschur@usaid.gov", "amompe@usaid.gov", "bkagniniwa@usaid.gov", "cmanoukian@usaid.gov", "cloukas@usaid.gov", "cnichols@usaid.gov", "chknight@usaid.gov", "dsong@usaid.gov", "dcollison@usaid.gov", "dcamara@usaid.gov", "dsesay@usaid.gov", "damin@usaid.gov", "elhart@usaid.gov", "erdunlap@usaid.gov", "gsarfaty@usaid.gov", "gha@usaid.gov", "gmorgan@usaid.gov", "jbuehler@usaid.gov", "jmontespenaloza@usaid.gov", "jbuttolph@usaid.gov", "jstephens@usaid.gov", "jrose@usaid.gov", "jmungurerebaker@usaid.gov", "jkamunyori@usaid.gov", "jkohler@usaid.gov", "ksrikanth@usaid.gov", "kkarimovahashkes@usaid.gov", "lbaraki@usaid.gov", "lkovacevic@usaid.gov", "lhaile@usaid.gov", "mzendt@usaid.gov", "mschneider@usaid.gov", "msattah@usaid.gov", "mdessie@usaid.gov", "nmcdavid@usaid.gov", "nmaina@usaid.gov", "nagbodo@usaid.gov", "oogunwobi@usaid.gov", "rbhattacharjee@usaid.gov", "rakter@usaid.gov", "smahadevan@usaid.gov", "tessam@usaid.gov", "vbiryukova@usaid.gov", "wjose@usaid.gov", "whanna@usaid.gov", "mau@usaid.gov")
  siei <- str_remove(siei, "@usaid.gov")

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

  #convert to date/time type
  df_usage <- df_usage %>%
    mutate(across(c(created_at, user_login_at, user_logout_at),
                  \(x) mdy_hms(x, quiet = TRUE)))


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
    distinct(workbook_name, friendly_name, pd_start = created_at) %>%
    mutate(pd_end = pd_start + minutes(1),
           pd_start = pd_start - seconds(2),
           is_publish_view = TRUE)

  #identify qc windows to exclude for SI/data community usage
  df_qc <- pepfar_data_calendar %>%
    select(msd_release) %>%
    mutate(qc_close = msd_release + days(7),
           msd_release = msd_release + days(1),
           across(c(msd_release, qc_close), as_datetime),
           is_qc_window = TRUE,
           action_type = "Access")

  #create flags - auto view, cover page, membership
  df_usage <- df_usage %>%
    left_join(df_publish_view_exclude,
              join_by(workbook_name, friendly_name,
                      between(created_at, pd_start, pd_end))) %>%
    select(-starts_with("pd")) %>%
    mutate(is_publish_view = ifelse(is.na(is_publish_view), FALSE, is_publish_view),
           is_cover_page = str_detect(view_name,
                                 "^Cover |^Cover$|CoverPage|Intro|Contents|0\\.Home|Country Overview|Introduction|Notes|$Title"),
           is_data_comm = user_name %in% data_comm,
           is_siei = user_name %in% siei)

  #create flags - qc window
  df_usage2 <- df_usage %>%
    left_join(df_qc,
              join_by(action_type,
                      between(created_at, msd_release, qc_close))) %>%
    select(-c(msd_release, qc_close)) %>%
    mutate(is_qc_window = ifelse(is.na(is_qc_window), FALSE, is_publish_view))


  df_usage2 %>%
    filter(action_type == "Access",
           between(created_at, as.Date("2023-11-15"), as.Date("2023-12-15"))) %>%
    count(day(created_at), is_qc_window) %>%
    pivot_wider(names_from = is_qc_window, values_from = n) %>%
    prinf()


  df_views <- df_usage %>%
    filter(event_type_name == "Access View") %>%
    distinct(hist_event_id, friendly_name, workbook_name, view_name, created_at)




  df_views %>%
     filter(!is_publish_view) %>%
     count(workbook_name, view_name, sort = TRUE) %>%
     mutate(share = n/sum(n))


   df_usage %>%
     filter(event_type_name == "Access View",
            !is_publish_view,
            !is_cover_page,
            !(is_data_comm & is_qc_window),
            ) %>%
     distinct(hist_event_id, friendly_name, workbook_name, view_name, created_at) %>%
     count(friendly_name, sort = TRUE, name = "views") %>%
     mutate(share = views/sum(views)) %>%
     print(n = 25)

# VIZ ---------------------------------------------------------------------
