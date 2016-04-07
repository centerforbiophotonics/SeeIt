@SeeIt.GraphView = (->
  class GraphView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @id, @container, @destroyCallback) ->
      @maximized = false
      @collapsed = false
      @editing = false
      @empty = true
      @graph = null
      @dataset = []
      @initHandlers()
      @initLayout()

    addData: (data) ->
      #DEMO PATCH
      if @dataset.indexOf(data) == -1
        @dataset.push(data)

        self = @

        @listenTo(data, 'label:changed', (idx) ->
          self.updateGraph.call(self)
        )

        @listenTo(data, 'header:changed', ->
          self.updateGraph.call(self)
        )

        @listenTo(data, 'data:destroyed', ->
          self.updateGraph.call(self)
        )

        @listenTo(data, 'data:created', ->
          self.updateGraph.call(self)
        )

        @listenTo(data, 'destroy', ->
          colToDestroy = @dataset.indexOf(data)

          if colToDestroy >= 0
            @dataset.splice(colToDestroy, 1)
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
      @graph = new SeeIt.Graphs.BarChart(@container.find('.panel-body'),@dataset)

    initHandlers: ->
      graph = @

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
            <button role="button" class="btn btn-default"><span data-id=#{@id}" class="glyphicon glyphicon-wrench" style="float: left"></span></button>
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
            <div class="SeeIt panel-body" style='min-height: 300px'></div>
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