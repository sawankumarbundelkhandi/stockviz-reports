library(rmarkdown)
args <- commandArgs(trailingOnly=TRUE)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
libPath <- "C:/StockViz/public/reports/rmdlibs"
render("rp-mf.Rmd", output_file=paste0("analysis/rp-", args[1], ".html"), params=list(scheme_code = args[1], benchmark = args[2]), output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))