library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
render("rp-US.Rmd", output_file="rp-US.html")