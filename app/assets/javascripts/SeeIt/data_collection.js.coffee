@SeeIt.DataCollection = (->
  class DataCollection
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, data, @editable) ->
      @datasets = []
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
        console.log dataset, colIdx
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
        DataCollection.coerceDataset(data[i], (dataset) ->
          console.log dataset
          if dataset then self.addDataset.call(self, dataset)
        )

      @initialized = true

    addDataset: (data) ->
      dataset = new SeeIt.Dataset(@app, data.dataset, data.title, data.isLabeled, @editable)
     	@datasets.push(dataset)

      if @initialized then @trigger('dataset:created', dataset)

      return dataset

    toJson: ->
      obj = []

      @datasets.forEach (d) ->
        obj.push d.toJson()

      return obj

    @coerceDataset = (dataset, callback) ->
      if !dataset.url then callback dataset

      error_cb = ->
        callback null

      switch dataset.type
        when "json"
          json_manager = new SeeIt.JsonManager()

          error_cb = -> 
            callback null
            
          try
            json_manager.downloadFromServer(dataset.url, 
              callback,
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

                callback new_dataset
              ),
              error_cb
            )
          catch error
            error_cb()
        when "google spreadsheet"
            googleSpreadsheet = new SeeIt.GoogleSpreadsheetManager(dataset.url, (success, collection) ->
              if success
                collection.forEach (dataset) ->
                  callback dataset
              else
                callback null 
            )
            googleSpreadsheet.getData()

  DataCollection  
).call(@)