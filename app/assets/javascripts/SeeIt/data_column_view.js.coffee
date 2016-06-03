@SeeIt.DataColumnView = (->
  class DataColumnView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @data) ->
      @init()

    init: ->
      self = @


      @container.html("""
        <div class="SeeIt data-column-panel panel panel-default">
          <div class="SeeIt data-column-panel-body panel-body">
            <div class="SeeIt btn-group" role="group" style="width: 100%">
              <button type="button" title='Change Color' class="color-picker data-column-button SeeIt btn btn-default" style="background-color: #{@data.color}; width: 15%">
              </button>
              <button type="button" class="data-column-button SeeIt btn btn-default data" style='width: 60%'>#{@data.header}</button>
              <div role="group" title='Add to graph' class="data-column-button SeeIt btn-group SeeIt dropdown-container" style='width: 25%'></div>
            </div>
          </div>
        </div>
      """) 

      @container.find('.color-picker').first().spectrum({
        color: @data.color, 
        replacerClassName: 'hiddenColorpicker',
        change: (color) ->
          self.setColor.call(self, color.toHexString())
      })

      @container.find('.hiddenColorpicker').hide()

      @container.find('.color-picker').first().click -> 
        self.container.find('.hiddenColorpicker').trigger('click')

      @populateGraphSelectBox()
      @registerListeners()
      @alignGroupHeight()

    setColor: (color) ->
      @data.setColor(color)

      @container.find('.color-picker').css('background-color', @data.color)

    registerListeners: ->
      self = @

      @listenTo(@data, 'header:changed', ->
        self.container.find('.SeeIt.data').html(@data.header)
        self.alignGroupHeight.call(self)
      )

      @listenTo(@data, 'destroy', ->
        self.destroy.call(self)
      )

      @on 'graph:created', (graphId, dataRoles) ->
        self.addGraphOption.call(self, graphId, dataRoles)

      @on 'graph:destroyed', (graphId) ->
        self.removeGraphOption.call(self, graphId)

      @on 'graph:id:change', (oldId, newId) ->
        self.updateGraphOption.call(self, oldId, newId)

      @listenTo @app, 'ready', ->
        self.populateGraphDropdown.call(self)

      @on 'populate:dropdown', ->
        self.populateGraphDropdown.call(self)

      @on 'dataColumns:show', ->
        self.alignGroupHeight.call(self)

      $(window).on 'resize', ->
        self.alignGroupHeight.call(self)

    alignGroupHeight: ->
      headerHeight = @container.find('.SeeIt.data').height()

      @container.find('.btn:not(.data)').height(headerHeight)

    destroy: ->
      @container.remove()
      @trigger('destroy')

    populateGraphDropdown: ->
      self = @

      @trigger('graphs:requestIDs', (graphData) ->
        graphData.forEach (graph) ->
          self.addGraphOption.call(self, graph.id, graph.dataRoles)
      )

    dropdownTemplate: ->
      """
        <button class="btn btn-primary dropdown-toggle SeeIt graph-dropdown" type="button" data-toggle="dropdown" aria-haspopup="true" id="dropdown_#{@data.header}" style="width: 100%">
          <div style='display: inline-block'><span class="glyphicon glyphicon-stats"></span></div>
          <span class="caret"></span>
        </button>
        <ul class="dropdown-menu text-center" aria-labelledby="dropdown_#{@data.header}" style="position: fixed">
          <span style='text-align: center; display: block; opacity: 0.75'>Add to graph...</span>
          <li role="separator" class="divider"></li>
        </ul>
      """

    updateGraphOption: (oldId, newId) ->
      @container.find("li a[data-id='#{oldId}']").attr('data-id', newId).html(newId)

    removeGraphOption: (graphId) ->
      @container.find("li a[data-id='#{graphId}']").remove()

    addGraphOption: (graphId, dataRoles) ->
      self = @


      if dataRoles.length == 1
        @container.find('.dropdown-menu').append("<li class='add_to_graph' style='box-shadow: none'><a href='#' class='dropdown_child' data-id='#{graphId}'>#{graphId}</a></li>")

        selectGraph = (event) ->
          #data: {name: "default", data: self.data} is a temporary placeholder. I need to pass the data-role info to this view
          self.trigger('graph:addData', {graph: $(@).find('.dropdown_child').attr('data-id'), data: [{name: dataRoles[0].name, data: self.data}]})

        @container.find('.add_to_graph').off('click', selectGraph).on('click', selectGraph)
      else
        appendRoles = ->
          htmlStr = ''
          dataRoles.forEach (d, i) ->
            htmlStr += "<li class='add_to_data_role' data-graph='#{graphId}' data-id='#{dataRoles[i].name}'><a href='#' class='dropdown_child'>#{dataRoles[i].name}</a></li>"

          return htmlStr

        @container.find('.dropdown-menu').append("""
          <li class='SeeIt add_to_graph_submenu dropdown-submenu' style='box-shadow: none'>
            <a href='#' style='box-shadow: none' class='SeeIt dropdown_child dropdown-toggle' data-id='#{graphId}' id='#{graphId}' data-toggle='dropdown' aria-haspopup="true">#{graphId}</a>
            <ul class="SeeIt dropdown-menu text-center" aria-labelledby='#{graphId}' style='position: fixed'>
              <span style='text-align: center; display: block; opacity: 0.75'>Data Roles</span>
              <li role="separator" class="divider"></li>
                #{appendRoles()}
            </ul>
          </li>
        """)


        $('.add_to_graph_submenu').click(->
          dropDownFixPosition($(@),$(@).find('.dropdown-menu'))
          # $(window).on 'scroll'
        )


        selectGraphDataRole = ->
          self.trigger('graph:addData', {graph: $(@).attr('data-graph'), data: [{name: $(@).attr('data-id'), data: self.data}]})
        
        @container.find('.add_to_data_role').off('click', selectGraphDataRole).on('click', selectGraphDataRole)


      true
          
    populateGraphSelectBox: ->
      @container.find('.SeeIt.dropdown-container').html(@dropdownTemplate())
      @populateGraphDropdown()

      $('.SeeIt.graph-dropdown').click(->
        dropDownFixPosition($(@),$(@).next())
      )

  dropDownFixPosition = (button,dropdown) ->
    dropDownTop = button.offset().top + button.innerHeight() - 18;
    dropdown.css('top', dropDownTop + button.height() + "px");
    dropdown.css('left', button.offset().left + "px")

  DataColumnView
).call(@)