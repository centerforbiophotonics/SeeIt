@SeeIt.FilterGroup = (->
  class FilterGroup
    _.extend(@prototype, Backbone.Events)

    constructor: (@container, @role) ->
      @filters = []

      @container.html("""
        <div class='SeeIt filter-group-tools'>
          <div class='SeeIt form-group'>
            <label for='filter-group-type' class='filter-group-type'>Filter group type:</label>
            <select name='filter-group-type' class='form-control SeeIt filter-group-type'>
              <option val='AND'>All filters must be met</option>
              <option val='OR'>At least one filter must be met</option>
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

      @filters.push filter

    removeFilterGroup: ->
      @container.remove()

      @trigger 'filter_group:destroyed'

    removeFilter: (filter) ->
      idx = @filters.indexOf(filter)
      @filters.splice(idx, 1)

      if !@filters.length then @removeFilterGroup()

  FilterGroup
).call(@)