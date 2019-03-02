library(dplyr)
library(politicaldata)
library(maps)

temp <- tempfile()
download.file("https://www.fec.gov/files/bulk-downloads/2018/oppexp18.zip",temp)
oppexp <- read.table(unz(temp, "oppexp.txt"), header=FALSE, sep="|", fill=TRUE)
unlink(temp)
remove(temp)

oppexp_head <- read.csv("oppexp_header_file (1).csv")

names(oppexp) <- names(oppexp_head) %>% tolower()
names(oppexp)[26] <- "none"

polling <- oppexp %>% filter(grepl('poll|Poll|POLL', purpose))

cand <- read.table(file="cn.txt", header=FALSE, sep="|", fill=TRUE)
cand_head <- read.csv(file="cn_header_file.csv")
names(cand) <- names(cand_head) %>% tolower()

committee <- read.table(file="cm.txt", header=FALSE, sep="|", fill=TRUE)
comm_head <- read.csv(file="cm_header_file.csv")
names(committee) <- names(comm_head) %>% tolower()

census <- read.csv(file="census_data_all.csv")
census_metadata <- read.csv(file="census_metadata.csv")

pres <- pres_results_by_cd
house <- house_results
pres_polls <- us_pres_polls_history
house_dw <- get_house_nominate(congress=114)
sen_dw <- get_senate_nominate(congress=114)
