@SeeIt.GraphCollectionView = (->
  class GraphCollectionView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @graphs_editable, @data) ->
      @graphView = []
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
      self = @

      self.handlers = {
        removeGraph: (graphId) ->
          delete self.graphs[graphId]
          self.trigger('graph:destroyed', graphId)
      }

      self.listenTo(@app, 'data:changed', (origin) ->
        # for graphId, graph of graphContainer.graphs
        #   graph.updateGraph.call(graph)
      )

      self.listenTo(@app, 'graph:addData', (graphData) ->
        if self.graphs[graphData.graph]
          self.graphs[graphData.graph].addData(graphData.data)
      )

      self.listenTo(@app, 'graph:filter', (graphData) ->
        if self.graphs[graphData.graph]
          self.graphs[graphData.graph].updateFilters(graphData.filters)
      )

      @listenTo(@app, 'graph:create', (graphType, inputGraphName) ->
        self.addGraph.call(self, graphType, inputGraphName)
      )

      @listenTo(@app, 'graphs:requestIDs', (cb) ->
        graphData = []

        for graphId, graph of self.graphs
          graph.trigger('request:dataRoles', (dataRoles) ->
            graphData.push {id: graphId, dataRoles: dataRoles}
          )

        cb(graphData)
      )

      @listenTo(@app, 'height:toggle', ->
        self.container.toggleClass("spreadsheet-visible")
        
        for graphId, graph of self.graphs
          graph.trigger('size:change')
      )

      @listenTo(@app, 'width:toggle', ->
        for graphId, graph of self.graphs
          graph.trigger('size:change')
      )

    findValidId: (inputGraphName) ->
      if inputGraphName == undefined || inputGraphName == ""
        @graphId = "Graph 1"
        idx = 1
        keys = Object.keys(@graphs)

        while keys.indexOf(@graphId) != -1
          @graphId = "Graph #{++idx}"
      else
        @graphId = inputGraphName


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

    addGraph: (graphType, inputGraphName) ->
      self = @

      @findValidId(inputGraphName)

      @container.find(".graph-list").append("""
        <li class="SeeIt graph list-group-item">
        </li>
      """)

      newGraph = new SeeIt.GraphView(@app, @graphId, @container.find(".graph.list-group-item:last"), @handlers.removeGraph, graphType, @graphs_editable, @data)
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

      @listenTo newGraph, 'filter:save-all', (filterGroups, name) ->
        needs_confirm = false
        filtered_graphs = []
        origin_graph_requirements = ""

        for id, graph of self.graphs
          if graph.filterGroups.length > 0 && id != name
            needs_confirm = true
            filtered_graphs.push(id)
          if id == name
            graph.saveFilters()
            origin_graph_requirements = graph.operator

        confirmed = true
        if needs_confirm
          confirmed = confirm("You are about to overwrite filters on #{filtered_graphs}")

        if confirmed  
          for id, graph of self.graphs
            if id != name
              for filterGroup in graph.filterGroups
                filterGroup.removeFilterGroup()
              graph.filterGroups = []
              for filterGroup, i in filterGroups
              
                graph.addFilterGroup()
                if filterGroup.filters.length > 1
                  for j in [1...filterGroup.filters.length]
                    self.trigger 'request:dataset_names', (datasets) ->
                      graph.filterGroups[i].addFilter(datasets)

                graph.container.find(".filter-group-requirements-select").val(origin_graph_requirements)
                graph.filterGroups[i].clone(filterGroup)

          for id, graph of self.graphs
            if id != name
              graph.saveFilters()

            
      newGraph.trigger('request:dataRoles', (dataRoles) ->
        self.trigger('graph:created', self.graphId, dataRoles)
      )
      
      # listen for trigger in graph_view
      @listenTo(newGraph, 'graph:addData', (dataGraph) ->
        self.trigger('graph:addData', dataGraph)
      )

    removeFooterFromDataset: (dataset_title) ->
      self = @

      for i, graph of @graphs
        graph.removeData(dataset_title)

    toggleFullscreen: ->
      if @isFullscreen 
        @container.removeClass(@fullscreenClass).addClass(@splitscreenClass)
      else
        @container.removeClass(@splitscreenClass).addClass(@fullscreenClass)

      @isFullscreen = !@isFullscreen

  GraphCollectionView
).call(@)