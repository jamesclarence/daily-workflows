#Attaches packages the script needs to run
suppressWarnings(suppressMessages(require(reshape)))
suppressWarnings(suppressMessages(require(dplyr)))

#Reads in files
# Reads in files
AR      <-read.csv(paste("tmp/acosta-ramon", ".csv", sep=""),stringsAsFactors=FALSE)
cam     <-read.csv(paste("tmp/camcare", ".csv", sep=""),stringsAsFactors=FALSE)
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
tvutils <-read.csv(paste("tmp/tvutils", ".csv", sep=""),stringsAsFactors=FALSE)

# Rename fields in UHI file
uhi <- reshape::rename(uhi, c(Last.Provider="Provider"))

# Deletes unused fields
uhi$PCP.Name <- ""
uhi$Practice <- ""
uhi$Source <- ""

# Adds "NIC" to the uhi Subscriber ID if it's not already there 
uhi$Subscriber.ID <- ifelse(grepl("NIC", uhi$Subscriber.ID), uhi$Subscriber.ID, paste("NIC", uhi$Subscriber.ID, sep=""))

# Appends all files
aco <- rbind(Amb,AR,cam,fairview,Fam,kylewill,Lourdes,luke,phope,Phys,reliance)

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
hieutils <- data.frame(aco2[,c(
  "Patient.ID",
  "Admit.Date",
  "Facility",
  "Patient.Class",
  "DischargeDate",
  "Provider",
  "Adm.Diagnoses",
  "Inp..6mo.",
  "ED..6mo.",
  "CurrentlyAdmitted"
)])

#Cleans date fields in the tvutils file by removing the time
tvutils$AdmitDate<-gsub("T12:00:00-0700", "",tvutils$AdmitDate)
tvutils$DischargeDate<-gsub("T12:00:00-0700", "",tvutils$DischargeDate)
tvutils$DischargeDate<-gsub("-0001-11-30T00:00:00-0700", "" ,tvutils$DischargeDate)

#Replaces blanks with NAs in the tvutils DischargeDate field
tvutils$DischargeDate[tvutils$DischargeDate==""]  <- NA 

#Replaces blanks with NA values in the hieutils DischargeDate field
hieutils$DischargeDate[hieutils$DischargeDate==""]  <- NA 

# Create ID field for utilizations in the import file
hieutils$ID <- paste(
  hieutils$Patient.ID, 
  hieutils$Admit.Date, 
  hieutils$Facility, 
  hieutils$Patient.Class, 
  hieutils$DischargeDate, sep="-")

# Create ID field for utilizations in the trackvia file
tvutils$ID <- paste(
  tvutils$HIEID, 
  tvutils$AdmitDate, 
  tvutils$Facility, 
  tvutils$PatientClass, 
  tvutils$DischargeDate, sep="-")

# Subset records that are not in the acoutil file
acoUtilization <- hieutils[!hieutils$ID %in% tvutils$ID,]

# Renames fields to import
acoUtilization <- reshape::rename(acoUtilization, c(Patient.ID="HIEID"))
acoUtilization <- reshape::rename(acoUtilization, c(Admit.Date="AdmitDate"))
acoUtilization <- reshape::rename(acoUtilization, c(Patient.Class="PatientClass"))
acoUtilization <- reshape::rename(acoUtilization, c(Adm.Diagnoses="HistoricalDiagnosis"))
acoUtilization <- reshape::rename(acoUtilization, c(Inp..6mo.="Inp6mo"))
acoUtilization <- reshape::rename(acoUtilization, c(ED..6mo.="ED6mo"))

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
acoUtilization$DischargeDate <- as.character(acoUtilization$DischargeDate)
acoUtilization$DischargeDate[is.na(acoUtilization$DischargeDate)] <- ""

#Exports csv file
#write.csv(acoUtilization, (file=paste("ACO-Utilizations", ".csv", sep="")), row.names=FALSE)
write.csv(acoUtilization, stdout(), row.names=FALSE)
