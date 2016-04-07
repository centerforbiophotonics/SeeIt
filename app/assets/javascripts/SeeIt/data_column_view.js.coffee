@SeeIt.DataColumnView = (->
  class DataColumnView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @data, @color) ->
      @init()

    init: ->
      #DEMO PATCH
      @container.html("""
        <div style="height: 20px; width: 20px; display: inline-block; vertical-align: middle; background-color: #{@color};"></div>
        <a class='SeeIt data' style='display: inline-block;'>#{@data.header}</a>
      """)
      @populateGraphSelectBox()
      @registerListeners()
      
    registerListeners: ->
      self = @

      @listenTo(@data, 'header:changed', ->
        self.container.find('.SeeIt.data').html(@data.header)
      )

      @listenTo(@data, 'destroy', ->
        self.destroy.call(self)
      )

      @on 'graph:created', (graphId) ->
        self.addGraphOption.call(self, graphId)

      @on 'graph:destroyed', (graphId) ->
        self.removeGraphOption.call(self, graphId)

      @on 'graph:id:change', (oldId, newId) ->
        self.updateGraphOption.call(self, oldId, newId)

      @listenTo @app, 'ready', ->
        self.populateGraphDropdown.call(self)

    destroy: ->
      @container.remove()
      @trigger('destroy')

    populateGraphDropdown: ->
      self = @

      @trigger('graphs:requestIDs', (graphIds) ->
        graphIds.forEach (id) ->
          self.addGraphOption.call(self, id)
      )

    dropdownTemplate: ->
      """<div class="dropdown pull-right" style='padding: 3px; display: inline-block'>
        <button class="btn btn-primary dropdown-toggle" type="button" data-toggle="dropdown" aria-haspopup="true" id="dropdown_#{@data.header}">
          <div style='display: inline-block'><span class="glyphicon glyphicon-stats"></span></div>
          <span class="caret"></span>
        </button>
        <ul class="dropdown-menu text-center" aria-labelledby="dropdown_#{@data.header}">
          <span style='text-align: center; display: block; opacity: 0.75'>Add to graph...</span>
          <li role="separator" class="divider"></li>
        </ul>
      </div>"""

    updateGraphOption: (oldId, newId) ->
      @container.find("li a[data-id=#{oldId}]").attr('data-id', newId).html(newId)

    removeGraphOption: (graphId) ->
      @container.find("li a[data-id=#{graphId}]").remove()

    addGraphOption: (graphId) ->
      self = @

      @container.find('.dropdown-menu').append("<li class='add_to_graph'><a href='#' class='dropdown_child' data-id='#{graphId}'>#{graphId}</a></li>")

      selectGraph = (event) ->
        self.trigger('graph:addData', {graph: $(@).find('.dropdown_child').attr('data-id'), data: self.data})

      @container.find('.add_to_graph').off('click', selectGraph).on('click', selectGraph)

    populateGraphSelectBox: ->
      @container.find('a').after(@dropdownTemplate())
      @populateGraphDropdown()



  DataColumnView
).call(@)