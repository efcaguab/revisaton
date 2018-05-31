folder <- "scrapped-data"

# get all files
mesas_data_files <- list.files(folder, recursive = T, full.names = T)

# determine duplicates
duplicates <- mesas_data_files %>%
  purrr::array_branch() %>%
  purrr::map(stringr::str_split, "/") %>%
  purrr::map(~ purrr::map(., function(x) x[[5]])) %>%
  unlist() %>% {
    d1 <- duplicated(., fromLast = T)
    d2 <- duplicated(., fromLast = F)
    d1 | d2
  }
  
message(sum(duplicates), " mesas to remove")

# remove duplicates
mesas_data_files[duplicates]

# %>%
  # file.remove()
