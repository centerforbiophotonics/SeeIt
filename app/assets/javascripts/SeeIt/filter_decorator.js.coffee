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

    length: ->
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