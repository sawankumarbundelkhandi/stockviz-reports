library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
libPath <- "C:/StockViz/public/reports/rmdlibs"
render("commodities/rp-cmdy.Rmd", output_file="rp-cmdy.html", output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))
render("bonds/rp-bnd.Rmd", output_file="rp-bnd.html", output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))
render("currencies/rp-cur.Rmd", output_file="rp-cur.html", output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))