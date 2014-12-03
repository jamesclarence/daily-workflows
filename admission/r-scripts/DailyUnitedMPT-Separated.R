# Packages
require(reshape)
require("jsonlite")

# Load data from stdin
data <- fromJSON(readLines(file("stdin")))
UMPT <- read.csv(text=data[1], row.names=NULL);
uhi <- read.csv(text=data[2], row.names=NULL);

#Call temporary files and name it UMPT#
# setwd("Y:/API/")
# Lourdes<-read.csv(paste("Y:/API/", "lourdes-", Sys.Date(), ".csv", sep=""))
# Amb<-read.csv(paste("Y:/API/", "cooper-ambulatory-", Sys.Date(), ".csv", sep=""))
# Fam<-read.csv(paste("Y:/API/", "cooper-family-med-", Sys.Date(), ".csv", sep=""))
# Phys<-read.csv(paste("Y:/API/", "cooper-physicians-", Sys.Date(), ".csv", sep=""))
# AR<-read.csv(paste("Y:/API/", "acosta-ramon-", Sys.Date(), ".csv", sep=""))
# fairview<-read.csv(paste("Y:/API/", "fairview-", Sys.Date(), ".csv", sep=""))
# phope<-read.csv(paste("Y:/API/", "project-hope-", Sys.Date(), ".csv", sep=""))
# reliance<-read.csv(paste("Y:/API/", "reliance-", Sys.Date(), ".csv", sep=""))
# luke<-read.csv(paste("Y:/API/", "st-luke-", Sys.Date(), ".csv", sep=""))
# uhi<-read.csv(paste("Y:/API/", "uhi-", Sys.Date(), ".csv", sep=""))

#Binds practice data into one united file#
# UMPT <- rbind(Lourdes,Amb,Fam,Phys,AR,fairview,phope,reliance,luke)

#Deletes unused fields#
UMPT$Practice<-NULL
UMPT$PCP.Name<-NULL

# #Adds  text identifiers to Subscriber_ID (NIC and U)#
uhi$nic<-"NIC"
uhi$Subscriber.ID<-paste(uhi$nic, uhi$Subscriber.ID, sep="")
uhi$nic<-NULL
UMPT$U<-"U"
UMPT$Subscriber.ID<-paste(UMPT$U, UMPT$Subscriber.ID, sep="")
UMPT$U<-NULL

#Renames fields to bind#
uhi<-reshape::rename(uhi, c(Last.Provider="Provider"))

#Binds uhi and united data into one file#
UMPT<-rbind(UMPT,uhi)

#Remove "U" from string to match TrackVia subscriber id's#
UMPT$Subscriber.ID<-gsub("U", "", UMPT$Subscriber.ID)

#Create variables to calculate difference in days between today and admit date#
UMPT$TodaysDate <- Sys.Date()
UMPT$date_diff <- as.Date(UMPT$TodaysDate, format="%Y/%m/%d")- as.Date(UMPT$Admit.Date) 

#Create subset of days < 21#
UMPT2<-subset(UMPT, date_diff<21)

#Create CurrentlyAdmitted Field with text from AdmitDate Field#
UMPT2$CurrentlyAdmitted <- gsub("\\(()\\)","\\1",  UMPT2$DischargeDate)

#Remove parenthetical values from DateAdmited fields#
UMPT2$DischargeDate <- gsub("\\(.*\\)","\\1", UMPT2$DischargeDate)

#Remove dates from CurrentlyAdmitted field#
UMPT2$CurrentlyAdmitted <- ifelse(UMPT2$CurrentlyAdmitted == UMPT2$DischargeDate, "", UMPT2$CurrentlyAdmitted)

#renames fields#
UMPT2<-reshape::rename(UMPT2, c(Admit.Date="AdmitDate"))
UMPT2<-reshape::rename(UMPT2, c(Adm.Diagnoses="HistoricalDiagnosis"))
UMPT2<-reshape::rename(UMPT2, c(Inp..6mo.="Inp6mo"))
UMPT2<-reshape::rename(UMPT2, c(ED..6mo.="ED6mo"))
UMPT2<-reshape::rename(UMPT2, c(Patient.Class="PatientClass"))
UMPT2<-reshape::rename(UMPT2, c(Subscriber.ID="SUBSCRIBER_ID"))
UMPT2<-reshape::rename(UMPT2, c(Patient.ID="HIEID"))

#Identifies the columns for the file to be exported#
UMPT2<-UMPT2[,c("SUBSCRIBER_ID", "AdmitDate","HIEID")]

#Replaces NICNIC with NIC if it exists in any of the Subscriber IDs
UMPT2$SUBSCRIBER_ID<-gsub("NICNIC", "NIC", UMPT2$SUBSCRIBER_ID)

#Export csv file#
# write.csv(UMPT2, (file=paste ("DailyUnitedMPT", format(Sys.Date(), "-%Y-%m-%d"), ".csv", sep="")), row.names=FALSE)
write.csv(UMPT2, stdout(), row.names=FALSE)
