suppressMessages(require(reshape))

#Sets file path
#path<-"Y:/Projects/Horizon Dashboard Automation"

#Calls temporary file and names it 
triageoutcome<-read.csv(paste("tmp/horizon_dashboard_update", ".csv", sep=""),stringsAsFactors = FALSE)
caplist <-read.csv(paste("tmp/caplist",  ".csv", sep=""), stringsAsFactors=FALSE)
#triageoutcome<-read.csv(paste(path, "/", "horizon_dashboard_update_", Sys.Date(), "_1",  ".csv", sep=""),stringsAsFactors = FALSE)
#caplist <-read.csv(paste(path,"/", "daily_cap_list_export_", Sys.Date(),"_1", ".csv", sep=""), stringsAsFactors=FALSE)

#Subsets data as matching and not matching HIE IDs
good<-subset(triageoutcome,   HIEID == HIE.Import.Link)
bad<-subset(triageoutcome,   HIEID != HIE.Import.Link)

#For the set with unmatched HIE IDs, sets HIE ID as HIE Import Link
bad$HIE.Import.Link<-bad$HIEID

#Subsets only HIE IDs that already exist in the caplist
bad<-subset(bad, (bad$HIE.Import.Link %in% caplist$Patient.ID.HIE))

#Renames variables to match to table
bad<-reshape::rename(bad, c(HIE.Import.Link="HIE Import Link"))
bad<-reshape::rename(bad, c(ticketid="Record Locator"))

#Removes unnecessary columns
bad$HIEID<-NULL

#Identifies fields to export
#HorizonDashboardUpdate<-bad[,c("Record Locator","HIE Import Link")]

#Exports file
#write.csv(bad, paste(Sys.Date(), "-", file="Horizon-Dashboard-Update", ".csv", sep=""), row.names=FALSE)
write.csv(bad, stdout(), row.names=FALSE)
