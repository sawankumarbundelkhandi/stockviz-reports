library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
libPath <- "C:/StockViz/public/reports/rmdlibs"
render("drawdowns-US.Rmd", output_file="drawdowns-US.html", output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))