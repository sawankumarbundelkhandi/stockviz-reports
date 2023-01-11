library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
libPath <- "C:/StockViz/public/reports/rmdlibs"
render("rp-IN.Rmd", output_file="rp-IN.html", output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))