library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
libPath <- "C:/StockViz/public/reports/rmdlibs"
render("drawdowns.Rmd", output_file="drawdowns.html", output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))