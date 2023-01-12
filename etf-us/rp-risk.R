library('RODBC')
library('tidyverse')
library(rmarkdown)

Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
source("C:/stockviz/r/config.r")

options("scipen"=100)
options(stringsAsFactors = FALSE)

lconUs2 <- odbcDriverConnect(sprintf("Driver={ODBC Driver 17 for SQL Server};Server=%s;Database=%s;Uid=%s;Pwd=%s;", ldbserver, "StockVizUs2", ldbuser, ldbpassword), case = "nochange", believeNRows = TRUE)

#render("rp-country.Rmd", output_file="rp-country.html")
#render("rp-risk.Rmd", output_file="rp-risk.html")
#q()

renderEtfs <- function(){
	maxDt <- sqlQuery(lconUs2, "select max(time_stamp) from EQ_CAPM") [[1]]
	etfTickers <- sqlQuery(lconUs2, sprintf("select distinct symbol from eq_capm where time_stamp = '%s'", maxDt))[,1]

	for(i in 1:length(etfTickers)){
		
		iName <- etfTickers[i]
		fName <- gsub("[^[:alnum:] ]| ", "", iName)
		
		print(iName)
		tryCatch({
			render("risk/rp-etf-risk.Rmd", output_file=paste0("rp-", fName, ".html"), params=list(ticker = iName))
		}, error=function(e){print(e)})
	}
}

print("rendering etfs...")
renderEtfs()

print("rendering master page...")

render("rp-risk.Rmd", output_file="rp-risk.html")
render("rp-country.Rmd", output_file="rp-country.html")
