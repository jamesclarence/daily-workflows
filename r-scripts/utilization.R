#Attaches packages the script needs to run
library(reshape)

#Sets the working directory
path<-setwd("tmp/")

#Reads in files
AR      <-read.csv(paste(path,"acosta-ramon", ".csv", sep=""),stringsAsFactors=FALSE)
Amb     <-read.csv(paste(path,"cooper-ambulatory", ".csv", sep=""),stringsAsFactors=FALSE)
Fam     <-read.csv(paste(path,"cooper-family-med", ".csv", sep=""),stringsAsFactors=FALSE)
Phys    <-read.csv(paste(path,"cooper-physicians", ".csv", sep=""),stringsAsFactors=FALSE)
fairview<-read.csv(paste(path,"fairview", ".csv", sep=""),stringsAsFactors=FALSE)
kylewill<-read.csv(paste(path,"kyle-will", ".csv", sep=""),stringsAsFactors=FALSE)
Lourdes <-read.csv(paste(path,"lourdes", ".csv", sep=""), stringsAsFactors=FALSE)
phope   <-read.csv(paste(path,"project-hope", ".csv", sep=""),stringsAsFactors=FALSE)
reliance<-read.csv(paste(path,"reliance", ".csv", sep=""),stringsAsFactors=FALSE)
luke    <-read.csv(paste(path,"st-luke", ".csv", sep=""),stringsAsFactors=FALSE)
uhi     <-read.csv(paste(path,"uhi", ".csv", sep=""),stringsAsFactors=FALSE)

#Rename fields in UHI file
uhi<-reshape::rename(uhi, c(Last.Provider="Provider"))

#Deletes unsued fields
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

#Identifies the columns for the two lists to be exported
acoUtilization<-data.frame(aco2[,c("Patient.ID",
                                   "Admit.Date",
                                   "Facility",
                                   "Patient.Class",
                                   "DischargeDate",
                                   "Provider",
                                   "Adm.Diagnoses",
                                   "Inp..6mo.",
                                   "ED..6mo.",
                                   "CurrentlyAdmitted")])

#Renames fields to import
acoUtilization<-reshape::rename(acoUtilization, c(Patient.ID="HIE Import Link"))
acoUtilization<-reshape::rename(acoUtilization, c(Admit.Date="AdmitDate"))
acoUtilization<-reshape::rename(acoUtilization, c(Patient.Class="PatientClass"))
acoUtilization<-reshape::rename(acoUtilization, c(Adm.Diagnoses="HistoricalDiagnosis"))
acoUtilization<-reshape::rename(acoUtilization, c(Inp..6mo.="Inp6mo"))
acoUtilization<-reshape::rename(acoUtilization, c(ED..6mo.="ED6mo"))


#Exports csv file
#write.csv(acoUtilization, (file=paste("ACO-Utilizations", ".csv", sep="")), row.names=FALSE)
write.csv(acoUtilization, stdout(), row.names=FALSE)
