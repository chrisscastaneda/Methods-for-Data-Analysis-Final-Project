# Legislative Analysis using Natural Language Processing: 
## Text Mining the Wisconsin State Legislature for ALEC Model Legislation
## (DS 350: Methods for Data Analysis Final Project)

This project was completed a part of the requirements for the _Data Science 350: Methods for Data Analysis_ class as part of the Certificate in Data Science program at the University of Washington.  

For an overview of the project, please refer to [final_project_writeup.pdf](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/final_project_writeup.pdf).

## ANALYIS

This project was an exercise in Natural Language Processing in R.  To recreate my analysis, copy this repo and run this file in R Studio: [final_project.R](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/final_project.R).

For a quick overview, I've also encapsulated the analysis into a [jupyter notebook](
https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/Legislative_Analysis_using_Natural_Language_Processing.ipynb).

My algorithm sifted through nearly 17,000 pieces of legislation, nearly every piece of legislation introduced into the Wisconsin state legislature over the past two decades, and ultimately produced a list of [246 identified bills](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/crime_bills_in_wi.csv) as possible matches for ALEC model legislation.  This algorithm is simply a first pass over the data.  Deeper analysis of these identified bills is necessary in order to identify model legislation.

## SCRAPERS

[scrapers/driver.js](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/scrapers/driver.js)

[scrapers/wibot.js](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/scrapers/wibot.js)

[scrapers/alec-exposed-bot.js](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/scrapers/alec-exposed-bot.js)



## DATA
[scrapers/data/](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/tree/master/scrapers/data)

## TO DO:
  [ ] finish this README
