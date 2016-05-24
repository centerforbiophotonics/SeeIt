@SeeIt.Filter = (->
  class Filter
    _.extend(@prototype, Backbone.Events)

    constructor: (@container, @datasets) ->
      @columns = []

      @selectedDataset = null
      @selectedColumn = null
      @filterType = null
      @filterData = null
      @operator = null
      @value = null

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
            <option value="lt">Less than</option>
            <option value="lte">Less than or equal to</option>
            <option value="eq">Equal to</option>
            <option value="neq">Not equal to</option>
            <option value="gte">Greater than or equal to</option>
            <option value="gt">Greater than</option>
          </select>
          <input class="SeeIt numeric-filter filter-value numeric-filter-value hidden form-control" placeholder="Specify number" name="numeric-filter-value" type="number">
          <label class='SeeIt categorical-filter hidden' for='categorical-filter-comparison'>Only include data points</label>
          <select class='SeeIt categorical-filter categorical-filter-comparison form-control hidden' name='categorical-filter-comparison'>
            <option value="eq">Equal to</option>
            <option value="neq">Not equal to</option>
          </select>
          <input type='text' class='SeeIt categorical-filter filter-value categorical-filter-value hidden form-control' name='categorical-filter-value'>  
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

      console.log @
      @datasets.forEach (dataset) ->
        options += "<option value='#{dataset}'>#{dataset}</option>"

      select.html(options)

      select.on 'change', (event) ->
        self.selectedColumn = null
        dataset = $(@).val()
        self.container.find('.categorical-filter, .numeric-filter').addClass('hidden')

        self.trigger "dataset:select:#{dataset}"

        self.trigger 'request:columns', dataset, (columns, types) ->
          self.populateColumnSelect.call(self, columns, types, dataset)

      if selected_dataset then select.val(selected_dataset)


    init: ->
      self = @

      @datasets.forEach (dataset) ->
        old_title = dataset
        this_dataset = null

        self.trigger 'request:dataset', dataset, (dataset_object) ->
          if this_dataset
            this_dataset.off 'dataset:title:changed'

          this_dataset = dataset_object

          this_dataset.on 'dataset:title:changed', ->
            select = self.container.find(".dataset-select").val() == old_title
            self.container.find(".dataset-select option[value='#{old_title}']").attr('value', this_dataset.title).html(this_dataset.title)

            if select then self.container.find(".dataset-select").val(this_dataset.title)

            old_title = this_dataset.title

            self.off "dataset:select:#{old_title}"
            self.on "dataset:select:#{this_dataset.title}", ->
              self.selectedDataset = dataset_object

          self.on "dataset:select:#{dataset}", ->
            self.selectedDataset = dataset_object


    update: (filter_data) ->
      @container.find('.dataset-select').val(filter_data.dataset_title)
      @container.find('.dataset-select').trigger('change')

      @container.find('.data-column-select').val(filter_data.column_header)
      @container.find('.data-column-select').trigger('change')

      if @filterType == "numeric"
        @container.find(".numeric-filter-comparison").val(filter_data.comparison)
        @container.find(".numeric-filter-value").val(filter_data.value)
      else
        @container.find(".categorical-filter-comparison").val(filter_data.comparison)
        @container.find(".categorical-filter-value").val(filter_data.value)

    getFilterData: ->
      {
        dataset_title: @filterData.dataset.title,
        column_header: @filterData.column.header,
        comparison: @filterData.operator,
        value: @filterData.value
      }

    save: ->
      @filterData = {
        dataset: @selectedDataset,
        column: @selectedColumn,
        operator: (@container.find(
            if @filterType == "numeric"
              ".numeric-filter-comparison" 
            else 
              ".categorical-filter-comparison"
          ).val()
        )
        value: (
          if @filterType == "numeric"
            parseFloat(@container.find(".numeric-filter-value").val())
          else
            @container.find(".categorical-filter-value").val()
        )
      }

    filter: (dataColumn) ->
      self = @

      validData = []
      columnHash = {}

      @filterData.column.data().forEach (data) ->
        columnHash[data.label()] = data.value()

      dataColumn.data().forEach (data, i) ->
        value = data.value()
        label = data.label()

        if label of columnHash && self.requirementMet(columnHash[label], self.filterData.value, self.filterData.operator)
          validData.push i

      return validData

    requirementMet: (value, threshold, operator) ->
      switch operator
        when 'eq'
          return value == threshold
        when 'neq'
          return value != threshold
        when 'lt'
          return value < threshold
        when 'lte'
          return value <= threshold
        when 'gt'
          return value > threshold
        when 'gte'
          return value >= threshold

    validate: ->
      return (
        @container.find(".dataset-select").val() &&
        @container.find(".data-column-select").val() &&
        (
          @container.find(".numeric-filter-value").val() && @container.find(".numeric-filter-value").is(':visible') ||
          @container.find(".categorical-filter-value").val() && @container.find(".categorical-filter-value").is(':visible')
        )
      )

    populateColumnSelect: (columns, types, dataset, selected, value) ->
      self = @

      @container.find(".data-column-select").html("""
        #{"<option value='' selected disabled>Please select a column</option>" + columns.map((col) -> "<option value='#{col.header}'>#{col.header}</option>" ).join("")}
      """)

      @registerDataListeners.call(self, columns, types, dataset)

      @container.find(".data-column").removeClass('hidden')

      handler = (event) ->
        self.initValueField.call(self, $(@), columns, types, dataset, value)

      @container.find(".data-column-select").off('change')
      @container.find(".data-column-select").on('change', handler)

      if selected then @container.find(".data-column-select").val(selected)


    initValueField: ($column_select, columns, types, dataset, value) ->
      self = @
      idx = columns.map((col) -> col.header).indexOf($column_select.val())
      type = types[idx]

      @selectedColumn = columns[idx]

      console.log typeof $column_select.val(),$column_select.val(), columns, idx, @selectedColumn, 'in initValueField'
      if type == "numeric" 
        @filterType = "numeric"
        @container.find(".categorical-filter").addClass("hidden")
        @container.find(".numeric-filter").removeClass("hidden")
      else if type == "categorical"
        @filterType = "categorical"
        @populateCategoricalSelect(dataset, idx, type, value)



    populateCategoricalSelect: (dataset, idx, type, value) ->
      self = @

      @container.find(".numeric-filter").addClass("hidden")
      @container.find(".categorical-filter").removeClass("hidden")  

      if value != null && value != undefined then @container.find(".filter-value").val(value) 


    registerDataListeners: (columns, types, dataset) ->
      self = @

      @columns.forEach (column, i) ->
        column.off('data:changed type:changed data:destroyed data:created header:changed')

      @columns = columns

      @columns.forEach (column, i) ->
        old_header = column.header

        column.on 'data:changed', ->
          self.handleDataChange.call(self, types, dataset, column, i)
              

        column.on 'type:changed', (type) ->
          old_type = types[i]
          types[i] = type

          if column.header == self.container.find('.data-column-select').val() && old_type != type
            self.initValueField.call(self, self.container.find('.data-column-select'), columns, types, dataset)
            self.placeOpentip.call(self, "Filter removed because column type changed", self.container.find('.filter-value:visible'))


        column.on 'data:destroyed', ->
          self.handleDataChange.call(self, types, dataset, column, i)

        column.on 'data:created', ->
          self.handleDataChange.call(self, types, dataset, column, i)

        column.on 'header:changed', ->
          select = self.container.find(".data-column-select").val() == old_header
          self.container.find(".data-column-select option[val='#{old_header}']").attr('value', column.header).html(column.header)

          if select then self.container.find(".data-column-select").val(column.header)

          old_header = column.header


    handleDataChange: (types, dataset, column, i) ->
      if column.header == @container.find('.data-column-select').val() && types[i] == "categorical"
        selected_val = @container.find('.categorical-filter-value').val()
        value = if column.data().map((d) -> d.value()).indexOf(selected_val) > -1 then selected_val else null

        @populateCategoricalSelect(dataset, i, types[i], value)

        if selected_val && selected_val.length && !value
          @placeOpentip("Filter removed because selected filter no longer exists in column", self.container.find('.filter-value:visible'))


    placeOpentip: (msg, target) ->
      tip = new Opentip(target, msg, 
        {style: "alert", target: target, showOn: "creation"}
      )

      tip.setTimeout(->
        tip.hide.call(tip)
        return
      , 5)  

    removeFilter: ->
      @container.remove()

      @trigger 'filter:destroyed'

  Filter
).call(@)