source("helpers.R")
require(readr)

sentiments = read_csv("sentiments_states.csv", col_names = F)
names(sentiments) = c("state", "score")

# check that we have the right number of states
unique(sentiments$state)

str(sentiments)
summary(sentiments)

# seems like something wrong with Washington
#sentiments %>% filter(state=="Washington")
#sentiments %>% filter(is.na(score)) %>% select(state) %>% unique() # only state with NAs. Is it because of the name formatting in the csv file? Yes!

# reload and reprocess

# how much data do we have per state?
require(dplyr)

sentiments %>%  group_by(state) %>%
                summarise(N = n()) %>%
                arrange(N)  %>%
                print.data.frame()

avgSent =   sentiments %>%  group_by(state) %>%
                            summarise(avgSent = mean(score), N = n()) %>%
                            arrange(desc(avgSent))

avgSent %>% print.data.frame()

# Ok the first nice thing we see is that in average, every state seems happy. Or at least not unhappy...

# Let's do a nice bar chart with ggplot

require(ggplot2)
canvas()
ggplot(data = avgSent, aes(x=state, y=avgSent)) + geom_bar(stat = "identity", fill = "red") + coord_flip() + theme_minimal()

# would prefer bars ordered by avg sentiment
avgSent = arrange(avgSent, (avgSent))
avgSent$state = factor(avgSent$state, levels = avgSent$state, ordered = T)

canvas()
(barChart = ggplot(data = avgSent, aes(x=state, y=avgSent)) + 
                geom_bar(stat = "identity", fill = "cadetblue3") + 
                geom_text(aes(label=state), size = 3.2, hjust = 1.5, vjust = 0.35) + 
                coord_flip() + labs(y = "Average sentiment score", x = "State", title = "Happiest states") + 
                theme_minimal() + theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()))

mapDF = as.data.frame(avgSent[,1:2])
mapDF$state = sapply(mapDF$state, tolower)
names(mapDF) = c("region", "value")
mapDF = arrange(mapDF, region)

# need state codes
state_code = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
               "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
               "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")

mapDF$code = state_code


# want to see a map to see if there is some geographical influence
source("mapping.R")
#canvas()
drawMap(mapDF, method = "plotly")

# What factors influence quality of life?

qualityFactors = read_csv("lifeQualityFactors.csv")

avgSent = arrange(avgSent, as.character(state))
avgSent$code = state_code

avgSent = inner_join(avgSent, qualityFactors, by="code")
avgSent = avgSent[,c(1,4,3,2,5,6,7,8,9,10)]

require(mice)
avgSent = complete(mice(avgSent))

cor(avgSent[,4:10]) # :-(
# why do is there no influence ?
#   1- too few data => wrong ranking and sentiments
#   2- sentiment computation
#   3- choice of factors
#   4- 

###
### RJags analysis
###

# 1 - see if there actually is a difference between groups in those data points
#   This is one of the simplest case: metric predicted variable (score) + 1 nominal predictor

# fit = aov(score~state, data=sentiments) too much differences between sample sizes
sentiments$state = as.factor(sentiments$state)
fit = kruskal.test(score~state, data = sentiments) # of course it is unequal
# tukTest = TuekyHSD(fit)
require(pgirmess)
fitMC = kruskalmc(score~state, data = sentiments) # pairwise comparison
fitMC$dif.com[grepl("New York", rownames(fitMC$dif.com)),]


source("bayesModel.R") 

sentiments$state = as.factor(sentiments$state)
NY = sentiments %>% filter(state == "New York")
SD = sentiments %>% filter(state == "South Dakota")


avgSDMCMC = avgSentimentStan(SD, nChains = 4, nSteps = 20000)
plotPost(avgSDMCMC[,"mu"], cenTend = "mode", credMass = 0.95)

# system.time(avgSentimentStan(sentiments[sample(1:nrow(sentiments), 40000, replace = F),], nChains = 5, nSteps = 20000) -> avgMCMC)
# plotPost(avgMCMC[,"mu"], cenTend = "mode", credMass = 0.95)
# 
# avgNYMCMC = avgSentiment(NY, nChains = 4, nSteps = 20000)
# plotPost(avgNYMCMC[,"mu"], cenTend = "mode", credMass = 0.95)
