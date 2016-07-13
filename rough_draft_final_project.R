setwd("~/Dropbox/UW_DATA_SCIENCE/class-2/final_project")

library(jsonlite)

d <- fromJSON('./scrapers/data/example.json')
# lid_bils <- fromJSON('./lid/bill_to_bill_sample.json')
# lid_align <- fromJSON('./lid/model_legislation_alignments.json')





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


ConfusionMatrix <- function (actuals, predictions, threshold) {
  # ---------------------------------------------------------------------------
  # Assumes that  `predictions` and `actuals` are in the same order and are the 
  # same length.
  #
  # ARGUMENTS:
  #   actuals: numeric vector of 1s and 0s
  #   predictions: numeric vector of probabilities ranging from 0.0 to 1.0, 
  #                some values may be NA
  #   threshold: numeric vector of at least length of 1, w/ values ranging from 
  #              0 to 1, ideally in a sequence/sorted
  #
  # RETURNS: dataframe w/ as many rows and `length(threshold)` 
  #          and five columns: threshold, TP, TN, FP, and FN
  # ---------------------------------------------------------------------------
  
  # Cache number of observations
  observations <- length(predictions)
  
  # Make sure threshold is in a sequence
  threshold <- sort(threshold)
  
  # Deal w/ null values in predictions
  predictions[is.na(predictions)] <- mean(predictions, na.rm=TRUE)
  
  confusion_matrix <- sapply(threshold, function(th) {
    p <- ifelse(predictions > th, 1, 0)
    # True Positives
    tp <- sapply(1:observations, function(i) as.numeric(actuals[i]==1 && p[i]==1))
    # True Negatives
    tn <- sapply(1:observations, function(i) as.numeric(actuals[i]==0 && p[i]==0))
    # False Positives
    fp <- sapply(1:observations, function(i) as.numeric(actuals[i]==0 && p[i]==1))
    # False Negatives
    fn <- sapply(1:observations, function(i) as.numeric(actuals[i]==1 && p[i]==0))
    return(c(th, sum(tp), sum(tn), sum(fp), sum(fn)))
  })
  
  df <- as.data.frame(t(confusion_matrix))
  names(df) <- c('threshold', 'TP', 'TN', 'FP', 'FN')
  
  return(df)
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
##                                   MAIN
## ============================================================================
if (interactive()){
  # ---------------------------------------------------------------------------
  #                               LOAD DATA
  # ---------------------------------------------------------------------------
  
  ## Examples of ALEC Model Legislation related to Guns, Prisons, Crime and Immigration
  ## Extracted from: http://www.alecexposed.org/wiki/Bills_related_to_Guns,_Prisons,_Crime,_and_Immigration
  ## To be used to develop a target vector used to mine raw legislative text data
  crimebills <- as.data.frame(fromJSON('./scrapers/data/alec_exposed/crime_bills3.json'))


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
  
  
  crimebills.tfidf <- TFIDFList(crimebills$normalized)
  length(names(crimebills.tfidf))  # 2209
  
  
  
  
  # ---------------------------------------------------------------------------
  #                         FEATURE ENGINEERING
  # ---------------------------------------------------------------------------
  
  
  ## Feature engineering for logistic regression model for hefe reviews
  wi2013Corpus <- Corpus(VectorSource(wi2013$normalized))
  wi2013Terms <- DocumentTermMatrix(wi2013Corpus)
  dim(wi2013Terms)  # 1898 9495
  
  ### SOME EXPLORING
  length(intersect( names(crimebills.tfidf), names(as.data.frame(as.matrix(wi2013Terms))) ))  # 2150
  length(intersect( names(crimebills.tfidf[1:100]), names(as.data.frame(as.matrix(wi2013Terms))) ))  # 97
  names(wi2013.crimeTerms)
  #[1] "sentenc"   "convict"   "firearm"   "violat"    "commit"    "offens"    "nation"    "determin" 
  #[9] "offend"    "report"    "juvenil"   "constitut" "licens"    "meet"      "correct"   "decemb"   
  #[17] "appear"    "requir"    "cite"      "penalti"   "permit"    "januari"   "establish" "mail"     
  #[25] "oper"      "enact"     "issu"      "particip"  "full"      "test"      "releas"    "program"  
  #[33] "provid"    "task"      "bill"      "offic"     "crime"     "polici"    "feloni"    "theft"    
  #[41] "enter"     "applic"    "adopt"     "adult"     "prohibit"  "august"    "restrict"  "prison"   
  #[49] "attempt"   "forc"      "commun"    "relat"     "place"     "author"    "allow"     "american" 
  #[57] "insert"    "probat"    "increas"   "agenc"     "case"      "jurisdict" "notifi"    "defend"   
  #[65] "resid"     "court"     "limit"     "director"  "proceed"   "charg"     "justic"    "incarcer" 
  #[73] "individu"  "complet"   "code"      "post"      "appropri"  "request"   "protect"   "investig" 
  #[81] "receiv"    "file"      "repeal"    "annual"    "term"      "know"      "victim"    "possess"  
  #[89] "short"     "reason"    "known"     "implement" "year"      "statut"    "make"      "carri"    
  #[97] "consid"
  
  #wi2013Terms <- removeSparseTerms(wi2013Terms, 0.99)
  #dim(wi2013Terms)  # 
  #wi2013Terms <- as.data.frame(as.matrix(reviewTerms))
  
  ## Reduce wi2013 document-term-matrix
  crime_terms_index <- intersect( names(crimebills.tfidf[1:100]), names(as.data.frame(as.matrix(wi2013Terms))) )
  wi2013.crimeTerms <- wi2013Terms[ , crime_terms_index]
  wi2013.crimeTerms <- as.data.frame(as.matrix(wi2013.crimeTerms))
  
  # wi2013 document 1 terms column vector
  v1 <- as.matrix(as.numeric(wi2013.crimeTerms[1,]))
  
  
  crimeCorpus <- Corpus(VectorSource(crimebills$normalized))
  crimeTerms <- DocumentTermMatrix(crimeCorpus)
  dim(crimeTerms)  # 145 3536
  
  crimeTermAverages <- colSums(as.data.frame(as.matrix(crimeTerms))) / nrow(crimeTerms) 
  crimeTermAverages <- crimeTermAverages[crime_terms_index]
  
  crimeVector <- NormalizeVector(as.matrix(as.numeric(crimeTermAverages)))
  
  
  crimeIndex <- sapply(1:nrow(wi2013.crimeTerms), function (i) {
    documentVector <- NormalizeVector(as.matrix(as.numeric(wi2013.crimeTerms[i,])))
    return( cos.sim(t(crimeVector), t(documentVector)) )
  })
  
  wi2013$crimeIndex <- crimeIndex
  
  crimeIndex2 <- sapply(1:nrow(wi2013.crimeTerms), function (i) {
    terms <- as.matrix(as.numeric(wi2013.crimeTerms[i,]))
    weights <- as.numeric(crimebills.tfidf[crime_terms_index])
    documentVector <- NormalizeVector( terms * weights )
    return( cos.sim(t(crimeVector), t(documentVector)) )
  })
  wi2013$crimeIndex2 <- crimeIndex2
  # top bills under crimeIndex2
  # WI_2013_REG_AB383 
  # WI_2013_REG_SB12
  # WI_2013_REG_AB40
  # WI_2013_REG_AB694
  # WI_2013_REG_AB766
  
  crimeIndex3 <- sapply(1:nrow(wi2013.crimeTerms), function (i) {
    terms <- as.matrix(as.numeric(wi2013.crimeTerms[i,]))
    weights <- as.numeric(crimebills.tfidf[crime_terms_index])
    documentVector <- NormalizeVector( terms * weights )
    v <- as.matrix(as.numeric(crimebills.tfidf[crime_terms_index]))
    return( cos.sim(t(v), t(documentVector)) )
  })
  wi2013$crimeIndex3 <- crimeIndex3
  # top bills under crimeIndex3
  # WI_2013_REG_AB40
  
  weights <- as.numeric(crimebills.tfidf[crime_terms_index])
  crimeIndex4 <- sapply(1:nrow(wi2013.crimeTerms), function (i) {
    terms <- as.matrix(as.numeric(wi2013.crimeTerms[i,]))
    documentVector <- NormalizeVector( terms * weights )
    targetVector <- NormalizeVector(as.matrix(as.numeric(crimebills.tfidf[crime_terms_index])))
    return( cos.sim(t(targetVector), t(documentVector)) )
  })
  wi2013$crimeIndex4 <- crimeIndex4
  # top bills under crimeIndex3
  
  
  View(wi2013[c('id', 'crimeIndex', 'crimeIndex2', 'crimeIndex3', 'crimeIndex4', 'url')])
  
  
  ## Reduce review document-term-matrix down to just terms w/ high Hefeweizen TF-IDF scores
  hefe_high_tfidf_index <- intersect(names(reviewTerms), names(hefe.tfidf[1:50]))  # 44 terms
  hefeTerms <- reviewTerms[ ,hefe_high_tfidf_index]
  dim(hefeTerms)  # 
  
  
  # Join `hefeData` with `hefeTerms`
  # Assuming hefeTerms and hefeData are in the same order
  hefeTerms$index <- 1:nrow(hefeTerms)
  hefeData$index <- 1:nrow(hefeData)
  hefeData <- merge(hefeData, hefeTerms, by='index')
  # View(hefeData)
  
  
  
  
  
  
}
