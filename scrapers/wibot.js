'use strict';
var request = require('request');
var srequest = require('sync-request');
var cheerio = require('cheerio');
var EventEmitter = require("events").EventEmitter;

var ee = new EventEmitter();
var EMIT_COUNT = 0;


var WIbot = (function() {
  'use strict';
  // PRIVATE ATTRIBUTES
  var $, $$;  
  var bienniums = [2015, 2013, 2011, 2009, 2007, 2005, 2003, 2001, 1999, 1997, 1995];
  var counts_of_bills = {};

  // PRIVATE METHODS
  var proposalUrl = function( biennium ) {
    return 'http://docs.legis.wisconsin.gov/' + biennium + '/related/proposals';
  };
  var objVals = function(o) {
    var keys = Object.keys(o);
    var output = [];
    var i;
    for ( i=0; i < keys.length; i++ ) {
      output[i] = o[keys[i]];
    }
    return output;
  };
  var billId = function (url) {
    return 'WI_'+url.split('proposaltext/')[1].replace(/\//g,'_');
  };

  // PUBLIC METHODS
  var billList = function (biennium, format) {
    /* -------------------------------------------------------------------- *\
     * ARGS:
     *  biennium: odd numbered year representing beginning of biennium
     *           only the following are valid values:
     *           2015, 2013, 2011, 2009, 2007, 2005, 2003, 2001, 1999, 1997, 1995
     *  format: string, 'html' or 'pdf'
     * RETURNS:
     *  array of url strings referencing either html or pdf versions of bills
    \* -------------------------------------------------------------------- */
    var host = 'http://docs.legis.wisconsin.gov';
    var url = proposalUrl(biennium);
    var starting_index = (format === 'html') ? 0 : 1;  // 'html' or 'pdf'

    var r = {};  // for caching the http request response
    var anchor_tags_obj = {};
    var list = [];

    r = srequest('GET', url);
    $ = cheerio.load(r.getBody('utf8'));
    anchor_tags_obj = $('ul.docLinks li a');

    // Iterate over `anchor_tags_obj` and cache url values
    for ( var i = starting_index; i < anchor_tags_obj.length; i+=2 ) {
      list[i/2] = host + $(anchor_tags_obj[i])[0].attribs.href;
    }

    // console.log('anchor_tags_obj.length:', anchor_tags_obj.length);
    // console.log('list.length: ', list.length);
    // console.log('starting_index: ', starting_index);
    // console.log('====================================================\n');
    // for(var j=0; j < list.length; j++) {
    //   console.log('\tlist['+j+']:: ', list[j]);
    // }

    return list;
  };
  var countBillsPerBiennium = function() {
    /**
    EXAMPLE OUTPUT TO CONSOLE
    bill counts: 
     { '1995': 2000,
      '1997': 1750,
      '1999': 1744,
     x '2001': 1707,
     x '2003': 1818,
     x '2005': 2249,
     x '2007': 1875,
     X '2009': 1994,
     X '2011': 1669,
     X '2013': 1898,
     x '2015': 2116 }
    */ // sum is 20820
    for (var i = 0; i < bienniums.length; i++) {
      var biennium = bienniums[i];
      var url = proposalUrl(biennium);
      var count = 0;
      var output = {};
      request(url, (function (biennium) { 
        return function (err, resp, body) {
          $ = cheerio.load(body);
          count = $('ul.docLinks li').length;
          output[biennium] = count;
          var done_scrapping = Object.keys(output).length === bienniums.length;
          if( done_scrapping ){
            counts_of_bills = output;
            ee.emit('done_counting');
          }
        }
      })(biennium));
    };
    ee.on('done_counting', function() { 
      console.log('bill counts: \n', counts_of_bills);
    });
  };

  var scrapeBill = function(url) {
    /* -------------------------------------------------------------------- *\
     * ARGS:
     *  url: url of bill to be scraped
     * RETURNS:
     *  object w/ keys `billId` and `billText`
    \* -------------------------------------------------------------------- */

    var bill_id = billId(url);

    var scroll_prefix = 'http://docs.legis.wisconsin.gov/scroll/down/';
    var scroll_sufix = String();
    var scroll_url = String();
    // var scroll_pos = [1, 60, 89, 118, 147, 176, 205, 234, 263, 292, 321, 350, 379, 408, 437, 466, 495, 524, 553, 582, 611, 640, 669, 698, 727, 756, 785, 814, 843, 872, 901, 930, 959, 988];
    var scroll_pos = 60;
    var scrollUrl = function( scroll_url, position ) {
      scroll_sufix = scroll_url.split('scroll/down/')[1].split('/').splice(1).join('/');
      return String() + scroll_prefix + position + '/' + scroll_sufix;
    };

    var selector = '.proposaltext';
    var html = String();
    var text = String();
    var is_done_scrapping = false;
    var r = {};  // for caching the http request response

    console.log('Scraping:', billId(url), '\n======================================\n', url);

    // DO SOME WEBSCRAPPING
    r = srequest('GET', url);
    html = '<div class="WIbot">' + r.getBody('utf8') + '</div>';
    $ = cheerio.load(html);
    text = $(selector).text();
    scroll_url = 'http://docs.legis.wisconsin.gov' +
                 $('.WIbot a[href^="/scroll/down"]').attr('href');
    is_done_scrapping = (text.indexOf('(End)') > 0);

    var scroll_index = 1;
    while ( !is_done_scrapping ) {
      // url = scrollUrl(scroll_url, scroll_pos[scroll_index++]);
      url = scrollUrl(scroll_url, scroll_pos);

      selector = '.WIbot';
      r = srequest('GET', url);
      html = '<div class="WIbot">' + r.getBody('utf8') + '</div>';
      $ = cheerio.load(html);
      text += $(selector).text();

      console.log(url);
      console.log('\tscroll_index: ', scroll_index++);
      console.log('\ttext.indexOf("(End)"): ', text.indexOf("(End)"));

      is_done_scrapping = (text.indexOf('(End)') > 0);
      scroll_pos += 29;
    }

    return { billId: bill_id, billText: text };
  };

  var VOID_scrapeBill = function () {  // DOEN'T WORK - ASYNC WEBSCRAPING SUCKS!!!
    /** 
    https://docs.legis.wisconsin.gov/2013/related/proposals/ab63
    https://docs.legis.wisconsin.gov/scroll/down/60/2013/related/proposals/ab63
    https://docs.legis.wisconsin.gov/scroll/down/89/2013/related/proposals/ab63
    https://docs.legis.wisconsin.gov/scroll/down/118/2013/related/proposals/ab63
    https://docs.legis.wisconsin.gov/scroll/down/119/2013/related/proposals/ab6
    */
    var scrollUrl = function( position ) {
      var prefix = 'https://docs.legis.wisconsin.gov/scroll/down/';
      var sufix = '/2013/related/proposals/ab63';
      return String() + prefix + position + sufix;
    };
    var url = 'https://docs.legis.wisconsin.gov/2013/related/proposals/ab63';
    var selector = '.proposaltext';
    var scroll_pos = [1, 60, 89, 118, 147, 176, 205, 234, 263, 275, 304, 333, 362, 391, 420, 449, 478];

    var bill_text = String();

    // var scrape = function () {
    // };
    // scrape();
    var pos = 60;
    var text = [], btext = String();
    var text_obj = {};
    // for( var i in scroll_pos ) {
    for( var i=0; i < scroll_pos.length; i++ ) {
      var pos = scroll_pos[i];

      var is_not_first_page = ( pos >= 60 );
      if ( is_not_first_page ) {
        url = scrollUrl(scroll_pos[i]);
        selector = '.WIbot';
      }
      // url = scrollUrl(scroll_pos[i]);
      // console.log(url);
      // console.log(selector);
      
      request(url, (function (pos, selector) {
        return function (error, response, body) {
          var html = String() + '<div class="WIbot">' + body + '</div>';
          $ = cheerio.load(html);
          text_obj[pos] = $(selector).text();
          // btext += $(selector).text();
          // bill_text = text.join(' '); 

          console.log(pos+'=======================================================================');
          console.log( $(selector).text() );
          console.log(pos+'=======================================================================');
          var is_done_scrapping = false;
          // is_done_scrapping = ( text.join(' ').indexOf('(End)') !== -1 );
          // console.log( 'POS: '+pos+'     INDEX OF END: '+bill_text.indexOf('(End)') + ' | $('+selector+')...' );
          // is_done_scrapping = ( bill_text.indexOf('(End)') !== -1 ) ;
          // console.log( 'text['+pos+'].length: '+ text[pos].length );
          // console.log( 'text['+pos+'].indexOf((End)): '+ text[pos].indexOf('(End)') );
          // console.log( '\n' );
          // is_done_scrapping = ( text_obj[pos].indexOf('(End)') > 0 );
          // is_done_scrapping = Object.keys(output).length 
          if( is_done_scrapping ) {
            var keys = Object.keys(text_obj);
            // ##### START HERE #######################
            bill_text = text_obj;
            console.log('@@@ EMIT_COUNT: ', ++EMIT_COUNT);
            ee.emit('done-scrapping');
          } 
        }
      })(pos, selector));
    }
    

    ee.on('done-scrapping', function() {
      console.log( "*********************************************************" );
      console.log( bill_text );
      console.log( "*********************************************************" );
      // console.log( '*** INDEX OF END: ', bill_text.indexOf('(END)'), ' ***' );
    });
  };

  // Expose WIbot API
  return {
    countBillsPerBiennium: countBillsPerBiennium,
    scrapeBill: scrapeBill,
    billList: billList
  }
}())

module.exports = WIbot;