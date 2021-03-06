library(dplyr)
library(zoo)
source("../../src/aux_functions.R")


dates <- read.csv("../raw_data/Journal data archiving policies (as relevant to JDAP).csv", as.is=T)

# extract only the relevant parts
dates <- subset(dates, Abbreviation != "")[,c('Journal','Abbreviation','Policy.short','Date.policy.took.effect')]
colnames(dates) <- c('JournalName','Journal', 'policy', 'policy_start')

# reduce the number of policy categories
dates[dates$policy=="Unclear", 'policy_start'] <- '-'
dates[dates$policy=="Unclear", 'policy'] <- 'Encouraged'
dates[dates$policy=="SomeDataTypesRequired", 'policy'] <- 'Encouraged'

dates[dates$policy_start=='-','policy_start'] <- NA
#date_boundary <- grepl("[<>]", dates$policy_start)
#date_range <- grepl("-", dates$policy_start)

# parse_date() can deal with extra characters and the sort of ranges defined here. It uses the second date in the range.
# parse_date("< 18.08.2010")
# parse_date("31.12.2010-01.01.2010")

dates$policy_start_str <- dates$policy_start

dates$policy_start <- ""
dates$policy_start[!is.na(dates$policy_start_str)] <- parse_date(dates$policy_start_str[!is.na(dates$policy_start_str)]) %>% as.character
dates$policy_start

write.table(dates, file="../derived/Journal_JDAP_Adoption_Dates.csv")
save(dates, file="../derived/Journal_JDAP_Adoption_Dates.rda")
