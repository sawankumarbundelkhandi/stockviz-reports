library(rmarkdown)

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

options(stringsAsFactors = FALSE)
options("scipen"=100)

Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/Pandoc")
source("C:/stockviz/r/config.r")
source("C:/stockviz/r/plot.common.r")

source("../common/fan-chart.R")

plotPath <- "risk/plots"
idPath <- "../"

benchName <- "NIFTY TOTAL MARKET TR"
startDate <- as.Date("2010-01-01")

lcon <- odbcDriverConnect(sprintf("Driver={ODBC Driver 17 for SQL Server};Server=%s;Database=%s;Uid=%s;Pwd=%s;", ldbserver, ldbname, ldbuser, ldbpassword), case = "nochange", believeNRows = TRUE)

maxDt <- sqlQuery(lcon, "select max(time_stamp) from index_capm")[[1]]
indices <- sqlQuery(lcon, sprintf("select distinct index_name from index_capm where time_stamp = '%s'", maxDt))[,1]

plottedIndices <- c()
createPlots <- function(){
	bDf1 <- sqlQuery(lcon, sprintf("select px_close, time_stamp from bhav_index where index_name='%s' and time_stamp >= '%s' order by time_stamp", benchName, startDate))
	bXts <- xts(bDf1[,1], bDf1[,2])
	
	if(last(index(bXts)) != maxDt) return

	bRetDaily <- dailyReturn(bXts)
	bRetAnn <- annualReturn(bXts)

	names(bRetDaily) <- c(benchName)
	names(bRetAnn) <- c(benchName)

	for(i in 1:length(indices)){
		
		iName <- indices[i]
		fName <- gsub("[^[:alnum:] ]| ", "", iName)
		
		print(iName)
		tryCatch({
			iDf1 <- sqlQuery(lcon, sprintf("select px_close, time_stamp from bhav_index where index_name='%s' and time_stamp >= '%s' order by time_stamp", iName, startDate))
			iXts <- xts(iDf1[,1], iDf1[,2])
			
			if(last(index(bXts)) != last(index(iXts)) || first(index(iXts)) > startDate + 5) {
				print(paste(iName, "DATE MISMATCH!!!"))
				next
			}

			retDaily <- dailyReturn(iXts)
			retAnn <- annualReturn(iXts)

			names(retDaily) <- c(iName)
			names(retAnn) <- c(iName)

			Common.PlotCumReturns(merge(retDaily, bRetDaily), iName, "", sprintf("%s/%s.cumret.png", plotPath, fName))
			
			toPlotAnn <- data.frame(merge(retAnn, bRetAnn))
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
				labs(x = "Year", y="Returns (%)", fill="", color="", size="", title=sprintf("%s", iName), subtitle=sprintf("Annual Returns [%s:%s]", first(index(retDaily)), last(index(retDaily)))) +
				annotate("text", x=maxYear, y=minRet, label = "@StockViz", hjust=1, vjust=0, col="white", cex=6, fontface = "bold", alpha = 0.8)
				
			ggsave(sprintf("%s/%s.annret.png", plotPath, fName), width=12, height=6)
			
			
			fanPlot <- common.CreateFanChart(iDf1, iName, sprintf("%d:%s", min(year(iDf1$time_stamp)), max(iDf1$time_stamp)))
			ggsave(sprintf("%s/%s.fan.png", plotPath, fName), fanPlot, width=12, height=6)
			
			
			metricMap <- read.csv(paste0(idPath, "/metric_map.csv"))

			statsDf <- sqlQuery(lcon, sprintf("select INDEX_NAME, ID, VAL from INDEX_CAPM where INDEX_NAME in ('%s')", paste(indices, collapse="','"))) 

			statsTibs <- statsDf %>% 
				pivot_wider(names_from=ID, values_from=VAL) %>% 
				mutate_at(vars(-INDEX_NAME), rescale)
				
			avgTibs <- statsTibs %>% summarize_at(vars(-INDEX_NAME), mean, na.rm=T) %>% mutate(INDEX_NAME='Average')

			toPlot <- statsTibs %>% filter(INDEX_NAME==iName) %>% mutate(INDEX_NAME = 'INDEX') %>% bind_rows(avgTibs) %>% select(where(~!any(is.na(.x)))) %>% as.data.frame()
						
			rplot <- ggradar(plot.data = toPlot,
					font.radar = "roboto",
					grid.label.size = 5,  # Affects the grid annotations (0%, 50%, etc.)
					axis.label.size = 8, # Afftects the names of the variables
					group.point.size = 3   # Simply the size of the point 
				  ) +
				labs(title = iName, tag=paste("@StockViz", maxDt)) + 
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
			
			plottedIndices <- c(plottedIndices, iName)
			
		}, error=function(e){print(e)})
	}
}

renderIndices <- function(){
	
	plotFiles <- list.files(plotPath, pattern="*.png")
	plottedNames <- unique(unlist(lapply(strsplit(plotFiles, ".", fixed=T), `[[`, 1)))
	
	for(i in 1:length(indices)){
		
		iName <- indices[i]
		fName <- gsub("[^[:alnum:] ]| ", "", iName)
		
		if (!(fName %in% plottedNames)) {
			print(paste(iName, "NOT PLOTTED!!!"))
			next
		}
		
		print(iName)
		tryCatch({
			render("risk/rp-index-risk.Rmd", output_file=paste0("rp-", fName, ".html"), params=list(index_name = iName, fName = fName))
		}, error=function(e){print(e)})
	}
}

print("creating plots...")
#createPlots()

print("rendering indices...")
renderIndices()

print("rendering master page...")

render("rp-risk.Rmd", output_file="rp-risk.html")

