library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
render("drawdowns-US.Rmd", output_file="drawdowns-US.html")