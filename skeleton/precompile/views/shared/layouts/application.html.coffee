doctype 5
ie 'IE7', -> html class: 'no-js ie7', lang: 'en'
ie 'IE8', -> html class: 'no-js ie8', lang: 'en'
ie 'IE9', -> html class: 'no-js ie9', lang: 'en'
literal "<!--[if gt IE9]>\n  "
html '.no-js', lang: 'en', ->
  literal "<![endif]-->\n"
  head ->
    title 'CoffeeShop'
    meta charset: 'utf-8'
    link rel: 'stylesheet', href: '/assets/application.css'
    link rel: 'icon', type: 'image/x-icon', href: 'favicon.ico'
    ie 'lt IE9', -> script src: '//html5shiv.googlecode.com/svn/trunk/html5.js'
    yields 'head'
  body ->
    yields 'content'
    script src: '/assets/application.js'
    yields 'foot'
