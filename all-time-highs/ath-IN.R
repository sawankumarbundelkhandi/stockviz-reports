library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
libPath <- "C:/StockViz/public/reports/rmdlibs"
render("ath-IN.Rmd", output_file="ath-IN.html", output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))