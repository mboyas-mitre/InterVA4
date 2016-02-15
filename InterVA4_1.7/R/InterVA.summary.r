#' Summary of the results obtained from InterVA4 algorithm
#'
#' This function prints the summary message of the fitted results.
#'
#' @param object fitted object from \code{InterVA()}
#' @param top number of top CSMF to show
#' @param id the ID of a specific death to show
#' @param InterVA If it is set to "TRUE", only the top 3 causes reported by 
#' InterVA4 is calculated into CSMF as in InterVA4. The rest of probabilities 
#' goes into an extra category "Undetermined". Default set to "TRUE".
#' @param ... not used
#' @references http://www.interva.net/
#' @keywords InterVA
#' @examples
#' 
#' data(SampleInput)
#' ## to get easy-to-read version of causes of death make sure the column
#' ## orders match interVA4 standard input this can be monitored by checking
#' ## the warnings of column names
#' 
#' sample.output1 <- InterVA(SampleInput, HIV = "h", Malaria = "l", directory = "VA test", 
#'     filename = "VA_result", output = "extended", append = FALSE, replicate = FALSE)
#' 
#' summary(sample.output1)
#' summary(sample.output1, top = 10)
#' summary(sample.output1, id = "100532")
summary.interVA <- function(object, top = 5, id = NULL, InterVA = TRUE, ...){
    data("causetext", envir = environment())
    causetext <- get("causetext", envir  = environment())

	out <- NULL
	va <- object$VA
	out$top <- top
	out$N <- length(va)
	out$Malaria <- object$Malaria
	out$HIV <- object$HIV


	## Get population distribution
  	## Initialize the population distribution
    dist <- NULL
    for(i in 1:length(va)){
        if(!is.null(va[[i]][14])){	
	        dist <- rep(0, length(unlist(va[[i]][14])))	
	        break
        }
    } 
    ## determine how many causes from top need to be summarized
    undeter <- 0

    if(is.null(dist)){cat("No va probability found in input"); return}   
    ## Add the probabilities together
	if(!InterVA){
        for(i in 1:length(va)){
            if(is.null(va[[i]][14])) {undeter = undeter + 1; next}
            this.dist <- unlist(va[[i]][14])
            dist <- dist + this.dist
        }  
            ## Normalize the probability for CODs
        if(undeter > 0){
            dist.cod <- c(dist[4:63], undeter)
            dist.cod <- dist.cod/sum(dist.cod)
            names(dist.cod)<-c(causetext[4:63,2], "Undetermined")
        }else{
            csmf <- dist[4:63]/sum(dist[4:63])
            names(csmf)<-causetext[4:63,2]
        }      
    }else{
        csmf <- CSMF.interVA4(va)   
    }
    csmf <- data.frame(cause = names(csmf), likelihood = csmf)
    rownames(csmf) <- NULL

	if(!is.null(id)){
		index <- which(object$ID == id)
		if(is.null(index)){
			stop("Error: provided ID not found")
		}else if(is.null(va[[i]][14])){
			out$undet <- TRUE
		}else{
			out$undet <- FALSE
			probs.tmp <- object$VA[[index]][14][[1]]
			out$preg <- probs.tmp[1:3]
			out$probs <- probs.tmp[4:63]
			topcauses <- sort(out$probs, decreasing = TRUE)[1:top]
			out$indiv.top <- data.frame(Cause = names(topcauses))
			out$indiv.top$Likelihood <- topcauses
		}
		out$id.toprint <- id
	}else{
		out$csmf.ordered <- csmf[order(csmf[,2], decreasing = TRUE),]
	}

	class(out) <- "interVA_summary"
	return(out)
}

#' Print method for summary of the results obtained from InterVA4 algorithm
#'
#' This function prints the summary message of the fitted results.
#'
#' @param x summary of InterVA results
#' @param ... not used
#' @keywords InterVA
print.interVA_summary <- function(x, ...){
	# print single death summary
	if(!is.null(x$id.toprint)){
		cat(paste0("InterVA-4 fitted top ", x$top, " causes for death ID: ", x$id.toprint, "\n\n"))	
		if(x$undet){
			cat("Cause of death undetermined\n")
		}else{
			x$indiv.top[, 2] <- round(x$indiv.top[, 2], 4)
			print(x$indiv.top, row.names = FALSE, right = FALSE)		
		}	
	# print population summary
	}else{
		cat(paste("InterVA-4 fitted on", x$N, "deaths\n"))
		cat("\n")
		cat(paste("Top", x$top,  "CSMFs:\n"))
		csmf.out.ordered <- x$csmf.ordered[1:x$top, ]
	    csmf.out.ordered[, 2] <- round(csmf.out.ordered[, 2], 4)
	    print(csmf.out.ordered, right = FALSE, row.names = F)
	}	
}