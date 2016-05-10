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