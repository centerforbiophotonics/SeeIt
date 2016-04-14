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
              <a class='SeeIt navbar-brand' href='#'>Tools</a>
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

        if el.type == "dropdown"
          htmlStr += """
            <li class="SeeIt dropdown" style="cursor: pointer;">
              <div class="icon_container SeeIt nav-el left" style="display: inline-block">#{icon}</div>
              <div class="dropdown-toggle SeeIt nav-el right" data-toggle="dropdown" aria-haspopup="true" id="#{el.title}_dropdown">
                <a style="color: #777">
                  #{el.title}
                </a>
              </div>
              <ul class="dropdown-menu text-center" aria-labelledby="#{el.title}_dropdown">
                #{el.options.map((option) -> "<li class='#{el.class} toolbar_dropdown_option' data-id='#{option.name}'><a href='#' class='dropdown_child'>#{option.name}</a></li>")}
              </ul>
            </li>
          """
        else
          htmlStr += """
              <li class="#{el.class}">#{icon}<a href="#">#{el.title}</a></li>         
          """

      return htmlStr+"</ul>"

    registerEvents: ->
      toolbar  = @
      @navElements.forEach (el) ->
        if el.handler
          toolbar.container.find(".#{el.class}").off('click', el.handler).on('click', el.handler)

  ToolbarView
).call(@)