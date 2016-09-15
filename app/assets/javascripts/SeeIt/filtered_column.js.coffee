SeeIt.FilteredColumn = ( ->
  class FilteredColumn
    _.extend(@prototype, Backbone.Events)

    constructor: (@column, @requirements, @operator = "AND") ->
      @initListeners()
      @header = @column.getHeader()
      @datasetTitle = @column.datasetTitle
      @type = @column.type

    data: ->                            #APPLIES THE FILTERS IN @REQUIREMENTS TO THE DATA ARRAY OF @COLUMN AND RETURNS THE RESULTING ARRAY
      self = @                          #EACH ENTRY IN THE ARRAY IS OF THE FORM {label: label(), value: value()} WHERE THE FUNCTIONS WILL RETURN THE STORED VALUES OF EACH PROPERTY

      filteredData = [0...self.column.data().length]   #filteredData is actually an array just of indexes, it does not hold the real data at all

      if self.requirements.length > 0 && self.operator == "OR" then filteredData = []

      self.requirements.forEach (requirement) ->      #This loop will go through filteredData and remove any indexes of data in the column that do not meet requirements
        if self.operator == "AND"
          filteredData = _.intersection(filteredData, requirement(self.column))
        else
          filteredData = _.union(filteredData, requirement(self.column))

      filteredDataArray = @column.data().filter((d, i) ->  #Here, the Javascript built-in filter function filters the data from the column
        return filteredData.indexOf(i) > -1   #If the index of the column's data still exists in filteredData, then it is added to the filtered data array 
      )

      return filteredDataArray

    changeData: (_data) ->        #calls the columns change data function which overwrites the data of the column with the passed in _data argument
      @column.changeData(_data)

    setValue: (idx, value, context) ->        #IDX IS WITH RESPECT TO THE DATACOLUMN BENEATH
      @column.setValue(idx, value, context)   #NOT THE INDEX THAT WITH RESPECT TO THE FILTERED DATA ARRAY RETURNED BY THIS CLASS

    setLabel: (idx, value) ->           #setValue and setLabel set their respective properties of the data entry of the specified index in the @column dataArray
      @column.setLabel(idx, value)

    getLabel: (idx) ->                  #get's the label from the specified index in @column's dataArray
      @column.getLabel(idx)

    removeElement: (idx) ->             #removes the entry specified by the index idx in @column's dataArray
      @column.removeElement(idx)

    insertElement: (idx, label, value) ->         #inserts an element into @column's dataArray at the specified idx with the label and value that is passed in
      @column.insertElement(idx, label, value)

    newElement: (idx, label, value) ->
      @column.newElement(idx, label, value)     #like insertElement but results in some manipulation on the datasets, this call is coming from the column to the set instead of the other way around

    filteredToJson: ->                            #FOR THIS FUNCTION AND UNIQUEDATA,
      {                                   #THE FILTERED VERSION ONLY RETURNS WITH DATA THAT EXISTS IN THE COLUMN AFTER FILTERS ARE APPLIED
        header: @header                   #THE NORMAL CALL WILL RETURN USING ALL DATA THAT EXISTS IN THE DATACOLUMN
        type: @type                       #THIS NAMING CONVENTION IS MEANT TO NOT MAINTAIN CONSISTENCY WITH OTHER PARTS OF THE CODE WHERE toJson OR uniqueData ARE CALLED
        data: @data().map (d) ->          #ON REGULAR DATACOLUMNS, SO THE SAME BEHAVIOR SHOULD BE EXPECTED WHEN THOSE CALLS ARE MADE USING A FILTEREDCOLUMN
          d.value()                       
      }                                   #the toJson functions will return a json object detailing the header, type, and data values of the column
                                          #toJson does it based off filtered data and the originalToJson is based off the full unfilitered data, though both objects should have the same header and type
    toJson: ->
      @column.toJson()

    filteredUniqueData: ->                #uniqueData will return an array of each unique data value in the dataArray
      unique_data = []                    #again, filteredUniqueData will only include filtered data and uniqueData includes all unfilitered data in the column.
      data = @data()

      for i in [0...data.length]
        if unique_data.indexOf(data[i].value()) == -1
          unique_data.push(data[i].value())

      return unique_data

    uniqueData: ->
      @column.uniqueData()

    typeIsCorrect: (value) ->           #checks if the given value is of the same type as the Column
      @column.typeIsCorrect(value)

    filteredLength: ->                          #returns the number of data entries in the filtered data
      data = @data()
      return data.length

    length: ->                  #returns the number of data entries in the full unfiltered column
      @column.length()

    compact: ->                         #returns the same thing as data(), but removes all values that are null, undefined, or NaN
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

    getColor: ->            #gets the color of the column
      @column.getColor()

    setColor: (color) ->        #sets the color of the column
      @column.setColor(color)

    getOriginalColumn: ->       #returns the underlying DataColumn
      return @column

    getHeader: ->             #returns the header of the column
      @column.getHeader()

    setHeader: (header) ->    #sets the header of the column
      @header = header
      @column.setHeader(header)

    setRequirements: (newRequirements) ->     #overwrites the filter requirements of the filteredColumn
      @requirements = newRequirements
      @trigger 'filter:changed'

    addRequirement: (requirement) ->        #adds a single requirement to the requirements of the filteredColumn
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