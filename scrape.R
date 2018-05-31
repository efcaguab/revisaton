packrat::on()


# Functions ---------------------------------------------------------------

get_dropdown_values <- function(s, id){
  s %>%
    read_html() %>%
    html_node(id) %>%
    html_nodes("option") %>% {
      dplyr::data_frame(value = html_attr(., "value"), string = html_text(.))
    }
}

get_dropdown <- function(client, id, remove_first = F){
  v <- client$getPageSource() %>% 
    extract2(1) %>%
    get_dropdown_values(id)
  if(remove_first) v <- v[-1, ]
  return(v)
}

select_dropdown_child <- function(client, id, child){
  selection_string <- paste0(id, " > option:nth-child(", child, ")")
  el <- client$findElement(using = "css selector", 
                           value = selection_string)
  el$clickElement()
}

log_progress <- function(..., logfile = "logfile"){
  mes <- list(...)
  s <- do.call(paste, mes) %>%
    paste(Sys.time(), .)
  message(s)
  readr::write_lines(s, logfile, append = T)
}

wait <- function(x){
  Sys.sleep(runif(1,x-1,x+1))
}


library(rvest)
library(magrittr)
library(RSelenium)
library(methods)


# Parameters --------------------------------------------------------------

dep_id <- "#select_dep"
mun_id <- "#mpio"
zon_id <- "#zona"
pto_id <- "#pto"

scrap_folder <- "scrapped-data"
break_length <- 5
dep_start <- 1
dep_done <- 14

# Scrap data --------------------------------------------------------------

#initiate RSelenium. If it doesn't work, try other browser engines
rD <- rsDriver(port=4444L,browser="chrome")
remDr <- rD$client

remDr$open()
remDr$navigate("https://visor.e14digitalizacion.com")
wait(break_length * 4)
departamentos <- get_dropdown(remDr, dep_id)

# per departamento
for(l in (nrow(departamentos) - dep_done):dep_start){
  
  select_dropdown_child(remDr, dep_id, l)
  log_progress("selected departamento -", departamentos$string[l])
  wait(break_length)
  municipios <- get_dropdown(remDr, mun_id)
  
  # per municipio
  for(k in nrow(municipios):1){
    
    select_dropdown_child(remDr, mun_id, k)
    log_progress("selected municipio -", municipios$string[k])
    wait(break_length)
    zonas <- get_dropdown(remDr, zon_id, remove_first = T)
    
    # per zona
    for(j in nrow(zonas):1){
      
      select_dropdown_child(remDr, zon_id, j + 1)
      log_progress("selected zona -", zonas$string[j])
      wait(break_length)
      puestos <- get_dropdown(remDr, pto_id)
      
      this_folder <- file.path(scrap_folder, departamentos$string[l],
                               municipios$string[k], zonas$string[j])
      suppressWarnings(dir.create(this_folder, recursive = T))
      
      to_download <- list.files(this_folder) %>%
        tools::file_path_sans_ext() %>% {
          dplyr::filter(puestos, ! string %in% .)}
      
      if(nrow(to_download) == 0){
        log_progress("all puestos in this zone have already been downloaded")
      } 
      else {
        # per puesto
        for(i in nrow(to_download):1){
          select_dropdown_child(remDr, pto_id, i)
          log_progress("selected puesto -", puestos$string[i])
          wait(break_length)
          
          try({
            links <- remDr$getPageSource() %>% 
              extract2(1) %>%
              read_html() %>%
              html_node("#datatable-example") %>%
              html_node("tbody") %>%
              html_nodes("a") 
          
            df <- dplyr::data_frame(mesa_name = html_text(links), 
                                    href = html_attr(links, "href"))
            readr::write_csv(df, 
                             file.path(this_folder, paste0(puestos$string[i], ".csv")))
            log_progress(nrow(df), " mesas saved")
          }, silent = T)
        }
      }
    }
  }
}

remDr$close()
