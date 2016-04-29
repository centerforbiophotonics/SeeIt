@SeeIt.DataColumn = (->
  class DataColumn
    _.extend(@prototype, Backbone.Events)
    
    constructor: (@app, @header, @data, @datasetTitle, @color) ->
      if !@color then @color = SeeIt.Utils.getRandomColor()

      console.log @color

    setDatasetTitle: (title) ->
      @datasetTitle = title

    setValue: (idx, value) ->
      console.log @
      @data[idx].value = value
      @trigger('data:changed',@)

    getValue: (idx) ->
      return @data[idx].value

    compact: ->
      @data.filter((d) -> d.value != null && d.value != undefined && !isNaN(d.value))

    getColor: -> 
      @color

    setColor: (color) ->
      @color = color
      @trigger('color:changed')

    setLabel: (idx, value) ->
      @data[idx].label = value
      @trigger('label:changed', idx)

    setHeader: (header) ->
      @header = header
      @trigger('header:changed')

    removeElement: (idx) ->
      @data.splice(idx, 1)
      @trigger('data:destroyed', idx)

    insertElement: (idx, label, value) ->
      @data.splice(idx, 0, {
        label: label,
        value: value
      })

      @trigger('data:created', idx)

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