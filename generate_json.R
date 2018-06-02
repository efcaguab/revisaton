library(magrittr)
folder <- "scrapped-data"
out_folder <- "public_html/json-data"
mesas_data_files <- list.files(folder, recursive = T, full.names = T)
mesas_data_files_name_only <- list.files(folder, recursive = T, full.names = F)

read_add <- function(x, col_types){
  readr::read_csv(x, col_types = col_types) %>%
    dplyr::mutate(path = x)
}

mesas_data <- mesas_data_files %>%
  purrr::array_branch() %>%
  purrr::map_df(read_add, col_types = "cc")

mesas_data_sep <- mesas_data %>%
  dplyr::mutate(file_str = stringr::str_sub(href, 53, -1)) %>% 
  tidyr::separate(file_str, c("departamento", "municipio", "zona", "pre", "filename"), sep = "/", remove = F) %>% 
  tidyr::separate(filename, c("no", "e14", "pre", "x", "departamento2", "municipio2", "zona2", "xx", "puesto", "consecutivo", "x2", "xxx"), sep = "_") %>%
  tidyr::separate(path, c("base_dir", "dep_path", "mun_path", "zona_name", "pto_path"), sep = "/")%>%
  tidyr::separate(dep_path, c("departamento_path", "departamento_str_path"), sep = " - ") %>%
  tidyr::separate(departamento_str_path, c("departamento_name_path"), sep = " \\(", extra = "drop") %>%
  tidyr::separate(mun_path, c("municipio_path", "municipio_name_path"), sep = " - ") %>%
  tidyr::separate(zona_name, c("x", "zona_path"), sep = " ", remove = F) %>%
  tidyr::separate(pto_path, c("puesto_path", "puesto_name_path"), sep = " - ", extra = "merge") %>%
  tidyr::separate(mesa_name, c("xx", "mesa"), sep = " ", extra = "merge", remove = F) %>%
  dplyr::mutate(departamento_path = as.numeric(departamento_path), 
                departamento_path = sprintf("%02d", departamento_path), 
                municipio_path = as.numeric(municipio_path), 
                municipio_path = sprintf("%03d", municipio_path), 
                municipio_name_path = trimws(municipio_name_path),
                zona_path = as.numeric(zona_path), 
                zona_path = sprintf("%03d", zona_path),
                puesto_name_path = stringr::str_sub(puesto_name_path, end = -5)) %>%
  dplyr::filter(departamento == departamento_path, 
                municipio == municipio_path, 
                zona == zona_path, 
                puesto == puesto_path) %>%
  dplyr::mutate(d = duplicated(no, fromLast = F)) %>%
  dplyr::filter(!d) %>%
  dplyr::select(href, mesa_name, 
                departamento,
                departamento_name = departamento_name_path, 
                municipio, municipio_name = municipio_name_path,
                zona, zona_name,
                puesto, puesto_name = puesto_name_path, 
                mesa,
                file_str, no)
  
readr::write_csv(mesas_data_sep, "public_html/form-data.csv")

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
  df <- x %>% 
    dplyr::select(file_str, no, puesto_name, mesa)
  list(dep = x$departamento_name[1], mun = x$municipio_name[1], zon = x$zona_name[1],
       df = df)%>%
    jsonlite::toJSON(dataframe = "values") %>%
    jsonlite::minify() %>%
    write(file.path(this_folder, paste0(x$zona[1], ".json")))
}
l <- mesas_data_sep %>%
  split(list(.$departamento, .$municipio, .$zona))
nrowl <- l %>% purrr::map_dbl(nrow)
l <- l[nrowl > 0]
pb <- dplyr::progress_estimated(length(l))
o <- l %>%
    purrr::map(~{
      pb$tick()$print()
      save_puesto(., out_folder)
    })

