@SeeIt.GraphContainer = (->
  class GraphContainer
    constructor: (@container) ->
      @graphs = []
      @initLayout()
      @addGraph()

    initLayout: ->
      config = {
        content: [{
          type: 'column',
          componentName: 'Graphs'
        }]
      }
      @layout = new GoldenLayout(config, @container)

      @layout.registerComponent 'Graphs', (container, state) ->

      @layout.init()

    addGraph: ->
      graphContainer = @
      @layout.registerComponent "Graph #{@graphs.length + 1}", (container, state) ->
        graphContainer.graphs.push(new SeeIt.Graph($(container.getElement())))

      @layout.root.contentItems[0].addChild({
        type: 'component',
        componentName: "Graph #{@graphs.length + 1}"
      });


    removeGraph: (graphIdx) ->
      @graphs.splice graphIdx

  GraphContainer
).call(@)