@SeeIt.DataColumn = (->
  class DataColumn
    _.extend(@prototype, Backbone.Events)
    
    constructor: (@app, @header, data, @datasetTitle, @type, @color, editable = true) ->
      if !@color then @color = SeeIt.Utils.getRandomColor()

      dataArray = []

      self = @

      setDataArray = ->
        dataArray = []
        data.forEach (d, i) ->
          dataArray.push({
            label: ->
              if arguments.length
                self.setLabel.call(self, i, arguments[0])

              d.label
            value: ->
              if arguments.length
                console.log arguments
                self.setValue.call(self, i, arguments[0])

              d.value
          })

      setDataArray()

      @staleData = false

      @length = ->
        data.length

      @changeData = (_data) ->
        data = _data
        @staleData = true
        @trigger('data:changed', @)

      @setValue = (idx, value, context) ->
        if !context then context = @
        
        if editable && @typeIsCorrect(value)
          data[idx].value = value
          @trigger('data:changed',context, idx)
          @staleData = true
          return true

        return false

      @data = ->
        if @staleData then setDataArray()
        return dataArray

      @getValue = (idx) ->
        return data[idx].value

      @setType = (type, callback) ->
        if type == "numeric"
          for i in [0...data.length]
            if isNaN(Number(data[i].value))
              if callback then callback(false, "Could not change type to numeric because column has non-numeric values")
              return

        @type = type
        for i in [0...data.length]
          data[i].value = if @type == "numeric" then Number(data[i].value) else data[i].value + ''

        if callback then callback(true, "Data type changed to #{type}")

        @trigger('type:changed', type)


      @compact = ->
        if @staleData then setDataArray()

        dataArray.filter((d) -> d.value() != null && d.value() != undefined && !isNaN(d.value()))

      @setLabel = (idx, value) ->
        data[idx].label = value
        @staleData = true
        @trigger('label:changed', idx)

      @getLabel = (idx) ->
        return data[idx].label

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
          type: @type,
          data: @data().map (d) ->
            d.value()
        }

      @uniqueData = ->
        unique_data = []

        for i in [0...data.length]
          if unique_data.indexOf(data[i].value) == -1
            unique_data.push(data[i].value)

        return unique_data

      @isEditable = ->
        editable

    typeIsCorrect: (value) ->
      (
        @type == "numeric" && Number(value) ||
        @type == "categorical" && typeof value == "string"
      )

    setDatasetTitle: (title) ->
      @datasetTitle = title

    getColor: -> 
      @color

    setColor: (color) ->
      @color = color
      @trigger('color:changed')

    getHeader: ->
      return @header


    setHeader: (header) ->
      @header = header
      @trigger('header:changed')

    @new: ->
      # Being created from array of arrays
      if $.isArray(arguments[1])
        return ((app, dataset, column, title, type, color, editable) ->
          header = dataset[0][column] + ''
          data = []

          for i in [1...dataset.length]
            data.push({label: dataset[i][0], value: dataset[i][column]})

          return new DataColumn(app, header, data, title, type, color, editable)
        ).apply(@, arguments)
      else
        return ((app, data, column, title, type, color, editable) ->
          dataColumn = []

          for i in [0...data.columns[column].data.length]
            dataColumn.push({label: data.labels[i], value: data.columns[column].data[i]})

          return new DataColumn(app, data.columns[column].header, dataColumn, title, type, color, editable)
        ).apply(@,arguments)


  DataColumn
).call(@)