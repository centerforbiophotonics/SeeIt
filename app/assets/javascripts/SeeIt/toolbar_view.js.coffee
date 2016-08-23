@SeeIt.ToolbarView = (->
  class ToolbarView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @navElements) ->
      @init()
      @resizeListener()

    init: ->
      @container.html(
        """<nav class='SeeIt navbar navbar-default'>
          <div class='SeeIt container-fluid'>
            <div class='SeeIt navbar-header'>
              <a class='SeeIt navbar-brand' href='#'>SeeIt</a>
            </div>
            #{
              if $(".Globals").width() < 1003
                @buildDropdownNav()
              else
                @buildNav()
            }
          </div>
        </nav>"""
      )

      @registerEvents()

    # Menu
    buildDropdownNav: ->
      htmlStr = '<ul class="nav navbar-nav navbar-right">'
      htmlStr += """ 
        <li = class="dropdown">
          <a class="dropdown-toggle" type="button" data-toggle="dropdown" href="#">
            Menu<span class="caret"></span>
          </a>
          <ul class="dropdown-menu">
      """

      @navElements.forEach (el) ->
        icon = if el.icon then "<div class='iconContainer'>#{el.icon}</div>" else ''

        if el.type == "dropdown"
          htmlStr += """
            <li class="SeeIt dropdown-submenu" style="cursor: pointer;">
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
              <li class="#{el.class}">#{icon}<a href="#" style="color: #777">#{el.title}</a></li>         
          """ 

      return htmlStr+"</ul>"+"</li>"+"</ul>"

    buildNav: ->
      htmlStr = '<ul class="nav navbar-nav" display="none">'
      @navElements.forEach (el) ->
        icon = if el.icon then "<div class='iconContainer'>#{el.icon}</div>" else ''

        if el.type == "dropdown"
          htmlStr += """
            <li>
              <div class="icon_container SeeIt nav-el left" style="display: inline-block">#{icon}</div>
              <div class="SeeIt nav-el right"  id="#{el.title}_dropdown">
                <a href="#myModal" data-toggle="modal" data-target="#myModal" style="color: #777">
                  #{el.title}
                </a>
              </div>

              <div class="modal fade" id="myModal" role="dialog">
                <div class="modal-dialog">
                  <div class="modal-content">
                    <div class="modal-header">
                      <button type="button" class="close" data-dismiss="modal">&times;</button>
                      <h4 class="modal-title">Graph Options</h4>
                    </div>
                    <div class="modal-body">
                      <div class="form-group">
                        <label for="dropdown-form">Graph Type</label>
                        <select class="form-control" id="dropdown-form">
                          #{el.options.map((option) -> "<option class='#{el.class}' data-id='#{option.name}'><a href='#'>#{option.name}</a></option>")}
                        </select>
                      </div>
                      <div class="form-group">
                        <label for="dropdown-form">Graph Name</label>
                        <input class="form-control" id="inputGraphName" placeholder="Enter name" type="text">
                      </div>
                    </div>
                    <div class="modal-footer">
                      <a href="#" data-dismiss="modal" class="btn">Close</a>
                      <a href="#" class="btn btn-primary">Create</a>
                    </div>
                  </div>
                </div>
              </div>
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

    resizeListener: ->
      self = @       
      $(window).on 'resize', ->
        self.init()

      # mql = window.matchMedia("screen and (min-width: 800px)")
      # if mql.matches
      #   alert("800px")


  ToolbarView
).call(@)