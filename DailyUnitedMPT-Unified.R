#Call temporary file and name it UMPT#
setwd("Y:/API/")
UMPT<-read.csv(paste("Y:/API/", "unified-", Sys.Date(), ".csv", sep=""))
UMPT$Subscriber.ID<-as.character(UMPT$Subscriber.ID)
UMPT<-subset(UMPT,is.na(Subscriber.ID)==FALSE)

#Corrects Subscriber ID's for the UHI data
UHI<-subset(UMPT, Cooper.UHI=="True")
UHI$Subscriber.ID[UHI$Cooper.UHI!=""]<-paste("NIC", UHI$Subscriber.ID, sep="")

#Removes UHI data from original data to be able to merge again with correct IDs#
UMPT<-subset(UMPT, Cooper.UHI=="")

#Rebinds the data with the corrected IDs#
require(gtools)
smartbind(UMPT,UHI)

#Renames Discharge date for Unified report#
require(reshape)
UMPT<-reshape::rename(UMPT, c(Discharge.Date..Day.  ="DischargeDate"))

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

#renames Patient.ID to HIE_ID#
require(reshape)
UMPT2<-reshape::rename(UMPT2, c(Admit.Date="AdmitDate"))
UMPT2<-reshape::rename(UMPT2, c(Adm.Diagnoses="HistoricalDiagnosis"))
UMPT2<-reshape::rename(UMPT2, c(Inp..6mo.="Inp6mo"))
UMPT2<-reshape::rename(UMPT2, c(ED..6mo.="ED6mo"))
UMPT2<-reshape::rename(UMPT2, c(Patient.Class="PatientClass"))
UMPT2<-reshape::rename(UMPT2, c(Subscriber.ID="SUBSCRIBER_ID"))

#Identifies the columns for the file to be exported#
UMPT2<-UMPT2[,c("SUBSCRIBER_ID", "AdmitDate")]

#Export csv file#
write.csv(UMPT2, (file=paste ("DailyUnitedMPT", format(Sys.Date(), "-%Y-%m-%d"), ".csv", sep="")), row.names=FALSE)
