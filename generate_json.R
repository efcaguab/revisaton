library(magrittr)
folder <- "scrapped-data"
out_folder <- "public_html/json-data"
mesas_data_files <- list.files(folder, recursive = T, full.names = T)
mesas_data_files_name_only <- list.files(folder, recursive = T, full.names = F)

mesas_data <- mesas_data_files %>%
  purrr::array_branch() %>%
  purrr::map_df(readr::read_csv, col_types = "cc")

mesas_data_sep <- mesas_data %>%
  dplyr::mutate(file_str = stringr::str_sub(href, 53, -1)) %>% 
  tidyr::separate(file_str, c("departamento", "municipio", "zona", "pre", "filename"), sep = "/", remove = F) %>% 
  tidyr::separate(filename, c("no", "e14", "pre", "x", "departamento2", "municipio2", "zona2", "xx", "puesto", "consecutivo", "x2", "xxx"), sep = "_") %>%
  dplyr::distinct()

simplify <- . %>% dplyr::summarise(n = n()) %>% 
  jsonlite::toJSON(dataframe = "values") %>%
  jsonlite::minify()

# master by departamentos
mesas_data_sep %>%
  dplyr::group_by(departamento) %>%
  simplify() %>%
  write(file.path(out_folder, "dep.json"))

# by municipio
save_mun <- function(x, out_folder){
  this_folder <- file.path(out_folder, "dep")
  suppressWarnings(dir.create(this_folder, recursive = T))
  x %>% dplyr::group_by(municipio) %>%
    simplify() %>%
    write(file.path(this_folder, paste0(x$departamento[1], ".json")))
}
o <- mesas_data_sep %>%
  split(.$departamento) %>%
  purrr::map(save_mun, out_folder)
 
# by zone
save_zone <- function(x, out_folder){
  this_folder <- file.path(out_folder, "mun", x$departamento[1]) 
  suppressWarnings(dir.create(this_folder, recursive = T))
  x %>% dplyr::group_by(zona) %>%
    simplify() %>%
    write(file.path(this_folder, paste0(x$municipio[1], ".json")))
}
o <- mesas_data_sep %>%
  split(list(.$departamento, .$municipio)) %>%
  purrr::map(save_zone, out_folder)

# by puesto
save_puesto <- function(x, out_folder){
  this_folder <- file.path(out_folder, "pto", x$departamento[1], x$municipio[1]) 
  suppressWarnings(dir.create(this_folder, recursive = T))
  x %>% 
    dplyr::select(file_str, no) %>%
    jsonlite::toJSON(dataframe = "values") %>%
    jsonlite::minify() %>%
    write(file.path(this_folder, paste0(x$zona[1], ".json")))
}
l <- mesas_data_sep %>%
  split(list(.$departamento, .$municipio, .$zona))
pb <- dplyr::progress_estimated(length(l))
o <- l %>%
    purrr::map(~{
      pb$tick()$print()
      save_puesto(., out_folder)
    })

