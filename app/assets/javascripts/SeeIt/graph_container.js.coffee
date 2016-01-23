@SeeIt.GraphContainer = (->
  class GraphContainer
    constructor: (@container) ->
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

    addGraph: ->
        @container.find(".graph-list").append("""
        <li class="SeeIt graph list-group-item" id="graph_#{@graphId}">
        </li>
        """)

        @graphs[@graphId.toString()] = new SeeIt.Graph(@graphId, @container.find("#graph_#{@graphId}"), @handlers.removeGraph)
        @graphId++

    toggleFullscreen: ->
      if @isFullscreen 
        @container.removeClass(@fullscreenClass).addClass(@splitscreenClass)
      else
        @container.removeClass(@splitscreenClass).addClass(@fullscreenClass)

      @isFullscreen = !@isFullscreen

  GraphContainer
).call(@)