library('RODBC')
library('tidyverse')
library(rmarkdown)

Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
source("C:/stockviz/r/config.r")

options("scipen"=100)
options(stringsAsFactors = FALSE)

lcon <- odbcDriverConnect(sprintf("Driver={ODBC Driver 17 for SQL Server};Server=%s;Database=%s;Uid=%s;Pwd=%s;", ldbserver, ldbname, ldbuser, ldbpassword), case = "nochange", believeNRows = TRUE)

maxDt <- sqlQuery(lcon, "select max(time_stamp) from index_capm")[[1]]

indices <- sqlQuery(lcon, sprintf("select distinct index_name from index_capm where time_stamp = '%s'", maxDt))[,1]

#render("rp-risk.Rmd", output_file="rp-risk.html")
#q()

print("rendering indices...")
for(i in 1:length(indices)){
	
	iName <- indices[i]
	fName <- gsub("[^[:alnum:] ]| ", "", iName)
	
	print(iName)
	tryCatch({
		render("risk/rp-index-risk.Rmd", output_file=paste0("rp-", fName, ".html"), params=list(index_name = iName))
	}, error=function(e){print(e)})
}

print("rendering master page...")

render("rp-risk.Rmd", output_file="rp-risk.html")

