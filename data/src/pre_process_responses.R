
library(plyr)
library(dplyr)
library(tidyr)
library(assertthat)
source("../../src/aux_functions.R")

assign_type_to_columns <- function(d, questions, mapping, levels, to_NA, type=ordered) {
  expected_levels  <- c(levels, to_NA)
  for(q_col in questions) {
    if (!q_col %in% colnames(d))
      stop(sprintf("Column '%s' does not exist.", q_col))
    
    d[,q_col] <- nmap(d[,q_col], mapping)
    not_in_expected_levels <- !d[,q_col] %in% expected_levels
    if(any(not_in_expected_levels)) {
      cat("Unexpected levels in", q_col, ":")
      print(unique(d[not_in_expected_levels,q_col]))
      stop()
    }
    
    d[,q_col] <- type(d[,q_col], levels) %>% droplevels
  }
  d
}


d <- read.csv("../raw_data/JDAP_Survey_Data.csv", header=T, fill=TRUE, fileEncoding="UTF-8", as.is=T)
key <- d[1,]
d <- d[-1,]
colnames(d)[1:6] <- as.character(key[1:6])

# remove irrelevant variable
assert_that(unique(d$ResponseSet) ==  "Default Response Set")
d$ResponseSet <- NULL
key$ResponseSet <- NULL

# # temporarily (TODO) delete open questions
# d$Q9_16_TEXT <- NULL
# d$Q12_6_TEXT <- NULL
# d$Q13_5_TEXT <- NULL
# d$Q14_8_TEXT <- NULL
# d$Q18_12_TEXT <- NULL
# d$Q25 <- NULL

# These records look strange. Besides the journal names and year (9999), all the answers that were given are the same. Furthermore, only questions with numberical answers
# were answered.
invalid_journal_names <- c("","A","B","F","G","J","M","O", "TEST","Test Journal")
subset(d, journal %in% invalid_journal_names)
# Let's exclude them
d <- subset(d, !journal %in% invalid_journal_names)


sort(unique(d$journal))


### Recode responses to all questions using the agree-disagree scale
questions_agree_disagree <- c('Q4','Q5','Q17',sprintf("Q18_%d",1:12),sprintf("Q19_%d",1:11), 'Q21', 'Q22')
mapping_agree_disagree <- c("Strongly disagree"="Strongly Disagree","Somewhat disagree"="Somewhat Disagree","Somewhat agree"="Somewhat Agree","Strongly agree"="Strongly Agree")
levels_agree_disagree <- rev(c("Strongly Disagree","Disagree","Somewhat Disagree","Neutral","Somewhat Agree","Agree","Strongly Agree"))
d <- assign_type_to_columns(d, questions_agree_disagree, mapping_agree_disagree, levels_agree_disagree, c("","."))  # TODO: What's with the dots in responses to questions 18-19
  

### Recode responses to all subquestions of question 9
questions_never_often <- c(sprintf("Q9_%d", c(1:5,7:17)))
mapping_never_often <- c()
levels_never_often <- c("Never","Once","A few times","Many times")
d <- assign_type_to_columns(d, questions_never_often, c(), levels_never_often, c(""))


### Recode responses to question 7
mapping_Q7 <- c("I'm not sure if any of my papers have publicly available datasets"="Not sure",
                "I've never published a paper based on a dataset collected by me or my co-authors"="No papers based on own data",
                "No, none of my paper-related datasets are publicly available on the internet"="No papers with archived data",
                "Yes, a dataset from <b>one paper</b> is publicly available on the internet"="1 paper with archived data",
                "Yes, datasets from <b>2-4 papers</b> are publicly available on the internet"="2-4 papers with archived data",
                "Yes, datasets from <b>5 or more papers</b> are publicly available on the internet"="5+ papers with archived data")
d <- assign_type_to_columns(d, 'Q7', mapping_Q7, mapping_Q7, c(""), factor)



num_nonempty <- function(d) rowSums(d != '')
unique_nonempty <- function(d) ddply(d, .(1:nrow(d)), function(d) { sort(unique(unlist(d)),T)[1] })$V1

### Recode responses to question 11_1
cur_d <- d[,paste0("Q11_1_",1:6)]
d <- select(d, -starts_with("Q11_1_"))
# map all responses which include "I don't know" (Q11_x_6) to "I don't know" as the single response
cur_d[cur_d$Q11_1_6!="", paste0("Q11_1_",1:5)] <- ""
# delete the response "Recommends online public archiving" (Q11_x_2) when "Requires online public archiving" (Q11_x_3) was also specified
cur_d[cur_d$Q11_1_3!="", "Q11_1_2"] <- ""
# treat all other conflicting responses as missing
several_values <- num_nonempty(cur_d) > 1
cur_d[several_values,] <- ""
# collect all responses in one column
d$Q11_1 <- unique_nonempty(cur_d)
# set all empty values to NAs
d$Q11_1[d$Q11_1 == ""] <- NA

### Recode responses to question 11_2
cur_d <- d[,paste0("Q11_2_",1:6)]
d <- select(d, -starts_with("Q11_2_"))
# map all responses which include "I don't know" (Q11_x_6) to "I don't know" as the single response
cur_d[cur_d$Q11_2_6!="", paste0("Q11_2_",1:5)] <- ""
# delete the response "Recommends online public archiving" (Q11_x_2) when "Requires online public archiving" (Q11_x_3) was also specified
cur_d[cur_d$Q11_2_3!="", "Q11_2_2"] <- ""
# treat all other conflicting responses as missing
several_values <- num_nonempty(cur_d) > 1
cur_d[several_values,] <- ""
# collect all responses in one column
d$Q11_2 <- unique_nonempty(cur_d)
# set all empty values to NAs
d$Q11_2[d$Q11_2 == ""] <- NA

### Recode responses to question 11_3
cur_d <- d[,paste0("Q11_3_",1:6)]
d <- select(d, -starts_with("Q11_3_"))
# map all responses which include "I don't know" (Q11_x_6) to "I don't know" as the single response
cur_d[cur_d$Q11_3_6!="", paste0("Q11_3_",1:5)] <- ""
# delete the response "Recommends online public archiving" (Q11_x_2) when "Requires online public archiving" (Q11_x_3) was also specified
cur_d[cur_d$Q11_3_3!="", "Q11_3_2"] <- ""
# treat all other conflicting responses as missing
several_values <- num_nonempty(cur_d) > 1
cur_d[several_values,] <- ""
# collect all responses in one column
d$Q11_3 <- unique_nonempty(cur_d)
# set all empty values to NAs
d$Q11_3[d$Q11_3 == ""] <- NA

# 
# ### Recode responses to question 12
# cur_d <- d[,paste0("Q12_",1:6)]
# d <- select(d, -starts_with("Q12_"))
# # overwrite 'other' if another value was specified as well
# several_values <- num_nonempty(cur_d) > 1
# cur_d[several_values, 'Q12_6'] <- ""
# # treat all other conflicting responses as missing
# several_values <- num_nonempty(cur_d) > 1
# # TODO: Figure out what to do with these
# cur_d[several_values,]
# cur_d[several_values,] <- ""
# d$Q12 <- unique_nonempty(cur_d)

library(plyr)
library(dplyr)
library(zoo)

# parse dates
d$PublicationDate <- parse_date(with(d, paste(month, year))) %>% as.yearmon %>% as.character
d$ResponseDate <- parse_date(d$StartDate) %>% as.yearmon %>% as.character

d <- select(d, ResponseID, ResponseDate, PublicationDate, Journal=journal, Q_1=Q4, Q_2=Q5, Q_3=Q7, 
            Q_4_=starts_with("Q9"), Q_5_=starts_with("Q11"), Q_6_=starts_with("Q12"), Q_7_=starts_with("Q13"),
            Q_8_=starts_with("Q14"), Q_9=Q17, Q_10_=starts_with("Q18"), Q_11_=starts_with("Q19"),
            Q_12=Q21, Q_13=Q22, Q_14_=starts_with("Q23"), Q_15=Q25, Q_16=Q26 )
d <- rename(d, Q_4_15_TEXT=Q_4_16, Q_4_16=Q_4_17, Q_6_6_TEXT=Q_6_7, Q_7_5_TEXT=Q_7_6, Q_7_6=Q_7_7, Q_8_8_TEXT=Q_8_9, 
            Q_8_9=Q_8_10, Q_8_10=Q_8_11, Q_10_12_TEXT=Q_10_13, Q_11_11_TEXT=Q_11_12 )

save(d, file="../JDAP_Survey_Data_Tidy.rda")
write.csv(d, file="../JDAP_Survey_Data_Tidy.csv")





