# Packages
suppressMessages(require(data.table))
suppressMessages(require(reshape))


#Calls in all downloaded files from the HIE#
unified<-read.csv(paste("tmp/unified", ".csv", sep=""))

#Calls the master patient table from TrackVia > CMMI#
mpt<-read.csv(paste("tmp/mpt", ".csv", sep=""))

#Builds the UniqueID in the unified report to be able to compare to mpt#
#Changes capitalized Name fields to title case#
unified$Name<-tolower(unified$Name)
simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
}

unified$Name<-sapply(unified$Name, simpleCap)

#Splits the "Names" column into First and Last Name#
unified$LastName = as.character(lapply(strsplit(as.character(unified$Name), split=", "), "[", 1))
unified$FirstName = as.character(lapply(strsplit(as.character(unified$Name), split=", "), "[", 2))

#Creates the shortened name fields that will comprise the first part of the Unique ID#
unified$FN<-substr(unified$FirstName, 1, 2)
unified$LN<-substr(unified$LastName, 1, 3)

#Prepares the Date.of.Birth Field to be concatenated for the Unique ID field#
unified$DOB1 <- as.POSIXct(unified$DOB, format="%m/%d/%Y")
# unified$DOB1<-as.numeric(unified$DOB1)
unified$DOB2<-format(unified$DOB1, "%m%d%Y")

#Concatenates the 3 fields that form the Unique ID2 field#
unified$UniqueID <- do.call(paste, c(unified[c("FN", "LN", "DOB2")], sep = ""))

#Keeps the records in unified report that exist in mpt#
readmit<-unified[unified$UniqueID %in% mpt$UniqueID,]

#If the individual exists in the MPT, then it adds their RCTSTudyGroup#
readmit<-data.table(readmit, key="UniqueID")
mpt<-data.table(mpt, key="UniqueID")
readmit2<-mpt[readmit]

readmit2$BulkImport<-"Import"

#Remove parenthetical values from DateAdmited fields#
readmit2$Discharge.Date..Day. <- gsub("\\(.*\\)","\\1", readmit2$Discharge.Date..Day.)

#Selects the fields to be exported#
readmit3<-data.frame(readmit2$UniqueID, readmit2$Patient.ID, readmit2$Admit.Date, readmit2$Discharge.Date..Day., readmit2$Visit.Type, readmit2$Facility, readmit2$BulkImport)

#Renames fields to match TrackVia table#
readmit3<-reshape::rename(readmit3, c(readmit2.Admit.Date="AdmitDate"))
readmit3<-reshape::rename(readmit3, c(readmit2.Facility="Facility"))
readmit3<-reshape::rename(readmit3, c(readmit2.UniqueID="UniqueID"))
readmit3<-reshape::rename(readmit3, c(readmit2.Visit.Type="VisitType"))
readmit3<-reshape::rename(readmit3, c(readmit2.BulkImport="BulkImport"))
readmit3<-reshape::rename(readmit3, c(readmit2.Discharge.Date..Day.="DischargeDate"))
readmit3<-reshape::rename(readmit3, c(readmit2.Patient.ID="Patient ID"))

#Exports file#
# write.csv(readmit3, (file=paste ("CMMI-Readmissions", format(Sys.Date(), "-%Y-%m-%d"), ".csv", sep="")), row.names=FALSE)
write.csv(readmit3, stdout(), row.names=FALSE)
