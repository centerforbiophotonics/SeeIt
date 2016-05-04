@SeeIt.GraphCollectionView = (->
  class GraphCollectionView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container) ->
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
        console.log "In GraphCollectionsView's addData handler:", graphData, graphContainer.graphs
        if graphContainer.graphs[graphData.graph]
          graphContainer.graphs[graphData.graph].addData(graphData.data)
      )

      @listenTo(@app, 'graph:create', (graphType) ->
        graphContainer.addGraph.call(graphContainer, graphType)
      )

      @listenTo(@app, 'graphs:requestIDs', (cb) ->
        console.log "getting IDs"
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

      @container.find("#graph_#{oldId}").attr('id', "graph_#{newId}")

      delete @graphs[oldId]
      @graphs[newId] = graph

      @trigger('graph:id:change', oldId, newId)

    addGraph: (graphType) ->
      self = @

      @findValidId()

      @container.find(".graph-list").append("""
      <li class="SeeIt graph list-group-item" id="graph_#{@graphId.split(' ').join('-')}">
      </li>
      """)

      newGraph = new SeeIt.GraphView(@app, @graphId, @container.find("#graph_#{@graphId.split(' ').join('-')}"), @handlers.removeGraph, graphType)
      @graphs[@graphId] = newGraph

      @listenTo newGraph, 'graph:id:change', (oldId, newId) ->
        self.changeGraphId.call(self, oldId, newId)

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