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
      for i in [0...data.length]
        @datasets.push(new SeeIt.Dataset(@app, data[i].dataset, data[i].title, data[i].isLabeled, @editable))

      @initialized = true

    addDataset: (data) ->
      dataset = new SeeIt.Dataset(@app, data.dataset, data.title, data.isLabeled, @editable)
     	@datasets.push(dataset)

      if @initialized then @trigger('dataset:created', dataset)

      return dataset

    toJsonString: ->
      obj = []

      @datasets.forEach (d) ->
        obj.push d.toJson()

      return JSON.stringify obj

  DataCollection
).call(@)