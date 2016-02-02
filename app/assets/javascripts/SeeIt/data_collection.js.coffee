@SeeIt.DataCollection = (->
  class DataCollection
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, data) ->
      @datasets = []
      @initDatasets(data)

    initDatasets: (data) ->
      for i in [0...data.length]
        @datasets.push(new SeeIt.Dataset(@app, data[i].dataset, data[i].title, data[i].isLabeled))

  DataCollection
).call(@)