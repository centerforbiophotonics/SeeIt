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
      console.log params
      @container = if params.container then $(params.container) else $("body")

      ui = if params.ui then params.ui else {}

      @loadGraphs()

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
          {class: "toggleData", title: "Show/Hide Data", handler: @handlers.toggleDataVisible, type: "button"},
          {class: "toggleSpreadsheet", title: "Show/Hide Spreadsheet", handler: @handlers.toggleSpreadsheetVisible, type: "button"},
          {class: "addGraph", title: "Add graph", handler: @handlers.addGraph, icon: "<span class='glyphicon glyphicon-plus'></span>", type: "dropdown", options: @graphTypes}  ,
          {class: "uploadCSV", title: "Upload CSV", handler: @handlers.uploadCSV, type:"button"},
          {class: "uploadJSON", title: "Upload JSON", handler: @handlers.uploadJson, type: "button"},
          {class: "downloadJSON", title: "Download JSON", handler: @handlers.downloadJson, type: "button"}
        ]
      )

      @registerListeners()
      @trigger('ready')

    loadGraphs: ->
      @graphTypes = []

      for name, graph of SeeIt.Graphs
        @graphTypes.push({name: SeeIt.GraphNames[name], class: graph})

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
          graphName = $(@).attr('data-id')
          console.log graphName
          graphType = app.graphTypes.filter((g) -> g.name == graphName)[0]

          console.log graphType

          app.trigger('graph:create', graphType)
          # app.graphCollectionView.addGraph()
          # #DEMO PATCH
          # app.dataCollectionView.datasetViewCollection.forEach (datasetView) ->
          #   datasetView.dataColumnViews.forEach (dataView) ->
          #     dataView.init.call(dataView)

        saveCSVData: (event) ->
          event.stopPropagation()

          app.csvManager.handleUpload(@files[0], (data) ->
            dataset = {
              isLabeled: true,
              dataset: data
            }

            app.addDataset.call(app, dataset)
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
      # @dataCollectionView.addDatasetView(data)

    ###*
      # Initialize Backbone event listeners in which controller listens to members
    ###
    registerListeners: ->
      app = @

      @listenTo(app.dataCollectionView, 'spreadsheet:load', (dataset) ->
        if !app.spreadsheetVisible then app.toggleSpreadsheetVisible.call(app)
        

        console.log 'spreadsheet:load trigger in controller'
        app.trigger('spreadsheet:load', dataset)
      )

      @listenTo(app.spreadsheetView, 'data:changed', (origin) ->
        app.trigger('data:changed', origin)
      )

      @listenTo(app.dataCollectionView, 'graph:addData', (graphData) ->
        app.trigger('graph:addData', graphData)
      )

      @listenTo(app.dataCollectionView, 'dataset:create', (title) ->
        app.trigger('dataset:create', title)
      )

      @listenTo(app.model, 'dataset:created', (dataset) ->
        app.trigger('dataset:created', dataset)

        if !app.spreadsheetVisible then app.toggleSpreadsheetVisible.call(app)

        app.trigger('spreadsheet:load', dataset)
      )

      @listenTo(app.graphCollectionView, 'graph:created', (graphId, dataRoles) ->
        app.trigger('graph:created', graphId, dataRoles)
      )

      @listenTo(app.dataCollectionView, 'graphs:requestIDs', (cb) ->
        app.trigger('graphs:requestIDs', cb)
      )

      @listenTo(app.graphCollectionView, 'graph:destroyed', (graphId) ->
        app.trigger('graph:destroyed', graphId)
      )

      @listenTo(app.graphCollectionView, 'graph:id:change', (oldId, newId) ->
        app.trigger('graph:id:change', oldId, newId)
      )

    ###*
      # Toggles visibility of SpreadsheetView
    ###
    toggleSpreadsheetVisible: ->
      @spreadsheetView.toggleVisible()
      @spreadsheetVisible = !@spreadsheetVisible

      if @spreadsheetVisible then @spreadsheetView.updateView()

      @trigger('height:toggle')
      

    ###*
      # Toggles visibility of DataCollectionView
    ###
    toggleDataVisible: ->
      @dataCollectionView.toggleVisible()
      @graphCollectionView.toggleFullscreen()
      @spreadsheetView.toggleFullscreen()
      @dataVisible = !@dataVisible
      @trigger('width:toggle')

  ApplicationController
).call(@)