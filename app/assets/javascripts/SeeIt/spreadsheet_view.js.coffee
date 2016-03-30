@SeeIt.SpreadsheetView = (->
  privateMembers = {}
  privateMembers.dataset = null
  class SpreadsheetView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @dataset) ->
      privateMembers.dataset = @dataset
      @visible = true
      @fullscreenClass = 'col-md-12'
      @splitscreenClass = 'col-md-10'
      @hot = null
      @initLayout()

    initLayout: ->
      @container.html("""
        <div class="SeeIt spreadsheet-panel panel panel-default">
          <div class="SeeIt panel-heading">#{if @dataset && @dataset.data.length then @dataset.title else 'New Dataset'}</div>
          <div class="SeeIt panel-body spreadsheet">
            <div class="SeeIt Handsontable-Container"></div>
          </div>
        </div>
      """)

      @resetTable()
      @initHandlers()
      @toggleVisible()

    toggleFullscreen: ->
      if @isFullscreen 
        @container.removeClass(@fullscreenClass).addClass(@splitscreenClass)
      else
        @container.removeClass(@splitscreenClass).addClass(@fullscreenClass)

      @isFullscreen = !@isFullscreen

    updateTitle: ->
      @container.find('.panel-heading').html(@dataset.title)

    updateDataset: (dataset) ->
      @dataset = dataset
      privateMembers.dataset = @dataset
      @updateTitle()
      @resetTable()

    initHandlers: ->
      self = @

      @listenTo(@app, 'spreadsheet:load', (dataset) ->
        if dataset != self.dataset
          self.updateDataset.call(self, dataset)
      )

      @listenTo(@app, 'data:changed', (origin) ->
        #Do nothing
      )

    resetTable: ->
      if !@dataset then return

      spreadsheetView = @
      settings = {
        rowHeaders: @dataset.labels,
        colHeaders: @dataset.headers,
        data: privateMethods.formatModelData(),
        columns: privateMethods.formatColumns(),
        manualColumnResize: true,
        manualRowResize: true,
        copyPaste: true,
        contextMenu: ['row_above', 'row_below', 'remove_row', 'col_left', 'col_right', 'remove_row', 'remove_col', 'undo', 'redo'],
        afterChange: (changes, source) ->
          spreadsheetView.trigger('data:changed', spreadsheetView)
      }

      if @hot 
        @hot.destroy()
        @hot = null

      @hot = new Handsontable(
        @container.find('.SeeIt.Handsontable-Container')[0],
        settings
      )

    toggleVisible: ->
      @container.toggleClass('hidden')
      @visible = !@visible

  privateMethods = {
    formatColumns: ->
      columns = []

      for i in [0...privateMembers.dataset.data.length]
        columns.push({data: this.property(i), type: 'numeric'})

      return columns

    formatModelData: ->
      data = []

      for i in [0...privateMembers.dataset.data[0].data.length]
        data.push(this.hotModel(i))

      return data

    hotModel: (rowIdx) ->
      obj = {}

      obj.attr =  (colIdx, val) -> 
        if typeof val == "undefined"
          #Get element of model
          return privateMembers.dataset.data[colIdx].getValue(rowIdx)
        else
          #Set element of model
          privateMembers.dataset.data[colIdx].setValue(rowIdx, val)
          return obj

      return obj


    property: (colIdx) ->
      return (row, value) ->
        return row.attr(colIdx, value)
  }

  SpreadsheetView
).call(@)