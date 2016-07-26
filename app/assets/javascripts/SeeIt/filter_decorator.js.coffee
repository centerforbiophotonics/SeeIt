SeeIt.FilteredColumn = ( ->
  class FilteredColumn
    _.extend(@prototype, Backbone.Events)

    constructor: (@column, @requirements, @operator = "AND") ->


    data: ->
      self = @

      filteredData = [0...self.column.data().length]

      if self.requirements.length > 0 && self.operator == "OR" then filteredData = []

      self.requirements.forEach (requirement) ->
        if self.operator == "AND"
          filteredData = _.intersection(filteredData, requirement(self.column))
        else
          filteredData = _.union(filteredData, requirement(self.column))

      data = @column.data().map((d) ->
        {
          label: d.label()
          value: d.value()
        }
      ).filter((d, i) ->
        return filteredData.indexOf(i) > -1
      )

      return data

    getOriginal: ->
      return @column

    setRequirements: (newRequirements) ->
      @requirements = newRequirements

    addRequirement: (requirement) ->
      @requirements.push(requirement)



  FilteredColumn
).call(@)