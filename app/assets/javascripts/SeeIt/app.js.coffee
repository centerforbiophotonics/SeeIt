@SeeIt.Application = (->
  class Application
    constructor: (@container) ->
      @layoutContainers = {}
      @initLayout()
      @initHandlers()
      @dataVisible = true
      @graphContainer = new SeeIt.GraphContainer(@layoutContainers['Graphs'])
      @dataMenu = new SeeIt.DataMenu(@layoutContainers['Data'])
      @dataSet = new SeeIt.Dataset(["test"], [["I am data"]])
      @globals = new SeeIt.Globals(@layoutContainers['Globals'], 
        [
          {class: "toggleData", title: "Show/Hide Data", handler: @handlers.toggleDataVisible}
        ]
      )

    initHandlers: ->
      app = @

      app.handlers = {
        toggleDataVisible: ->
          app.toggleDataVisible.call(app)
      }

    initLayout: ->
      @container.html('<div class="SeeIt Globals"></div><div class="SeeIt container-fluid"><div class="SeeIt row"></div></div>')
    
      @layoutContainers['Globals'] = @container.find(".Globals")

      @container.find('.row').append("<div class='SeeIt Data col-md-2'></div>")
      @layoutContainers['Data'] = @container.find(".Data")
        
      @container.find('.row').append("<div class='SeeIt Graphs col-md-10'></div>")
      @layoutContainers['Graphs'] = @container.find(".Graphs")

    toggleDataVisible: ->
      @dataMenu.toggleVisible()
      @graphContainer.toggleFullscreen()
      @dataVisible = !@dataVisible

  Application
).call(@)