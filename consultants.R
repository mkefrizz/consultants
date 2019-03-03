# Load Libraries

library(dplyr)
library(politicaldata)
library(maps)
library(sqldf)
library(stringr)

# Get FEC Expenditures data
temp <- tempfile()
download.file("https://www.fec.gov/files/bulk-downloads/2018/oppexp18.zip",temp)
oppexp <- read.table(unz(temp, "oppexp.txt"), header=FALSE, sep="|", fill=TRUE)
unlink(temp)
remove(temp)

oppexp_head <- read.csv("oppexp_header_file (1).csv")

names(oppexp) <- names(oppexp_head) %>% tolower()
names(oppexp)[26] <- "none"

# Subset for polling only
polling <- oppexp %>% filter(grepl('poll|Poll|POLL', purpose))

# Load FEC Candidate lookup
cand <- read.table(file="cn.txt", header=FALSE, sep="|", fill=TRUE)
cand_head <- read.csv(file="cn_header_file.csv")
names(cand) <- names(cand_head) %>% tolower()

# Load FEC committee lookup
committee <- read.table(file="cm.txt", header=FALSE, sep="|", fill=TRUE)
comm_head <- read.csv(file="cm_header_file.csv")
names(committee) <- names(comm_head) %>% tolower()

# Load census data
census <- read.csv(file="census_data_all.csv")
census_metadata <- read.csv(file="census_metadata.csv")
names(census)[2] <- "census_id"


# Load election results
pres <- pres_results_by_cd
house <- house_results
pres_polls <- us_pres_polls_history
house_dw <- get_house_nominate(congress=114)

# Load FIPS lookup
fips <- read.csv(file="fips_lookup.csv")
fips_cd_temp <- sqldf("select distinct census_id from census")
fips_states_temp <- sqldf("select distinct state, state_fips from fips")
fips_states_temp$state_fips <- str_pad(fips_states_temp$state_fips, 2, pad="0")
fips_cd_temp <- as.data.frame(fips_cd_temp[-c(1),])
names(fips_cd_temp)[1] <- "census_id"
fips_cd <- sqldf("select fips_cd_temp.census_id, fips_states_temp.state_fips, fips_states_temp.state, 
                 rightstr(fips_cd_temp.census_id, 2) as cd 
                 from fips_states_temp 
                 left join fips_cd_temp 
                 on fips_states_temp.state_fips = leftstr(fips_cd_temp.census_id,2)"
                 )




remove(fips_cd_temp)
remove(fips_states_temp)