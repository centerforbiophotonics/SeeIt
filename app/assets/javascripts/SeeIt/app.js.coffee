@SeeIt.Application = (->
  class Application
    _.extend(@prototype, Backbone.Events)

    constructor: (@container) ->
      @layoutContainers = {}
      @initLayout()
      @initHandlers()
      @dataVisible = true
      @graphContainer = new SeeIt.GraphContainer(@layoutContainers['Graphs'])
      @dataMenu = new SeeIt.DataMenu(
        @layoutContainers['Data'],
        [{
          title: "Dataset 1", 
          dataset: [
            ['', 'Header 1'],
            ['Label 1', 1]
          ],
          hasLabels: true
        }]
      )
      @globals = new SeeIt.Globals(@layoutContainers['Globals'], 
        [
          {class: "toggleData", title: "Show/Hide Data", handler: @handlers.toggleDataVisible},
          {class: "addGraph", title: "Add graph", handler: @handlers.addGraph, icon: "<span class='glyphicon glyphicon-plus'></span>"}  
        ]
      )

    initHandlers: ->
      app = @

      app.handlers = {
        toggleDataVisible: ->
          app.toggleDataVisible.call(app)
        addGraph: ->
          app.graphContainer.addGraph()
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