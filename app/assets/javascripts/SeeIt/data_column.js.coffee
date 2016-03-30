@SeeIt.DataColumn = (->
  class DataColumn
    _.extend(@prototype, Backbone.Events)
    constructor: (@app, @header, @data, @datasetTitle) ->

    setValue: (idx, value) ->
      @data[idx].value = value
      @trigger('data:changed',@)

    getValue: (idx) ->
      return @data[idx].value

    toJson: ->
      {
        header: @header,
        type: "numeric",
        data: @data.map (d) ->
          d.value
      }

    @new: ->
      # Being created from array of arrays
      if $.isArray(arguments[1])
        return ((app, dataset, column, title) ->
          header = dataset[0][column]
          data = []

          for i in [1...dataset.length]
            data.push({label: dataset[i][0], value: dataset[i][column]})

          return new DataColumn(app, header, data, title)
        ).apply(@, arguments)
      else
        return ((app, data, column, title) ->
          dataColumn = []

          for i in [0...data.columns[column].data.length]
            dataColumn.push({label: data.labels[i], value: data.columns[column].data[i]})

          return new DataColumn(app, data.columns[column].header, dataColumn, title)
        ).apply(@,arguments)


  DataColumn
).call(@)