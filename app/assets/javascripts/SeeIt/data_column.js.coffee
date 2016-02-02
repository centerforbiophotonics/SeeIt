@SeeIt.DataColumn = (->
  class DataColumn
    _.extend(@prototype, Backbone.Events)
    constructor: (@app, @header, @data) ->

    changeData: (idx, value) ->
      @data[idx] = value

    @new: (app, dataset, column) ->
      header = dataset[0][column]
      data = []

      for i in [1...dataset.length]
        data.push({label: dataset[i][0], value: dataset[i][column]})

      return new DataColumn(app, header, data)

  DataColumn
).call(@)