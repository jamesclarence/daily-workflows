#Attaches packages the script needs to run
suppressWarnings(suppressMessages(require(dplyr)))

#Sets the working directory#
path<-setwd("Y:/Perry's Codes/")

#Reads in files
Lourdes<-read.csv(paste(path,"/", "lourdes-", Sys.Date(), ".csv", sep=""), stringsAsFactors=FALSE)
Amb<-read.csv(paste(path, "/","cooper-ambulatory-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
Fam<-read.csv(paste(path, "/","cooper-family-med-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
Phys<-read.csv(paste(path,"/", "cooper-physicians-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
AR<-read.csv(paste(path, "/","acosta-ramon-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
fairview<-read.csv(paste(path, "/","fairview-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
phope<-read.csv(paste(path,"/", "project-hope-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
reliance<-read.csv(paste(path,"/", "reliance-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
luke<-read.csv(paste(path,"/", "st-luke-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
kylewill<-read.csv(paste(path,"/", "kyle-will-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
camcare<-read.csv(paste(path,"/", "camcare-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
uhi<-read.csv(paste(path,"/", "uhi-", Sys.Date(), ".csv", sep=""),stringsAsFactors=FALSE)
tvutils<-read.csv(paste(path,"/", "daily-utilization-export_", Sys.Date(),"_1", ".csv", sep=""),stringsAsFactors=FALSE)

# Rename fields in UHI file
uhi <- rename(uhi, c(Last.Provider="Provider"))

# Deletes unused fields
uhi$PCP.Name <- ""
uhi$Practice <- ""
uhi$Source <- ""

# Adds "NIC" to the uhi Subscriber ID if it's not already there 
uhi$Subscriber.ID <- ifelse(grepl("NIC", uhi$Subscriber.ID), uhi$Subscriber.ID, paste("NIC", uhi$Subscriber.ID, sep=""))

# Appends all files
aco <- rbind(Amb,AR,camcare,fairview,Fam,kylewill,Lourdes,luke,phope,Phys,reliance)

# Sorts columns alphabetically
aco <- aco[,order(names(aco))]
uhi <- uhi[,order(names(uhi))]

# Appends remaining files
aco <-rbind(aco,uhi)

# Subtracts the Admit Date from Today's date and subsets those admitted in the last 21 days
aco2 <- subset(aco, (Sys.Date()- as.Date(aco$Admit.Date, format="%Y-%m-%d"))<21)

# Creates a CurrentlyAdmitted field with text from Admit.Date field
aco2$CurrentlyAdmitted <- gsub("\\(()\\)","\\1",  aco2$DischargeDate)

# Removes parenthetical values from DateAdmited field
aco2$DischargeDate <- gsub("\\(.*\\)","\\1", aco2$DischargeDate)

# Removes dates from CurrentlyAdmitted field
aco2$CurrentlyAdmitted <- ifelse(aco2$CurrentlyAdmitted == aco2$DischargeDate, "", aco2$CurrentlyAdmitted)

# Identifies the columns for the two lists to be exported
hieutils <- data.frame(aco2[,c("Patient.ID",
                                     "Admit.Date",
                                     "Facility",
                                     "Patient.Class",
                                     "DischargeDate",
                                     "Provider",
                                     "Adm.Diagnoses",
                                     "Inp..6mo.",
                                     "ED..6mo.",
                                     "CurrentlyAdmitted")])


#Function to convert TrackVia dates to R dates
exceldate <- function(date){
  
  if (!is.character(date)) {
    
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

#Cleans date fields in the aco util file
tvutils$AdmitDate<-exceldate(tvutils$AdmitDate)
tvutils$DischargeDate<-exceldate(tvutils$DischargeDate)

# Create ID field for utilizations in the import file
hieutils$DischargeDate <- ifelse(hieutils$DischargeDate=="", "NA", hieutils$DischargeDate)
hieutils$ID <- paste(hieutils$Patient.ID, hieutils$Admit.Date, hieutils$Facility, hieutils$Patient.Class, hieutils$DischargeDate, sep="-")

# Create ID field for utilizations in the trackvia file
tvutils$ID <- paste(tvutils$HIE.Import.Link, tvutils$AdmitDate, tvutils$Facility, tvutils$PatientClass, tvutils$DischargeDate, sep="-")

# Subset records that are not in the acoutil file
acoUtilization <- hieutils[!hieutils$ID %in% tvutils$ID,]

# Renames fields to import
acoUtilization <- rename(acoUtilization, c(Patient.ID="HIE Import Link"))
acoUtilization <- rename(acoUtilization, c(Admit.Date="AdmitDate"))
acoUtilization <- rename(acoUtilization, c(Patient.Class="PatientClass"))
acoUtilization <- rename(acoUtilization, c(Adm.Diagnoses="HistoricalDiagnosis"))
acoUtilization <- rename(acoUtilization, c(Inp..6mo.="Inp6mo"))
acoUtilization <- rename(acoUtilization, c(ED..6mo.="ED6mo"))

# Filters acoUtilization to find ED Standards
ed_standards <- filter(acoUtilization, ED6mo <= 4, acoUtilization$PatientClass == "E")

# Adds an "import" column to ED Standards subset
ed_standards$import <- "no"

# Records not in the ED subset are "yes" in the import column
acoUtilization <- suppressMessages(left_join(acoUtilization, ed_standards)) %>% mutate(import = ifelse(is.na(import), "yes", "no"))

# Gets ACO Utilizations where import is "yes" (and ED Standards are removed)
acoUtilization <- subset(acoUtilization, acoUtilization$import == "yes")

# Drops unused columns
acoUtilization$import <- NULL
acoUtilization$ID <- NULL

# Replaces NA with spaces
acoUtilization$DischargeDate<-ifelse(acoUtilization$DischargeDate=="NA","", acoUtilization$DischargeDate)

#Exports csv file
write.csv(acoUtilization, (file=paste("ACO-Utilizations-", format(Sys.Date(), "%Y-%m-%d"), ".csv", sep="")), row.names=FALSE)
