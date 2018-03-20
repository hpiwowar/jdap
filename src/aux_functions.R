vmap <- function (vec, from, to) {
  newVec <- vec
  for (i in 1:length(from)) {
    newVec[vec == from[i]] <- to[i]
  }
  return(newVec)
}
nmap <- function (vec, fromto, cast = I) cast(vmap(vec, names(fromto), fromto))


#@parse_date is overrides parse_date() from the parsedate package to deal with a bug which
#   results in incorrect days being returned when empty strings are present
parse_date <- function(dates, approx = TRUE) {
  library(parsedate)
  ret <- parsedate::parse_date(dates, approx)
  ind_invalid <- is.na(ret)
  ret[!ind_invalid] <- parsedate::parse_date(dates[!ind_invalid], approx)
  ret
}