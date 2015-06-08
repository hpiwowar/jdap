
responses <- c("Strongly Agree","Agree","Somewhat Agree","Somewhat Disagree","Disagree","Strongly Disagree") # from top to bottom

library(reshape2)
x <- melt(d, measure.vars=c('Q4','Q5','Q17','Q21','Q22'))

p <- plot_likert(x, response='value', var_x='PolicyAdoptedAtPublication', var_facet="variable", response_order=responses, above_mid="Somewhat Agree", na.label="No response", xlab="% Responses", ylab="JDAP Policy")
  
p


response_order <- c("Strongly Agree","Agree","Somewhat Agree","Somewhat Disagree","Disagree","Strongly Disagree") # from top to botoom
above_mid <- "Somewhat Agree"
na.label = "No response"
xlab <- "% Responses"
ylab <- "JDAP Policy"

d$Response <- d[,]
d$XVar <- d[,]

plot_likert <- function(d, response='Q4', grouping_vars=, )
  
plot_likert <- function(d, response, grouping_vars, ) {
  d$Response <- d[,]
  d$XVar <- d[,]
  
    agg_responses <- ddply(d, .(Response, XVar), summarize, N.resp=length(Response))
    agg_totals <- ddply(d, .(XVar), summarize, N.total=length(Response))
    agg <- left_join(agg_responses, agg_totals, by="XVar")
    agg$P.resp <- with(agg, N.resp/N.total)
    
    agg$Response <- as.character(agg$Response)
    if (na.label != "") {
      agg$Response[is.na(agg$Response)] <- na.label
    } else {
      agg <- agg[!is.na(agg$Response),]
    }
    
    neutral_levels <- unique(agg$Response) %>% .[!. %in% response_order]
    agg$Response <- ordered(agg$Response, levels=c(response_order, neutral_levels))
    
    is_neutral <- with(agg, !Response %in% response_order)
    agg_neutral <- agg[is_neutral,]
    agg_neg <- subset(agg[!is_neutral,], Response > above_mid)
    agg_pos <- subset(agg[!is_neutral,], Response <= above_mid)
    
    n_pos <- length(unique(agg_pos$Response))
    n_neg <- length(unique(agg_neg$Response))
    n_neutral <- length(unique(agg_neutral$Response))
    
    fill_type <- c(rep("blue",n_pos), rep("red",n_neg), rep("darkgrey",n_neutral))
    names(fill_type) <- sort(unique(agg$Response))
    
    alpha_type <- c(seq(1, .1, -1/(1.1*n_pos)), seq(.1, 1, 1/(1.1*n_neg)), seq(1, .5, -1/(1.1*n_neutral)) )
    names(alpha_type) <- sort(unique(agg$Response))
    
    agg_pos <- agg_pos[order(agg_pos$Response, decreasing=T),]
    agg_neg <- agg_neg[order(agg_neg$Response, decreasing=F),]
    
    neutrality_levels <- c("Non-neutral","Neutral")
    agg_pos$ResponseNeutrality <- ordered(neutrality_levels[1], levels=neutrality_levels)
    agg_neg$ResponseNeutrality <- ordered(neutrality_levels[1], levels=neutrality_levels)
    agg_neutral$ResponseNeutrality <- ordered(neutrality_levels[2], levels=neutrality_levels)
    
    plot_breaks <- seq(-100,100,10)
    plot_labels <- c(seq(100,0,-10), seq(10,100,10))
    
    p <- ggplot(NULL, aes(fill=Response, alpha=Response)) + 
            geom_bar(data=agg_pos, aes(XVar, P.resp*100), stat="identity", position="stack") +
            geom_bar(data=agg_neg, aes(XVar, -P.resp*100), stat="identity", position="stack") +
            geom_bar(data=agg_neutral, aes(XVar, P.resp*100), stat="identity", position="stack") +
            scale_fill_manual(values=fill_type, breaks=names(fill_type), labels=names(fill_type)) + 
            scale_alpha_manual(values=alpha_type,  breaks=names(alpha_type), labels=names(alpha_type)) +
            ggplot2::xlab(ylab) + ggplot2::ylab(xlab) + scale_y_continuous(breaks=seq(-100,100,10), labels=plot_labels)
    # + geom_hline(intercept=1)
    
    p + theme_bw() + facet_grid(ResponseNeutrality~., scales="free_y", space="free_y", labeller=function(...) "") 
}

