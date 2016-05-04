@SeeIt.DataColumn = (->
  class DataColumn
    _.extend(@prototype, Backbone.Events)
    
    constructor: (@app, @header, data, @datasetTitle, @color, editable = true) ->
      if !@color then @color = SeeIt.Utils.getRandomColor()

      dataArray = []

      setDataArray = ->
        dataArray = []
        data.forEach (d) ->
          dataArray.push({
            label: ->
              d.label
            value: ->
              d.value
          })

      setDataArray()

      @staleData = false

      @setValue = (idx, value) ->
        if editable
          data[idx].value = value
          @trigger('data:changed',@)
          @staleData = true
          return true

        return false

      @data = ->
        if @staleData then setDataArray()

        return dataArray

      @getValue = (idx) ->
        return data[idx].value

      @compact = ->
        if @staleData then setDataArray()

        dataArray.filter((d) -> d.value() != null && d.value() != undefined && !isNaN(d.value()))

      @setLabel = (idx, value) ->
        data[idx].label = value
        @staleData = true
        @trigger('label:changed', idx)

      @removeElement = (idx) ->
        @staleData = true
        data.splice(idx, 1)
        @trigger('data:destroyed', idx)

      @insertElement = (idx, label, value) ->
        @staleData = true
        data.splice(idx, 0, {
          label: label,
          value: value
        })

        @trigger('data:created', idx)

      @toJson = ->
        {
          header: @header,
          type: "numeric",
          data: @data.map (d) ->
            d.value
        }

    setDatasetTitle: (title) ->
      @datasetTitle = title

    getColor: -> 
      @color

    setColor: (color) ->
      @color = color
      @trigger('color:changed')

    setHeader: (header) ->
      @header = header
      @trigger('header:changed')

    @new: ->
      # Being created from array of arrays
      if $.isArray(arguments[1])
        return ((app, dataset, column, title, color, editable) ->
          header = dataset[0][column]
          data = []

          for i in [1...dataset.length]
            data.push({label: dataset[i][0], value: dataset[i][column]})

          return new DataColumn(app, header, data, title, color, editable)
        ).apply(@, arguments)
      else
        return ((app, data, column, title, color, editable) ->
          dataColumn = []

          for i in [0...data.columns[column].data.length]
            dataColumn.push({label: data.labels[i], value: data.columns[column].data[i]})

          return new DataColumn(app, data.columns[column].header, dataColumn, title, color, editable)
        ).apply(@,arguments)


  DataColumn
).call(@)