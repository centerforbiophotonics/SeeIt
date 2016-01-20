@SeeIt.GraphContainer = (->
  class GraphContainer
    constructor: (@container) ->
      @graphs = {}
      @graphId = 1
      @isFullscreen = false
      @fullscreenClass = 'col-md-12'
      @splitscreenClass = 'col-md-10'
      @initLayout()
      @addGraph()

    initLayout: ->
      @container.html("<ul class='SeeIt graph-list list-group'></ul>")

    addGraph: ->
        @container.find(".graph-list").append("""
        <li class="SeeIt graph list-group-item" id="graph_#{@graphId}">
          <div class="SeeIt graph-panel panel panel-default">
            <div class="SeeIt panel-heading">Graph #{@graphId++}<span class="glyphicon glyphicon-remove" style="float: right"></span></div>
            <div class="SeeIt panel-body"></div>
          </div>
        </li>
        """)

    toggleFullscreen: ->
      if @isFullscreen 
        @container.removeClass(@fullscreenClass).addClass(@splitscreenClass)
      else
        @container.removeClass(@splitscreenClass).addClass(@fullscreenClass)

      @isFullscreen = !@isFullscreen

    removeGraph: (graphIdx) ->
      @graphs.splice graphIdx

  GraphContainer
).call(@)