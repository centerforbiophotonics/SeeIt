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
        <li class="dropdown">
          <a class="dropdown-toggle" type="button" data-toggle="dropdown" href="#">
            Menu<span class="caret"></span>
          </a>
          <ul class="dropdown-menu">
      """

      for i of @navElements
        if i == '0' || i == '1'
          continue
        else
          icon = if @navElements[i].icon then "<div class='iconContainer'>#{@navElements[i].icon}</div>" else ''

          if @navElements[i].type == "dropdown"
            htmlStr += """
              <li>
                <div class="icon_container SeeIt nav-el left" style="display: inline-block">#{icon}</div>
                <div class="SeeIt nav-el right" id="#{@navElements[i].title}_dropdown">
                  <a href="#graph-modal" data-toggle="modal" data-target="#graph-modal" style="color: #777">
                    #{@navElements[i].title}
                  </a>
                </div>
              </li>
            """
          else if @navElements[i].class == "downloadInitOptions"
            htmlStr += """
                <li class="#{@navElements[i].class}">#{icon}<a href="#" style="color: #777">#{@navElements[i].title}</a></li> 
              </ul>
              <div class="modal" id="graph-modal" role="dialog">
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
                          #{@populateDropdownModal()}
                        </select>
                      </div>
                      <div class="form-group">
                        <label for="dropdown-form">Graph Name</label>
                        <input class="form-control" id="inputGraphName" placeholder="Enter name" type="text">
                      </div>
                    </div>
                    <div class="modal-footer">
                      <a href="#" data-dismiss="modal" class="btn">Close</a>
                      <a href="#" class="btn btn-primary" id="create-graph">Create</a>
                    </div>
                  </div>
                </div>
              </div>        
            """ 
          else
            htmlStr += """
              <li class="#{@navElements[i].class}">#{icon}<a href="#" style="color: #777">#{@navElements[i].title}</a></li> 
            """

      return htmlStr+"</li>"+"</ul>"

    populateDropdownModal: ->
      navEl = @navElements[2]
      graphNames = """#{navEl.options.map((option) -> "<option class='#{navEl.class}' data-id='#{option.name}'><a href='#'>#{option.name}</a></option>")}"""
      
      return graphNames
    
    buildNav: ->
      htmlStr = '<ul class="nav navbar-nav" display="none">'
      @navElements.forEach (el) ->
        icon = if el.icon then "<div class='iconContainer'>#{el.icon}</div>" else ''

        if el.type == "dropdown"
          htmlStr += """
            <li>
              <div class="icon_container SeeIt nav-el left" style="display: inline-block">#{icon}</div>
              <div class="SeeIt nav-el right" id="#{el.title}_dropdown">
                <a href="#graph-modal" data-toggle="modal" data-target="#graph-modal" style="color: #777">
                  #{el.title}
                </a>
              </div>

              <div class="modal" id="graph-modal" role="dialog">
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
                      <a href="#" class="btn btn-primary" id="create-graph">Create</a>
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

      toolbar.container.find("#create-graph").on 'click', (event) ->
        $('#graph-modal').modal('hide')
        selectedGraph = toolbar.container.find("#dropdown-form").val()
        $(".addGraph[data-id='"+selectedGraph+"']").trigger("click")
        $('a[href="#graphs_tab"]').tab('show')
        $("html, body").animate({ scrollTop: $(document).height() - $(window).height() })

    resizeListener: ->
      self = @       
      $(window).on 'resize', ->
        self.init()

  ToolbarView
).call(@)