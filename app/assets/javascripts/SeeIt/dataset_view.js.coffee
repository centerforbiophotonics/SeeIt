@SeeIt.DatasetView = (->
  class DatasetView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @dataset) ->
      @dataColumnViews = []
      @colors = d3.scale.category20()
      @viewsCreated = 0
      @initListeners()
      @initLayout()

    initListeners: ->
      self = @

      @on 'datasetview:open', ->
        self.container.find('.dataset').trigger('click')

      @listenTo @dataset, 'dataColumn:created', (col) ->
        self.addData.call(self, self.dataset.data[col])

    initLayout: ->
      @container.html("""
        <li class="SeeIt dataset list-group-item">
          <a class="SeeIt">#{@dataset.title}</a>
          <span class='show-in-spreadsheet glyphicon glyphicon-expand' style='float: right;'></span>
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

    initDataColumnViews: ->
      for i in [0...@dataset.data.length]
        @addData(@dataset.data[i])

    addData: (dataColumn) ->
      @container.find(".data-list").append("<li class='SeeIt list-group-item data-container'></li>")
      columnView = new SeeIt.DataColumnView(@app, @container.find(".data-container").last(), dataColumn, @colors(@viewsCreated++ % 20))
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


    registerEvents: ->
      self = @
      toggleData = ->
        $(@).toggleClass('active')
        $(@).find('a').toggleClass('selected')
        $(@).parent().find('.data-columns').slideToggle()
      showInSpreadsheet = (event) ->
        event.stopPropagation()
        self.trigger('spreadsheet:load', self.dataset)


      @container.find('.dataset').off('click', toggleData).on('click', toggleData)
      @container.find('.show-in-spreadsheet').off('click', showInSpreadsheet).on('click', showInSpreadsheet)

  DatasetView
).call(@)