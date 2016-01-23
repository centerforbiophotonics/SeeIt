@SeeIt.Globals = (->
  class Globals
    constructor: (@container, @navElements) ->
      @init()

    init: ->
      @container.html(
        """<nav class='navbar navbar-default'>
          <div class='container-fluid'>
            <div class='navbar-header'>
              <a class='navbar-brand' href='#'>Global Options</a>
            </div>
            #{@buildNav()}
          </div>
        </nav>"""
      )

      @registerEvents()

    buildNav: ->
      htmlStr = '<ul class="nav navbar-nav">'
      @navElements.forEach (el) ->
        icon = if el.icon then "<div class='iconContainer'>#{el.icon}</div>" else ''
        htmlStr += """
            <li class="#{el.class}">#{icon}<a href="#">#{el.title}</a></li>         
        """

      return htmlStr+"</ul>"

    registerEvents: ->
      globals  = @
      @navElements.forEach (el) ->
        if el.handler
          globals.container.find(".#{el.class}").on('click', el.handler)

  Globals
).call(@)