@SeeIt.GraphView = (->
  class GraphView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @id, @container, @destroyCallback, @graphType, @graph_editable) ->
      @maximized = false
      @filterGroups = []
      @collapsed = false
      @editing = false
      @empty = true
      @initialized = false
      @graph = null
      @options = null
      @optionsVisible = false
      @dataset = []
      @initHandlers()
      @initLayout()

      @graph = new @graphType.class(@container.find('.graph-wrapper'),@dataset)

      if !@graph.options().length then @container.find('.options-button').hide()

      @initDataContainers()

    addData: (data) ->
      console.log data
      for j in [0...data.length]
        this_data = data[j]

        ((this_data) ->
          datasetIdx = -1

          @dataset.forEach (d, i) ->
            if d.name == this_data.name then datasetIdx = i

          if datasetIdx != -1
            dataIdx = @dataset[datasetIdx].data.indexOf(this_data.data)

            if dataIdx == -1
              @dataset[datasetIdx].data.push(this_data.data)

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

              @listenTo(this_data.data, 'destroy', ->
                console.log this_data, @dataset[0].data[2]
                datasetIdx = -1


                self.dataset.forEach (d, i) ->
                  if d.name == this_data.name then datasetIdx = i

                if datasetIdx >= 0
                  colToDestroy = self.dataset[datasetIdx].data.indexOf(this_data.data)

                  console.log colToDestroy
                  if colToDestroy >= 0
                    self.dataset[datasetIdx].data.splice(colToDestroy, 1)
                    self.graph.trigger('column:destroyed', self.options.getValues())

                self.updateFooterData.call(self)
              )

              @addDataToFooter(this_data)

              if j == data.length - 1
                if !@initialized
                  @initGraph()
                  @initialized = true

                @graph.trigger('data:assigned', self.options.getValues())
        ).call(@, this_data)

    addDataToFooter: (data) ->
      self = @

      @container.find(".data-drop-zone[data-id='#{data.name}']").append("""
        <div class="SeeIt data-rep btn-group" role="group" data-id='#{data.data.header}'>
          <button class="SeeIt data-rep-color btn btn-default" style="background-color: #{data.data.color}"></button>
          <button class="SeeIt data-rep-text btn btn-default">#{data.data.header}</button>
          <button class="SeeIt data-rep-remove btn btn-default"><span class="glyphicon glyphicon-remove"></span></button>
        </div>
      """)

      @container.find(".data-rep[data-id='#{data.data.header}'] .data-rep-remove").on 'click', ->
        console.log "removeData called"
        self.removeData.call(self, data)

      @container.find(".data-rep[data-id='#{data.data.header}'] .data-rep-text").on 'click', ->
        msg = """
          <b>Dataset:</b> #{data.data.datasetTitle}
          <br>
          <b>Data Type:</b> #{data.data.type}
        """

        tip = new Opentip($(@), msg, {target: $(@), showOn: "creation"})
        tip.setTimeout(->
          tip.hide.call(tip)
          return
        , 5)
      

    updateFooterData: ->
      self = @

      @container.find(".data-rep").remove()

      @dataset.forEach (role) ->
        console.log role
        role.data.forEach (d) ->
          console.log d
          self.addDataToFooter.call(self, {name: role.name, data: d})

    removeDataFromFooter: (data) ->
      @container.find(".data-drop-zone[data-id='#{data.name}'] .data-rep[data-id='#{data.data.header}']").remove()

    removeData: (data) ->
      console.log @dataset
      dataset_idx = @dataset.map((d) -> d.name).indexOf(data.name)

      if dataset_idx >= 0
        console.log @dataset[dataset_idx]
        idx = @dataset[dataset_idx].data.indexOf(data.data)
        if idx >= 0
          console.log "data found"
          @dataset[dataset_idx].data.splice(idx, 1)
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


    initHandlers: ->
      graph = @

      @on 'request:dataRoles', (cb) ->
        cb(graph.graph.dataFormat())

      @on 'size:change', ->
        if graph.initialized then graph.graph.trigger('size:change', graph.options.getValues())

      graph.handlers = {
        removeGraph: ->
          graph.destroy.call(graph)
          graph.destroyCallback(graph.id.toString())

        maximize: ->
          graph.maximize.call(graph)

        collapse: ->
          console.log "collapse called"
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

    initLayout: ->
      @container.html("""
        <div class="SeeIt graph-panel panel panel-default">
          <div class="SeeIt panel-heading">
            <button role="button" class="options-button btn btn-default"><span data-id=#{@id}" class="glyphicon glyphicon-wrench" style="float: left"></span></button>
            <div class="SeeIt graph-title">
              <div class="SeeIt graph-title-content">#{@id}</div>
              <span class="SeeIt graph-title-edit-icon glyphicon glyphicon-pencil"></span>
            </div>
            <div class="btn-group" role="group" style="float: right">
              <button class="collapse-footer btn btn-default"><span data-id="#{@id}" class="glyphicon glyphicon-chevron-up"></span></button>
              <button class="collapse-btn btn btn-default"><span data-id="#{@id}" class="glyphicon glyphicon-collapse-down"></span></ button>
              <button class="maximize btn btn-default"><span data-id="#{@id}" class="glyphicon glyphicon-resize-full"></span></button>
              #{if @graph_editable then '<button class="remove btn btn-default"><span data-id="#{@id}" class="glyphicon glyphicon-remove"></span></button>' else ''}
            </div>
          </div>
          <div id="collapse_#{@id.split(' ').join('-')}" class="SeeIt graph-panel-content panel-collapse collapse in">
            <div class="SeeIt panel-body" style='min-height: 300px'>
              <div class="SeeIt options-wrapper hidden col-md-3"></div>
              <div class="SeeIt graph-wrapper"></div>
            </div>
          </div>
          <div class="SeeIt panel-footer container-fluid">
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
              <button class="SeeIt btn btn-default expand-data" data-id="#{role.name}"><span data-id="#{role.name}" class="glyphicon glyphicon-collapse-down"></span></ button>
            </div>
          </div>
        """)

        self.container.find('.footer-expanded-row').append("""
          <div class='SeeIt expanded-data-container' data-id="#{role.name}">
            <div class='SeeIt expanded-data-zone text-center'>
              <h3 class='text-center SeeIt filters-header append-anchor' data-id="#{role.name}">Filters</h3>
              <button class="SeeIt add-filter-group btn btn-primary text-center"><div class='SeeIt icon-container'><span class='glyphicon glyphicon-plus'></span></div>Add filter group</button>
            </div>
          </div>
        """)

        self.container.find(".expand-data[data-id='#{role.name}']").on('click', (event) ->
          self.expandRoleField.call(self, role.name)
        )

        self.container.find(".expanded-data-container[data-id='#{role.name}'] .add-filter-group").on 'click', (event) ->
          console.log "add filter group clicked"
          self.addFilterGroup.call(self, role.name)

    addFilterGroup: (role) ->
      self = @

      self.container.find(".expanded-data-container[data-id='#{role}'] .append-anchor").after("""
        <div class='SeeIt filter-group' data-id='#{role}'>
        </div>
      """)

      this_container = @container.find(".expanded-data-container[data-id='#{role}'] .filter-group:last")
      parent = this_container.parent()
      filter_group = new SeeIt.FilterGroup(this_container, role)
      @filterGroups.push filter_group

      self.container.find(".append-anchor").removeClass('append-anchor')
      self.container.find(".filter-group[data-id='#{role}']:last").addClass('append-anchor')

      @listenTo filter_group, 'request:dataset_names', (callback) ->
        self.trigger 'request:dataset_names', callback

      @listenTo filter_group, 'filter_group:destroyed', ->
        self.placeAppendAnchor.call(self, parent)

      @listenTo filter_group, 'request:columns', (dataset, callback) ->
        self.trigger 'request:columns', dataset, callback

      filter_group.init()

    placeAppendAnchor: (container) ->
      if !container.find('.append-anchor').length
        if container.find(".filter-group:last").length
          container.find(".filter-group:last").addClass('append-anchor')
        else
          container.find('.filters-header').addClass('append-anchor')


    expandRoleField: (role) ->
      @container.find(".expanded-data-container[data-id='#{role}']").slideToggle()
      @container.find(".expand-data span[data-id='#{role}']").toggleClass('glyphicon-collapse-down glyphicon-collapse-up')

    destroy: ->
      if @graph then @graph.destroy()
      @container.remove()


    maximize: ->
      if @collapsed
        @container.find(".collapse-btn").trigger('click')
        
      @container.toggleClass('maximized')
      @container.find('.maximize .glyphicon').toggleClass('glyphicon-resize-full glyphicon-resize-small')
      @maximized = !@maximized

      @graph.trigger('size:change', @options.getValues())
      @options.trigger('graph:maximize', @maximize)

    collapse: ->
      if @maximized
        @container.find(".maximize").trigger('click')

      console.log @container.find("#collapse_#{@id.split(' ').join('-')}"), @container.find('.collapse-btn .glyphicon')
      @container.find("#collapse_#{@id.split(' ').join('-')}").toggleClass('in')
      @container.find('.collapse-btn .glyphicon').toggleClass('glyphicon-collapse-down glyphicon-collapse-up')
      @collapsed = !@collapsed

    collapseFooter: ->
      @container.find(".panel-footer").slideToggle()
      @container.find(".collapse-footer span").toggleClass("glyphicon-chevron-up glyphicon-chevron-down")

  GraphView
).call(@)