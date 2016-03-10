#Attaches packages the script needs to run
library(reshape)

#Reads in files
caplist <-read.csv(paste("tmp/caplist",".csv", sep=""), stringsAsFactors=FALSE)
pra     <-read.csv(paste("tmp/pra",".csv", sep=""), stringsAsFactors=FALSE)

#Subsets only those with a Subscriber ID and with a PRA Creation Date, and those who don't have NIC in their Subscriber ID
pra2<-subset(pra,Subscriber.ID!="" )
pra3<-subset(pra2,PRA.Creation.Date!="" )
pra4<-subset(pra3,!grepl("NIC", pra3$Subscriber.ID))

#Remove "U" from string to match TrackVia Subscriber IDs
pra4$Subscriber.ID<-gsub("U", "", pra4P$Subscriber.ID)

#Identifies missing HIE Import Link values
pra4<-subset(pra4, !(pra4$HIE.ID %in% caplist$Patient.ID.HIE))

#Keeps only those that have a corresponding Subscriber ID
pra4<-subset(pra4, (pra4$Subscriber.ID %in% caplist$SUBSCRIBER_ID))

#Identifies fields for export
praCAP<-pra4[,c("Subscriber.ID", "HIE.ID")]

#Renames fields
praCAP<-reshape::rename(praCAP, c(Subscriber.ID="SUBSCRIBER_ID"))
praCAP<-reshape::rename(praCAP, c(HIE.ID="Patient ID HIE"))

#Exports csv files
#write.csv(praCAP, (file=paste ("PRA-Cap", ".csv", sep="")), row.names=FALSE)
write.csv(praCAP, stdout(), row.names=FALSE)
