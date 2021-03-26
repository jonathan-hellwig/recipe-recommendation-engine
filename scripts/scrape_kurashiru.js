// scrape_techstars.js

var webPage = require('webpage');
var page = webPage.create();

var fs = require('fs');
var path = 'kurashiru.html'

page.open('https://www.kurashiru.com/recipes/3365e1c3-f4e5-4de4-8b04-f1ad19e44f51', function (status) {
  var content = page.content;
  fs.write(path,content,'w')
  phantom.exit();
});

