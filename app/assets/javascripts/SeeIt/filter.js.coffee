@SeeIt.Filter = (->
  class Filter
    _.extend(@prototype, Backbone.Events)

    constructor: (@container, @datasets) ->
      @container.html("""
        <div class='SeeIt panel-body form-group'>
          <label for='dataset'>Filter by column from dataset:</label>
          <select class="form-control dataset-select" name='dataset' placeholder='Dataset'>
          </select>
          <label class='hidden data-column' for="dataColumn">Select a column to filter by:</label>
          <select class="data-column data-column-select form-control hidden" name="dataColumn">
          </select>
          <label class='SeeIt numeric-filter hidden' for='numeric-filter-comparison'>Only inlclude data points</label>
          <select class='SeeIt numeric-filter numeric-filter-comparison hidden form-control' name='numeric-filter-comparison'>
            <option val="lt">Less than</option>
            <option val="lte">Less than or equal to</option>
            <option val="eq">Equal to</option>
            <option val="neq">Not equal to</option>
            <option val="gte">Greater than or equal to</option>
            <option val="gt">Greater than</option>
          </select>
          <input class="SeeIt numeric-filter filter-value numeric-filter-value hidden form-control" placeholder="Specify number" name="numeric-filter-value" type="number">
          <label class='SeeIt categorical-filter hidden' for='categorical-filter-comparison'>Only include data points</label>
          <select class='SeeIt categorical-filter categorical-filter-comparison form-control hidden' name='categorical-filter-comparison'>
            <option val="eq">Equal to</option>
            <option val="neq">Not equal to</option>
          </select>
          <select class='SeeIt categorical-filter filter-value categorical-filter-value hidden form-control' name='categorical-filter-value'>
          </select>  
          <button class="SeeIt remove-filter btn btn-primary text-center">
            <div class='SeeIt icon-container'>
              <span class='glyphicon glyphicon-minus'></span>
            </div>
            Remove filter
          </button>
        </div>
      """)

      @populateDatasetSelect()

      self = @
      @container.find('.remove-filter').on 'click', (event) ->
        self.removeFilter.call(self)

    populateDatasetSelect: (selected_dataset) ->
      self = @

      select = @container.find('.dataset-select')

      options = '<option value="" selected disabled>Please select a dataset</option>'

      @datasets.forEach (d) ->
        options += "<option value='#{d}'>#{d}</option>"

      select.html(options)

      select.on 'change', (event) ->
        dataset = $(@).val()
        self.trigger 'request:columns', dataset, (columns, types) ->
          self.populateColumnSelect.call(self, columns, types)

      if selected_dataset then select.val(selected_dataset)


    populateColumnSelect: (columns, types, selected, value) ->
      self = @

      @container.find(".data-column-select").html("""
        #{"<option val='' selected disabled>Please select a column</option>" + columns.map((col) -> "<option val='#{col.header}'>#{col.header}</option>" ).join("")}
      """)

      @registerDataListeners.call(self, columns)

      @container.find(".data-column").removeClass('hidden')

      @container.find(".data-column-select").on 'change', (event) ->
        self.initValueField.call(self, $(@), columns, types, value)

      if selected then @container.find(".data-column-select").val(selected)


    initValueField: ($column_select, columns, types, value) ->
      self = @
      idx = columns.map((col) -> col.header).indexOf($column_select.val())
      type = types[idx]

      if type == "numeric" 
        @container.find(".categorical-filter").addClass("hidden")
        @container.find(".numeric-filter").removeClass("hidden")
      else if type == "categorical"
        @trigger 'request:values:unique', dataset, idx, (values) ->
          self.container.find(".numeric-filter").addClass("hidden")
          self.container.find(".categorical-filter-value").html("""
            #{"<option val='' selected disabled>Please select values to filter by</option>" + values.map((d) -> "<option value='#{d}'>#{d}</option>").join("")}
          """)
          self.container.find(".categorical-filter").removeClass("hidden")  

      if value != null && value != undefined then @container.find(".filter-value").val(value) 


    registerDataListeners: (columns) ->
      self = @

      # columns.forEach (column) ->
      #   column.on 'data:changed', ->

    removeFilter: ->
      @container.remove()

      @trigger 'filter:destroyed'

  Filter
).call(@)