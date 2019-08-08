library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:\Program Files\Pandoc\")
render("drawdowns.Rmd", output_file="drawdowns.html")