@SeeIt.Application = (->
  class Application
    constructor: (@container) ->
      @initLayout()
      @graphContainer = new SeeIt.GraphContainer()
      @dataMenu = new SeeIt.DataMenu()
      @dataSet = new SeeIt.Dataset(["test"], [["I am data"]])

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
          container.getElement().html ''
        

      @layout.init()
      console.log @layout

  Application
).call(@)