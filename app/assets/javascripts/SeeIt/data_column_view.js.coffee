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
      @populateBadSelectBox()
      @registerListeners()
      
    registerListeners: ->
      self = @

      @listenTo(@data, 'header:changed', ->
        self.container.find('.SeeIt.data').html(@data.header)
      )

      @listenTo(@data, 'destroy', ->
        self.destroy.call(self)
      )

    destroy: ->
      @container.remove()
      @trigger('destroy')

    #DEMO PATCH
    populateBadSelectBox: ->
      @container.find('a').after("""
        <div class="dropdown pull-right" style='padding: 3px; display: inline-block'>
          <button class="btn btn-primary dropdown-toggle" type="button" data-toggle="dropdown" aria-haspopup="true" id="dropdown_#{@data.header}">
            <div style='display: inline-block'><span class="glyphicon glyphicon-stats"></span></div>
            <span class="caret"></span>
          </button>
          <ul class="dropdown-menu text-center" aria-labelledby="dropdown_#{@data.header}">
            <span style='text-align: center; display: block; opacity: 0.75'>Add to graph...</span>
            <li role="separator" class="divider"></li>
          </ul>
        </div>
      """)

      self = @

      for graphId, graph of @app.graphCollectionView.graphs
        @container.find('.dropdown-menu').append("<li class='add_to_graph'><a href='#' class='dropdown_child' data-id='#{graphId}'>#{graphId}</a></li>")

      reallyBadHandler = (event) ->
        self.trigger('graph:addData', {graph: $(@).find('.dropdown_child').attr('data-id'), data: self.data})

      @container.find('.add_to_graph').off('click', reallyBadHandler).on('click', reallyBadHandler)

  DataColumnView
).call(@)