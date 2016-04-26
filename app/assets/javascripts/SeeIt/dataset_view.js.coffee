@SeeIt.DatasetView = (->
  class DatasetView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @dataset) ->
      @dataColumnViews = []
      @initListeners()
      @initLayout()

    initListeners: ->
      self = @

      @on 'datasetview:open', ->
        self.container.find('.dataset').trigger('click')

      @listenTo @dataset, 'dataColumn:created', (col) ->
        self.addData.call(self, self.dataset.data[col])

      @on 'graph:created', (graphId, dataRoles) ->
        self.dataColumnViews.forEach (d) ->
          d.trigger('graph:created', graphId, dataRoles)

      @on 'graph:destroyed', (graphId) ->
        self.dataColumnViews.forEach (d) ->
          d.trigger('graph:destroyed', graphId)

      @on 'graph:id:change', (oldId, newId) ->
        self.dataColumnViews.forEach (d) ->
          d.trigger('graph:id:change', oldId, newId)
      
      @listenTo @dataset, 'dataset:title:changed', ->
        self.updateTitle.call(self)

    initLayout: ->
      @container.html("""
        <li class="SeeIt dataset list-group-item" style="min-height: 54px">
          <a class="SeeIt dataset-title">#{@dataset.title}</a>
          <button class="btn btn-default show-in-spreadsheet pull-right">
            <span class='glyphicon glyphicon-expand'></span>
          </button>
        </li>
        <div class="SeeIt data-columns list-group-item" style="padding: 5px; display: none">
          <ul class='SeeIt list-group data-list'>
          </ul>
        </div>
      """)

      @initDataColumnViews()
      @registerEvents()


    destroy: ->
      @container.remove()
      @trigger('destroy')

    updateTitle: ->
      @container.find('.dataset-title').html(@dataset.title)

    initDataColumnViews: ->
      for i in [0...@dataset.data.length]
        @addData(@dataset.data[i])

    addData: (dataColumn) ->
      @container.find(".data-list").append("<li class='SeeIt list-group-item data-container'></li>")
      columnView = new SeeIt.DataColumnView(@app, @container.find(".data-container").last(), dataColumn)
      @dataColumnViews.push(columnView)

      self = @

      @listenTo(columnView, 'graph:addData', (graphData) ->
        self.trigger('graph:addData', graphData)
      )

      @listenTo(columnView, 'destroy', ->
        idx = self.dataColumnViews.indexOf(columnView)

        if idx >= 0
          self.dataColumnViews.splice(idx, 1)
      )

      @listenTo(columnView, 'graphs:requestIDs', (cb) ->
        self.trigger('graphs:requestIDs', cb)
      )


    registerEvents: ->
      self = @

      toggleData = ->
        $(@).toggleClass('active')
        $(@).find('a').toggleClass('selected')
        $(@).parent().find('.data-columns').slideToggle()

        if $(@).hasClass('active')
          self.dataColumnViews.forEach (d) ->
            d.trigger('dataColumns:show')

      showInSpreadsheet = (event) ->
        event.stopPropagation()
        self.trigger('spreadsheet:load', self.dataset)


      @container.find('.dataset').off('click', toggleData).on('click', toggleData)
      @container.find('.show-in-spreadsheet').off('click', showInSpreadsheet).on('click', showInSpreadsheet)

  DatasetView
).call(@)