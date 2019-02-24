library(dplyr)


temp <- tempfile()
download.file("https://www.fec.gov/files/bulk-downloads/2018/oppexp18.zip",temp)
oppexp <- read.table(unz(temp, "oppexp.txt"), header=FALSE, sep="|", fill=TRUE)
unlink(temp)
remove(temp)

oppexp_head <- read.csv("oppexp_header_file (1).csv")

names(oppexp) <- names(oppexp_head) %>% tolower()
names(oppexp)[26] <- "none"

polling <- oppexp %>% filter(grepl('Polling', purpose))