@SeeIt.GraphCollectionView = (->
  class GraphCollectionView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container) ->
      @graphs = {}
      @graphId = 1
      @handlers = {}
      @isFullscreen = false
      @fullscreenClass = 'col-md-12'
      @splitscreenClass = 'col-md-9'
      @initLayout()
      @initHandlers()

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
        console.log "In GraphCollectionsView's addData handler:", graphData, graphContainer.graphs
        if graphContainer.graphs[graphData.graph]
          graphContainer.graphs[graphData.graph].addData(graphData.data)
      )

      @listenTo(@app, 'graph:create', (graphType) ->
        graphContainer.addGraph.call(graphContainer, graphType)
      )

      @listenTo(@app, 'graphs:requestIDs', (cb) ->
        console.log "getting IDs"
        ids = []
        for graphId, graph of graphContainer.graphs
          ids.push graphId

        cb(ids)
      )

    findValidId: ->
      @graphId = 1

      keys = Object.keys(@graphs)

      while keys.indexOf(@graphId.toString()) != -1
        @graphId++

    changeGraphId: (oldId, newId) ->
      graph = @graphs[oldId]

      @container.find("#graph_#{oldId}").attr('id', "graph_#{newId}")

      delete @graphs[oldId]
      @graphs[newId] = graph

      @trigger('graph:id:change', oldId, newId)

    addGraph: (graphType) ->
      self = @

      @findValidId()

      @container.find(".graph-list").append("""
      <li class="SeeIt graph list-group-item" id="graph_#{@graphId}">
      </li>
      """)

      newGraph = new SeeIt.GraphView(@app, @graphId, @container.find("#graph_#{@graphId}"), @handlers.removeGraph, graphType)
      @graphs[@graphId.toString()] = newGraph

      @listenTo newGraph, 'graph:id:change', (oldId, newId) ->
        self.changeGraphId.call(self, oldId, newId)

      @graphId++

      newGraph.trigger('request:dataRoles', (dataRoles) ->
        self.trigger('graph:created', self.graphId-1, dataRoles)
      )


    toggleFullscreen: ->
      if @isFullscreen 
        @container.removeClass(@fullscreenClass).addClass(@splitscreenClass)
      else
        @container.removeClass(@splitscreenClass).addClass(@fullscreenClass)

      @isFullscreen = !@isFullscreen

  GraphCollectionView
).call(@)