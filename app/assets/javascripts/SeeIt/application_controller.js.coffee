@SeeIt.ApplicationController = (->
  class ApplicationController
    _.extend(@prototype, Backbone.Events)

    ###*
      # The constructor for ApplicationController
      # @class
      # @classdesc ApplicationController is responsible for initializing views and models, handling event passing, and communicating with the world.
      # @param {Object} container - jQuery object referencing container SeeIt will live in
    ###
    constructor: (params = {}) ->
      @container = if params.container then $(params.container) else $("body")

      ui = if params.ui then params.ui else {}

      @view = new SeeIt.ApplicationView(@, @container)
      @layoutContainers = @view.initLayout()
      @initHandlers()

      #Get data
      #TODO: Add more validation of data
      data = if params.data != undefined then params.data else []

      #Initialize UI options
      @ui = {
        editable: if ui.editable != undefined then ui.editable else true,
        spreadsheet: if ui.spreadsheet != undefined then ui.spreadsheet else true,
        dataMenu: if ui.dataMenu != undefined then ui.dataMenu else true,
        toolbar: if ui.toolbar != undefined then ui.toolbar else true,
        graph_editable: if ui.graph_editable != undefined then ui.graph_editable else true
      }

      testData = [{
        title: "Dataset 1", 
        dataset: [
          ['', 'Kia', 'Nissan', 'Toyota', 'Honda', 'Mazda', 'Ford'],
          ['2012', 10, 11, 12, 13, 15, 16],
          ['2013', 12, 11, 12, 13, 15, 16],
          ['2014', 15, 11, 12, 13, 15, 16],
          ['2015', 10, 11, 12, 13, 15, 16],
          ['2016', 5, 11, 12, 13, 15, 16]
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
      },{
        title: "Dataset 3",
        dataset: {
          labels: ['A', 'B', 'C'],
          columns: [
            {
              header: 'a',
              type: "numeric",
              data: [2,3,4]
            },
            {
              header: 'b',
              type: "numeric",
              data: [21,34,45]
            }
          ]
        },
        isLabeled: true
      }]

      newData = {
        title: "Random Data",
        dataset: [[1,2,3,4,5]],
        isLabeled: false
      }

      for i in [1...10000]
        newData.dataset.push []
        for j in [0...5]
          newData.dataset[i].push Math.random() * 10

      console.log newData
      testData.push newData
      data = testData

      #Data model
      @model = new SeeIt.DataCollection(@, data)

      @dataVisible = true
      @spreadsheetVisible = false

      # Container for graphs
      @graphCollectionView = new SeeIt.GraphCollectionView(@, @layoutContainers['Graphs'])

      #Container for list of datasets
      @dataCollectionView = new SeeIt.DataCollectionView(
        @,
        @layoutContainers['Data'],
        @model
      )

      #Create CSV manager
      @csvManager = new SeeIt.CSVManager()

      #Create JSON manager
      @jsonManager = new SeeIt.JsonManager()

      #Container for spreadsheet
      @spreadsheetView = new SeeIt.SpreadsheetView(@, @layoutContainers['Spreadsheet'])

      #Container for toolbar
      @toolbarView = new SeeIt.ToolbarView(@, @layoutContainers['Globals'], 
        [
          {class: "toggleData", title: "Show/Hide Data", handler: @handlers.toggleDataVisible},
          {class: "toggleSpreadsheet", title: "Show/Hide Spreadsheet", handler: @handlers.toggleSpreadsheetVisible},
          {class: "addGraph", title: "Add graph", handler: @handlers.addGraph, icon: "<span class='glyphicon glyphicon-plus'></span>"}  ,
          {class: "uploadCSV", title: "Upload CSV", handler: @handlers.uploadCSV},
          {class: "uploadJSON", title: "Upload JSON", handler: @handlers.uploadJson},
          {class: "downloadJSON", title: "Download JSON", handler: @handlers.downloadJson}
        ]
      )

      @registerListeners()

    ###*
      # Sets active dataset in spreadsheet to the given dataset
      # @param {Object} dataset - DatasetModel instance
    ###
    showDatasetInSpreadsheet: (dataset) ->
      @spreadsheetView.updateDataset(dataset)

    ###*
      # Initializes SeeIt.ApplicationController.handlers with DOM event handlers
    ###
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
        saveCSVData: (event) ->
          event.stopPropagation()

          app.csvManager.handleUpload(@files[0], (data) ->
            app.addDataset.call(app, data)
          )

          return false
        uploadCSV: ->
          if !$("#hidden-csv-upload").length
            app.container.append "<input id='hidden-csv-upload' type='file' style='display: none'>"

          $("#hidden-csv-upload").off('change', app.handlers.saveCSVData).on('change', app.handlers.saveCSVData)
          $("#hidden-csv-upload").click()
    
        uploadJson: ->
          if !$("#hidden-json-upload").length
            app.container.append "<input id='hidden-json-upload' type='file' style='display: none'>"

          $("#hidden-json-upload").off('change', app.handlers.saveJsonData).on('change', app.handlers.saveJsonData)
          $("#hidden-json-upload").click()

        saveJsonData: (event) ->
          event.stopPropagation()

          app.jsonManager.handleUpload(@files[0], (data) ->
            data.forEach (d) ->
              app.addDataset.call(app, d)
          )

          return false

        downloadJson: (event) ->
          app.jsonManager.handleDownload(app.model)
      }

    addDataset: (dataset) ->
      data = @model.addDataset(dataset)
      @dataCollectionView.addDatasetView(data)

    ###*
      # Initialize Backbone event listeners in which controller listens to members
    ###
    registerListeners: ->
      app = @

      @listenTo(app.dataCollectionView, 'spreadsheet:load', (dataset) ->
        app.trigger('spreadsheet:load', dataset)
      )

      @listenTo(app.spreadsheetView, 'data:changed', (origin) ->
        app.trigger('data:changed', origin)
      )

      @listenTo(app.dataCollectionView, 'graph:addData', (graphData) ->
        app.trigger('graph:addData', graphData)
      )

    ###*
      # Toggles visibility of SpreadsheetView
    ###
    toggleSpreadsheetVisible: ->
      @spreadsheetView.toggleVisible()
      @graphCollectionView.container.toggleClass("spreadsheet-visible")
      @spreadsheetVisible = !@spreadsheetVisible

    ###*
      # Toggles visibility of DataCollectionView
    ###
    toggleDataVisible: ->
      @dataCollectionView.toggleVisible()
      @graphCollectionView.toggleFullscreen()
      @spreadsheetView.toggleFullscreen()
      @dataVisible = !@dataVisible

  ApplicationController
).call(@)