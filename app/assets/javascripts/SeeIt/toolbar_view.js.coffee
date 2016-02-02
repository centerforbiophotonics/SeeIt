@SeeIt.ToolbarView = (->
  class ToolbarView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @navElements) ->
      @init()

    init: ->
      @container.html(
        """<nav class='SeeIt navbar navbar-default'>
          <div class='SeeIt container-fluid'>
            <div class='SeeIt navbar-header'>
              <a class='SeeIt navbar-brand' href='#'>Global Options</a>
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
      toolbar  = @
      @navElements.forEach (el) ->
        if el.handler
          toolbar.container.find(".#{el.class}").on('click', el.handler)

  ToolbarView
).call(@)