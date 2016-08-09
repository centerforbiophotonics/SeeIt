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

      #Initialize UI options
      @ui = {
        editable:           if ui.editable != undefined then ui.editable else true,
        spreadsheet:        if ui.spreadsheet != undefined then ui.spreadsheet else true,
        dataMenu:           if ui.dataMenu != undefined then ui.dataMenu else true,
        toolbar:            if ui.toolbar != undefined then ui.toolbar else true,
        graph_editable:     if ui.graph_editable != undefined then ui.graph_editable else true,
        dataset_add_remove: if ui.dataset_add_remove != undefined then ui.dataset_add_remove else true
      }
      
      graph_init_data = if params.graphs then params.graphs else []

      @graph_settings = if params.graph_settings then params.graph_settings else []

      #Data model
      @model = new SeeIt.DataCollection(@, data, @ui.editable)

      @dataVisible = true
      @spreadsheetVisible = false

      # Container for graphs
      @graphCollectionView = new SeeIt.GraphCollectionView(@, @layoutContainers['Graphs'], @ui.graph_editable, @model)

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
          {class: "downloadInitOptions", title: "Save SeeIt", handler: @handlers.saveInitJson, type: "button"}
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
      self = @

      self.handlers = {
        toggleDataVisible: ->
          self.toggleDataVisible.call(self)
        toggleSpreadsheetVisible: ->
          self.toggleSpreadsheetVisible.call(self)
        addGraph: ->
          graphName = $(@).attr('data-id')
          graphType = self.graphTypes.filter((g) -> g.name == graphName)[0]


          self.trigger('graph:create', graphType)
          # app.graphCollectionView.addGraph()
          # #DEMO PATCH
          # app.dataCollectionView.datasetViewCollection.forEach (datasetView) ->
          #   datasetView.dataColumnViews.forEach (dataView) ->
          #     dataView.init.call(dataView)

        saveCSVData: (event) ->
          event.stopPropagation()

          self.csvManager.handleUpload(@files[0], (data) ->
            dataset = {
              isLabeled: true,
              dataset: data
            }

            self.addDataset.call(self, dataset)
          )

          return false

        uploadCSV: ->
          if !$("#hidden-csv-upload").length
            self.container.append "<input id='hidden-csv-upload' type='file' style='display: none'>"

          $("#hidden-csv-upload").off('change', self.handlers.saveCSVData).on('change', self.handlers.saveCSVData)
          $("#hidden-csv-upload").click()
    
        uploadJson: ->
          if !$("#hidden-json-upload").length
            self.container.append "<input id='hidden-json-upload' type='file' style='display: none'>"

          $("#hidden-json-upload").off('change', self.handlers.saveJsonData).on('change', self.handlers.saveJsonData)
          $("#hidden-json-upload").click()

        saveJsonData: (event) ->
          event.stopPropagation()

          self.jsonManager.handleUpload(@files[0], (data) ->
            data.forEach (d) ->
              self.addDataset.call(self, d)
          )

          return false

        saveInitJson: (event) ->
          self.saveInitOptions.call(self)

        downloadJson: (event) ->
          self.jsonManager.handleDownload(self.model)
      }

    addDataset: (dataset) ->
      self = @
      data = @model.addDataset(dataset)

    ###*
      # Initialize Backbone event listeners in which controller listens to members
    ###
    registerListeners: ->
      self = @

      @listenTo(self.graphCollectionView, 'graphSettings:get', (graphName, cb) ->
        if (idx = self.graph_settings.map((s) -> s.type).indexOf(graphName)) >= 0
          cb(self.graph_settings[idx])
        else
          cb()
      )

      @listenTo(self.dataCollectionView, 'spreadsheet:load', (dataset) ->
        if !self.spreadsheetVisible then self.toggleSpreadsheetVisible.call(self)

        self.trigger('spreadsheet:load', dataset)
      )

      @listenTo(self.dataCollectionView, 'spreadsheet:unload', ->
        self.trigger('spreadsheet:unload')

        if self.spreadsheetVisible then self.toggleSpreadsheetVisible.call(self)
      )

      @listenTo(self.spreadsheetView, 'data:changed', (origin) ->
        self.trigger('data:changed', origin)
      )

      @listenTo(self.dataCollectionView, 'graph:addData', (graphData) ->
        self.trigger('graph:addData', graphData)
      )

      @listenTo(self.dataCollectionView, 'dataset:create', (title) ->
        self.trigger('dataset:create', title)
      )

      @listenTo(self.dataCollectionView, 'datasets:create', (collection) ->
        collection.forEach (dataset) ->
          self.addDataset.call(self, dataset)
      )

      @listenTo(self.model, 'dataset:created', (dataset) ->
        self.trigger('dataset:created', dataset)

        # if !app.spreadsheetVisible then app.toggleSpreadsheetVisible.call(app)

        # app.trigger('spreadsheet:load', dataset)
      )

      @listenTo(self.graphCollectionView, 'graph:created', (graphId, dataRoles) ->
        self.lastGraphId = graphId
        self.trigger('graph:created', graphId, dataRoles)
      )

      @listenTo(self.dataCollectionView, 'graphs:requestIDs', (cb) ->
        self.trigger('graphs:requestIDs', cb)
      )

      @listenTo(self.graphCollectionView, 'graph:destroyed', (graphId) ->
        self.trigger('graph:destroyed', graphId)
      )

      @listenTo(self.graphCollectionView, 'graph:id:change', (oldId, newId) ->
        self.trigger('graph:id:change', oldId, newId)
      )

      @listenTo self.graphCollectionView, 'request:dataset_names', (cb) ->
        self.trigger 'request:dataset_names', cb

      @listenTo self.graphCollectionView, 'request:columns', (dataset, cb) ->
        self.trigger 'request:columns', dataset, cb

      @listenTo self.graphCollectionView, 'request:values:unique', (dataset, colIdx, cb) ->
        self.trigger 'request:values:unique', dataset, colIdx, cb

      @listenTo self.graphCollectionView, 'request:dataset', (name, callback) ->
        self.trigger 'request:dataset', name, callback

      # listen for trigger in graphCollectionView and will trigger the actual function in graphCollectionView
      @listenTo self.graphCollectionView, 'graph:addData', (dataGraph) ->
        self.trigger 'graph:addData', dataGraph


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
      $('#fixedbutton').toggleClass('hidden')

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