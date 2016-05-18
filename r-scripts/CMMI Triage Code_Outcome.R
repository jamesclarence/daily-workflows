# Packages
suppressMessages(require(reshape))

#Sets working directory, reads file and creates a nickname#
CMITriage <- read.csv("tmp/Admitted Past Month (High Use).csv", header=TRUE,  stringsAsFactors = FALSE)

#Splits the "Name" column into First and Last Name#
CMITriage$LastName = as.character(lapply(strsplit(as.character(CMITriage$Name), split=", "), "[", 1))
CMITriage$FirstName = as.character(lapply(strsplit(as.character(CMITriage$Name), split=", "), "[", 2))

#Removes the full Name field#
CMITriage$Name <- NULL

#Creates the name fields that will comprise the first part of the PatientID#
CMITriage$FN<-substr(CMITriage$FirstName, 1, 2)
CMITriage$LN<-substr(CMITriage$LastName, 1, 3)

#Prepares the DOB Field to be concatenated for the PatientID2 field#
CMITriage[ CMITriage == "08/08/1888" ] = ""
CMITriage$DOB  <- as.Date(CMITriage$DOB, format="%m/%d/%Y")
CMITriage$DOB3 <- format(CMITriage$DOB, "%m%d%Y")
CMITriage$DOB3 <- ifelse(is.na(CMITriage$DOB), "00000000", CMITriage$DOB3)

#Concatenates the 3 fields that form the PatientID field#
CMITriage$PatientID2 <- do.call(paste, c(CMITriage[c("FN", "LN", "DOB3")], sep = ""))

#Drop the extra fields#
CMITriage$FN<- NULL
CMITriage$LN<- NULL
CMITriage$DOB3 <-NULL

#Keeps only Cooper and Lourdes#
CMITriage2<-subset(CMITriage, Facility %in% c("CUH", "LGA") )

#Transforms the values in the "Age" column to characters, drops "yo" from the end of the value and transforms the values back to number#
CMITriage2$Age <-as.character(CMITriage2$Age)
CMITriage2$Age2 <- substr(CMITriage2$Age, 1, nchar(CMITriage2$Age)-2)
CMITriage2$Age2<-as.numeric(CMITriage2$Age2)

#Only keeps entries that are 18 and over#
CMITriage3<-subset(CMITriage2, Age2 >=18)

#Creates a new column "CurrentlyAdmitted" with text from "AdmitDate" Field#
CMITriage3$CurrentlyAdmitted <- gsub("\\(()\\)","\\1",  CMITriage3$Discharge.Date..Day.)

#Removes parenthetical values from DischargeDate field#
CMITriage3$Discharge.Date..Day. <- gsub("\\(.*\\)","\\1", CMITriage3$Discharge.Date..Day.)

#Removes dates from CurrentlyAdmitted field#
CMITriage3$CurrentlyAdmitted <- ifelse(CMITriage3$CurrentlyAdmitted == CMITriage3$Discharge.Date..Day., "", CMITriage3$CurrentlyAdmitted)

#Maps CUH and LGA to Cooper and Lourdes, Gender M to Male, F to Female#
CMITriage3$nFacility[CMITriage3 $Facility=="CUH"] <- "Cooper"
CMITriage3$nFacility[CMITriage3 $Facility=="LGA"] <- "Lourdes"
CMITriage3$nGender[CMITriage3 $Gender=="M"] <- "Male"
CMITriage3$nGender[CMITriage3 $Gender=="F"] <- "Female"

#Drops unnecessary columns#
CMITriage3$Practice <- NULL
CMITriage3$Adm.Diagnoses <- NULL
CMITriage3$Age<-NULL
CMITriage3$Facility<-NULL
CMITriage3$Gender<-NULL

#Sets DOB as character
CMITriage3$DOB <- as.character(CMITriage3$DOB)

#Renames columns#
CMITriage3<-reshape::rename(CMITriage3, c(Patient.ID="HIEID"))
CMITriage3<-reshape::rename(CMITriage3, c(DOB="Date of Birth"))
CMITriage3<-reshape::rename(CMITriage3, c(Admit.Date="Admit Date"))
CMITriage3<-reshape::rename(CMITriage3, c(Discharge.Date..Day.="Discharge Date"))
CMITriage3<-reshape::rename(CMITriage3, c(Total.Days..6mo.="TotalDays6months"))
CMITriage3<-reshape::rename(CMITriage3, c(Inp..6mo.="Inp6mo"))
CMITriage3<-reshape::rename(CMITriage3, c(ED..6mo.="ED6mo"))
CMITriage3<-reshape::rename(CMITriage3, c(Provider="HIEProvider"))
CMITriage3<-reshape::rename(CMITriage3, c(Insurance="HIEInsurance"))
CMITriage3<-reshape::rename(CMITriage3, c(Age2="AgeTriage"))
CMITriage3<-reshape::rename(CMITriage3, c(nFacility="Facility"))
CMITriage3<-reshape::rename(CMITriage3, c(nGender="Gender"))
CMITriage3<-reshape::rename(CMITriage3, c(LastName="Last Name"))
CMITriage3<-reshape::rename(CMITriage3, c(FirstName="First Name"))

#Identifies the columns for the two lists to be exported#
TriageOutcome<-CMITriage3[,c("Last Name", "First Name", "Date of Birth", "PatientID2", "Gender", "HIEID")]

#If there are genders other than F or M, it leaves it blank
TriageOutcome$Gender[is.na(TriageOutcome$Gender)==TRUE] <- ""

#If there are NA's, replaces with blanks
TriageOutcome[is.na(TriageOutcome)] <- ""

#Exports file
# write.csv(TriageOutcome, (file=paste("TriageOutcome", format(Sys.Date(), "-%Y-%m-%d"), ".csv", sep="")), row.names=FALSE)
write.csv(TriageOutcome, stdout(), row.names=FALSE)
