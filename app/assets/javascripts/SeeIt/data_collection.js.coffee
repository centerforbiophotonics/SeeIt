@SeeIt.DataCollection = (->
  class DataCollection
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, data, @editable) ->
      @nextDatasetID = 1
      @datasets = []
      @pendingDatasets = []               #Keeps track of all datasets in the initialization data that need to be loaded from a remote source
      @loadingMessage = new Opentip(
        $(".container-fluid"), "", "Loading Datasets",
        {
          showOn: null,
          style:"glass",
          stem: false,
          target: $(".container-fluid"),
          tipJoint: "center",
          targetJoint: "center",
          showEffectDuration: 0,
          showEffect: "none"
        }
      )
      @initialized = false
      @initDatasets(data)
      @initListeners()


    initListeners: ->
      self = @

      @listenTo(@app, 'dataset:create', (title) ->
        data = {
          dataset: {
            labels: ['1', '2', '3', '4', '5'],
            columns: []
          },
          title: title,
          isLabeled: true
        }

        for c in ['A', 'B', 'C', 'D', 'E']
          data.dataset.columns.push {header: c, type: 'numeric', data: [null,null,null,null,null]}

        self.addDataset.call(self, data)
      )

      @listenTo @app, 'request:dataset_names', (callback) ->
        datasets = self.datasets.map((d) -> d.title)
        callback(datasets)

      @listenTo @app, 'request:columns', (dataset, callback) ->
        found_dataset = self.datasets.filter((d) -> d.title == dataset)

        if found_dataset.length
          found_dataset = found_dataset[0]
          found_dataset.trigger 'request:columns', callback

      @listenTo @app, 'request:values:unique', (dataset, colIdx, callback) ->
        found_dataset = self.datasets.filter((d) -> d.title == dataset)

        if found_dataset.length
          found_dataset = found_dataset[0]
          found_dataset.trigger 'request:values:unique', colIdx, callback  

      @listenTo @app, 'request:dataset', (name, callback) ->
        found_dataset = self.datasets.filter((d) -> d.title == name)

        if found_dataset.length
          found_dataset = found_dataset[0]
          callback found_dataset

    getByTitle: (dataset_title) ->
      for i in [0...@datasets.length]
        if dataset_title == @datasets[i].title
          return @datasets[i]

      return null


    initDatasets: (data) ->
      self = @
      for i in [0...data.length]                                    
        if data[i].url then self.pendingDatasets.push(data[i].url)      #populates pendingDatasets with the urls of any data objects that have them
      
      if self.pendingDatasets.length == 0                    #If no datasets need to be downloaded, the app can goAhead with the graph initialization as it used to
        self.app.graphGoAhead = true
      else
        self.loadingMessage.show()
      #console.log "the urls of all datasets pending load are", @pendingDatasets

      for i in [0...data.length]
        url = ""
        if data[i].url then url = data[i].url
        
        DataCollection.coerceDataset(data[i], (dataset, cbUrl) ->   #cbUrl will only be passed to this function if all data from that url has been downloaded through the managers
          if dataset.jsonString
            dataset = JSON.parse(dataset.jsonString)
          if dataset then self.addDataset.call(self, dataset)
          if cbUrl                                                                #If a cbUrl is passed to the callback
            self.pendingDatasets.splice(self.pendingDatasets.indexOf(cbUrl), 1)   #it is removed from pendingDatasets
            if self.pendingDatasets.length == 0                   #If pendingDatasets is empty
              console.log "pendingDatasets IS EMPTY"
              self.loadingMessage.hide()
              self.initialized = true                             #The DataCollection is fully initialized
              self.trigger 'datasets:loaded'                      #And the AppController can continue on to initialize the graphs.
        , url)                                #This is the url of the data object being coerced, it is passed to coerceDataset so that it can be kept track of and returned in the callbacks within that function

      if self.app.graphGoAhead then @initialized = true       #If pendingDatasets was empty, graphGoAhead is true and this DataCollection is fully initialized

    addDataset: (data) ->
      dataset = new SeeIt.Dataset(@app, data.dataset, data.title, data.isLabeled, @editable, @nextDatasetID)
      @nextDatasetID++
     	@datasets.push(dataset)

      if @initialized then @trigger('dataset:created', dataset)

      return dataset

    toJson: ->
      obj = []

      @datasets.forEach (d) ->
        obj.push d.toJson()

      return obj

    @coerceDataset = (dataset, callback, url) ->
      if !dataset.url then callback dataset, null

      error_cb = ->
        callback null

      switch dataset.type
        when "json"
          json_manager = new SeeIt.JsonManager()

          error_cb = -> 
            callback null
          
          success_cb = (dataset) ->   #A wrapper callback for the success of json downloads, since the json manager calls its callbacks from within on return from download
            callback dataset, url     #This allows us to pass the url properly to the callback defined in initDatasets
          try
            json_manager.downloadFromServer(dataset.url, 
              success_cb,
              error_cb
            )
          catch error
            error_cb()

        when "csv"
          csv_manager = new SeeIt.CSVManager()

          try
            csv_manager.downloadFromServer(dataset.url, 
              ((data) ->

                csvData = SeeIt.CSVManager.parseCSV(data.data)

                new_dataset = {
                  isLabeled: true,
                  title: data.name,
                  dataset: csvData
                }

                callback new_dataset, url
              ),
              error_cb
            )
          catch error
            error_cb()
        when "google spreadsheet"
            googleSpreadsheet = new SeeIt.GoogleSpreadsheetManager(dataset.url, (success, collection) ->
              if success
                collection.forEach (dataset, index) ->
                  if index == collection.length-1         #Since the google spreadsheet can have a collection of datasets within one link
                    callback dataset, url                 #It only hands the url to the callback if it is the last dataset in the collection
                  else
                    callback dataset, null                #Else the callback has no url and will not remove the google spreadsheet url from pendingDatasets
              else
                callback null 
            )
            googleSpreadsheet.getData()

  DataCollection  
).call(@)