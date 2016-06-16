#Attaches packages the script needs to run
library(reshape)

#Reads in files
caplist <-read.csv(paste("tmp/caplist",  ".csv", sep=""), quote = "", stringsAsFactors=FALSE)
AR      <-read.csv(paste("tmp/acosta-ramon", ".csv", sep=""), quote = "",stringsAsFactors=FALSE)
cam     <-read.csv(paste("tmp/camcare", ".csv", sep=""), quote = "",stringsAsFactors=FALSE)
Amb     <-read.csv(paste("tmp/cooper-ambulatory", ".csv", sep=""), quote = "",stringsAsFactors=FALSE)
Fam     <-read.csv(paste("tmp/cooper-family-med", ".csv", sep=""), quote = "",stringsAsFactors=FALSE)
Phys    <-read.csv(paste("tmp/cooper-physicians", ".csv", sep=""), quote = "",stringsAsFactors=FALSE)
fairview<-read.csv(paste("tmp/fairview", ".csv", sep=""), quote = "",stringsAsFactors=FALSE)
kylewill<-read.csv(paste("tmp/kyle-will", ".csv", sep=""), quote = "",stringsAsFactors=FALSE)
Lourdes <-read.csv(paste("tmp/lourdes", ".csv", sep=""), quote = "", stringsAsFactors=FALSE)
phope   <-read.csv(paste("tmp/project-hope", ".csv", sep=""), quote = "",stringsAsFactors=FALSE)
reliance<-read.csv(paste("tmp/reliance", ".csv", sep=""), quote = "",stringsAsFactors=FALSE)
luke    <-read.csv(paste("tmp/st-luke", ".csv", sep=""), quote = "",stringsAsFactors=FALSE)
uhi     <-read.csv(paste("tmp/uhi", ".csv", sep=""), quote = "",stringsAsFactors=FALSE)

#Rename fields in UHI file
uhi<-reshape::rename(uhi, c(Last.Provider="Provider"))

#Deletes unused fields
uhi$PCP.Name<-""
uhi$Practice<-""
uhi$Source<-""

# Adds "NIC" to the uhi Subscriber ID if it's not already there 
uhi$Subscriber.ID<-ifelse(grepl("NIC", uhi$Subscriber.ID), uhi$Subscriber.ID, paste("NIC", uhi$Subscriber.ID, sep=""))

#Subsets camcare file to only include Horizon data
cam<-subset(cam, Source=="Horizon")

#Appends all files
aco <- rbind(Amb,AR,cam,fairview,Fam,kylewill,Lourdes,luke,phope,Phys,reliance)

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
aco2<-subset(aco2, !(aco2$Patient.ID %in% caplist$Patient.ID.HIE))

#Identifies the columns for the two lists to be exported
acoCAP<-data.frame(aco2[,c("Subscriber.ID","Patient.ID")])

#Renames fields to import
acoCAP<-reshape::rename(acoCAP, c(Subscriber.ID  ="SUBSCRIBER_ID"))
acoCAP<-reshape::rename(acoCAP, c(Patient.ID="Patient ID HIE"))

#Subsets records that have a corresponding SUBSCRIBER_ID in TrackVia
acoCAP<-subset(acoCAP, (acoCAP$SUBSCRIBER_ID %in% caplist$SUBSCRIBER_ID))

#Exports csv file
#write.csv(acoCAP, (file=paste ("ACO-Cap", ".csv", sep="")), row.names=FALSE)
write.csv(acoCAP, stdout(), row.names=FALSE)
