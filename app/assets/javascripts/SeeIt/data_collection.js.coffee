@SeeIt.DataCollection = (->
  class DataCollection
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, data) ->
      @datasets = []
      @initDatasets(data)

    initDatasets: (data) ->
      for i in [0...data.length]
        @datasets.push(new SeeIt.Dataset(@app, data[i].dataset, data[i].title, data[i].isLabeled))

    addDataset: (data) ->
      dataset = new SeeIt.Dataset(@app, data.dataset, data.title, data.isLabeled)
     	@datasets.push(dataset)
     	@trigger('dataset:created')

      return dataset

    toJsonString: ->
      obj = []

      @datasets.forEach (d) ->
        obj.push d.toJson()

      return JSON.stringify obj

  DataCollection
).call(@)