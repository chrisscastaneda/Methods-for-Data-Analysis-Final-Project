# Legislative Analysis using Natural Language Processing: 
## Text Mining the Wisconsin State Legislature for ALEC Model Legislation (Data Science 350: Methods for Data Analysis Final Project)

This project was completed a part of the requirements for the _Data Science 350: Methods for Data Analysis_ class as part of the Certificate in Data Science program at the University of Washington.  

## OVERVIEW

Using natural language processing (NLP) techniques I data mined legislative texts introduced into the [Wisconsin state legislature](http://docs.legis.wisconsin.gov/) in search of ALEC Model Legislation. I harvested the texts of nearly every piece of legislation introduced into the Wisconsin state legislature from 1995 to 2014 (my scrapper bot had issues with extracting the texts from the 1999-2000 and 2015-16 bienniums, so those texts have been omitted from my analysis; legislation prior to 1995 were not easily accessible in a digital format). In total I harvested the texts of nearly 17,000 pieces of legislation. I also scrapped the text of known examples of ALEC Model legislation from the Center for Media and Democracy’s ALECExposed.org website, specifically examples of bills related to Guns, Prisons, Crime and Immigration here: http://www.alecexposed.org/wiki/Bills_related_to_Guns,_Prisons,_Crime,_and_Immigration.

For a complete overview of the project, please refer to [final_project_writeup.pdf](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/final_project_writeup.pdf).

## RESULTS

My algorithm sifted through nearly 17,000 pieces of legislation, nearly every piece of legislation introduced into the Wisconsin state legislature over the past two decades, and ultimately produced a list of [246 identified bills](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/crime_bills_in_wi.csv) as possible matches for ALEC model legislation.  This algorithm is simply a first pass over the data.  Deeper analysis of these identified bills is necessary in order to identify model legislation.


## ANALYSIS

This project was an exercise in Natural Language Processing using R.  To recreate my analysis, clone this repo and run [final_project.R](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/final_project.R) in R, or RStudio, i.e. form the R console, run (note: may take up to ten minutes to run):
```R
source("final_project.R")
```

For a quick overview, I've also encapsulated the analysis into a [jupyter notebook](
https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/Legislative_Analysis_using_Natural_Language_Processing.ipynb).

## WEB SCRAPERS

It is said that 80% of a data scientists work is comprised of extracting, transforming, and loading data (ETL).  That 80% of this project was carried out by a set of web scraping bots written in NodeJS.  These scripts are designed to scrape the [Wisconsin State Legislature's website](http://docs.legis.wisconsin.gov/) and extract the text of every piece of legislation introduced into the legislature since 1995.  These scripts were written for ease of use, code readability, and maintainability at the expense of being fast.  If you choose to fire up these bots on your own machine, be warned that it will likely take about 45 minutes to an hour run per legislative biennium.

[scrapers/driver.js](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/scrapers/driver.js) Is the primary driver of my bots, and provides a set of simple functions for utilizing them.  Edit the file to call the function you're interested in and execute as follows.  I recommend redirecting your console output to a log file.

```bash
node driver.js > log.text
```

### WIbot.js API
[scrapers/wibot.js](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/scrapers/wibot.js) was the primary ETL workhorse for this project. It exposes a simple API for scraping the Wisconsin state legislature's website.

#### `wibot.countBillsPerBiennium()`

Arguments:
  * None.

Returns: 
  * Nothing. Outputs to console the number of bills in each biennium.  Primarily used for data exploration.

#### `wibot.scrapeBill( url )`

Arguments:
  * `url`: a string referencing the url of a specific piece of legislation, i.e. 'http://docs.legis.wisconsin.gov/2015/related/proposals/ab155'

Returns:
  * object w/ keys `billId` and `billText`

#### `wibot.billList( biennium, format)`

Arguments:
  * `biennium`: Odd numbered year representing beginning of biennium. Only the following are valid values: 2015, 2013, 2011, 2009, 2007, 2005, 2003, 2001, 1999, 1997, 1995
  * `format`: string, 'html' or 'pdf'

Returns: 
  * Array of url strings referencing either html or pdf versions of bills.


### AEbot.js API
[scrapers/alec-exposed-bot.js](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/blob/master/scrapers/alec-exposed-bot.js) was built specifically for scraping this page: 
[www.alecexposed.org/wiki/Bills_related_to_Guns,_Prisons,_Crime,_and_Immigration](http://www.alecexposed.org/wiki/Bills_related_to_Guns,_Prisons,_Crime,_and_Immigration).  The code is probably generalizable to all 'bills related to...' pages, but not tested yet.

#### `aebot.scrapeBillsRelatedPage()`

Arguments:
  * `url`: string of url referencing page to scrape, i.e. http://www.alecexposed.org/wiki/Bills_related_to_Guns,_Prisons,_Crime,_and_Immigration

Returns:
  *  Array of url strings referencing model bills.


#### `aebot.scrapeAlecBill( url )`

Arguments:
  * `url`: string of url referencing alec model legislation on ALEC Exposed website

Returns: 
  * object w/ keys `billId` and `billText`


## DATA

All of the textual legislative data I harvested lives here as JSON files: [scrapers/data/](https://github.com/chrisscastaneda/Methods-for-Data-Analysis-Final-Project/tree/master/scrapers/data).  


