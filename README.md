# raintweets
What is the correlation between rainfall and tweets containing the word RAIN

## A trivial day for Rain and Twitter correlation
On Friday 25 October I woke up with the sweet sound of rain on our corrugated roof. Like anyone who has lived through the real threat of “day zero” where Cape Town’s taps would run dry, rain will forever be a life-giving blessing. Later, sitting on the front porch with my morning coffee the sweet sound had evolved into a deafening sound of a cold shower of water bucketing down.  I don my rain coat and old tekkies and check the normally soothing mountain stream bordering our garden - it has quadrupled in size, breaking the bank on the far side – our bedroom still safe from any flooding – for now.  Thirty minutes later this has changed, with rain still beating down, the stream breaks bank on the near side transforming our back garden into an ankle-deep muddy pool.  I give up any illusions of staying dry under my raincoat.  Clearing the water outlet on the back wall from rotting oak leaves and earthworm sand with a clumsy shovel, the water starts draining, into the road on the one side and back into the stream on the other, but not quite at the same volume water is filling up the backyard mud pool.  I leave the shovel, snap a few pictures and share it.  Drenched, clutching my cold coffee mug, I watch the river, willing it to slow down.  It somehow responds and slowly, over an hour, the water subsides.  By mid-morning the rain is still sifting down, but the garden stream is back within its confined banks and I have had a warm shower. 
Working on a client’s twitter data analysis that afternoon the rain had calmed to a drizzle.  I thought about the rain that morning and my eagerness to discuss and share this online.  I am surely not unique in this eagerness to tweet when rain beats down.  If that is true, there must be a strong correlation between the volume of twitter posts originating from a defined area containing the word RAIN and the actual recorded rainfall for that area.  Alas my null hypothesis was born.  The opposing alternative hypothesis – there is no correlation between the RAIN twitter posts for the area and the rainfall recorded.

## Collecting the data
To prove my hypotheses, I had to collect some data.
I defined the timeline of my hypotheses test as a few days before, during and after the heavy rain – about a week’s worth of data.  
I thought it should be easy to find the rainfall recorded (as opposed to predicted) for an area. It surprisingly is not.  I scoured the net for a few hours before I found the site that give a detailed breakdown of weather “as it happened” https://www.worldweatheronline.com.  I did not do too much research on the exact spot the rain was measured or who the measuring authority was – I was happy to read the millimetres of rain recorded in 3 hour intervals for a specific day in what I believe is Cape Town city centre.  Although World Weather Online has an API that I could have connected through, I decided since the data needed is limited to a week, building the API code in R would be time wasted.  I simply copied the data from the website to a .csv file that I could read into my analysis. 
Twitter proved to be much easier, mostly because I have my Twitter developer account already set up. (You will need a developer account at Twitter to do this – there are several articles scattered on the net explaining how to set up the account and link your R environment to your account.) Many people work in Cape Town but live in the surrounding suburbs and towns which makes a 125km radius reasonable.  Looking at this circle on mapdevelopers.com I moved the centre of my circle a little East so somewhere between Stellenbosch and Franschhoek to catch more land and less sea.  
The free twitter developer license gives me tweets from the last 7 to 8 days, 18 000 tweets every 15 minutes. After a few test runs downloading tweets that contain the word RAIN, I realised even looking at retweets, the total tweet count will be less than 5000 .  Using the rtweet package in r I could make the following once-off call to the twitter API:
search_tweets(q="rain", lang = "en", n=5000, include_rts, geocode = "-33.89,19.12,125km")

## Cleaning the data
Throughout my cleaning process I checked that each date/time column represent the date in the Central African Time zone using the ymd_hms() function with tz = "Africa/Johannesburg".
I needed to get the two data series to map one-to-one which means some work on the tweet data.  Since the historical rainfall was listed in 3 hour intervals I used the cut() function in r to change each tweet date/time to the 3 hour interval data/time and then counted the tweets per interval.
I reduced the each of the two series to have the same start and end date, removing entries outside these and joined on the common date column. Since the rainfall for each timeslot is given – even if it is zero, I do a left join on the rainfall data so each timeslot is represented in the combined data table.  I then replace the missing tweet data (NA) with 0.  Tweets are now represented in counts and rainfall in milli meters.

## Explore the data
Since the two series have completely different scales any good statistician would tell me I cannot represent them on the same plot – yet for clarity and seeing that this is exploration, I am prepared to commit a statistical cardinal sin.  I used GGPLOT to plot the twitter counts in geom_area() and the rainfall in geom_bar().  For the graph I adjust the twitter count by a factor of 5 (yet another statistical sin !).  
 
Exploring the graph (P1) I could see a some correlation, especially on the 25th  October – alas they both peak on 25 October – but here seems to be another factor at play.  The tweet count has a daily pattern while rain does not – makes sense a people tweet when they are awake.  So time of day will negatively impact the correlation.
I reviewed the data table and sum each series per date – to get a daily total.  Plotting the same graph (P3) for the daily series the correlation is much more evident.
 
## Statistical analysis
Having put all the effort into sourcing, cleaning and exploring the data, the actual analysis is simple.
I applied Pearson’s correlation test with the function 
cor.test(rain_tweet.dt$tweets, rain_tweet.dt$rain, method= "pearson")
and the graph 
ggscatter(rain_tweet.dt, x = "tweets", y = "rain", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson",….)
 and voila:

As expected, there is a limited 84% correlation between the two series looking at the 3 hour intervals (P2).  Although the correlation is not as strong as I expected, the confidence of the correlation coefficient is high with a p-value well below 1%.
 
Looking at the daily series there is a strong correlation – 98% and the confidence is very high (P4).  The p-value is 3.781e-08 which is less than an alpha of 5% or even 1% which means the correlation is statistically significant.
But - before accepting my null hypothesis …
 
…what if we look at a time series where the rainfall was not out of the ordinary – like the days leading up the 25th October.  To check this correlation on the “normal” days, I perform the same test but limit my data to dates 18th to 24th October.
The correlation is 84% but the confidence is much lower than before (P6).  With a p-level below 5% the null hypothesis can still be accepted with 95% confidence, but should we go stricter and demand a 99% confidence the null hypothesis would be rejected, and correlation not accepted for days when there is normal rainfall.
 
## Conclusion
So I can accept my null hypothesis that there must be a strong correlation between the volume of twitter posts originating from a defined area containing the word RAIN and the actual recorded rainfall for that area.  (And reject the alternative).  There is one caveat – the correlation is strong if the rain is a conversation piece.  Once rainfall returns to normal the correlation drops significantly.

## The power of the trivial
The analysis might seem trivial and probably is – but it demonstrated the following steps in simple a data science exercise:
*	Formulate the question.  Do people tweet more about rain when there is more rain?

*	Source the data 

**	Confirm the data is available - identify an area, harvest tweets from the area, source historic rainfall data for the area

**	Clean up the data – the rainfall was given in 3 hour intervals, the tweets  at a specific time, add up the tweets, divide them into 
 hour intervals, join the groups, manage missing data.

**	Explore the data – initial graphs set the expectation to expect a higher correlation in daily data than 3 hourly data.

*	Apply an algorithm – Pearson’s correlation to the rescue !

*	Tell the story – well a simple conclusion we have and we can communicate it with a few icon graphics and no stats !

## Also demonstrated:

*	In the data exploration the question is refined – from a general correlation to a correlation by date.

*	Once the question was answered an additional question came about – what the correlation is if rain is not exceptional.  Making a small adjustment to the data (adjusting the end date) the data and statistic could be re-used to answer the follow-up question.

*	I made a few compromises around the data that could influence the quality of my conclusion (the old story of garbage-in / garbage-out) – the rainfall is measured in Cape Town but the tweets come from a 125km radius around Franschhoek which includes Cape Town, the suburbs and the surrounding towns. 

