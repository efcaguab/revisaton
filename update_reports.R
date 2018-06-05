# master update
source("functions.R")
date_format <- '%I:%M%p %d %b, %Y'

# update counter
e14 <- readr::read_csv(file = "e14-main-form.csv") %>%
  dplyr::filter(nota != "666" | is.na(nota)) %>%
  tidyr::separate(Timestamp, c("t", "z"), sep = " GMT") %>%
  dplyr::mutate(z = paste0(z, "00"), 
                date = paste(t, z), 
                date = as.POSIXct(date, format = "%Y/%m/%d %I:%M:%S %p %z"))

per_id <- e14 %>%
  dplyr::group_by(id) %>%
  dplyr::summarise(n = n()) %>%
  dplyr::mutate(r = dplyr::percent_rank(n))

rate <- dplyr::n_distinct(e14$no) /(as.numeric(max(e14$date)) - as.numeric(min(e14$date)))

list(max_contribution_user = max(per_id$n), 
     mean_contribution_user = median(per_id$n), 
     rate = rate, 
     min_date = as.numeric(min(e14$date)) * 1000, 
     max_date = as.numeric(max(e14$date)) * 1000,
     n_submissions = dplyr::n_distinct(e14)) %>%
  jsonlite::toJSON() %>%
  write("public_html/json-data/global-vars.json")

# Datos & Resultados
latest_csv <- "e14-main-form.csv"
date<- get_date(latest_csv)
rmarkdown::render("public_html/datos/index.Rmd", 
                  params = list(author = paste("Ultima Actualizacion", date)))

## Reportes ##

# reporte 1
r1 <- list()
r1$title <- "Calentando motores"
r1$csv <- "e14-main-form_2018-06-04 02-12-15 +1200.csv"
r1$date <- get_date(r1$csv)
r1$subtitle <- paste("Primer reporte -", r1$date)
r1$desc <- "Ha pasado solo un día desde que que se lanzó esta iniciativa ciudadana y la respuesta ha sido increíble. Entre todos ya hemos revisado más de 1,300 que equivalen aproximadamente al 1.3% del total."
r1$href <- "primer-reporte-revsion-e14"
rmarkdown::render(file.path("public_html", "reportes", r1$href, "index.Rmd"), 
                  params = r1)

# reporte 2
r2 <- list()
r2$title <- "Transparencia, ese es el nombre del juego"
r2$csv <- "e14-main-form_2018-06-05 12-00-05 +1200.csv"
r2$date <- get_date(r2$csv)
r2$subtitle <- paste("Segundo reporte -", r2$date)
r2$desc <- "Para ser transparentes hay que rendir cuentas. A partir de este momento puedes visualizar y explorar los formularios que ya se han revisado. También puedes ver un resumen gráfico que se actualiza periódicamente."
r2$href <- "segundo-reporte-revision-e14"
rmarkdown::render(file.path("public_html", "reportes", r2$href, "index.Rmd"), 
                  params = r2)

# main
# list(reports = list(r1, r1)) %>%
  # yaml::write_yaml("public_html/reportes/_output.yaml")
rmarkdown::render("public_html/reportes/index.Rmd", 
                  params = list(reportes = list(r2,r1)))

