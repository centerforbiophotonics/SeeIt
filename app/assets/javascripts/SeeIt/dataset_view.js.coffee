@SeeIt.DatasetView = (->
  class DatasetView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @dataset) ->
      @dataColumnViews = []
      @inSpreadsheet = false
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
      
      @on 'populate:dropdowns', ->
        self.populateDropdowns.call(self)

      @on 'spreadsheet:unloaded', ->
        if self.inSpreadsheet then self.container.find('.show-in-spreadsheet').trigger('click')

      @listenTo @dataset, 'dataset:title:changed', ->
        self.updateTitle.call(self)

    initLayout: ->
      @container.html("""
        <li class="SeeIt dataset list-group-item" style="min-height: 54px">
          <div class="btn-group-vertical dataset-view-group SeeIt" role="group">
            <button class="SeeIt dataset-title btn btn-default" role="button">#{@dataset.title}</button>
            <button class="SeeIt btn btn-default show-in-spreadsheet #{if @app.ui.spreadsheet then '' else 'hidden'}" role="button">
              Show in Spreadsheet
              <span class='glyphicon glyphicon-th'></span>
            </button>
          </div>
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


    populateDropdowns: ->
      @dataColumnViews.forEach (columnView) ->
        columnView.trigger('populate:dropdown')

    addData: (dataColumn) ->

      @container.find(".data-list").append("<li class='SeeIt list-group-item data-container'></li>")
      columnView = new SeeIt.DataColumnView(@app, @container.find(".data-container").last(), dataColumn)
      # addData will get called 4 times
      console.log "addData"
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

      #columnView.populateGraphSelectBox();

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

        if !self.inSpreadsheet
          self.trigger('spreadsheet:load', self.dataset)
          self.inSpreadsheet = true
          $(@).html("""
            Remove from Spreadsheet
            <span class='glyphicon glyphicon-th'></span>
          """)
        else
          self.inSpreadsheet = false
          $(@).html("""
            Show in Spreadsheet
            <span class='glyphicon glyphicon-th'></span>
          """)
          self.trigger('spreadsheet:unload')

        $(@).toggleClass('btn-default btn-primary')

      @container.find('.dataset').off('click', toggleData).on('click', toggleData)
      @container.find('.show-in-spreadsheet').off('click', showInSpreadsheet).on('click', showInSpreadsheet)

  DatasetView
).call(@)