#Attaches packages the script needs to run
library(reshape)
library(gtools)

#Sets the working directory
path<-setwd("Y:/Data Share Daily/API/ACO Automation/")

#Reads in files
acompt     <-read.csv(paste(path,"/", "daily_aco_mpt_export_", Sys.Date(),"_1", ".csv", sep=""), stringsAsFactors=FALSE)
Lourdes <-read.csv(paste(path,"/", "lourdes-", Sys.Date(), ".csv", sep=""), stringsAsFactors=FALSE)
Amb     <-read.csv(paste(path, "/","cooper-ambulatory-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
Fam     <-read.csv(paste(path, "/","cooper-family-med-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
Phys    <-read.csv(paste(path,"/", "cooper-physicians-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
AR      <-read.csv(paste(path, "/","acosta-ramon-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
fairview<-read.csv(paste(path, "/","fairview-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
phope   <-read.csv(paste(path,"/", "project-hope-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
reliance<-read.csv(paste(path,"/", "reliance-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
luke    <-read.csv(paste(path,"/", "st-luke-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
kylewill<-read.csv(paste(path,"/", "kyle-will-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
uhi     <-read.csv(paste(path,"/", "uhi-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)

#Rename fields in UHI file
uhi<-reshape::rename(uhi, c(Last.Provider="Provider"))

#Deletes unsued fields
uhi$PCP.Name<-""
uhi$Practice<-""
uhi$Source<-""

# Adds "NIC" to the uhi Subscriber ID if it's not already there 
uhi$Subscriber.ID<-ifelse(grepl("NIC", uhi$Subscriber.ID), uhi$Subscriber.ID, paste("NIC", uhi$Subscriber.ID, sep=""))

#Appends all files
aco <- rbind(Lourdes,Amb,Fam,Phys,luke,phope,fairview,reliance,AR,kylewill)

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
write.csv(acoMPT, (file=paste ("ACO-MPT-", format(Sys.Date(), "%Y-%m-%d"), ".csv", sep="")), row.names=FALSE)
