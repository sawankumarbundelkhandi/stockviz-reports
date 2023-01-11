library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
libPath <- "C:/StockViz/public/reports/rmdlibs"
render("52wk-US.Rmd", output_file="52wk-US.html", output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))