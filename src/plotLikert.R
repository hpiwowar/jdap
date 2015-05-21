plot_likert <- function(d, response_order, above_mid, response, var_x, var_facet=NULL, na.label="No response", 
                        xlab="% Responses", ylab="", include.N=FALSE) 
{
    stopifnot(above_mid %in% response_order)
    
    grouping_vars <- c(var_x, var_facet)
    names(response) <- "Response"

    agg_responses <- ddply(d, c(response, grouping_vars), function(x) c(N.resp=nrow(x)))
    agg_totals <- ddply(d, c(grouping_vars), function(x) c(N.total=nrow(x)))
    agg <- left_join(agg_responses, agg_totals, by=c(grouping_vars))
    agg$P.resp <- with(agg, N.resp/N.total)
    agg$sgnP.resp <- agg$P.resp
    
    if (include.N) {
      agg[,var_x] <- sprintf("%s\n(N=%s)", agg[,var_x], agg$N.total)
    }
    
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
    agg_neg$sgnP.resp <- -agg_neg$sgnP.resp
    
    n_pos <- length(unique(agg_pos$Response))
    n_neg <- length(unique(agg_neg$Response))
    n_neutral <- length(unique(agg_neutral$Response))
    
    fill_type <- c(rep("blue",n_pos), rep("red",n_neg), rep("darkgrey",n_neutral))
    names(fill_type) <- sort(unique(agg$Response))
    
    alpha_type <- c(seq(1,.25,length.out=n_pos), seq(.25,1,length.out=n_neg), seq(1,.25,length.out=n_neutral) )
    names(alpha_type) <- sort(unique(agg$Response))
    
    agg_pos <- agg_pos[order(agg_pos$Response, decreasing=T),]
    agg_neg <- agg_neg[order(agg_neg$Response, decreasing=F),]
    
    neutrality_levels <- c("Non-neutral","Neutral")
    p <- ggplot(NULL, aes_string(x=var_x, fill='Response', alpha='Response'))
    if (nrow(agg_pos)) {
      agg_pos$ResponseNeutrality <- ordered(neutrality_levels[1], levels=neutrality_levels)
      p <- p + geom_bar(data=agg_pos, aes(y=sgnP.resp*100), stat="identity", position="stack")
    }
    if (nrow(agg_neg)) {
      agg_neg$ResponseNeutrality <- ordered(neutrality_levels[1], levels=neutrality_levels)
      p <- p + geom_bar(data=agg_neg, aes(y=sgnP.resp*100), stat="identity", position="stack")      
    }
    if (nrow(agg_neutral)) {
      agg_neutral$ResponseNeutrality <- ordered(neutrality_levels[2], levels=neutrality_levels)
      p <- p + geom_bar(data=agg_neutral, aes(y=sgnP.resp*100), stat="identity", position="stack")     
    }
    p <- p + scale_fill_manual(values=fill_type, breaks=names(fill_type), labels=names(fill_type)) + 
             scale_alpha_manual(values=alpha_type,  breaks=names(alpha_type), labels=names(alpha_type)) 
    
    plot_breaks <- seq(-100,100,10)
    plot_labels <- c(seq(100,0,-10), seq(10,100,10))
    p <- p + ggplot2::xlab(ylab) + ggplot2::ylab(xlab) + scale_y_continuous(breaks=plot_breaks, labels=plot_labels)
    
    facet_formula <- sprintf("%s ~ %s", ifelse(nrow(agg_neutral), "ResponseNeutrality", "."),
                                        ifelse(is.null(var_facet), ".", var_facet)) %>% as.formula
    p <- p + theme_bw() + facet_grid(facet_formula, scales="free_y", space="free_y") #, labeller=function(...) "" 
    p
}