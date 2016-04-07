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
          graphContainer.trigger('graph:destroyed', graphId)
      }

      graphContainer.listenTo(@app, 'data:changed', (origin) ->
        for graphId, graph of graphContainer.graphs
          graph.updateGraph.call(graph)
      )

      graphContainer.listenTo(@app, 'graph:addData', (graphData) ->
        if graphContainer.graphs[graphData.graph]
          graphContainer.graphs[graphData.graph].addData(graphData.data)
      )

      @listenTo(@app, 'graph:create', ->
        graphContainer.addGraph.call(graphContainer)
      )

      @listenTo(@app, 'graphs:requestIDs', (cb) ->
        console.log "getting IDs"
        ids = []
        for graphId, graph of graphContainer.graphs
          ids.push graphId

        cb(ids)
      )

    changeGraphId: (oldId, newId) ->
      graph = @graphs[oldId]
      delete @graphs[oldId]
      @graphs[newId] = graph

      @trigger('graph:id:change', oldId, newId)

    addGraph: ->
      self = @

      @container.find(".graph-list").append("""
      <li class="SeeIt graph list-group-item" id="graph_#{@graphId}">
      </li>
      """)

      newGraph = new SeeIt.GraphView(@app, @graphId, @container.find("#graph_#{@graphId}"), @handlers.removeGraph)
      @graphs[@graphId.toString()] = newGraph

      @listenTo newGraph, 'graph:id:change', (oldId, newId) ->
        self.changeGraphId.call(self, oldId, newId)

      @graphId++

      @trigger('graph:created', @graphId-1)


    toggleFullscreen: ->
      if @isFullscreen 
        @container.removeClass(@fullscreenClass).addClass(@splitscreenClass)
      else
        @container.removeClass(@splitscreenClass).addClass(@fullscreenClass)

      @isFullscreen = !@isFullscreen

  GraphCollectionView
).call(@)