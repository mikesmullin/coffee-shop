doctype 5
ie 'IE7', -> html class: 'no-js ie7', lang: 'en'
ie 'IE8', -> html class: 'no-js ie8', lang: 'en'
ie 'IE9', -> html class: 'no-js ie9', lang: 'en'
literal "<!--[if gt IE9]>\n  "
html '.no-js', lang: 'en', ->
  literal "<![endif]-->\n"
  head ->
    title '{{settings.title}}'
    meta charset: 'utf-8'
    link rel: 'icon', type: 'image/png', href: block 'cdn_url "/favicon.png"'
    ie 'lt IE9', -> script src: block 'cdn_url "/vendor/html5shiv.js"'
    yields 'head'
    yields 'head2'
  body class: '{{body_class}}', ->
    yields 'content'

    yields 'foot'
