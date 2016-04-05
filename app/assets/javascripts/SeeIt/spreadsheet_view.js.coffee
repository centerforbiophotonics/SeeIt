@SeeIt.SpreadsheetView = (->
  privateMembers = {}
  privateMembers.dataset = null
  class SpreadsheetView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @dataset) ->
      # if !@dataset then @dataset = new SeeIt.Dataset(@app)

      privateMembers.dataset = @dataset
      @visible = true
      @fullscreenClass = 'col-md-12'
      @splitscreenClass = 'col-md-10'
      @hot = null
      @initLayout()

    initLayout: ->
      @container.html("""
        <div class="SeeIt spreadsheet-panel panel panel-default">
          <div class="SeeIt panel-heading">
            <span class='title'>#{if @dataset && @dataset.data.length then @dataset.title else ""}</span>
          </div>
          <div class="SeeIt panel-body spreadsheet">
            <div class="SeeIt Handsontable-Container"></div>
          </div>
        </div>
      """)

            # <div class="SeeIt spreadsheet-button-group btn-group" role="group">
            #   <button class="SeeIt add-dataset btn btn-default"><span class="glyphicon glyphicon-plus"></span></button>
            #   <button class="SeeIt save-dataset btn btn-default"><span class="glyphicon glyphicon-save"></span></button>
            # </div>

      @initHandlers()
      @resetTable()
      @toggleVisible()

    toggleFullscreen: ->
      if @isFullscreen 
        @container.removeClass(@fullscreenClass).addClass(@splitscreenClass)
      else
        @container.removeClass(@splitscreenClass).addClass(@fullscreenClass)

      @isFullscreen = !@isFullscreen

    updateTitle: ->
      @container.find('.panel-heading .title').html(@dataset.title)

    updateDataset: (dataset) ->
      #Unsubscribe from old dataset
      @stopListening(@dataset)

      #Update dataset
      @dataset = dataset
      privateMembers.dataset = @dataset

      #Subscribe to new dataset events
      @subscribeToDataset()

      @updateTitle()
      @resetTable()

    subscribeToDataset: ->
      self = @

      @listenTo(@dataset, 'dataColumn:destroyed', ->
        self.resetTable.call(self)
      )

      @listenTo(@dataset, 'dataColumn:created', ->
        self.resetTable.call(self)
      )

      @listenTo(@dataset, 'row:destroyed', ->
        self.resetTable.call(self)
      )

      @listenTo(@dataset, 'row:created', ->
        self.resetTable.call(self)
      )

    initHandlers: ->
      self = @


      @listenTo(@app, 'spreadsheet:load', (dataset) ->
        console.log 'spreadsheet:load triggered'
        if dataset != self.dataset
          self.updateDataset.call(self, dataset)
      )

      @subscribeToDataset()

      @listenTo(@app, 'data:changed', (origin) ->
        #Do nothing
      )

    resetTable: ->
      if !@dataset then return

      spreadsheetView = @

      #Creates 'afterGet' callbacks for row and column headers
      headerCallbackFactory = (dim = "header") ->
        data = if dim == "label" then spreadsheetView.dataset.labels else spreadsheetView.dataset.headers

        if dim != "label" && dim != "header" then dim = "header"

        (idx, TH) ->
          #Nothing to do if first row/column
          if idx == -1 then return

          instance = @

          headerDblclick = (event) ->
            event.stopPropagation()
            event.preventDefault()

            $(TH).off('dblclick')

            input = document.createElement('input')
            input.type = 'text'
            input.value = TH.firstChild.textContent

            TH.appendChild(input)

            TH.style.position = 'relative'
            TH.firstChild.style.display = 'none'

            $(input).keyup (event) ->
              event.stopPropagation()
              event.preventDefault()

              if event.keyCode == 13
                value = $(input).val()

                spreadsheetView.dataset.trigger("#{dim}:change", value, idx)

                instance.updateSettings({
                  "#{if dim == 'header' then 'colHeaders' else 'rowHeaders'}": data
                })

                $(input).remove()
                TH.style.position = 'auto'
                TH.firstChild.style.display = 'table-cell'

                registerDblclick()
              return false


            return false


          registerDblclick = ->
            $(TH).off('dblclick').on('dblclick', headerDblclick)

          $(TH).off('dblclick').on('dblclick', headerDblclick)

      settings = {
        rowHeaders: @dataset.labels,
        colHeaders: @dataset.headers,
        data: privateMethods.formatModelData(),
        columns: privateMethods.formatColumns(),
        afterGetRowHeader: headerCallbackFactory("label"),
        afterGetColHeader: headerCallbackFactory("header")
        manualColumnResize: true,
        manualRowResize: true,
        copyPaste: true,
        contextMenu: {
          items: {
            "my_row_above": {
              name: "Insert row above",
              callback: (key, options) ->
                spreadsheetView.dataset.trigger('row:create', options.end.row)
            },
            "my_row_below": {
              name: "Insert row below",
              callback: (key, options) ->
                spreadsheetView.dataset.trigger('row:create', options.end.row + 1)
            },
            "my_remove_row": {
              name: "Remove row",
              callback: (key, options) ->
                if spreadsheetView.hot.countRows.call(spreadsheetView.hot) > 1
                  spreadsheetView.dataset.trigger('row:destroy', options.end.row)
                else
                  setTimeout(->
                    alert("Dataset must have at least one row")
                  , 100)                  
            },
            "my_remove_col": {
              name: "Remove column",
              callback: (key, options) ->
                if spreadsheetView.hot.countCols.call(spreadsheetView.hot) > 1
                  spreadsheetView.dataset.trigger('dataColumn:destroy', options.end.col)
                else
                  setTimeout(->
                    alert("Dataset must have at least one column")
                  , 100)
            },
            "my_col_left": {
              name: "Insert column on the left",
              callback: (key, options) ->
                spreadsheetView.dataset.trigger('dataColumn:create', options.end.col)
            },
            "my_col_right": {
              name: "Insert column on the right",
              callback: (key, options) ->
                spreadsheetView.dataset.trigger('dataColumn:create', options.end.col + 1)
            }
          }
        },
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
      len = if privateMembers.dataset.data.length then privateMembers.dataset.data[0].data.length else 0

      for i in [0...len]
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