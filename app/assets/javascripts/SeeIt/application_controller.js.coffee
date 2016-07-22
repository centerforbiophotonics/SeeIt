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
      @params = params
      @container = if params.container then $(params.container) else $("body")

      ui = if params.ui then params.ui else {}

      @loadGraphs()

      @view = new SeeIt.ApplicationView(@, @container)
      @layoutContainers = @view.initLayout()
      @initHandlers()

      #Get data
      #TODO: Add more validation of data
      data = if params.data != undefined then params.data else []

      
      
      color = d3.scale.linear().domain([-1, 0, 1]).range(["red", "white", "green"])
      color2 = d3.scale.linear().domain([0,1]).range("white", "black")
      colorRed = []
      colorGreen = []
      blackAndWhite = [];
      blackAndWhite.push((color2(num/100))) for num in [0..100]
      colorRed.push(color(-num/100) ) for num in [0..100]
      colorGreen.push(color(num/100) ) for num in [0..100]

      redPalette = new SeeIt.ColorPalette('Red', colorRed)
      greenPalette = new SeeIt.ColorPalette('Green', colorGreen)
      blackPalette = new SeeIt.ColorPalette("Black and White", blackAndWhite)
      @paletteTypes = [];
      @paletteTypes.push({name: blackPalette.name, class: blackPalette })
      @paletteTypes.push({name: redPalette.name, class: redPalette })
      @paletteTypes.push({name: greenPalette.name, class: greenPalette })  





      #Initialize UI options
      @ui = {
        editable:       if ui.editable != undefined then ui.editable else true,
        spreadsheet:    if ui.spreadsheet != undefined then ui.spreadsheet else true,
        dataMenu:       if ui.dataMenu != undefined then ui.dataMenu else true,
        toolbar:        if ui.toolbar != undefined then ui.toolbar else true,
        graph_editable: if ui.graph_editable != undefined then ui.graph_editable else true
      }

      graph_init_data = if params.graphs then params.graphs else []

      @graph_settings = if params.graph_settings then params.graph_settings else []

      #Data model
      @model = new SeeIt.DataCollection(@, data, @ui.editable)

      @dataVisible = true
      @spreadsheetVisible = false

      # Container for graphs
      @graphCollectionView = new SeeIt.GraphCollectionView(@, @layoutContainers['Graphs'], @ui.graph_editable)

      if @ui.dataMenu
        #Container for list of datasets
        @dataCollectionView = new SeeIt.DataCollectionView(
          @,
          @layoutContainers['Data'],
          @model
        )
      else
        @layoutContainers['Data'].remove()

      #Create CSV manager
      @csvManager = new SeeIt.CSVManager()

      #Create JSON manager
      @jsonManager = new SeeIt.JsonManager()

      #Container for spreadsheet
      @spreadsheetView = new SeeIt.SpreadsheetView(@, @layoutContainers['Spreadsheet'])

      if @ui.toolbar

        toolbar_params = [
          {class: "addGraph", title: "Add graph", handler: @handlers.addGraph, icon: "<span class='glyphicon glyphicon-plus'></span>", type: "dropdown", options: @graphTypes},
          {class: "downloadJSON", title: "Download JSON", handler: @handlers.downloadJson, type: "button"},
          {class: "downloadInitOptions", title: "Save SeeIt", handler: @handlers.saveInitJson, type: "button"},
          {class: "changePalette", title: "Color Palette", handler: @handlers.changePalette, icon: "<span class='glyphicon glyphicon-flag'></span>", type: "dropdown", options: @paletteTypes}
        ]

        if @ui.dataMenu then toolbar_params.unshift {class: "toggleData", title: "Show/Hide Data", handler: @handlers.toggleDataVisible, type: "button"}

        if @ui.spreadsheet then toolbar_params.splice(1,0,{class: "toggleSpreadsheet", title: "Show/Hide Spreadsheet", handler: @handlers.toggleSpreadsheetVisible, type: "button"})

        #Container for toolbar
        @toolbarView = new SeeIt.ToolbarView(@, @layoutContainers['Globals'], toolbar_params)


      if !@ui.dataMenu
        if @ui.spreadsheet then @spreadsheetView.toggleFullscreen()
        @graphCollectionView.toggleFullscreen()  

      @lastGraphId = null

      @registerListeners()
      @trigger('ready')

      self = @
      graph_init_data.forEach (d) ->
        graph_types = self.graphTypes.filter((g) -> g.name == d.type)
        graph_type = if graph_types.length then graph_types[0] else null

        if graph_type then self.trigger('graph:create', graph_type)

        if d.data && d.data.length
          new_data = []
          d.data.forEach (data) ->
            dataset = self.model.getByTitle.call(self.model, data.dataset_title)

            if dataset
              column = dataset.getByHeader.call(dataset, data.column_header)

              if column && data.role_in_graph
                new_data.push {name: data.role_in_graph, data: column}

          obj = {graph: self.lastGraphId, data: new_data}
          self.trigger('graph:addData', obj)
          if d.filters && d.filters.length
            ((lastGraphId) ->
              setTimeout(->
                self.trigger('graph:filter', {graph: lastGraphId, filters: d.filters})
              50)
            )(self.lastGraphId)


    loadGraphs: ->
      @graphTypes = []
      for name, graph of SeeIt.Graphs
        @graphTypes.push({name: SeeIt.GraphNames[name], class: graph})
    
    
    ###*
      # Sets active dataset in spreadsheet to the given dataset
      # @param {Object} dataset - DatasetModel instance
    ###
    showDatasetInSpreadsheet: (dataset) ->
      if @ui.spreadsheet then @spreadsheetView.updateDataset(dataset)

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
          graphType = app.graphTypes.filter((g) -> g.name == graphName)[0]

          app.trigger('graph:create', graphType)
          # app.graphCollectionView.addGraph()
          # #DEMO PATCH
          # app.dataCollectionView.datasetViewCollection.forEach (datasetView) ->
          #   datasetView.dataColumnViews.forEach (dataView) ->
          #     dataView.init.call(dataView)
        changePalette: ->
          paletteName = $(@).attr('data-id')
          paletteType = app.paletteTypes.filter((g) -> g.name == paletteName ) [0]
          app.trigger('palette:change', paletteType)
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

        saveInitJson: (event) ->
          app.saveInitOptions.call(app)

        downloadJson: (event) ->
          app.jsonManager.handleDownload(app.model)
      }

    addDataset: (dataset) ->
      app = @
      data = @model.addDataset(dataset)

      # @listenTo(app.dataCollectionView, 'graphs:requestIDs', (cb) ->
      #   app.trigger('graphs:requestIDs', cb)
      # )
      # @dataCollectionView.addDatasetView(data)

    ###*
      # Initialize Backbone event listeners in which controller listens to members
    ###
    registerListeners: ->
      app = @

      @listenTo(app.graphCollectionView, 'graphSettings:get', (graphName, cb) ->
        if (idx = app.graph_settings.map((s) -> s.type).indexOf(graphName)) >= 0
          cb(app.graph_settings[idx])
        else
          cb()
      )

      @listenTo(app.dataCollectionView, 'spreadsheet:load', (dataset) ->
        if !app.spreadsheetVisible then app.toggleSpreadsheetVisible.call(app)

        app.trigger('spreadsheet:load', dataset)
      )

      @listenTo(app.dataCollectionView, 'spreadsheet:unload', ->
        app.trigger('spreadsheet:unload')

        if app.spreadsheetVisible then app.toggleSpreadsheetVisible.call(app)
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

      @listenTo(app.dataCollectionView, 'datasets:create', (collection) ->
        collection.forEach (dataset) ->
          app.addDataset.call(app, dataset)
      )

      @listenTo(app.model, 'dataset:created', (dataset) ->
        app.trigger('dataset:created', dataset)

        # if !app.spreadsheetVisible then app.toggleSpreadsheetVisible.call(app)

        # app.trigger('spreadsheet:load', dataset)
      )

      @listenTo(app.graphCollectionView, 'graph:created', (graphId, dataRoles) ->
        app.lastGraphId = graphId
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

      @listenTo app.graphCollectionView, 'request:dataset_names', (cb) ->
        app.trigger 'request:dataset_names', cb

      @listenTo app.graphCollectionView, 'request:columns', (dataset, cb) ->
        app.trigger 'request:columns', dataset, cb

      @listenTo app.graphCollectionView, 'request:values:unique', (dataset, colIdx, cb) ->
        app.trigger 'request:values:unique', dataset, colIdx, cb

      @listenTo app.graphCollectionView, 'request:dataset', (name, callback) ->
        app.trigger 'request:dataset', name, callback

    ###*
      # Toggles visibility of SpreadsheetView
    ###
    toggleSpreadsheetVisible: ->
      if @ui.spreadsheet
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

      if @ui.spreadsheet then @spreadsheetView.toggleFullscreen()

      @dataVisible = !@dataVisible
      @trigger('width:toggle')


    saveInitOptions: ->
      @params.container = @container.selector
      @params.data = @model.toJson()
      @params.graphs = @graphCollectionView.getGraphSettings()
      
      blob = new Blob([JSON.stringify(@params)]);
      filename = prompt("Please enter the name of the file you want to save to (will save with .json extension)");

      if filename == "" || (filename != null && filename.trim() == "")
        alert('Filename cannot be blank');
      else if filename && filename != "null" 
        saveAs(blob, filename+".json");      

  ApplicationController
).call(@)