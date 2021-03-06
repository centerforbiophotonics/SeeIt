@SeeIt.FilterGroup = (->
  class FilterGroup
    _.extend(@prototype, Backbone.Events)

    constructor: (@container) ->
      @filters = []

      @filterOperator = null
      @filterData = ["AND"]

      @container.html("""
        <div class='SeeIt filter-group-tools'>
          <div class='SeeIt form-group'>
            <label for='filter-group-type' class='SeeIt filter-group-type'>Filter requirements:</label>
            <select name='filter-group-type' class='form-control SeeIt filter-group-type filter-group-type-select'>
              <option value='AND'>All filters must be fulfilled</option>
              <option value='OR'>At least one filter must be fulfilled</option>
            </select>
          </div>
          <button class="SeeIt add-filter btn btn-primary text-center">
            <div class='SeeIt icon-container'>
              <span class='glyphicon glyphicon-plus'></span>
            </div>
            Add filter
          </button>
          <button class="SeeIt remove-filter-group btn btn-primary text-center">
            <div class='SeeIt icon-container'>
              <span class='glyphicon glyphicon-minus'></span>
            </div>
            Remove filter group
          </button>
        </div>
      """)

    init: ->
      self = @

      @trigger 'request:dataset_names', (datasets) ->
        self.container.find(".add-filter").on 'click', (event) ->
          self.addFilter.call(self, datasets)

        self.addFilter(datasets)

        self.container.find('.remove-filter-group').on 'click', (event) ->
          self.removeFilterGroup.call(self)


    updateFilters: (filter_data) ->
      self = @

      if filter_data.length > 1
        self.container.find(".filter-group-type-select").val(filter_data[0])

        @trigger 'request:dataset_names', (datasets) ->
          filter_data.forEach (data, i) ->
            if i == 0 then return

            if i > 1
              filter = self.addFilter.call(self, datasets)
            else
              filter = self.filters[0]
              
            filter.update(data)



    saveFilters: ->
      self = @
      @filterOperator = @container.find(".filter-group-type-select").val()

      @filterData = [@filterOperator]

      @filters.forEach (filter) ->
        filter.save()
        self.filterData.push filter.getFilterData()

      @filterData

    getFilters: ->
      return @filterData

    getFilter: ->
      self = @

      if @filterOperator == "AND"
        return (dataColumn) ->
          filteredData = [0...dataColumn.data().length]

          self.filters.forEach (filter) ->
            filteredData = _.intersection(filteredData, filter.filter(dataColumn))

          return filteredData
      else
        return (dataColumn) ->
          filteredData = []

          self.filters.forEach (filter) ->
            filteredData = _.union(filteredData, filter.filter(dataColumn))

          return filteredData

    validate: ->
      valid = true

      @filters.forEach (filter) ->
        valid = filter.validate() && valid

      return valid

    addFilter: (datasets) ->
      self = @

      @container.find('.filter-group-tools').before("""
        <div class='filter panel panel-default SeeIt'>
        </div>   
      """)

      filter_container = @container.find('.filter:last')

      filter = new SeeIt.Filter(filter_container, datasets)

      @listenTo filter, 'request:columns', (dataset, callback) ->
        self.trigger 'request:columns', dataset, callback

      @listenTo filter, 'filter:destroyed', ->
        self.removeFilter.call(self, filter)

      @listenTo filter, 'request:values:unique', (dataset, idx, callback) ->
        self.trigger 'request:values:unique', dataset, idx, callback

      @listenTo filter, 'request:dataset', (name, callback) ->
        self.trigger 'request:dataset', name, callback

      filter.init()

      @filters.push filter

      return filter

    removeFilterGroup: ->
      @container.remove()

      @trigger 'filter_group:destroyed'

    removeFilter: (filter) ->
      idx = @filters.indexOf(filter)
      @filters.splice(idx, 1)

      if !@filters.length then @removeFilterGroup()

    clone: (givenFilterGroup) ->   #To be used by a newly instantiated filterGroup and make itself a clone of the given filterGroup
      self = @

      for filter, i in givenFilterGroup.filters
        self.filters[i].clone(filter)
      @filterData = givenFilterGroup.getFilters()    
      @container.find(".filter-group-type").val(givenFilterGroup.filterData[0])


  FilterGroup
).call(@)