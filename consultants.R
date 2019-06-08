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
fips_cd <- sqldf("select fips_cd.*, case when fips_cd.cd = '00' THEN '01' ELSE fips_cd.cd END as cd_fix from fips_cd")

remove(fips_cd_temp)
remove(fips_states_temp)

# Add Census ID to DW House Scores
house_dw$district_code <- str_pad(house_dw$district_code, 2, pad="0")
house_dw <- sqldf("select house_dw.*, fips_cd.census_id from house_dw left join fips_cd on fips_cd.state = house_dw.state_abbrev and fips_cd.cd_fix = house_dw.district_code")

# Add Census ID to House Election Results
house <- sqldf("select house.*, rightstr(house.district, 2) as cd from house")
house <- sqldf("select house.*, case when house.cd='AL' THEN '01' ELSE house.cd END as cd_fix from house")
house <- sqldf("select house.*, fips_cd.census_id from house left join fips_cd on house.cd_fix = fips_cd.cd_fix and house.state_abb = fips_cd.state")
 
# Add Census ID to DW Nominate
house_dw <- sqldf("select distinct house_dw.*, fips_cd.census_id from house_dw left join fips_cd on house_dw.state_abbrev=fips_cd.state and house_dw.district_code = fips_cd.cd_fix")

# Add Census ID to Pres Election Results
pres$district <- str_pad(pres$district,2, pad = "0")
pres <- sqldf("select pres.*, fips_cd.census_id from pres left join fips_cd on pres.district = fips_cd.cd_fix and pres.state_abb = fips_cd.state")

#Subsets
census_data <- census[-1,]
census_small <- sqldf("select distinct census_data.census_id, census_data.HD02_S025 as over65, census_data.HD02_S051 as female, census_data.HD02_S101 as afam from census_data")

pres16 <- sqldf("select distinct * from pres where pres.year=2016")
pres12 <- sqldf("select distinct * from pres where pres.year=2012")

house16 <- sqldf("select distinct * from house where house.year=2016")
house10 <- sqldf("select distinct * from house where house.year=2010")
house18 <- sqldf("select distinct * from house where house.year=2018")

pred_data <- sqldf("select distinct census_small.*, house18.dem as h18dem, house10.dem as h10dem, house_dw.nominate_dim1, house_dw.nominate_dim2, pres16.dem as p16dem, pres12.dem as p12dem from census_small 
left join house18 on census_small.census_id = house18.census_id
left join house10 on census_small.census_id = house10.census_id
left join pres16 on census_small.census_id = pres16.census_id
left join pres12 on census_small.census_id = pres12.census_id
left join house_dw on census_small.census_id = house_dw.census_id")

pred_data$over65 <- as.numeric(pred_data$over65)
pred_data$afam <- as.numeric(pred_data$afam)
pred_data$female <- as.numeric(pred_data$female)

#Modeled 2018 House Results
model <- lm(h18dem ~ h10dem + p16dem + p12dem + nominate_dim1 + nominate_dim2 + afam + female + over65, data=pred_data)

pred_data$predict <- predict(model, newdata = pred_data)
pred_data$resid <- pred_data$predict - pred_data$h18dem


