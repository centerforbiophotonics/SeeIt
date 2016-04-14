@SeeIt.GraphView = (->
  class GraphView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @id, @container, @destroyCallback, @graphType) ->
      @maximized = false
      @collapsed = false
      @editing = false
      @empty = true
      @graph = null
      @options = null
      @optionsVisible = false
      @dataset = []
      @initHandlers()
      @initLayout()
      @graph = new @graphType.class(@container.find('.graph-wrapper'),@dataset)

    addData: (data) ->
      datasetIdx = -1

      console.log @dataset

      @dataset.forEach (d, i) ->
        if d.name == data.name then datasetIdx = i

      if datasetIdx != -1
        dataIdx = @dataset[datasetIdx].data.indexOf(data.data)

        if dataIdx == -1
          @dataset[datasetIdx].data.push(data.data)

          self = @

          @listenTo(data.data, 'label:changed', (idx) ->
            self.updateGraph.call(self)
          )

          @listenTo(data.data, 'header:changed', ->
            self.updateGraph.call(self)
          )

          @listenTo(data.data, 'data:destroyed', ->
            self.updateGraph.call(self)
          )

          @listenTo(data.data, 'data:created', ->
            self.updateGraph.call(self)
          )

          @listenTo(data.data, 'destroy', ->
            idx = @dataset.indexOf(data.name)

            if idx >= 0
              colToDestroy = @dataset[idx].indexOf(data.data)

              if colToDestroy >= 0
                @dataset[idx].data.splice(colToDestroy, 1)
                self.updateGraph.call(self)
          )

          if @empty
            @empty = false
            @initGraph()
          else
            @updateGraph()


    updateGraph: ->
      if @graph then @graph.refresh()

    initGraph: ->
      self = @

      console.log "initGraph called"

      @graph.draw()
      @options = new SeeIt.GraphOptions(@container.find('.options-button'), @container.find('.options-wrapper'), @graph.options())

      @listenTo @options, 'options:show', ->
        self.container.find('.graph-wrapper').addClass('col-md-9')
        self.container.find('.options-wrapper').removeClass('hidden')
        self.updateGraph.call(self)

      @listenTo @options, 'options:hide', ->
        self.container.find('.graph-wrapper').removeClass('col-md-9')
        self.container.find('.options-wrapper').addClass('hidden')
        self.updateGraph.call(self)


    initHandlers: ->
      graph = @

      @on 'request:dataRoles', (cb) ->
        cb(graph.graph.dataFormat())

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
          <div id="collapse_#{@id}" class="panel-collapse collapse in">
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
      @container.remove()


    maximize: ->
      if @collapsed
        @container.find(".collapse-btn").trigger('click')
        
      @container.toggleClass('maximized')
      @container.find('.maximize .glyphicon').toggleClass('glyphicon-resize-full glyphicon-resize-small')
      @maximized = !@maximized

    collapse: ->
      if @maximized
        @container.find(".maximize").trigger('click')

      @container.find("#collapse_#{@id}").toggleClass('in')
      @container.find('.collapse-btn .glyphicon').toggleClass('glyphicon-collapse-down glyphicon-collapse-up')
      @collapsed = !@collapsed

  GraphView
).call(@)