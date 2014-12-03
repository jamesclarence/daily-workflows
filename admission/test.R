require("jsonlite")

x <- fromJSON(readLines(file("stdin")))
print(x[2])

# UMPT<-read.csv(text=commandArgs(TRUE)[1]);
# write.csv(UMPT, stdout(), row.names=FALSE)
