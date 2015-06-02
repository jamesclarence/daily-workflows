#Attaches packages the script needs to run
library(reshape)

#Reads in files
acompt  <-read.csv(paste("tmp/acompt",".csv", sep=""), stringsAsFactors=FALSE)
AR      <-read.csv(paste("tmp/acosta-ramon", ".csv", sep=""),stringsAsFactors=FALSE)
Amb     <-read.csv(paste("tmp/cooper-ambulatory", ".csv", sep=""),stringsAsFactors=FALSE)
Fam     <-read.csv(paste("tmp/cooper-family-med", ".csv", sep=""),stringsAsFactors=FALSE)
Phys    <-read.csv(paste("tmp/cooper-physicians", ".csv", sep=""),stringsAsFactors=FALSE)
fairview<-read.csv(paste("tmp/fairview", ".csv", sep=""),stringsAsFactors=FALSE)
kylewill<-read.csv(paste("tmp/kyle-will", ".csv", sep=""),stringsAsFactors=FALSE)
Lourdes <-read.csv(paste("tmp/lourdes", ".csv", sep=""), stringsAsFactors=FALSE)
phope   <-read.csv(paste("tmp/project-hope", ".csv", sep=""),stringsAsFactors=FALSE)
reliance<-read.csv(paste("tmp/reliance", ".csv", sep=""),stringsAsFactors=FALSE)
luke    <-read.csv(paste("tmp/st-luke", ".csv", sep=""),stringsAsFactors=FALSE)
uhi     <-read.csv(paste("tmp/uhi", ".csv", sep=""),stringsAsFactors=FALSE)

#Rename fields in UHI file
uhi<-reshape::rename(uhi, c(Last.Provider="Provider"))

#Deletes unused fields
uhi$PCP.Name<-""
uhi$Practice<-""
uhi$Source<-""

# Adds "NIC" to the uhi Subscriber ID if it's not already there 
uhi$Subscriber.ID<-ifelse(grepl("NIC", uhi$Subscriber.ID), uhi$Subscriber.ID, paste("NIC", uhi$Subscriber.ID, sep=""))

#Appends all files
aco <- rbind(Amb,AR,fairview,Fam,kylewill,Lourdes,luke,phope,Phys,reliance)

#Sorts columns alphabetically
aco <- aco[,order(names(aco))]
uhi <- uhi[,order(names(uhi))]

#Appends remaining files
aco <-rbind(aco,uhi)

#Subtracts the Admit Date from Today's date and subsets those admitted in the last 21 days
aco2<- subset(aco, (Sys.Date()- as.Date(aco$Admit.Date, format="%Y-%m-%d"))<21)

#Creates a CurrentlyAdmitted field with text from Admit.Date field
aco2$CurrentlyAdmitted <- gsub("\\(()\\)","\\1",  aco2$DischargeDate)

#Removes parenthetical values from DateAdmited field
aco2$DischargeDate <- gsub("\\(.*\\)","\\1", aco2$DischargeDate)

#Removes dates from CurrentlyAdmitted field
aco2$CurrentlyAdmitted <- ifelse(aco2$CurrentlyAdmitted == aco2$DischargeDate, "", aco2$CurrentlyAdmitted)

#Identifies missing HIE Import Link values
aco2<-subset(aco2, !(aco2$Patient.ID %in% acompt$HIE.Import.Link))

#Identifies the columns for the two lists to be exported
acoMPT<-aco2[,c("Patient.ID", "Subscriber.ID")]

#Renames fields to import
acoMPT<-reshape::rename(acoMPT, c(Patient.ID="HIE Import Link"))

#Deletes unused column
acoMPT$Subscriber.ID<-NULL

#Exports csv file
#write.csv(acoMPT, (file=paste ("ACO-MPT", ".csv", sep="")), row.names=FALSE)
write.csv(acoMPT, stdout(), row.names=FALSE)
