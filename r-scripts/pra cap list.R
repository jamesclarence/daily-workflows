#Attaches packages the script needs to run
library(reshape)
library(gtools)

#Sets the working directory
path<-setwd("Y:/Data Share Daily/API/ACO Automation/")

#Reads in files
caplist <-read.csv(paste(path,"/", "daily_cap_list_export_", Sys.Date(),"_1", ".csv", sep=""), stringsAsFactors=FALSE)
pra     <-read.csv(paste(path,"/", "pra-", Sys.Date(), ".csv", sep=""), stringsAsFactors=FALSE)

#Subsets only those with a Subscriber ID and with a PRA Creation Date, and those who don't have NIC in their Subscriber ID
pra2<-subset(pra,Subscriber.ID!="" )
pra3<-subset(pra2,PRA.Creation.Date!="" )
pra4<-subset(pra3,!grepl("NIC", pra3$Subscriber.ID))

#Identifies missing HIE Import Link values
pra4<-subset(pra4, !(pra4$HIE.ID %in% caplist$Patient.ID.HIE))

#Identifies fields for export
praCAP<-pra4[,c("Subscriber.ID", "HIE.ID")]

#Renames fields
praCAP<-reshape::rename(praCAP, c(Subscriber.ID="SUBSCRIBER_ID"))
praCAP<-reshape::rename(praCAP, c(HIE.ID="HIE Import Link"))

#Exports csv files
write.csv(praCAP, (file=paste ("PRA-Cap-", format(Sys.Date(), "%Y-%m-%d"), ".csv", sep="")), row.names=FALSE)
