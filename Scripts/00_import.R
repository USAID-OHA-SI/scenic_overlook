# PROJECT:  scenic_overlook
# AUTHOR:   A.Chafetz | USAID
# PURPOSE:  setup and access data
# LICENSE:  MIT
# DATE:     2022-02-01
# UPDATED:

# DEPENDENCIES ------------------------------------------------------------

  library(tidyverse)
  library(glamr)
  library(googledrive)
  library(lubridate)

# GLOBAL VARIABLES --------------------------------------------------------

  load_secrets("email")

  #location of
  drive_data_folder <- as_id('1cBQVXjuwumVGMfGfSHfb-uFB6EyIliIi')


# SETUP FOLDER STRUCTURE --------------------------------------------------

  folder_setup()

# IMPORT ------------------------------------------------------------------

  #identify the latest dataset to download
  drive_data_latest <- drive_ls(drive_data_folder) %>%
    mutate(modified_time = map_chr(drive_resource, "modifiedTime") %>%
                    ymd_hms(tz = "EST", quiet = TRUE),
           name = name %>%
             str_replace_all(" - ", "_") %>%
             str_replace_all(" ", "-")) %>%
    select(name, id, modified_time) %>%
    filter(modified_time == max(modified_time))


  #download
  drive_download(drive_data_latest$id,
                 file.path("Data", drive_data_latest$name))
