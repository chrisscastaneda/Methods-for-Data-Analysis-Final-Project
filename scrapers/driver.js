'use strict';
var jsonfile = require('jsonfile');
var WIbot = require('./wibot.js');
var AEbot = require('./alec-exposed-bot.js');



// SCRAPING WI STATE LEGISLATURE WEBSITE
// ======================================


// WIbot.countBillsPerBiennium();
function test_WIbot_scrapeBill() {
  console.log('*** test_WIbot_scrapeBill ***');
  var output_file = 'example.json';
  var id = 'wi_2015_ab155';
  var url = 'http://docs.legis.wisconsin.gov/2015/related/proposals/ab155';
  var bill = WIbot.scrapeBill(url);
  var url2 = 'https://docs.legis.wisconsin.gov/2013/related/proposals/ab63';
  var id2 = 'wi_2013_ab63';
  var bill2 = WIbot.scrapeBill(url2);
  var bill3 = WIbot.scrapeBill('http://docs.legis.wisconsin.gov/document/proposaltext/2013/OC3/AB1');
  var output = { bills: [bill, bill2, bill3] };

  jsonfile.writeFile(output_file, output, {spaces: 2}, function(err) {
    console.error(err)
  });
}
// test_WIbot_scrapeBill();



function list_all_bill_urls_to_json() {
  console.log('list_all_bill_urls_to_json()\n==================================================\n');
  var output_file = './data/wi_bill_urls.json';
  var bienniums = [2015, 2013, 2011, 2009, 2007, 2005, 2003, 2001, 1999, 1997, 1995]
  // var bill_list = [];
  var bill_list_obj = {};

  for (var i = bienniums.length - 1; i >= 0; i--) {
    // bill_list.push( WIbot.billList(bienniums[i], 'html') ); 
    bill_list_obj[bienniums[i]] = WIbot.billList(bienniums[i], 'html');
  };

  jsonfile.writeFile(output_file, bill_list_obj, {spaces: 2}, function(err) {
    console.error(err)
  });
  console.log('bill_list_obj written to ' + output_file);
  console.log(bill_list_obj);
}
// list_all_bill_urls_to_json();



function scrape_by_biennium (biennium) {
  var START_INDEX = 265;

  var output_file = './data/wi_'+biennium+'_bills.json';
  var output_file_temp = './data/wi_'+biennium+'_bills_PARTIAL_'+START_INDEX+'-.json';

  var output = { bills: [] };
  var url_list = jsonfile.readFileSync('./data/wi_bill_urls.json');
  var urls = url_list[biennium];
  var bills = [];

  var urls_length = urls.length;
  console.log('biennium: '+biennium+'\t\turls.length: '+urls_length);
  // for (var i = 0; i < 50; i++) {
  for (var i = START_INDEX; i < urls_length; i++) {
    console.log('\nurls['+i+']::')
    bills.push( WIbot.scrapeBill(urls[i]) );
    output.bills = bills;
    jsonfile.writeFileSync(output_file_temp, output, {spaces: 2});
  }
  output.bills = bills;
  jsonfile.writeFile(output_file, output, {spaces: 2}, function(err) {
    console.error(err)
  });
  console.log('*** WI bills for the '+biennium+' biennium have been written to '+output_file+' ***');
}
// scrape_by_biennium(1999);


function test_jsonfile() {
  var biennium = 2015;
  var output_file = './data/wi_'+biennium+'_bills.json';
  var output = { foo: 'bar', baz: 'spam', fo: 'shizzle' };
  output.foo = 'BAR';
  
  jsonfile.writeFile(output_file, output, {spaces: 2}, function(err) {
    console.error(err)
  });
  console.log('*** WI bills for the '+biennium+' biennium have been written to '+output_file+' ***');
}
// test_jsonfile();


function scrape_alec_exposed () {
  var output_file = './data/alec_exposed/crime_bills3.json';
  var output = { bills: [] };
  var crime_bills_list_url = 'http://www.alecexposed.org/wiki/Bills_related_to_Guns,_Prisons,_Crime,_and_Immigration';

  var urls = AEbot.scrapeBillsRelatedPage(crime_bills_list_url);
  console.log('urls.length:', urls.length);
  for (var i = 0; i < urls.length; i++) {
    console.log('urls['+i+']:: '+ urls[i]);
    output.bills.push( AEbot.scrapeAlecBill(urls[i]) );
    jsonfile.writeFileSync(output_file, output, {spaces: 2});
  };
}
scrape_alec_exposed();