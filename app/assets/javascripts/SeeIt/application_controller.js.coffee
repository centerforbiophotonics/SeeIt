@SeeIt.ApplicationController = (->
  class ApplicationController
    _.extend(@prototype, Backbone.Events)

    constructor: (@container) ->
      @view = new SeeIt.ApplicationView(@, @container)
      @layoutContainers = @view.initLayout()
      @initHandlers()

      testData = [{
        title: "Dataset 1", 
        dataset: [
          ['', 'Header 1'],
          ['Label 1', 1]
        ],
        isLabeled: true
      }]

      #Data model
      @model = new SeeIt.DataCollection(@, testData)

      @dataVisible = true
      @spreadsheetVisible = false

      @graphCollectionView = new SeeIt.GraphCollectionView(@, @layoutContainers['Graphs'])

      @dataCollectionView = new SeeIt.DataCollectionView(
        @,
        @layoutContainers['Data'],
        @model
      )

      @spreadsheetView = new SeeIt.SpreadsheetView(@, @layoutContainers['Spreadsheet'], null)

      @toolbarView = new SeeIt.ToolbarView(@, @layoutContainers['Globals'], 
        [
          {class: "toggleData", title: "Show/Hide Data", handler: @handlers.toggleDataVisible},
          {class: "toggleSpreadsheet", title: "Show/Hide Spreadsheet", handler: @handlers.toggleSpreadsheetVisible},
          {class: "addGraph", title: "Add graph", handler: @handlers.addGraph, icon: "<span class='glyphicon glyphicon-plus'></span>"}  
        ]
      )

    initHandlers: ->
      app = @

      app.handlers = {
        toggleDataVisible: ->
          app.toggleDataVisible.call(app)
        toggleSpreadsheetVisible: ->
          app.toggleSpreadsheetVisible.call(app)
        addGraph: ->
          app.graphCollectionView.addGraph()
      }

    toggleSpreadsheetVisible: ->
      @spreadsheetView.toggleVisible()
      @graphCollectionView.container.toggleClass("spreadsheet-visible")
      @spreadsheetVisible = !@spreadsheetVisible

    toggleDataVisible: ->
      @dataCollectionView.toggleVisible()
      @graphCollectionView.toggleFullscreen()
      @dataVisible = !@dataVisible

  ApplicationController
).call(@)