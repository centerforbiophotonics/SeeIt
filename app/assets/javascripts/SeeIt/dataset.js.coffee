@SeeIt.Dataset = (->
  class Dataset
    _.extend(@prototype, Backbone.Events)
    @Validators = {}
    _.extend(@Validators, SeeIt.Modules.Validators)

    constructor: (@app, data, @title, @isLabeled) ->
      #Data will be an array of DataColumns
      @labels = []
      @headers = []
      @rawFormat = "array"
      @data = []
      @loadData(data)

    loadData: (data) ->
      if Dataset.validateData(data)
        #Data in spreadsheet format
        @rawData = data
        @formatRawData()
        @initData()
        @trigger("data:loaded")
      else
        alert "Error: Invalid data format"

    formatRawData: ->
      #Array of arrays
      if @rawFormat == "array"
        if !@isLabeled
          privateMethods.addLabels.call(@)
        else
          privateMethods.stringifyLabels.call(@)

        maxCols = privateMethods.maxNumCols.call(@)
        privateMethods.padRows.call(@,maxCols)
        @initHeaders()
      else
        #array of json

    initData: ->
      # Assume data is already in array of arrays format and is uniformly padded with 'undefined's
      for i in [1...@rawDataCols()]
        @data.push(SeeIt.DataColumn.new(@app, @rawData, i))

    rawDataRows: ->
      @rawData.length

    rawDataCols: ->
      if @rawData.length then @rawData[0].length else 0

    updateColumn: (idx, column) ->
      for i in [1...@getNumRows()]
        @data[i][idx] = column[i - 1]

    updateRow: (idx, row) ->
      start = (if @isLabeled then 1 else 0)
      for i in [start...@getNumCols()]
        @data[idx][i] = row[i - start]

    updateLabel: (idx, label) ->

    updateHeader: (idx, header) ->

    initHeaders: ->
      for i in [1...@rawDataCols()]
        @headers.push(@rawData[0][i])

    @validateData: (data) ->
      valid = true

      for key in @Validators
        valid = valid && @Validators[key](@rawData)

      return valid

  #privateMethods: methods for Dataset class
  privateMethods = {
    toString: (val) ->
      return val + ''

    stringifyLabels: ->
      for i in [1...@rawDataRows()]
        @rawData[i][0] = privateMethods.toString.call(@,@rawData[i][0])
        @labels.push(@rawData[i][0])

      @isLabeled = true

    addLabels: ->
      @rawData[0][0].unshift('')

      for i in [1...@rawDataRows()]
        @rawData.unshift(privateMethods.toString.call(@, i + 1))
        @labels.push(@rawData[i][0])

      @isLabeled = true

    maxNumCols: ->
      maxCols = @rawData[0].length
      for i in [1...@rawDataRows()]
        if @rawData[i].length > maxCols
          maxCols = @rawData[i].length

      maxCols

    padRows: (maxCols) ->
      for i in [0...@rawDataRows()]
        if @rawData[i].length < maxCols
          @rawData[i] = privateMethods.fillWithUndefined(@rawData[i], maxCols - @rawData[i].length)

    fillWithUndefined: (arr,count) ->
      for i in [0...count]
        arr.push(undefined)

      arr

  }

  Dataset
).call(@)