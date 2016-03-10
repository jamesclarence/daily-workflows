#Attaches packages the script needs to run
library(reshape)

#Reads in files
pra     <-read.csv(paste("tmp/pra",".csv", sep=""), stringsAsFactors=FALSE)

#Subsets only those with a Subscriber ID and with a PRA Creation Date, and those who don't have NIC in their Subscriber ID
pra2<-subset(pra,Subscriber.ID!="" )
pra3<-subset(pra2,PRA.Creation.Date!="" )
pra4<-subset(pra3,!grepl("NIC", pra3$Subscriber.ID))

#Remove "U" from string to match TrackVia Subscriber IDs
pra4$Subscriber.ID<-gsub("U", "", pra4$Subscriber.ID)

#Keeps only those that have a corresponding Subscriber ID
pra4<-subset(pra4, (pra4$Subscriber.ID %in% caplist$SUBSCRIBER_ID))

#Convert PRA PATID values to lower
pra4$PRA.PATID<-tolower(pra4$PRA.PATID)

#Identifies fields for export
pra5<-pra4[,c("HIE.ID", 
              "PRA.Creation.Date", 
              "PRA.Facility.Created", 
              "Most.Recent.Update.Date", 
              "PRA.Facility.Updated", 
              "PRA.PATID")]

#Renames fields
pra5<-reshape::rename(pra5, c(HIE.ID="HIEID"))
pra5<-reshape::rename(pra5, c(PRA.Creation.Date="PRA Creation Date"))
pra5<-reshape::rename(pra5, c(PRA.Facility.Created="PRA Facility Created"))
pra5<-reshape::rename(pra5, c(Most.Recent.Update.Date="Most Recent Update Date"))
pra5<-reshape::rename(pra5, c(PRA.Facility.Updated="PRA Facility Updated"))
pra5<-reshape::rename(pra5, c(PRA.PATID="PRA PATID"))

#Exports csv files
#write.csv(pra5, (file=paste ("PRA-Table", ".csv", sep="")), row.names=FALSE)
write.csv(pra5, stdout(), row.names=FALSE)
