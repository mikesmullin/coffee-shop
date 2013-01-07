content_for 'head', ->
  stylesheet 'application', media: 'all'

section '#flashes', ->
  for k, type of ['alert', 'notice']
    block "if flash.#{type}", ->
      div class: "flash flash-#{type}", "{{flash.#{type}}}"

section '#content', ->
  yields 'content'

content_for 'foot', ->
  javascript 'templates'
  javascript 'application'

layout 'shared/layouts/html5'
