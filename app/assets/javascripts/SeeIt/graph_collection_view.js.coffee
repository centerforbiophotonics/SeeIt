@SeeIt.GraphCollectionView = (->
  class GraphCollectionView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container) ->
      @graphs = {}
      @graphId = 1
      @handlers = {}
      @isFullscreen = false
      @fullscreenClass = 'col-md-12'
      @splitscreenClass = 'col-md-10'
      @initLayout()
      @initHandlers()
      @addGraph()

    initLayout: ->
      @container.html("<ul class='SeeIt graph-list list-group'></ul>")

    initHandlers: ->
      graphContainer = @

      graphContainer.handlers = {
        removeGraph: (graphId) ->
          delete graphContainer.graphs[graphId]
      }

      graphContainer.listenTo(@app, 'data:changed', (origin) ->
        for graphId, graph of graphContainer.graphs
          graph.updateGraph.call(graph)
      )

      graphContainer.listenTo(@app, 'graph:addData', (graphData) ->
        if graphContainer.graphs[graphData.graph]
          graphContainer.graphs[graphData.graph].addData(graphData.data)
      )

    addGraph: ->
        @container.find(".graph-list").append("""
        <li class="SeeIt graph list-group-item" id="graph_#{@graphId}">
        </li>
        """)

        @graphs[@graphId.toString()] = new SeeIt.GraphView(@app, @graphId, @container.find("#graph_#{@graphId}"), @handlers.removeGraph)
        @graphId++

    toggleFullscreen: ->
      if @isFullscreen 
        @container.removeClass(@fullscreenClass).addClass(@splitscreenClass)
      else
        @container.removeClass(@splitscreenClass).addClass(@fullscreenClass)

      @isFullscreen = !@isFullscreen

  GraphCollectionView
).call(@)