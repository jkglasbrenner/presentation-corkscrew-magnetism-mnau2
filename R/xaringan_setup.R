project_img_dir <- fs::path_rel(
  fs::path(here::here("img"))
)

knitr::opts_chunk$set(
  echo = TRUE,
  eval = TRUE,
  warning = FALSE,
  message = FALSE,
  cache = FALSE,
  dev = "svg",
  dpi = 120,
  fig.align = "center",
  fig.asp = 0.618,
  fig.path = glue::glue("{project_img_dir}/"),
  fig.width = 5,
  out.width = "70%"
)

options(
  htmltools.dir.version = FALSE,
  servr.daemon = TRUE
)
