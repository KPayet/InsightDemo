require(rjags)
require(runjags)

avgSentiment = function(sentiments, nChains = 3, nSteps = 10000){
    
    y = sentiments$score
    dataList = list(
        y = y,
        NTotal = length(y),
        yMean = mean(y),
        ySD = sd(y)
    )
    
    initList = function() {
        resampledY = sample(y , replace=TRUE )
        muInit = mean(resampledY)
        muInit = 0.001+0.998*muInit # keep away from 0 and 1
        sigmaInit = sd(resampledY)/sqrt(length(resampledY))
        nuInit = 30 + rnorm(1)
        
        
        return( list( mu = muInit, sigma = sigmaInit, nu = nuInit) )
    }
    
    modelString = "
      model {
        for(i in 1:NTotal) {
          y[i] ~ dt(mu, 1/sigma^2, nu)
        }
        mu ~ dnorm(yMean, 1/(10*ySD)^2)
        sigma ~ dunif(ySD/100, 100*ySD)
        nuMinusOne ~ dexp(1/29)
        nu <- nuMinusOne + 1
      }
    "
    writeLines(modelString, con = "tempMCMC.txt")
    
#     jagsModel = jags.model(file = "tempMCMC.txt", data = dataList, n.chains = 3, n.adapt = 1000)
#     update(jagsModel, n.iter = 2000)
#     codaSample = coda.samples(jagsModel, variable.names = c("mu", "sigma"), n.iter = ceiling(nSteps/3))
    
    runJagsOut = run.jags(method = "parallel", model = "tempMCMC.txt", monitor = c("mu"),
                          data = dataList, inits = initList, 
                          n.chains = nChains, adapt = 1000, burnin = 2000, sample = ceiling(nSteps/nChains), 
                          summarise = F, plots = F)
    
    codaSample = as.mcmc.list(runJagsOut)
      
    mcmcDiagnostics(codaSample)
    
    mcmcMat = as.matrix(codaSample)
    
    return(mcmcMat)
    
}

mcmcModel = function(data, predicted="", predictors="") {
    
}