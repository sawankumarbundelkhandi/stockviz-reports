library('RODBC')
library('tidyverse')
library('rmarkdown')

Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
source("C:/stockviz/r/config.r")
source("C:/stockviz/r/plot.common.r")

source("../common/fan-chart.R")

plotPath <- "risk/plots"
idPath <- "../"

library('RODBC')
library('quantmod')
library('PerformanceAnalytics')

library('tidyverse')
library('lubridate')
library('ggthemes')
library('reshape2')
library('viridis')
library('DT')
library('ggrepel')

library('scales')
library('sysfonts')
library('showtext')
library('ggradar') # remotes::install_github("ricardo-bion/ggradar")

font_add_google("Kanit", "kanit")
#font_add_google("Lobster Two", "lobstertwo")
font_add_google("Roboto", "roboto")
showtext_auto()


options("scipen"=100)
options(stringsAsFactors = FALSE)

lcon <- odbcDriverConnect(sprintf("Driver={ODBC Driver 17 for SQL Server};Server=%s;Database=%s;Uid=%s;Pwd=%s;", ldbserver, ldbname, ldbuser, ldbpassword), case = "nochange", believeNRows = TRUE)
lconUs2 <- odbcDriverConnect(sprintf("Driver={ODBC Driver 17 for SQL Server};Server=%s;Database=%s;Uid=%s;Pwd=%s;", ldbserver, "StockVizUs2", ldbuser, ldbpassword), case = "nochange", believeNRows = TRUE)

#render("rp-country.Rmd", output_file="rp-country.html")
#render("rp-risk.Rmd", output_file="rp-risk.html")
#q()

spyMaxDt <- sqlQuery(lconUs2, "select max(time_stamp) from BHAV_EQ_TD where symbol='SPY'")[[1]]
maxDt <- sqlQuery(lconUs2, "select max(time_stamp) from EQ_CAPM") [[1]]

plottedTickers <- c()
createPlots <- function(){
	etfTickers <- sqlQuery(lconUs2, sprintf("select distinct symbol from eq_capm where time_stamp = '%s'", maxDt))[,1]
	etfMetaDf <- sqlQuery(lcon, "select SYMBOL, ASSET_CLASS from ETF_META")
	
	for(i in 1:length(etfTickers)){
		ticker <- etfTickers[i]
		fName <- gsub("[^[:alnum:] ]| ", "", ticker)
		
		etfName <- sqlQuery(lcon, sprintf("select FUND from ETF_META where symbol='%s'", ticker))[[1]]
		
		etfMaxDate <- sqlQuery(lconUs2, sprintf("select max(time_stamp) from BHAV_EQ_TD where symbol='%s'", ticker))[[1]]
		etfMinDate <- sqlQuery(lconUs2, sprintf("select min(time_stamp) from BHAV_EQ_TD where symbol='%s'", ticker))[[1]]
		
		if (etfMaxDate != spyMaxDt){
			print("STALE ETF!!!")
			next
		}

		etfMinDate <- as.Date(sprintf("%d-01-01", year(etfMinDate)+1))

		tryCatch({
			iDf1 <- sqlQuery(lconUs2, sprintf("select c, time_stamp from BHAV_EQ_TD where symbol='%s' and time_stamp >= '%s'", ticker, etfMinDate))
			iXts <- xts(iDf1[,1], iDf1[,2])

			retDaily <- dailyReturn(iXts)
			retAnn <- annualReturn(iXts)

			names(retDaily) <- c(ticker)
			names(retAnn) <- c(ticker)
			
			Common.PlotCumReturns(retDaily, ticker, etfName, sprintf("%s/%s.cumret.png", plotPath, fName))

			toPlotAnn <- data.frame(retAnn*100)
			toPlotAnn$Y <- year(index(retAnn))

			maxYear <- length(unique(toPlotAnn$Y))
			toPlotAnn <- melt(toPlotAnn, id='Y')
			minRet <- min(toPlotAnn$value)
			toPlotAnn$Y <- factor(toPlotAnn$Y, levels = unique(toPlotAnn$Y))

			ggplot(toPlotAnn, aes(x=Y, y=value, fill=variable)) +
				theme_economist() +
				geom_bar(stat = "identity", position = position_dodge()) +
				geom_text_repel(aes(label = sprintf('%.2f', value)), position = position_dodge(0.9)) +
				scale_fill_viridis(discrete = TRUE) +
				labs(x = "Year", y="Returns (%)", fill="", color="", size="", title=sprintf("%s", ticker), subtitle=sprintf("Annual Returns [%s:%s]", first(index(retDaily)), last(index(retDaily)))) +
				annotate("text", x=maxYear, y=minRet, label = "@StockViz", hjust=1, vjust=0, col="white", cex=6, fontface = "bold", alpha = 0.8)
				
			ggsave(sprintf("%s/%s.annret.png", plotPath, fName), width=12, height=6)
				
			fanPlot <- common.CreateFanChart(iDf1, ticker, sprintf("%d:%s", min(year(iDf1$time_stamp)), max(iDf1$time_stamp)))
			ggsave(sprintf("%s/%s.fan.png", plotPath, fName), fanPlot, width=12, height=6)
			
			
			metricMap <- read.csv(paste0(idPath, "/metric_map.csv"))

			statsDf <- sqlQuery(lconUs2, sprintf("select SYMBOL, ID, VAL from EQ_CAPM where time_stamp = '%s'", spyMaxDt)) 

			ac <- etfMetaDf[etfMetaDf$SYMBOL == ticker,]$ASSET_CLASS[1]

			dataDf <- statsDf %>% inner_join(etfMetaDf, by='SYMBOL') %>% filter(ASSET_CLASS == ac) %>% select(SYMBOL, ID, VAL)

			statsTibs <- dataDf %>% 
					pivot_wider(names_from=ID, values_from=VAL) %>% 
					mutate_at(vars(-SYMBOL), rescale)
				
			avgTibs <- statsTibs %>% summarize_at(vars(-SYMBOL), mean, na.rm=T) %>% mutate(SYMBOL='Average')

			toPlot <- statsTibs %>% filter(SYMBOL==ticker) %>% mutate(SYMBOL = 'ETF') %>% bind_rows(avgTibs) %>% select(where(~!any(is.na(.x)))) %>% as.data.frame()
						
			rplot <- ggradar(plot.data = toPlot,
					font.radar = "roboto",
					grid.label.size = 5,  # Affects the grid annotations (0%, 50%, etc.)
					axis.label.size = 8, # Afftects the names of the variables
					group.point.size = 3   # Simply the size of the point 
				  ) +
				labs(title = ticker, tag=paste("@StockViz", spyMaxDt)) + 
				theme(
				  plot.background = element_rect(fill = "#fbf9f4", color = "#fbf9f4"),
				  panel.background = element_rect(fill = "#fbf9f4", color = "#fbf9f4"),
				  plot.title.position = "plot", # slightly different from default
				  plot.title = element_text(
						family = "noto", 
						size = 38,
						color = "#2a475e"
					),
				  plot.tag = element_text(
						family = "kanit", 
						size = 16,
						color = "lightgrey",
					),
				  plot.tag.position = "bottom"
				) +
				theme(
					legend.position = c(1, 0),  
					legend.justification = c(1, 0),
					legend.text = element_text(size = 24, family = "roboto"),
					legend.key = element_rect(fill = NA, color = NA),
					legend.background = element_blank()
				)
			
			ggsave(sprintf("%s/%s.radar.png", plotPath, fName), rplot, width=5.7*2, height=5*2)
			
			plottedTickers <- c(plottedTickers, ticker)
		}, error=function(e){print(e)})
	}
}

renderEtfs <- function(){
	if(length(plottedTickers) == 0){
		plotFiles <- list.files(plotPath, pattern="*.png")
		plottedTickers <- unique(unlist(lapply(strsplit(plotFiles, ".", fixed=T), `[[`, 1)))
	}
	
	for(i in 1:length(plottedTickers)){
		
		iName <- plottedTickers[i]
		fName <- gsub("[^[:alnum:] ]| ", "", iName)
		
		print(iName)
		tryCatch({
			render("risk/rp-etf-risk.Rmd", output_file=paste0("rp-", fName, ".html"), params=list(ticker = iName, fName = fName))
		}, error=function(e){print(e)})
	}
}

print("creating plots...")
createPlots()
print("rendering etfs...")
renderEtfs()

print("rendering master page...")

render("rp-risk.Rmd", output_file="rp-risk.html")
render("rp-country.Rmd", output_file="rp-country.html")
