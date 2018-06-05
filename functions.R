get_date <- function(x){
  readr::read_csv(x) %>%
    dplyr::slice(nrow(.)) %$% 
    Timestamp %>%
    stringr::str_sub(end = -8) %>%
    as.POSIXct(format = "%Y/%m/%d %I:%M:%M %p", tz = "Pacific/Auckland") %>%
    format("%I:%M %p %d %b, %Y", tz = "America/Bogota")
}
