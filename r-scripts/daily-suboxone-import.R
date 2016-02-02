# Calls package
suppressMessages(require(reshape))

# Sets working directory
#wd<-"Y:/Data Share Daily/daily-suboxone-import"

# Reads in files
unified<-read.csv(paste("tmp/unified", ".csv", sep=""))
clinicdata<-read.csv(paste("tmp/clinicdata", ".csv", sep=""))

# Splits Name field in unified report
unified$LastName = as.character(lapply(strsplit(as.character(unified$Name), split=", "), "[", 1))
unified$FirstName = as.character(lapply(strsplit(as.character(unified$Name), split=", "), "[", 2))

# Function to convert TrackVia dates to universal date format
exceldate <- function(date){
  
  if (!is.factor(date)) {
    
    return(date)
    
  } else {
    
    date<-gsub(" ", "/",date)
    date<-gsub("Jan", "01",date)
    date<-gsub("Feb", "02",date)
    date<-gsub("Mar", "03",date)
    date<-gsub("Apr", "04",date)
    date<-gsub("May", "05",date)
    date<-gsub("Jun", "06",date)
    date<-gsub("Jul", "07",date)
    date<-gsub("Aug", "08",date)
    date<-gsub("Sep", "09",date)
    date<-gsub("Oct", "10",date)
    date<-gsub("Nov", "11",date)
    date<-gsub("Dec", "12",date)
    date<-as.Date(date, format="%m/%d/%Y")
    
    return(date)
    
  }
}


# Cleans Excel dates in clinicdata file
clinicdata$dob<-exceldate(clinicdata$Patient.DOB)
clinicdata$Patient.DOB<-NULL

# Cleans unified report dates
unified$dob2<-as.Date(unified$DOB, format="%m/%d/%Y")

# Returns string w/o leading or trailing whitespace
trim <- function (x) gsub("^\\s+|\\s+$", "", x)
unified$FirstName<-unified$FirstName
unified$LastName<-unified$LastName
clinicdata$Patient.First.Name<-clinicdata$Patient.First.Name
clinicdata$Patient.Last.Name<-clinicdata$Patient.Last.Name

# Creates ID in both files
unified$ID<-paste(unified$FirstName,unified$LastName,unified$dob2, sep="")
clinicdata$ID<-paste(clinicdata$Patient.First.Name, clinicdata$Patient.Last.Name, clinicdata$dob, sep="")

# Subset records that are not in the acoutil file
suboxoneutils <- unified[unified$ID %in% clinicdata$ID,]

# Looks up Record Locator value for utilizations
suboxoneutils <- (merge(suboxoneutils, clinicdata, by.x = "ID", by.y = "ID", all.x = TRUE))

# Creates the name fields that will comprise the first part of the PatientID#
suboxoneutils$FN<-substr(suboxoneutils$FirstName, 1, 2)
suboxoneutils$LN<-substr(suboxoneutils$LastName, 1, 3)

#Prepares the DOB Field to be concatenated for the PatientID2 field#
suboxoneutils$dob3<-format(suboxoneutils$dob2, "%m%d%Y")

#Concatenates the 3 fields that form the PatientID field#
suboxoneutils$UniqueID <- do.call(paste, c(suboxoneutils[c("FN", "LN", "dob3")], sep = ""))

# Reduces number of fields to export
suboxoneutils<-suboxoneutils[,c("UniqueID",
                  "Admit.Date", 
                  "Discharge.Date..Day.", 
                  "Facility", 
                  "Visit.Type",
                  "Adm.Diagnoses",
                  "Inp..6mo.",
                  "ED..6mo.",
                  "Insurance", 
                  "ACO", 
                  "ACO.Practice")]

# Renames variables
suboxoneutils<-reshape::rename(suboxoneutils, c(Admit.Date="AdmitDate"))
suboxoneutils<-reshape::rename(suboxoneutils, c(Discharge.Date..Day.="DischargeDate"))
suboxoneutils<-reshape::rename(suboxoneutils, c(Visit.Type="VisitType"))
suboxoneutils<-reshape::rename(suboxoneutils, c(Adm.Diagnoses="AdmDiagnoses"))
suboxoneutils<-reshape::rename(suboxoneutils, c(Inp..6mo.="Inp6mo"))
suboxoneutils<-reshape::rename(suboxoneutils, c(ED..6mo.="ED6mo"))
suboxoneutils<-reshape::rename(suboxoneutils, c(ACO="Payer"))
suboxoneutils<-reshape::rename(suboxoneutils, c(ACO.Practice="Practice"))

# Replaces NA's with blanks
suboxoneutils[is.na(suboxoneutils)] <- ""

# Those with Payer CAMcare should actually say United - this fixes that
suboxoneutils$Payer[suboxoneutils$Payer=="CAMCare"] <- "UNITED"

# Exports file
#write.csv(suboxoneutils, file="suboxone-utilizations.csv", row.names=FALSE)
write.csv(suboxoneutils, stdout(), row.names=FALSE)
