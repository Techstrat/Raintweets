
rain_tweet_plot <- function(rain_tweet.dt,title){
  # --------------------------------------------------------------------------------------------
  # Generates two graphs on one plot with date as the common x-axis
  #  geom_area graph represents the number of tweets in turquoise
  #  geom_bar grpah represent the volume in rain measured
  # Input parameters is the data in a data.table and the title of the graph
  # Output is the Graph
  p<-ggplot(rain_tweet.dt, aes(x=date), fill = date) +
    geom_area(aes(y=tweets/5), colour = "turquoise3", fill = "skyblue3") + 
    geom_bar(aes(weight = rain), colour = "darkgoldenrod3", fill = "lightgoldenrod3") +
    theme(axis.text.y = element_blank(),
          axis.text.x = element_text(),
          axis.ticks = element_blank(),
          # panel.grid  = element_blank(),
          legend.title = element_blank(),
          legend.position="top",
          plot.title = element_text(hjust = 0.5,size=10, face="bold"),
          plot.subtitle = element_text(hjust = 0.5,size=8, face="bold"))+
    labs(x = "Date", y = "",
         subtitle = paste("Plotting tweets containing the word RAIN (blue)","against actual rainfall (gold) measured in Cape Town",sep="\n"),
         title = title)+    
  scale_x_datetime(date_breaks = "1 days", date_labels = "%d %b")
  
  return(p)
}

rain_tweet_cor <- function(rain_tweet.dt, title) {
  # --------------------------------------------------------------------------------------------
  # Generates a ggscatter graph to demonstrate the corelation beween two series
  # Use the Pearson method to calculate correlation and show the confidence interval
  # around the line fitted to the mapped points
  # Input parameters is the data in a data.table and the title of the graph
  # Output is the Graph
  
  ## Pearson Correlation test
  res1<- cor.test(rain_tweet.dt$tweets, rain_tweet.dt$rain, method= "pearson") 
  subtitle <- paste("The p-value of the test is",signif(res1$p.value,digits=4),", less than the significance level alpha = 0.05.") 
  subtitle <- paste(subtitle,"We can conclude that the rainfall and tweets containing the word Rain are correlated", sep="\n")
  tail<-paste("with a correlation coefficient of",signif(res1$estimate,digits=4))
  subtitle <- paste(subtitle,tail, sep="\n")
  
  #Visualise
  p<-ggscatter(rain_tweet.dt, x = "tweets", y = "rain", 
               add = "reg.line", conf.int = TRUE, 
               cor.coef = TRUE, cor.method = "pearson",
               xlab = "Number of RAIN tweets", ylab = "MM Rainfall",
               title = title, 
               subtitle = subtitle,
               font.title = c(10, "bold", "black"),
               font.subtitle = c(9, "bold", "black"),
               font.x = c(12, "bold", "skyblue3"),
               font.y = c(12, "bold", "lightgoldenrod3")
  )
  return(p)
}

collect_word_tweet <- function(word,num_tweets,geo="-33.89,19.12,125km") {
  # --------------------------------------------------------------------------------------------
  # This function uses the search_tweets method in the rtweet library
  # It havests all the tweets with in a specific geo code area containing a specific word.
  # (Default geo is 125km radius around Capt Town)
  # It returns the unique tweet id and the date and time the tweet was created.
  # The harvest includes re-tweets
  # To enusre the tweets retrieved do not exceed the twitter limit of 18000 tweets - num_tweets needs to be less than 18000
  # --------------------------------------------------------------------------------------------
  # Input Parameters:
  # word_string - word to look for on twitter
  # num_tweets - maximum number of tweets to harvest 
  # geo - the area where the tweets originate from
  # --------------------------------------------------------------------------------------------
  # Return:
  # A data table with 2 twitter fields: 
  # status_id - a uniq twitter id
  # created_at - date and time the tweet was created
  # --------------------------------------------------------------------------------------------
  
  library(rtweet) 
  #   harvest tweets
  word_tweets <- search_tweets(q = word, lang = "en", n=num_tweets, include_rts = TRUE, geocode = geo)
  
  # Create data table of harvested tweets
  word_tweets.dt <- setDT(as.list(word_tweets))[]
  if (nrow(word_tweets.dt)>0) { 
    word_tweets.dt <- word_tweets.dt[,c("status_id","created_at")]
  }
  return(word_tweets.dt) 
}

################################ Main process
library(lubridate)
library(ggmap)
library(data.table)
library(ggpubr)

##### Source the Data - Rainfall ##############################
## Upload Rainfall figures from CPT_Rainfall.csv
# Rainfall figures for Cape twon was previously downloaded 
# form the World Weather Online website (https://www.worldweatheronline.com)
# The .csv file contains two columns: 
#     Date: ä date at 3 hour intervals in the format dd/mm/yyyy hh:mm:ss
#     Rainfall a one decomal figutre indicating the rainfall for the 3 hour interval starting on the date time given
rainfall.dt <- fread("CPT_Rainfall.csv")
setnames(rainfall.dt, c("date","rain"))
rainfall.dt$date <- dmy_hms(rainfall.dt$date, tz = "Africa/Johannesburg") #convert to correct date format

##### SOurtce the Data - Tweets ##############################
### Harvest RAIN tweets from in and around Cape Town
# define harvest parameters
CPT_Yzerf_Agulhas <- "-33.89,19.12,125km"
word_string <- "rain"
num_tweets = 5000
# collect tweets
weather_words.dt <- collect_word_tweet(word_string,num_tweets,CPT_Yzerf_Agulhas)
### Summarise the tweets into weather words
#start from the ealiest date where both series has an entry
weather_words.dt <- weather_words.dt[order(created_at),]
rainfall.dt <- rainfall.dt[order(date),]
weather_words.dt$created_at<-ymd_hms(weather_words.dt$created_at, tz = "Africa/Johannesburg")
start_date = weather_words.dt$created_at[1]
if (start_date<rainfall.dt$date[1]) {start_date = rainfall.dt$date[1]}
weather_words.dt <- weather_words.dt[as.Date(weather_words.dt$created_at) >= as.Date(start_date)]

###Count tweets per 3 hour interval
#Set the time of the first tweet to be created on the hour
weather_words.dt$created_at[1]<-paste(substr(weather_words.dt$created_at[1],1,11),"00:00:00",sep="")

#convert created_at to date and create the by-the hour column
weather_words.dt$created_at<-ymd_hms(weather_words.dt$created_at, tz = "Africa/Johannesburg")
weather_words.dt<- weather_words.dt[, group := cut(weather_words.dt$created_at, breaks = "180 min")]  
#count occurences per hour per date
tweets_per_hour.dt <- weather_words.dt[, .(count = .N), by = group]
setnames(tweets_per_hour.dt, c("date","tweets") )
tweets_per_hour.dt$date<-ymd_hms(tweets_per_hour.dt$date, tz = "Africa/Johannesburg")

###Join Rainfall with Tweets per hour and graph
#Reset start and end dates
start_date <- tweets_per_hour.dt$date[1]
end_date <- tweets_per_hour.dt$date[nrow(tweets_per_hour.dt)]
if (start_date<rainfall.dt$date[1]) {start_date = rainfall.dt$date[1]}
if (end_date>rainfall.dt$date[nrow(rainfall.dt)]) {end_date=rainfall.dt$date[nrow(rainfall.dt)]}

# combine data
comb_data.dt <- tweets_per_hour.dt[rainfall.dt, on = 'date']
comb_data.dt <- comb_data.dt[date>=start_date & date<=end_date]
comb_data.dt[is.na(comb_data.dt)] <- 0
#Sum per day and graph
comb_data_sum.dt<- comb_data.dt[, .(tweets = sum(tweets), rain = sum(rain)), by = list(date(comb_data.dt$date))]
comb_data_sum.dt$date<-ymd(comb_data_sum.dt$date, tz = "Africa/Johannesburg")

#hourly correlation
p1 <- rain_tweet_plot(comb_data.dt,"Tweets from a 125km radius around Cape Town per 3 hour intervals")
p2 <- rain_tweet_cor(comb_data.dt,
                     paste("Correlation between rainfall and number of RAIN tweets per 3 hour intervals from",
                           comb_data_sum.dt$date[1],"to",comb_data_sum.dt$date[nrow(comb_data_sum.dt)]))
#daily total
p3 <- rain_tweet_plot(comb_data_sum.dt,"Tweets from a 125km radius around Cape Town per day")
p4 <- rain_tweet_cor(comb_data_sum.dt, 
                     paste("Correlation between rainfall and number of RAIN tweets per day from",
                          comb_data_sum.dt$date[1],"to",comb_data_sum.dt$date[nrow(comb_data_sum.dt)]))
# limit data to before 25 October - daily total correlation
end_date1 <-ymd_hms("2019-10-24 00:00:00", tz = "Africa/Johannesburg")
comb_data_sum1.dt <- comb_data_sum.dt[date<=end_date1]
p5 <- rain_tweet_plot(comb_data_sum1.dt,"Tweets from a 125km radius around Cape Town per day")
p6 <- rain_tweet_cor(comb_data_sum1.dt, 
                     paste("Correlation between rainfall and number of RAIN tweets per day from",
                           comb_data_sum1.dt$date[1],"to",comb_data_sum1.dt$date[nrow(comb_data_sum1.dt)]))




