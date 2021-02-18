# Function to create bootstrapped 95% confidence intervals on the fever_public_treat_wt.clustprop
# and fever_any_treat_wt.clustprop columns of the provided dataframe, which should contain data for 
# a single survey only.
# This method addresses the non-normality concern with the cluster proportion data but doesn't address 
# the more fundamental problem that the the cluster data are a different population (after the information 
# lost by aggregation) to the child data from which the national results area calculated. 
# Function also adds normal standard errors just for comparison to FME-calculated values for checking
createBootstrapCIs <- function(dfInput){
  # import the required library within the function as this code gets passed to independent 
  # processes by the paralleliser, sans environment
  library(bootBCa)
  
  # correct the cluster proportions according to the size of the cluster (such that the mean of the values is the same as the 
  # mean of the original child-level data, and thus the same as the national mean to which we will later apply the 
  # CIs we create here)
  avgClust <- mean(dfInput$had_fever_wt.clustcount)
  clustWts <- dfInput$had_fever_wt.clustcount / avgClust
  corrPubProp <- dfInput$fever_public_treat_wt.clustprop * clustWts 
  corrAnyProp <- dfInput$fever_any_treat_wt.clustprop * clustWts 
  
  # calculate the bootstrapped 95% CIs
  valsPub <- na.omit(corrPubProp)
  valsAny<-na.omit(corrAnyProp)  
  # don't attempt to call BCa if no data as it will crash the processing rather than return na
  if (length(valsPub > 0)){
    bsPub<-BCa(valsPub, 0.01, mean, alpha=c(0.025,0.975))
  } else {
    bsPub <- c("0.025"=0, "0.975"=0)
  }
  if (length(valsAny > 0)){
    bsAny<-BCa(valsAny, 0.01, mean, alpha=c(0.025,0.975))
  } else {
    bsAny <- c("0.025"=0, "0.975"=0)
  }
  # also add the se just so we can check them against the FME calculated values to make sure all is working
  sePublic <- sd(valsPub)/sqrt(length(valsPub))
  seAny <- sd(valsAny)/sqrt(length(valsAny))
  
  # need to use the weighted mean for the CI calculation. This should be the same as the national-level
  # figure so FME will have this anyway but we expose the R-derived version here to make sure we're 
  # getting things right...
  meanPublic <- mean(valsPub)
  meanAny <- mean(valsAny)
  
  # build the output dataframe that goes back to FME
  # columns added to the dataframe here are what we need to expose in the Attributes To Expose field
  dfOut<-data.frame(bs_lci_pub=bsPub["0.025"], bs_uci_pub=bsPub["0.975"], 
    bs_lci_any=bsAny["0.025"], bs_uci_any=bsAny["0.975"], 
    se_public=sePublic, se_any=seAny,
    mean_public=meanPublic, mean_any=meanAny)
  return(dfOut)
}

# function to create 95% confidence intervals for the public_treat and any_treat columns of the provided 
# dataframe. The dataframe should contain child-level data for a single survey only, and only for children who 
# had fever. The treatment columns should be binary (0/1) and weights provided as a separate column called 
# young_child_wt. This is the method used for the accepted confidence intervals .
createGLMCIs <- function(dfInput){
  pubmod <- glm(public_treat~1, data=dfInput, family=quasibinomial(), weights=young_child_wt)
  anymod <- glm(any_treat~1, data=dfInput, family=quasibinomial(), weights=young_child_wt)
  # just in case there were zero treated cases, that would cause an error, bodge around it.
  dfOut <- tryCatch({
      meanpub <- plogis(coef(pubmod))
      confpub <- plogis(confint(pubmod))
      meanany <- plogis(coef(anymod))
      confany <- plogis(confint(anymod))
      data.frame(glm_mean_public=meanpub, glm_lci_public=confpub["2.5 %"], glm_uci_public=confpub["97.5 %"], 
        glm_mean_any=meanany, glm_lci_any=confany["2.5 %"], glm_uci_any=confany["97.5 %"])
  },
  error=function(cond){
      return (data.frame(glm_mean_public=-9999, glm_lci_public=-9999, glm_uci_public=-9999, 
        glm_mean_any=-9999, glm_lci_any=-9999, glm_uci_any=-9999))
  },
  warning=function(cond){return(NULL)}
  )
  return (dfOut)
}