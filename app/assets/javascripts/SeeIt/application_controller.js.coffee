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
          ['', 'Kia', 'Nissan', 'Toyota', 'Honda', 'Mazda', 'Ford'],
          ['2012', 10, 11, 12, 13, 15, 16],
          ['2013', 10, 11, 12, 13, 15, 16],
          ['2014', 10, 11, 12, 13, 15, 16],
          ['2015', 10, 11, 12, 13, 15, 16],
          ['2016', 10, 11, 12, 13, 15, 16]
        ],
        isLabeled: true
      },{
        title: "Dataset 2",
        dataset: [
          ["", "Ford", "Volvo", "Toyota", "Honda"],
          ["2016", 10, 11, 12, 13],
          ["2017", 20, 11, 14, 13],
          ["2018", 30, 15, 12, 13]
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

      @spreadsheetView = new SeeIt.SpreadsheetView(@, @layoutContainers['Spreadsheet'], @model.datasets[0])

      @toolbarView = new SeeIt.ToolbarView(@, @layoutContainers['Globals'], 
        [
          {class: "toggleData", title: "Show/Hide Data", handler: @handlers.toggleDataVisible},
          {class: "toggleSpreadsheet", title: "Show/Hide Spreadsheet", handler: @handlers.toggleSpreadsheetVisible},
          {class: "addGraph", title: "Add graph", handler: @handlers.addGraph, icon: "<span class='glyphicon glyphicon-plus'></span>"}  
        ]
      )

      @registerListeners()

    showDatasetInSpreadsheet: (dataset) ->
      @spreadsheetView.updateDataset(dataset)

    initHandlers: ->
      app = @

      app.handlers = {
        toggleDataVisible: ->
          app.toggleDataVisible.call(app)
        toggleSpreadsheetVisible: ->
          app.toggleSpreadsheetVisible.call(app)
        addGraph: ->
          app.graphCollectionView.addGraph()
          #DEMO PATCH
          app.dataCollectionView.datasetViewCollection.forEach (datasetView) ->
            datasetView.dataColumnViews.forEach (dataView) ->
              dataView.init.call(dataView)
      }

    registerListeners: ->
      app = @

      @listenTo(app.dataCollectionView, 'spreadsheet:load', (dataset) ->
        app.trigger('spreadsheet:load', dataset)
      )

      @listenTo(app.spreadsheetView, 'data:changed', (origin) ->
        @trigger('data:changed', origin)
      )

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