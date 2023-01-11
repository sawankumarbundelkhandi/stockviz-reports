library('RODBC')
library('tidyverse')
library(rmarkdown)

Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
source("C:/stockviz/r/config.r")
libPath <- "C:/StockViz/public/reports/rmdlibs"

options("scipen"=100)
options(stringsAsFactors = FALSE)

lcon <- odbcDriverConnect(sprintf("Driver={ODBC Driver 17 for SQL Server};Server=%s;Database=%s;Uid=%s;Pwd=%s;", ldbserver, ldbname, ldbuser, ldbpassword), case = "nochange", believeNRows = TRUE)

maxDt <- sqlQuery(lcon, "select max(time_stamp) from bhav_index")[[1]]

indices <- sqlQuery(lcon, sprintf("select distinct index_name from index_capm where time_stamp = '%s'", maxDt))[,1]

#render("rp-risk.Rmd", output_file="rp-risk.html", output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))
#q()

print("rendering indices...")
for(i in 1:length(indices)){
	
	iName <- indices[i]
	fName <- gsub("[^[:alnum:] ]| ", "", iName)
	
	print(iName)
	tryCatch({
		render("rp-index-risk.Rmd", output_file=paste0("risk/rp-", fName, ".html"), params=list(index_name = iName), output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))
	}, error=function(e){print(e)})
}

print("rendering master page...")

render("rp-risk.Rmd", output_file="rp-risk.html", output_options=list(html_document = list(self_contained = FALSE, lib_dir = libPath)))

