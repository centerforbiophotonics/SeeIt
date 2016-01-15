@SeeIt.Application = (->
  class Application
    constructor: (@container) ->
      @layoutContainers = {}
      @initLayout()
      @graphContainer = new SeeIt.GraphContainer(@layoutContainers['Graphs'])
      @dataMenu = new SeeIt.DataMenu(@layoutContainers['Data'])
      @dataSet = new SeeIt.Dataset(["test"], [["I am data"]])
      @globals = new SeeIt.Globals(@layoutContainers['Globals'])

    initLayout: ->
      config = {
        content: [{
          type: 'column',
          content: [{
              type: 'component',
              componentName: 'Options',
              componentState: { text: 'Options' },
              isClosable: false,
              height: 10
            },
            {
              type: 'row',
              content: [
                {
                  type:'component',
                  componentName: 'Data',
                  componentState: { text: 'Data' },
                  isClosable: false
                },
                {
                  type:'component',
                  componentName: 'Graphs',
                  componentState: { text: 'Graphs' },
                  isClosable: false
                }
              ]
          }]
        }]
      }

      @layout = new GoldenLayout(config, @container)

      app = @
      ['Options', 'Data', 'Graphs'].forEach (type) ->
        app.layout.registerComponent type, (container, state) ->
          app.layoutContainers[type] = $(container.getElement())
        

      @layout.init()
      console.log @layout

  Application
).call(@)