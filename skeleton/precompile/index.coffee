doctype 5
ie 'IE7', -> html class: 'no-js ie7', lang: 'en'
ie 'IE8', -> html class: 'no-js ie8', lang: 'en'
ie 'IE9', -> html class: 'no-js ie9', lang: 'en'
text '<!--[if gt IE9]> '
html '.no-js', lang: 'en', ->
  text "<![endif]-->\n"
  head ->
    title ''
    meta charset: 'utf-8'
    stylesheet 'application'
    link rel: 'icon', type: 'image/x-icon', href: 'favicon.ico'
    ie 'lt IE9', -> script src: '//html5shiv.googlecode.com/svn/trunk/html5.js'
  body ->
    javascript 'application'
    script 'App.bootstrap();'
