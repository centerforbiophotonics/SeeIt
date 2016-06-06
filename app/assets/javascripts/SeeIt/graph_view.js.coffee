@SeeIt.GraphView = (->
  class GraphView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @id, @container, @destroyCallback, @graphType, @graph_editable) ->
      self = @
      @maximized = false
      @filterGroups = []

      @filter = (dataColumn) ->
        SeeIt.FilteredColumnFactory(dataColumn, [0...dataColumn.data().length], self)

      @requirements = []
      @filterState = []
      @operator = "AND"
      @collapsed = false
      @editing = false
      @empty = true
      @initialized = false
      @graph = null
      @options = null
      @optionsVisible = false
      @dataset = []
      @filteredDataset = []
      @initHandlers()
      @initLayout()


      @graph = new @graphType.class(@container.find('.graph-wrapper'),@filteredDataset)

      @graph.dataFormat().forEach (d) ->
        self.dataset.push({
          name: d.name,
          type: d.type,
          multiple: d.multiple,
          data: []
        })
        self.requirements[d.name] = []


      if !@graph.options().length then @container.find('.options-button').hide()

      @initDataContainers()


    getGraphSettings: ->
      return {
        type: @getGraphType(),
        data: @getGraphState(),
        filters: @getGraphFilters()
      }

    getGraphType: ->
      @graphType.name


    getGraphFilters: ->
      return @filterState


    getGraphState: ->
      return _.flatten([
        @dataset.map((role) ->
          role.data.map((dataColumn) ->
            {
              dataset_title: dataColumn.datasetTitle,
              column_header: dataColumn.header,
              role_in_graph: role.name
            }
          )
        )
      ])

    addData: (data) ->
      for j in [0...data.length]
        new_data = data[j]

        ((new_data) ->
          datasetIdx = -1

          @dataset.forEach (d, i) ->
            if d.name == new_data.name then datasetIdx = i

          if datasetIdx != -1
            dataIdx = @dataset[datasetIdx].data.indexOf(new_data.data)

            if dataIdx == -1
              @dataset[datasetIdx].data.push(new_data.data)

              this_data = {}
              this_data.data = @filter(new_data.data, new_data.name)
              this_data.name = new_data.name

              @filterColumn(this_data.data, new_data.data, this_data.name)

              @filteredDataset[datasetIdx].data.push(this_data.data)

              self = @

              @listenTo(this_data.data, 'label:changed', (idx) ->
                self.graph.trigger('label:changed', self.options.getValues())
              )

              @listenTo(this_data.data, 'color:changed', ->
                self.graph.trigger('color:changed', self.options.getValues())
              )

              @listenTo(this_data.data, 'header:changed', ->
                self.graph.trigger('header:changed', self.options.getValues())
              )

              @listenTo(this_data.data, 'data:destroyed', ->
                self.graph.trigger('data:destroyed', self.options.getValues())
              )

              @listenTo(this_data.data, 'data:created', ->
                self.graph.trigger('data:created', self.options.getValues())
              )

              @listenTo(this_data.data, 'data:changed', ->
                self.graph.trigger('data:changed', self.options.getValues())
              )

              @listenTo(this_data.data, 'type:changed', ->
                if this_data.data.type != self.dataset[datasetIdx].type
                  idx = -1

                  self.dataset.forEach (d, i) ->
                    if d.name == this_data.name then idx = i

                  if idx >= 0
                    colToDestroy = self.dataset[idx].data.indexOf(this_data.data)

                    if colToDestroy >= 0
                      self.dataset[idx].data.splice(colToDestroy, 1)
                      self.filteredDataset[idx].data.splice(colToDestroy, 1)
                      self.graph.trigger('column:destroyed', self.options.getValues())

                      msg = "Data removed due to type change"
                      tip = new Opentip(self.container.find('.data-drop-zone'), msg, {style: "alert", target: self.container.find('.data-drop-zone'), showOn: "creation", tipJoint: "top left"})
                      tip.setTimeout(->
                        tip.hide.call(tip)
                        return
                      , 5)

                  self.updateFooterData.call(self)
              )

              @listenTo(this_data.data, 'destroy', ->
                idx = -1

                self.dataset.forEach (d, i) ->
                  if d.name == this_data.name then idx = i

                if idx >= 0
                  colToDestroy = self.dataset[idx].data.indexOf(this_data.data)

                  if colToDestroy >= 0
                    self.dataset[idx].data.splice(colToDestroy, 1)
                    self.filteredDataset[idx].data.splice(colToDestroy, 1)
                    self.graph.trigger('column:destroyed', self.options.getValues())

                self.updateFooterData.call(self)
              )

              @addDataToFooter(new_data)

              if j == data.length - 1
                if !@initialized
                  @initGraph()
                  @initialized = true

                @graph.trigger('data:assigned', self.options.getValues())
        ).call(@, new_data)

    addDataToFooter: (data) ->
      self = @

      @container.find(".data-drop-zone[data-id='#{data.name}']").append("""
        <div class="SeeIt data-rep btn-group" role="group" data-id='#{data.data.header}'>
          <button class="SeeIt data-rep-color btn btn-default" style="background-color: #{data.data.color}"></button>
          <button class="SeeIt data-rep-text btn btn-default">#{data.data.header}</button>
          <button class="SeeIt data-rep-remove btn btn-default" title='Remove Data'><span class="glyphicon glyphicon-remove"></span></button>
        </div>
      """)

      item = @container.find(".data-drop-zone[data-id='#{data.name}'] .data-rep-color:last")

      @listenTo data.data, 'color:changed', ->
        item.css('background-color', data.data.color)

      @container.find(".data-rep[data-id='#{data.data.header}'] .data-rep-remove").on 'click', ->
        self.removeData.call(self, data)

      @container.find(".data-rep[data-id='#{data.data.header}'] .data-rep-text").on 'click', ->
        context = @
        data.data.trigger 'request:childLength', (childLength) ->

          msg = """
            <b>Dataset:</b> #{data.data.datasetTitle}
            <br>
            <b>Data Type:</b> #{data.data.type}
            <br>
            <b>Filters:</b> #{childLength} out of #{data.data.length()} selected by filter
          """

          tip = new Opentip($(context), msg, {target: $(context), showOn: "creation"})
          tip.setTimeout(->
            tip.hide.call(tip)
            return
          , 5)
      

    updateFooterData: ->
      self = @

      @container.find(".data-rep").remove()

      @dataset.forEach (role) ->
        role.data.forEach (d) ->
          self.addDataToFooter.call(self, {name: role.name, data: d})

    removeDataFromFooter: (data) ->
      @container.find(".data-drop-zone[data-id='#{data.name}'] .data-rep[data-id='#{data.data.header}']").remove()

    removeData: (data) ->
      dataset_idx = @dataset.map((d) -> d.name).indexOf(data.name)

      if dataset_idx >= 0
        idx = @dataset[dataset_idx].data.indexOf(data.data)
        if idx >= 0
          @dataset[dataset_idx].data.splice(idx, 1)
          @filteredDataset[dataset_idx].data.splice(idx, 1)
          @graph.trigger('data:destroyed', @options.getValues())
          @removeDataFromFooter(data)

    initGraph: ->
      self = @


      @trigger('graphSettings:get', @graphType.name, (settings = {}) ->
        self.options = new SeeIt.GraphOptions(self.container.find('.options-button'), self.container.find('.options-wrapper'), self.graph.options(), settings.disable, settings.defaults)

        self.listenTo self.options, 'options:show', ->
          self.container.find('.graph-wrapper').addClass('col-md-9')
          self.container.find('.options-wrapper').removeClass('hidden')
          self.graph.trigger('size:change', self.options.getValues())

        self.listenTo self.options, 'options:hide', ->
          self.container.find('.graph-wrapper').removeClass('col-md-9')
          self.container.find('.options-wrapper').addClass('hidden')
          self.graph.trigger('size:change', self.options.getValues())

        self.listenTo self.options, 'graph:update', ->
          self.graph.trigger('options:update', self.options.getValues())
      )


    updateFilters: (filterData) ->
      @filterGroups.forEach (group) ->
        group.removeFilterGroup()

      if filterData.length > 1
        @container.find(".filter-group-requirements-select").val(filterData[0])

        for filter_group in filterData
          if $.isArray(filter_group)
            filter_group_obj = @addFilterGroup()
            filter_group_obj.updateFilters(filter_group)

        @saveFilters()

    initHandlers: ->
      graph = @

      @on 'request:dataRoles', (cb) ->
        cb(graph.graph.dataFormat())

      @on 'size:change', ->
        # graph.setGraphHeight.call(graph)
        if graph.initialized then graph.graph.trigger('size:change', graph.options.getValues())

      @on 'filter', (filterData) ->
        graph.updateFilters.call(graph)

      graph.handlers = {
        removeGraph: ->
          graph.destroy.call(graph)
          graph.destroyCallback(graph.id.toString())

        maximize: ->
          graph.maximize.call(graph)

        collapse: ->
          graph.collapse.call(graph)

        collapseFooter: ->
          graph.collapseFooter.call(graph)

        editTitle: ->
          if !graph.editing
            graph.container.find(".graph-title-content").html("<input id='graph-title-input' type='text' value='#{graph.id}'>")
            graph.container.find('#graph-title-input').off('keyup', graph.handlers.graphTitleInputKeyup).on('keyup', graph.handlers.graphTitleInputKeyup)
            graph.editing = true
          else
            oldId = graph.id
            value = graph.container.find("#graph-title-input").val()
            graph.id = value
            newId = graph.id
            graph.container.find(".graph-title-content").html(value)
            graph.editing = false
            graph.trigger('graph:id:change', oldId, newId)

        graphTitleInputKeyup: (event) ->
          if event.keyCode == 13
            graph.container.find(".graph-title-edit-icon").trigger('click')

            
      }

      # $(window).on 'resize', ->
      #   graph.setGraphHeight.call(graph)

    initLayout: ->
      @container.html("""
        <div class="SeeIt graph-panel panel panel-default">
          <div class="SeeIt panel-heading">
            <div class="btn-group SeeIt graph-buttons" role="group">
              <button role="button" class="SeeIt options-button btn btn-default" title="Graph Options"><span data-id=#{@id}" class="glyphicon glyphicon-wrench"></span></button>
              <button class="SeeIt collapse-footer btn btn-default" title='Show/Hide Footer'><span data-id="#{@id}" class="glyphicon glyphicon-chevron-up"></span></button>
              <button class="SeeIt collapse-btn btn btn-default" title='Show/Hide Graph'><span data-id="#{@id}" class="glyphicon glyphicon-collapse-down"></span></ button>
              <button class="SeeIt maximize btn btn-default" title='Maximize Graph'><span data-id="#{@id}" class="glyphicon glyphicon-resize-full"></span></button>
              #{if @graph_editable then '<button class="SeeIt remove btn btn-default" title="Remove Graph"><span data-id="#{@id}" class="glyphicon glyphicon-remove"></span></button>' else ''}
            </div>
            <div class="SeeIt graph-title">
              <div class="SeeIt graph-title-content">#{@id}</div>
              <span class="SeeIt graph-title-edit-icon glyphicon glyphicon-pencil" title='Edit Title'></span>
            </div>
          </div>
          <div id="collapse_#{@id.split(' ').join('-')}" class="SeeIt graph-panel-content panel-collapse collapse in">
            <div class="SeeIt panel-body" style='min-height: 300px'>
              <div class="SeeIt options-wrapper hidden col-md-3"></div>
              <div class="SeeIt graph-wrapper"></div>
            </div>
          </div>
          <div class="SeeIt panel-footer">
            <div class="SeeIt footer-row row"></div>
            <div class="SeeIt footer-expanded-row row"></div>
          </div>
        </div>
      """)

      if @graph_editable then @container.find(".remove").on('click', @handlers.removeGraph)

      @container.find(".maximize").on('click', @handlers.maximize)
      @container.find(".collapse-btn").on('click', @handlers.collapse)
      @container.find(".graph-title-edit-icon").on('click', @handlers.editTitle)
      @container.find(".collapse-footer").on('click', @handlers.collapseFooter)


    initDataContainers: ->
      self = @
      dataFormat = @graph.dataFormat()

      cols = Math.floor(12 / dataFormat.length)

      dataFormat.forEach (role) ->
        self.container.find('.footer-row').append("""
          <div class='SeeIt data-drop-zone-container col-lg-#{cols}'>
            <h3 class='SeeIt role-name text-center'>#{if dataFormat.length > 1 then role.name else "Data"}</h3>
            <div class='SeeIt data-drop-zone' data-id="#{role.name}">
            </div>
          </div>
        """)

      @container.find('.footer-expanded-row').append("""
        <button class='btn btn-primary SeeIt toggle-filters'>
          <span class='caret'></span>
          Show Filters
        </button>
        <div class='SeeIt expanded-data-container'>
          <div class='SeeIt expanded-data-zone text-center'>
            <h3 class='text-center SeeIt filters-header append-anchor'>Filters</h3>
            <label for='filter-group-requirements' class='filter-group-requirements'>Filter group requirements:</label>
            <select name='filter-group-requirements' class='form-control SeeIt filter-group-requirements filter-group-requirements-select'>
              <option value='AND'>All filter groups must be fulifilled</option>
              <option value='OR'>At least one filter group must be fulfilled</option>
            </select>
            <button class="SeeIt add-filter-group btn btn-primary text-center"><div class='SeeIt icon-container'><span class='glyphicon glyphicon-plus'></span></div>Add filter group</button>
            <button class="SeeIt save-filters btn btn-success text-center"><div class='SeeIt icon-container'><span class='glyphicon glyphicon-ok'></span></div>Save Filters</button>
          </div>
        </div>
      """)


      @container.find(".toggle-filters").on 'click', (event) ->
        self.toggleFilters.call(self, @)

      @container.find(".expanded-data-container .add-filter-group").on 'click', (event) ->
        self.addFilterGroup.call(self)

      @container.find(".expanded-data-container .save-filters").on 'click', (event) ->
        if self.validateFilters.call(self)
          self.saveFilters.call(self)

    validateFilters: ->
      valid = true
      
      @filterGroups.forEach (filterGroup) ->
        valid = valid && filterGroup.validate()

      return valid

    saveFilters: ->
      self = @

      @operator = @container.find(".filter-group-requirements-select").val()
      @filterState = [@operator]
      @requirements = []

      @filterGroups.forEach (filterGroup) ->
        filterGroup.saveFilters()
        self.requirements.push filterGroup.getFilter()
        self.filterState.push filterGroup.getFilters()

      @filteredDataset.forEach (dataset, datasetIdx) ->
        dataset.data.forEach (dataColumn, i) ->
          parentColumn = self.dataset[datasetIdx].data[i]
          self.filterColumn.call(self, dataColumn, parentColumn)


    filterColumn: (dataColumn, parentColumn) ->
      self = @

      filteredData = [0...parentColumn.data().length]

      if self.requirements.length > 0 && self.operator == "OR" then filteredData = []

      self.requirements.forEach (requirement) ->
        if self.operator == "AND"
          filteredData = _.intersection(filteredData, requirement(parentColumn))
        else
          filteredData = _.union(filteredData, requirement(parentColumn))

      dataColumn.trigger 'filter:changed', filteredData

    addFilterGroup: ->
      self = @

      self.container.find(".expanded-data-container .append-anchor").after("""
        <div class='SeeIt filter-group'>
        </div>
      """)

      this_container = @container.find(".expanded-data-container .filter-group:last")
      parent = this_container.parent()
      filter_group = new SeeIt.FilterGroup(this_container)
      @filterGroups.push filter_group

      self.container.find(".append-anchor").removeClass('append-anchor')
      self.container.find(".filter-group:last").addClass('append-anchor')

      @listenTo filter_group, 'request:dataset_names', (callback) ->
        self.trigger 'request:dataset_names', callback

      @listenTo filter_group, 'filter_group:destroyed', ->
        self.placeAppendAnchor.call(self, parent)
        self.filterGroups.splice(self.filterGroups.indexOf(filter_group), 1)

      @listenTo filter_group, 'request:columns', (dataset, callback) ->
        self.trigger 'request:columns', dataset, callback

      @listenTo filter_group, 'request:values:unique', (dataset, idx, callback) ->
        self.trigger 'request:values:unique', dataset, idx, callback

      @listenTo filter_group, 'request:dataset', (name, callback) ->
        self.trigger 'request:dataset', name, callback

      filter_group.init()

      return filter_group

    placeAppendAnchor: (container) ->
      if !container.find('.append-anchor').length
        if container.find(".filter-group:last").length
          container.find(".filter-group:last").addClass('append-anchor')
        else
          container.find('.filters-header').addClass('append-anchor')


    toggleFilters: (target) ->
      self = @
      visible = !@container.find(".expanded-data-container").is(':visible')
      @container.find(".expanded-data-container").slideToggle()

      if visible
        $(target).html("""
          <span class='dropup'><span class="caret"></span></span>
          Hide Filters
        """)
      else
        $(target).html("""
          <span class="caret"></span>
          Show Filters
        """)

    destroy: ->
      if @graph then @graph.destroy()
      @container.remove()

    # setGraphHeight: ->
    #   @container.find('.graph-wrapper').height(
    #     if @maximized
    #       (
    #         @container.find('.graph-panel').innerHeight() -
    #         @container.find('.panel-heading').outerHeight() -
    #         @container.find('.panel-footer').outerHeight() -
    #         30
    #       )
    #     else
    #       300
    #   )

    maximize: ->
      if @collapsed
        @container.find(".collapse-btn").trigger('click')
        
      @container.toggleClass('maximized')
      @container.find('.maximize .glyphicon').toggleClass('glyphicon-resize-full glyphicon-resize-small')
      @maximized = !@maximized

      # @setGraphHeight()

      console.log 'maximize triggered'
      @graph.trigger('size:change', @options.getValues())
      @options.trigger('graph:maximize', @maximize)

    collapse: ->
      if @maximized
        @container.find(".maximize").trigger('click')

      @container.find("#collapse_#{@id.split(' ').join('-')}").toggleClass('in')
      @container.find('.collapse-btn .glyphicon').toggleClass('glyphicon-collapse-down glyphicon-collapse-up')
      @collapsed = !@collapsed

    collapseFooter: ->
      @container.find(".panel-footer").slideToggle()
      @container.find(".collapse-footer span").toggleClass("glyphicon-chevron-up glyphicon-chevron-down")

  GraphView
).call(@)