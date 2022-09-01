library(tidyr)
library(ggplot2)
library(ggpubr)
library(ggplot2)
#reading df, changing into long ####
{
areas <- read.csv(file = "merged_averaged_result_BPA.csv", header = T,sep = ",")
areas
areaslongA <- gather(areas,aliquottime, c, BLANK_X:BPA_480)
areaslongA$time <- as.numeric(unlist(lapply(strsplit(areaslongA$aliquottime, "_"), `[[`, 2)))
areaslongA$Type <- as.factor(unlist(lapply(strsplit(areaslongA$aliquottime, "_"), `[[`, 1)))

rm(areas)
areaslongA$mzmed<- as.factor(areaslongA$mzmed)
}

{
    areas <- read.csv(file = "merged_averaged_result_BPS.csv", header = T,sep = ",")
    areas
    areaslongS <- gather(areas,aliquottime, c, BLANK_X:BPS_480)
    areaslongS$time <- as.numeric(unlist(lapply(strsplit(areaslongS$aliquottime, "_"), `[[`, 2)))
    areaslongS$Type <- as.factor(unlist(lapply(strsplit(areaslongS$aliquottime, "_"), `[[`, 1)))
    
    rm(areas)
    areaslongS$mzmed<- as.factor(areaslongS$mzmed)
}

#these for the selected styl in future ####
theme1 <- theme(axis.line = element_line(colour = "black"),
                panel.grid.major = element_blank(),
                panel.grid.minor = element_blank(),
                panel.border = element_blank(),
                panel.background = element_blank(),
                axis.title.x = element_blank(),
                axis.title.y = element_blank(),)
dfA <- areaslongA
dfS <- areaslongS

#Function that generate all graphs on the same figure ####
getgraph1 <- function(df, folder){
  pl <- list()
  i <- 1
  print(levels(df$mzmed))
  for (mz in levels(df$mzmed)){
    title
    print(i)
    print(length(pl))
    pl[[i]] <- ggplot(df[df$mzmed==mz,],aes(x=time, y=c, color=Type))+
        scale_color_discrete(drop=TRUE,
                             limits = levels(df$Type))+           # <- this fixates colors for levels
        geom_point()+
        geom_line()+
        theme_bw()+
        # scale_x_continuous(name="time [days]", breaks = breakss)+
        scale_y_continuous(name="Response ratio")+
        ggtitle(mz)+
        theme1+
        theme(plot.title = element_text(element_text(hjust = 0.5),
                                        # margin = margin(t = 15, r=0, b = -25, l=0),
                                        size=10),)+
        # hjust = titleposition[[i]]))
        geom_hline(yintercept = df[df$mzmed==mz&df$Type=='BLANK','c'], color='red')
    
    
    # if (i %in% xaxis){
    #   pl[[i]] <- pl[[i]]+theme(axis.title.x = element_text())
    # }
    # if (i %in% yaxis){
    #   pl[[i]] <- pl[[i]]+theme(axis.title.y = element_text(angle=90))
    # }
    i <- i+1
    #ggsave(plot=pl[[i]], filename = paste(folder,"/",mz,".svg", sep = ""))
    #In case you want to save each graphs seperately than remove the comment
    
  }
  pl
}
#SAVE ALL GRAPHS #### 

#(currently command for saving plots is disabled)
BPA <- getgraph1(areaslongA,"BPA")
# BPFslow <- BPFslow[c(1,2, 4, 6, 5)] #rearange positions
BPA2 <- ggarrange(plotlist =  BPA, ncol=4, nrow=3, common.legend = TRUE, legend="bottom")
# BPA2

ggsave(plot = BPA2, filename = "BPA.png",dpi=400, width = 8, height = 4)
ggsave(plot = BPA2, filename = "BPA.svg",dpi=400, width = 8, height = 4)


BPS <- getgraph1(areaslongS,"BPS")
BPS2 <- ggarrange(plotlist =  BPS, ncol=2, nrow=3, common.legend = TRUE, legend="bottom")
ggsave(plot = BPS2, filename = "BPS.png",dpi=400, width = 4, height = 4)
ggsave(plot = BPS2, filename = "BPS.svg",dpi=400, width = 4, height = 4)
