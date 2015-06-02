#Attaches packages the script needs to run
library(reshape)

#Reads in files
prampt     <-read.csv(paste("tmp/prampt", ".csv", sep=""), stringsAsFactors=FALSE)
pra     <-read.csv(paste("tmp/pra",".csv", sep=""), stringsAsFactors=FALSE)

#Subsets only those with a Subscriber ID and with a PRA Creation Date, and those who don't have NIC in their Subscriber ID
pra2<-subset(pra,Subscriber.ID!="" )
pra3<-subset(pra2,PRA.Creation.Date!="" )
pra4<-subset(pra3,!grepl("NIC", pra3$Subscriber.ID))

#Identifies missing HIE Import Link values
pra4<-subset(pra4, !(pra4$HIE.ID %in% prampt$HIE.Import.Link))

#Identifies fields for export
praMPT<-pra4[,c("HIE.ID", "Subscriber.ID")]

#Renames fields
praMPT<-reshape::rename(praMPT, c(HIE.ID="HIE Import Link"))

#Deletes unused column
praMPT$Subscriber.ID<-NULL

#Exports csv files
#write.csv(praMPT, (file=paste ("PRA-MPT",".csv", sep="")), row.names=FALSE)
write.csv(praMPT, stdout(), row.names=FALSE)
