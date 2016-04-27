@SeeIt.GraphView = (->
  class GraphView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @id, @container, @destroyCallback, @graphType) ->
      @maximized = false
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

    addData: (data) ->
      datasetIdx = -1

      console.log @dataset, data

      @dataset.forEach (d, i) ->
        if d.name == data.name then datasetIdx = i

      if datasetIdx != -1
        dataIdx = @dataset[datasetIdx].data.indexOf(data.data)

        if dataIdx == -1
          console.log "adding to dataset"
          @dataset[datasetIdx].data.push(data.data)

          self = @

          @listenTo(data.data, 'label:changed', (idx) ->
            self.graph.trigger('label:changed', self.options.getValues())
          )

          @listenTo(data.data, 'color:changed', ->
            self.graph.trigger('color:changed', self.options.getValues())
          )

          @listenTo(data.data, 'header:changed', ->
            self.graph.trigger('header:changed', self.options.getValues())
          )

          @listenTo(data.data, 'data:destroyed', ->
            self.graph.trigger('data:destroyed', self.options.getValues())
          )

          @listenTo(data.data, 'data:created', ->
            self.graph.trigger('data:created', self.options.getValues())
          )

          @listenTo(data.data, 'data:changed', ->
            self.graph.trigger('data:changed', self.options.getValues())
          )

          @listenTo(data.data, 'destroy', ->
            console.log 'destroy triggered in graph view'
            datasetIdx = -1

            console.log self.dataset

            self.dataset.forEach (d, i) ->
              if d.name == data.name then datasetIdx = i

            if datasetIdx >= 0
              colToDestroy = self.dataset[datasetIdx].data.indexOf(data.data)

              if colToDestroy >= 0
                self.dataset[datasetIdx].data.splice(colToDestroy, 1)
                self.graph.trigger('column:destroyed', self.options.getValues())
          )

          if !@initialized
            @initGraph()
            @initialized = true

          @graph.trigger('data:assigned', self.options.getValues())

    initGraph: ->
      self = @


      @options = new SeeIt.GraphOptions(@container.find('.options-button'), @container.find('.options-wrapper'), @graph.options())

      @listenTo @options, 'options:show', ->
        self.container.find('.graph-wrapper').addClass('col-md-9')
        self.container.find('.options-wrapper').removeClass('hidden')
        self.graph.trigger('size:change', self.options.getValues())

      @listenTo @options, 'options:hide', ->
        self.container.find('.graph-wrapper').removeClass('col-md-9')
        self.container.find('.options-wrapper').addClass('hidden')
        self.graph.trigger('size:change', self.options.getValues())

      @listenTo @options, 'graph:update', ->
        self.graph.trigger('options:update', self.options.getValues())


    initHandlers: ->
      graph = @

      @on 'request:dataRoles', (cb) ->
        cb(graph.graph.dataFormat())

      @on 'size:change', ->
        if graph.graph then graph.graph.trigger('size:change', graph.options.getValues())

      graph.handlers = {
        removeGraph: ->
          graph.destroy.call(graph)
          graph.destroyCallback(graph.id.toString())

        maximize: ->
          graph.maximize.call(graph)

        collapse: ->
          graph.collapse.call(graph)

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
              <button class="collapse-btn btn btn-default"><span data-id="#{@id}" class="glyphicon glyphicon-collapse-down"></span></ button>
              <button class="maximize btn btn-default"><span data-id="#{@id}" class="glyphicon glyphicon-resize-full"></span></button>
              <button class="remove btn btn-default"><span data-id="#{@id}" class="glyphicon glyphicon-remove"></span></button>
            </div>
          </div>
          <div id="collapse_#{@id}" class="SeeIt graph-panel-content panel-collapse collapse in">
            <div class="SeeIt panel-body" style='min-height: 300px'>
              <div class="SeeIt options-wrapper hidden col-md-3"></div>
              <div class="SeeIt graph-wrapper"></div>
            </div>
          </div>
        </div>
      """)

      @container.find(".remove").on('click', @handlers.removeGraph)
      @container.find(".maximize").on('click', @handlers.maximize)
      @container.find(".collapse-btn").on('click', @handlers.collapse)
      @container.find(".graph-title-edit-icon").on('click', @handlers.editTitle)

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

      @container.find("#collapse_#{@id}").toggleClass('in')
      @container.find('.collapse-btn .glyphicon').toggleClass('glyphicon-collapse-down glyphicon-collapse-up')
      @collapsed = !@collapsed

  GraphView
).call(@)