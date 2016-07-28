SeeIt.FilteredColumn = ( ->
  class FilteredColumn
    _.extend(@prototype, Backbone.Events)

    constructor: (@column, @requirements, @operator = "AND") ->
      @initListeners()
      @header = @column.getHeader()
      @datasetTitle = @column.datasetTitle
      @type = @column.type

    data: ->
      self = @

      filteredData = [0...self.column.data().length]

      if self.requirements.length > 0 && self.operator == "OR" then filteredData = []

      self.requirements.forEach (requirement) ->
        if self.operator == "AND"
          filteredData = _.intersection(filteredData, requirement(self.column))
        else
          filteredData = _.union(filteredData, requirement(self.column))

      data = @column.data().filter((d, i) ->
        return filteredData.indexOf(i) > -1
      )

      return data

    changeData: (_data) ->
      @column.changeData(_data)

    setValue: (idx, value, context) ->        #IDX IS WITH RESPECT TO THE DATACOLUMN BENEATH
      @column.setValue(idx, value, context)   #NOT THE INDEX THAT WITH RESPECT TO THE FILTERED DATA ARRAY RETURNED BY THIS CLASS

    setLabel: (idx, value) ->
      @column.setLabel(idx, value)

    getLabel: (idx) ->
      @column.getLabel(idx)

    removeElement: (idx) ->
      @column.removeElement(idx)

    insertElement: (idx, label, value) ->
      @column.insertElement(idx, label, value)

    toJson: ->                            #FOR THIS FUNCTION AND UNIQUEDATA,
      {                                   #THE 'ORIGINAL' FUNCTION WILL RETURN BASED ON THE FULL DATA IN THE COLUMN
        header: @header                   #THE OTHER ONES WILL RETURN BASED ON THE FILTERED DATA RETURNED BY THIS CLASS' DATA()
        type: @type
        data: @data().map (d) ->
          d.value()
      }

    originalToJson: ->
      @column.toJson()

    uniqueData: ->
      unique_data = []
      data = @data()

      for i in [0...data.length]
        if unique_data.indexOf(data[i].value()) == -1
          unique_data.push(data[i].value())

      return unique_data

    originalUniqueData: ->
      @column.uniqueData()

    typeIsCorrect: (value) ->
      @column.typeIsCorrect(value)

    length: ->
      data = @data()
      return data.length

    originalLength: ->
      @column.length()

    compact: ->
      self = @

      someData = [0...@column.data().length]

      if self.requirements.length > 0 && self.operator == "OR" then someData = []

      self.requirements.forEach (requirement) ->
        if self.operator == "AND"
          someData = _.intersection(someData, requirement(self.column))
        else                                                            
          someData = _.union(someData, requirement(self.column))

      data = @column.data().filter((d, i) ->
        return someData.indexOf(i) > -1
      )

      data = data.filter((d) -> d.value() != null && d.value() != undefined && !isNaN(d.value()))

      return data

    getColor: ->
      @column.getColor()

    setColor: (color) ->
      @column.setColor(color)

    getOriginalColumn: ->
      return @column

    getHeader: ->
      @column.getHeader()

    setHeader: (header) ->
      @header = header
      @column.setHeader(header)

    setRequirements: (newRequirements) ->
      @requirements = newRequirements
      @trigger 'filter:changed'

    addRequirement: (requirement) ->
      @requirements.push(requirement)
      @trigger 'filter:changed'



    initListeners: ->
      self = @
      @listenTo(self.column, 'label:changed', (idx) ->
        self.trigger('label:changed', idx)
      )

      @listenTo(self.column, 'color:changed', ->
        self.trigger('color:changed')
      )

      @listenTo(self.column, 'header:changed', ->
        @header = @column.header
        self.trigger('header:changed')
      )

      @listenTo(self.column, 'data:destroyed', ->
        self.trigger('data:destroyed')
      )

      @listenTo(self.column, 'data:created', ->
        self.trigger('data:created')
      )

      @listenTo(self.column, 'data:changed', ->
        self.trigger('data:changed')
      )

      @listenTo(self.column, 'type:changed', -> 
        @type = @column.type
        self.trigger('type:changed')
      )     

      @listenTo(self.column, 'destroy', ->
        self.trigger('destroy')
      )



  FilteredColumn
).call(@)