@SeeIt.GraphCollectionView = (->
  class GraphCollectionView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @graphs_editable) ->
      @graphs = {}
      @graphId = "Graph 1"
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
        # for graphId, graph of graphContainer.graphs
        #   graph.updateGraph.call(graph)
      )

      graphContainer.listenTo(@app, 'graph:addData', (graphData) ->
        console.log "graph_container: ", graphContainer
        if graphContainer.graphs[graphData.graph]
          graphContainer.graphs[graphData.graph].addData(graphData.data)
      )

      graphContainer.listenTo(@app, 'graph:filter', (graphData) ->
        if graphContainer.graphs[graphData.graph]
          graphContainer.graphs[graphData.graph].updateFilters(graphData.filters)
      )

      @listenTo(@app, 'graph:create', (graphType) ->
        graphContainer.addGraph.call(graphContainer, graphType)
      )

      @listenTo(@app, 'graphs:requestIDs', (cb) ->
        graphData = []

        for graphId, graph of graphContainer.graphs
          graph.trigger('request:dataRoles', (dataRoles) ->
            graphData.push {id: graphId, dataRoles: dataRoles}
          )

        cb(graphData)
      )

      @listenTo(@app, 'height:toggle', ->
        graphContainer.container.toggleClass("spreadsheet-visible")
        
        for graphId, graph of graphContainer.graphs
          graph.trigger('size:change')
      )

      @listenTo(@app, 'width:toggle', ->
        for graphId, graph of graphContainer.graphs
          graph.trigger('size:change')
      )

    findValidId: ->
      @graphId = "Graph 1"
      idx = 1

      keys = Object.keys(@graphs)

      while keys.indexOf(@graphId) != -1
        @graphId = "Graph #{++idx}"

    changeGraphId: (oldId, newId) ->
      graph = @graphs[oldId]

      if @graphs[newId]
        return false
      else
        delete @graphs[oldId]
        @graphs[newId] = graph

        @trigger('graph:id:change', oldId, newId)
        return true


    getGraphSettings: ->
      settings = []

      for id, graph of @graphs
        settings.push graph.getGraphSettings()

      return settings

    getGraphTypes: ->
      types = []

      for id, graph of @graphs
        types.push graph.getGraphType()

      return types

    getGraphStates: ->
      states = []

      for id, graph of @graphs
        states.push graph.getGraphState()

      return states

    getGraphFilters: ->
      filters = []

      for id, graph of @graphs
        states.push graph.getGraphFilters()

      return filters

    addGraph: (graphType) ->
      self = @

      @findValidId()

      @container.find(".graph-list").append("""
        <li class="SeeIt graph list-group-item">
        </li>
      """)

      newGraph = new SeeIt.GraphView(@app, @graphId, @container.find(".graph.list-group-item:last"), @handlers.removeGraph, graphType, @graphs_editable)
      @graphs[@graphId] = newGraph

      @listenTo newGraph, 'graph:id:change', (oldId, newId, cb) ->
        cb self.changeGraphId.call(self, oldId, newId)

      @listenTo newGraph, 'graphSettings:get', (graphName, cb) ->
        self.trigger('graphSettings:get', graphName, cb)

      @listenTo newGraph, 'request:dataset_names', (cb) ->
        self.trigger 'request:dataset_names', cb

      @listenTo newGraph, 'request:columns', (dataset, cb) ->
        self.trigger 'request:columns', dataset, cb

      @listenTo newGraph, 'request:values:unique', (dataset, colIdx, callback) ->
        self.trigger 'request:values:unique', dataset, colIdx, callback

      @listenTo newGraph, 'request:dataset', (name, callback) ->
        self.trigger 'request:dataset', name, callback

      newGraph.trigger('request:dataRoles', (dataRoles) ->
        self.trigger('graph:created', self.graphId, dataRoles)
      )


    toggleFullscreen: ->
      if @isFullscreen 
        @container.removeClass(@fullscreenClass).addClass(@splitscreenClass)
      else
        @container.removeClass(@splitscreenClass).addClass(@fullscreenClass)

      @isFullscreen = !@isFullscreen

  GraphCollectionView
).call(@)