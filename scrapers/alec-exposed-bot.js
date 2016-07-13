'use strict';
var request = require('request');
var srequest = require('sync-request');
var cheerio = require('cheerio');
var EventEmitter = require("events").EventEmitter;

var ee = new EventEmitter();

/**
scrape this: 
http://www.alecexposed.org/wiki/Bills_related_to_Guns,_Prisons,_Crime,_and_Immigration


*/


var AlecExposedBot = (function() {
  'use strict';
  // PRIVATE ATTRIBUTES
  var $;

  // PRIVATE METHODS



  // PUBLIC METHODS
  var scrapeBillsRelatedPage = function( url ) {
    /* -------------------------------------------------------------------- *\
     * Built specifically for scraping this page: 
     * http://www.alecexposed.org/wiki/Bills_related_to_Guns,_Prisons,_Crime,_and_Immigration
     * Code is probably generalizable to all 'bills related to...' pages, but not tested yet.
     *
     * ARGS:
     *  url: http://www.alecexposed.org/wiki/Bills_related_to_Guns,_Prisons,_Crime,_and_Immigration
     *  
     * RETURNS:
     *  array of url strings referencing model bills
    \* -------------------------------------------------------------------- */
    var host = 'http://www.alecexposed.org/';
    var r = {};  // for caching the http request response
    var anchor_tags_obj = {};
    var list = [];
    var is_bill_html = false;

    r = srequest('GET', url);
    $ = cheerio.load(r.getBody('utf8'));

    anchor_tags_obj = $('#mw-content-text li a');

    for (var i = 0; i < anchor_tags_obj.length; i++) {
      is_bill_html = $(anchor_tags_obj[i]).text() === ' (HTML)';
      if (is_bill_html) {
        list.push( host + $(anchor_tags_obj[i])[0].attribs.href );
        // console.log('['+i+'] '+$(anchor_tags_obj[i]).text() + ': '+ $(anchor_tags_obj[i])[0].attribs.href )
      }
    };

    return list;
  }

  var scrapeAlecBill = function ( url ) {
    var r = {};  // for caching the http request response
    var id = String();
    var text = String();
    r = srequest('GET', url);
    $ = cheerio.load(r.getBody('utf8'));

    id = $('h1').text();
    text = $($('#mw-content-text').html().split('ALEC Bill Text')[1]).text()

    if ( text === '' ) {
      text = $($('#mw-content-text').html().split('ALEC Resolution Text')[1]).text()
    } else if ( text === '' ) {
      text = $($('#mw-content-text').html().split('<p>Summary\n</p>')[1]).text();
    } else if ( text === '' ) {
      text = $('<p>'+$('#mw-content-text').html().split('<p>Summary')[1]).text();
    }

    return { billId: id, billText: text };
  }



  // Expose AlecExposedBot API
  return {
    scrapeBillsRelatedPage: scrapeBillsRelatedPage,
    scrapeAlecBill: scrapeAlecBill
  }
}());

module.exports = AlecExposedBot;