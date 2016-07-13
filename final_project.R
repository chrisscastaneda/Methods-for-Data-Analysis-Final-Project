## ============================================================================
## Chris Castañeda-Barajas (chrisscastaneda@gmail.com)
## Final Project - Legislative Analysis using Natural Language Processing
## DATASCI 350: Methods for Data Analysis
## 2014.06.02
## ============================================================================



## ============================================================================
##                           Setup environment
## ============================================================================
rm(list=ls())
setwd("~/Dropbox/UW_DATA_SCIENCE/class-2/final_project")

## Load Libraries
library(jsonlite)
require(logging)
library(tm)
library(SnowballC)
library(wordcloud)
library(e1071)
library(caret)
library(RTextTools)
library(topicmodels)
library(slam)
library(RKEA)
library(stringdist)
library(textir)
library(openNLP)
library(openNLPdata)
library(stringr)
library(tools)
library(colorspace)




## ============================================================================
##                            Helper Functions
## ============================================================================

NormalizeText <- function (text) {
  # ---------------------------------------------------------------------------
  # Normalizes `text` for NLP by converting to lowercase and removing
  # punctuation, numbers, extra white space, and stop words, and then stem.
  #
  # ARGUMENTS:
  #   text: character vector of arbitrary length containing the text to be 
  #         normalized
  # RETURNS:
  #   A character vector of the normalized text ready for NLP
  # ---------------------------------------------------------------------------
  
  ## Error Handling
  if (is(text)[1] != is('this is a character vector')[1]) {
    stop("`text` is not a character vector ", text, ' is: ', is(text)[1])
  }
  
  ## Private Helper Function
  Normalize <- function(text) {
    # Convert to lower case:
    text <- tolower(text)
    # Remove line breaks and tabs
    text <- sapply(text, function(t) gsub("\\n", " ", t))
    text <- sapply(text, function(t) gsub("\\r", " ", t))
    text <- sapply(text, function(t) gsub("\\t", " ", t))
    # Remove apostrophes:
    text <- sapply(text, function(t) gsub("'", "", t))
    # Swap out the rest of the punctuation w/ spaces:
    text <- sapply(text, function(t) gsub("[[:punct:]]", " ", t))
    # Remove numbers:
    text <- sapply(text, function(t) gsub("\\d", "", t))
    # Remove extra white space:
    text <- sapply(text, function(t) gsub("[ ]+", " ", t))
    # Remove non-ascii
    text <- iconv(text, from="latin1", to="ASCII", sub="")
    
    return(paste(text))
  }
  
  ## Start Normalizing
  text <- Normalize(text)
  
  # Remove stop words:
  my_stops <- Normalize( stopwords() )  # add in custom stop words here if needed
  my_stops <- c(my_stops, 'summary', 'model', 'up', 'down')
  text <- sapply(text, function(t) {
    paste(setdiff(strsplit(t, " ")[[1]], my_stops), collapse=" ")
  })
  
  # Stem words:
  text <- sapply(text, function(t) {
    paste( wordStem(strsplit(t, ' ')[[1]]), collapse=" ")
    #paste(setdiff(wordStem(strsplit(t, " ")[[1]]), ""), collapse=" ")
  })
  
  return(text)
} 

TFIDFList <- function (text) {
  # ---------------------------------------------------------------------------
  # Generates TF-IDF scores for given `text`
  # 
  # ARGUMENTS:
  #   text: character vector of arbitrary length containing the set of 
  #         documents to calculate TF-IDF, ideally is already normalized
  # RETURNS:
  #   Numeric vector of sorted, in descending order, TF-IDF scores for the 
  #   given `text`.
  # ---------------------------------------------------------------------------
  
  ## Convert `text` into a Corpus object
  corpus = Corpus(VectorSource(text))
  
  ## Calculate TF-IDF scores
  tfidf_scores = DocumentTermMatrix(corpus, control=list(weighting=weightTfIdf))
  
  ## Pair down the list size to something more manageable
  # Play w/ the sparsity value here
  tfidf_small = removeSparseTerms(tfidf_scores, sparse=0.99)  
  
  tfidf_sorted = rev(sort(colSums(as.matrix(tfidf_small))))
  
  return(tfidf_sorted)
}


CosineSimilarity <- function(ma, mb) {
  mat <- tcrossprod(ma, mb)
  t1 <- sqrt(apply(ma, 1, crossprod))
  t2 <- sqrt(apply(mb, 1, crossprod))
  return( mat / outer(t1,t2) )
}

NormalizeVector <- function ( v ){
  v.min <- min(v)
  v.max <- max(v)
  return( (v - v.min) / (v.max - v.min) )
}

BillUrl <- function ( bill_id ) {
  host <- 'http://docs.legis.wisconsin.gov/document/proposaltext/'
  x <- strsplit(bill_id, '_')[[1]]
  return( paste(host ,x[2], '/', x[3], '/', x[4], sep='') )
}



## ============================================================================
##                                Unit Tests
## ============================================================================
test.NormalizeText <- function() {

  # Check if all lower case
  test.lowerCase <- function(text) {
    result <- ( 0 == length(intersect(LETTERS, strsplit(text, '')[[1]])) )
    if( !result ) stop('Failed: test.lowerCase')
    return(result)
  }
  # Check to see if punctuation is removed
  test.punctuation <- function(text) {
    p <- strsplit("!\"#$%&'()*+,-./:;<=>?@[\\]^_`{¦}~", '')[[1]]
    result <- ( 0 == length(intersect(p, strsplit(text, '')[[1]])) )
    if( !result ) stop('Failed: test.punctuation')
    return(result)
  }
  # Check if numbers have been removed
  test.numbers <- function(text) {
    n = c('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0')
    result <- ( 0 == length(intersect(n, strsplit(text, '')[[1]])) )
    if( !result ) stop('Failed: test.numbers')
    return(result)
  }
  # Check if non-ascii characters have been removed
  test.ascii <- function(text) {
    result <- ( 0 == length(showNonASCII(strsplit(text, '')[[1]])) )
    if( !result ) stop('Failed: test.ascii')
    return(result)
  }
  # Check if common stop words have been removed
  test.stopWords <- function(text) {
    sw <- stopwords()
    sw <- sapply(sw, function(w) gsub("'", "", w))  # remove punctuation
    result <- ( 0 == length(intersect(sw, strsplit(text, ' ')[[1]])) )
    if( !result ) stop('Failed: test.stopWords')
    return(result)
  }

  sample_text <- NormalizeText("This Sample Text has CAPITAL LETTERS, punctuation marks such as all of these: !\"#$%&'()*+,-./:;<=>?@[\\]^_`{¦}~. as well as numbers like 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 200, 3,456, and 70000, some non-ascii characters like ñ  as well as many stop words.")

  pass_all_tests <- ( test.lowerCase(sample_text) && 
                      test.punctuation(sample_text) &&
                      test.numbers(sample_text) &&
                      test.ascii(sample_text) &&
                      test.stopWords(sample_text) )

  return(pass_all_tests)
}


## ============================================================================
##                                   MAIN
## ============================================================================
if (interactive()){
  # ---------------------------------------------------------------------------
  #                             RUN UNIT TEST
  # ---------------------------------------------------------------------------
  test.NormalizeText()
  
  
  
  # ---------------------------------------------------------------------------
  #                              SETUP LOGGING
  # ---------------------------------------------------------------------------
  basicConfig()
  addHandler(writeToFile, logger="data_logger", file="final_project.log")
  loginfo(paste(":\n",
                "     TEXT MINING WISCONSIN STATE LEGISLATURE     \n",
                "--------------------------------------------------"),
          logger="data_logger")
  
  
  
  # ---------------------------------------------------------------------------
  #                               LOAD DATA
  # ---------------------------------------------------------------------------
  
  ## Examples of ALEC Model Legislation related to Guns, Prisons, Crime and Immigration.
  ## Examples have been identified by subject matter experts at the Center for Media
  ## and Democracy and ALEC Exposed.
  ## Extracted from: http://www.alecexposed.org/wiki/Bills_related_to_Guns,_Prisons,_Crime,_and_Immigration
  ## To be used to develop a target vector used to mine raw legislative text data
  crimebills <- as.data.frame(fromJSON('./scrapers/data/alec_exposed/crime_bills3.json'))

  ## WISCONSIN STATE LEGISLATIVE TEXTS
  ## The text of nearly every piece of legislation introduced into the Wisconsin 
  ## state legislature for the past two decades.  Legislation prior to the 1995
  ## biennium are not easily accessible in a digital format .
                                                                           #  SIZE  DOC COUNT
  wi1995 <- as.data.frame(fromJSON('./scrapers/data/wi_1995_bills.json'))  #  21MB  2,000 docs
  wi1997 <- as.data.frame(fromJSON('./scrapers/data/wi_1997_bills.json'))  #  37MB  1,750 docs
  ## web scraper bot had issues extracting bills from 1999 biennium, WI website had inconsistencies
  wi2001 <- as.data.frame(fromJSON('./scrapers/data/wi_2001_bills.json'))  #  22MB  1,707 docs
  wi2003 <- as.data.frame(fromJSON('./scrapers/data/wi_2003_bills.json'))  #  22MB  1,818 docs
  wi2005 <- as.data.frame(fromJSON('./scrapers/data/wi_2005_bills.json'))  #  25MB  2,249 docs
  wi2007 <- as.data.frame(fromJSON('./scrapers/data/wi_2007_bills.json'))  #  28MB  1,875 docs
  wi2009 <- as.data.frame(fromJSON('./scrapers/data/wi_2009_bills.json'))  #  29MB  1,994 docs
  wi2011 <- as.data.frame(fromJSON('./scrapers/data/wi_2011_bills.json'))  #  25MB  1,669 docs
  wi2013 <- as.data.frame(fromJSON('./scrapers/data/wi_2013_bills.json'))  #  24MB  1,898 docs
  ## web scrapper also had issues with 2015 biennium
                                                                   # TOTALS: 233MB 16,960 total documents 
  
  
  # ---------------------------------------------------------------------------
  #                               CLEAN DATA
  # ---------------------------------------------------------------------------
  
  ## Add a biennium column to each legislative data set
  wi1995$biennium <- rep(1995, nrow(wi1995))
  wi1997$biennium <- rep(1997, nrow(wi1997))
  wi2001$biennium <- rep(2001, nrow(wi2001))
  wi2003$biennium <- rep(2003, nrow(wi2003))
  wi2005$biennium <- rep(2005, nrow(wi2005))
  wi2007$biennium <- rep(2007, nrow(wi2007))
  wi2009$biennium <- rep(2009, nrow(wi2009))
  wi2011$biennium <- rep(2011, nrow(wi2011))
  wi2013$biennium <- rep(2013, nrow(wi2013))

  ## Stack them all together
  WI <- rbind(wi1995, wi1997, wi2001, wi2003, wi2005, wi2007, wi2009, wi2011, wi2013)
  
  ## Clean up the column names
  names(crimebills) <- c('id', 'text')
  names(WI) <- c('id', 'text', 'biennium')
  
  ## Add bill urls to data for reference later
  url <- sapply(WI$id, function(id) BillUrl(id))
  WI$url <- url
  
  ## Normalize text data
  crimebills$normalized <- NormalizeText(crimebills$text)
  WI$normalized <- NormalizeText(WI$text)
  
  
  
  # ---------------------------------------------------------------------------
  #                         FEATURE ENGINEERING
  # ---------------------------------------------------------------------------
  
  ## Generate key words for target vector
  target.tfidf <- TFIDFList(crimebills$normalized)
  length(names(target.tfidf))  # 2209
  
  ## Develop a Document Term Matrix for all legislative data
  WI.corpus <- Corpus(VectorSource(WI$normalized))
  WI.terms <- DocumentTermMatrix(WI.corpus)
  dim(WI.terms)  # 16340 20078
  
  ### SOME EXPLORING ###
  length(intersect( names(target.tfidf), names(as.data.frame(as.matrix(WI.terms))) ))  # 2194
  length(intersect( names(target.tfidf[1:100]), names(as.data.frame(as.matrix(WI.terms))) ))  # 99
  
  ## Use most important terms as index to subset other objects
  crime_terms_index <- intersect( names(target.tfidf[1:100]), names(as.data.frame(as.matrix(WI.terms))) )
  
  ## Reduce WI document-term-matrix to just terms that will be relavant to the target vector
  WI.crimeTerms <- WI.terms[ , crime_terms_index]
  WI.crimeTerms <- as.data.frame(as.matrix(WI.crimeTerms))
  
  loginfo(paste(" Crime Policy Model Legislation Terms to be used in target vector:\n"), logger="data_logger")
  loginfo(paste( names(WI.crimeTerms)), logger="data_logger")
  
  names(WI.crimeTerms)
  #[1] "sentenc"   "convict"   "firearm"   "violat"    "commit"    "offens"    "nation"    "determin" 
  #[9] "offend"    "report"    "juvenil"   "constitut" "licens"    "meet"      "correct"   "decemb"   
  #[17] "appear"    "requir"    "cite"      "penalti"   "permit"    "januari"   "establish" "mail"     
  #[25] "oper"      "enact"     "issu"      "particip"  "full"      "test"      "releas"    "program"  
  #[33] "provid"    "task"      "bill"      "offic"     "crime"     "polici"    "feloni"    "theft"    
  #[41] "enter"     "applic"    "adopt"     "adult"     "prohibit"  "august"    "restrict"  "summit"   
  #[49] "prison"    "attempt"   "forc"      "commun"    "relat"     "place"     "author"    "allow"    
  #[57] "american"  "insert"    "probat"    "increas"   "agenc"     "case"      "jurisdict" "notifi"   
  #[65] "defend"    "resid"     "court"     "limit"     "director"  "proceed"   "charg"     "justic"   
  #[73] "incarcer"  "individu"  "complet"   "code"      "post"      "appropri"  "request"   "protect"  
  #[81] "investig"  "receiv"    "file"      "repeal"    "annual"    "term"      "know"      "victim"   
  #[89] "possess"   "short"     "reason"    "known"     "etc"       "implement" "year"      "statut"   
  #[97] "make"      "carri"     "consid"   
  
  
  
  # ---------------------------------------------------------------------------
  #                             DATA MODELING
  # ---------------------------------------------------------------------------
  
  ## Create the target vector
  targetVector <- NormalizeVector(as.matrix(as.numeric(target.tfidf[crime_terms_index])))
  
  ## Set weights for document vector terms
  weights <- as.numeric(target.tfidf[crime_terms_index])
  
  ## Generate a relavancy model for each document by caluclating the the cosine
  ## similarity between the target vector and each document vector
  relevancyModel <- sapply(1:nrow(WI.crimeTerms), function (i) {
    terms <- as.matrix(as.numeric(WI.crimeTerms[i,]))
    documentVector <- NormalizeVector( terms * weights )
    return( CosineSimilarity(t(targetVector), t(documentVector)) )
  })
  WI$relevancy <- relevancyModel
  
  
  ## Plot a histogram of my relevancy model scores
  hist(relevancyModel, breaks=100)
  mean(relevancyModel) # 0.2703352
  sd(relevancyModel) # 0.1157261
  mean(relevancyModel)+2*sd(relevancyModel) # 0.5017875
  mean(relevancyModel)+3*sd(relevancyModel) # 0.6175136
  abline(v=mean(relevancyModel),col="green")
  abline(v=mean(relevancyModel)+2*sd(relevancyModel),col="red")
  abline(v=mean(relevancyModel)-2*sd(relevancyModel),col="red")
  abline(v=mean(relevancyModel)+3*sd(relevancyModel),col="blue")
  
  
  # ---------------------------------------------------------------------------
  #                            LOG RESULTS
  # ---------------------------------------------------------------------------
  
  ## Whittle results down to the most relavant bills
  plus3sigmas <- mean(relevancyModel)+3*sd(relevancyModel)
  results <- WI[c('id', 'biennium', 'url', 'relevancy')]
  results <- results[results$relevancy >= plus3sigmas, ]
  results <- results[order(-results$relevancy), ]
  
  write.csv(results, 'crime_bills_in_wi.csv')
  
  loginfo(paste('Results have been written to: crime_bills_in_wi.csv' ), logger="data_logger")
  
}
