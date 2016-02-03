@SeeIt.DataColumnView = (->
  class DataColumnView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @data) ->
      @init()

    init: ->
      #DEMO PATCH
      @container.html("<a class='SeeIt data' style='display: inline-block; min-height: 40px'>#{@data.header}</a>")
      @populateBadSelectBox()

    #DEMO PATCH
    populateBadSelectBox: ->
      @container.find('a').after("""
        <div class="dropdown pull-right" style='padding: 3px; display: inline-block'>
          <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown" aria-haspopup="true" id="dropdown_#{@data.header}">
            Add to graph...
            <span class="caret"></span>
          </button>
          <ul class="dropdown-menu" aria-labelledby="dropdown_#{@data.header}">
          </ul>
        </div>
      """)

      for graphId, graph of @app.graphCollectionView.graphs
        console.log graphId
        @container.find('.dropdown-menu').append("<li class='add_to_graph'><a href='#' class='dropdown_child' data-id='#{graphId}'>#{graphId}</a></li>")

      reallyBadHandler = (event) ->
        if self.app.graphCollectionView.graphs[$(@).find('.dropdown_child').attr('data-id')]
          self.app.graphCollectionView.graphs[$(@).find('.dropdown_child').attr('data-id')].addData(self.data)

      self = @
      @container.find('.add_to_graph').off('click', reallyBadHandler).on('click', reallyBadHandler)


  DataColumnView
).call(@)