library(parsedate)

d <- read.csv("../raw_data/Invitations_Timing.csv", as.is=T)

d$sent_date <- parse_date(d$sent_date)
d$publication_date <- parse_date(paste(d$year, d$data_month)) %>% as.yearmon
d$year <- NULL
d$data_month <- NULL
d$journal[d$journal=="unknown"] <- NA

# all notes are the same: 'initial'
unique(d$note)
d$note <- NULL

write.table(d, file="../Invitations_Timing.csv")
invitation_timing <- d
save(invitation_timing, file="../Invitations_Timing.rda")
