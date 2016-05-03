@SeeIt.SpreadsheetView = (->
  privateMembers = {}
  privateMembers.dataset = null
  class SpreadsheetView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @dataset) ->
      # if !@dataset then @dataset = new SeeIt.Dataset(@app)

      privateMembers.dataset = @dataset
      @visible = true
      @editingTitle = false
      @fullscreenClass = 'col-md-12'
      @splitscreenClass = 'col-md-9'
      @hot = null
      @initLayout()

    initLayout: ->
      @container.html("""
        <div class="SeeIt spreadsheet-panel panel panel-default">
          <div class="SeeIt panel-heading">
            <span class='title'>#{if @dataset && @dataset.data.length then @dataset.title else ""}</span>
            <span class="SeeIt title-edit-icon glyphicon glyphicon-pencil"></span>
          </div>
          <div class="SeeIt panel-body spreadsheet">
            <div class="SeeIt Handsontable-Container" style="position: relative; overflow: hidden; height: 100%"></div>
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
      @stopListening('dataColumn:destroyed dataColumn:created row:destroyed row:created')

      #Update dataset
      @dataset = dataset
      privateMembers.dataset = @dataset

      #Subscribe to new dataset events
      @subscribeToDataset()

      @updateTitle()
      @resetTable()

    subscribeToDataset: ->
      self = @

      @listenTo(@dataset, 'dataColumn:destroyed dataColumn:created row:destroyed row:created', ->
        self.resetTable.call(self)
      )

      # @listenTo(@dataset, 'dataColumn:created', ->
      #   self.resetTable.call(self)
      # )

      # @listenTo(@dataset, 'row:destroyed', ->
      #   self.resetTable.call(self)
      # )

      # @listenTo(@dataset, 'row:created', ->
      #   self.resetTable.call(self)
      # )

    initHandlers: ->
      self = @


      @listenTo(@app, 'spreadsheet:load', (dataset) ->
        console.log 'spreadsheet:load triggered', dataset
        if dataset != self.dataset
          self.updateDataset.call(self, dataset)
      )

      @listenTo(@app, 'width:toggle', ->
        $(window).triggerHandler('resize')
      )

      @subscribeToDataset()

      @listenTo(@app, 'data:changed', (origin) ->
        #Do nothing
      )

      @handlers = {
        editTitle: ->
          if !self.editingTitle
            self.container.find(".title").html("<input id='title-input' type='text' value='#{self.dataset.title}'>")
            self.container.find('#title-input').off('keyup', self.handlers.titleInputKeyup).on('keyup', self.handlers.titleInputKeyup)
            self.editingTitle = true
          else
            oldTitle = self.dataset.title
            value = self.container.find("#title-input").val()
            self.dataset.setTitle.call(self.dataset, value)
            self.container.find(".title").html(value)
            self.editingTitle = false

        titleInputKeyup: (event) ->
          if event.keyCode == 13
            self.container.find(".title-edit-icon").trigger('click')

        resize: (event) ->
          if self.hot
            self.hot.updateSettings({
              height: self.container.find('.SeeIt.Handsontable-Container').height(),
              colWidths: ->
                (self.container.find('.SeeIt.Handsontable-Container').width() - 50) / self.dataset.headers.length
            })

            self.container.find("td").css('text-align', 'center')
      }

      $(window).on 'resize', @handlers.resize

      @container.find('.title-edit-icon').off('click', @handlers.editTitle).on('click', @handlers.editTitle)

    validateUniqueness: (val, data, ignore) ->
      for i in [0...data.length]
        if val == data[i] && (!ignore && !ignore.length || ignore.indexOf(i) == -1)
          return false

      return true

    updateView: ->
      $(window).triggerHandler('resize')

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

                if !spreadsheetView.validateUniqueness(value, data, [idx])
                  tip = new Opentip($(input).parent(), "#{dim.charAt(0).toUpperCase() + dim.slice(1)} must be unique", {style: "alert", target: $(input).parent(), showOn: "creation"})
                  tip.setTimeout(->
                    tip.hide.call(tip)
                    return
                  , 5) 
                  return false

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
        className: "htCenter",
        height: spreadsheetView.container.find('.SeeIt.Handsontable-Container').height(),
        colWidths: ->
          (spreadsheetView.container.find('.SeeIt.Handsontable-Container').width() - 50) / spreadsheetView.dataset.headers.length
        # stretchH: "all",
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
                    cell = spreadsheetView.hot.getCell(options.end.row, options.end.col)
                    tip = new Opentip($(cell), "Dataset must have at least one row", {style: "alert", target: $(cell), showOn: "creation"})
                    tip.setTimeout(->
                      tip.hide.call(tip)
                      return
                    , 5)
                  , 100)                  
            },
            "my_remove_col": {
              name: "Remove column",
              callback: (key, options) ->
                if spreadsheetView.hot.countCols.call(spreadsheetView.hot) > 1
                  spreadsheetView.dataset.trigger('dataColumn:destroy', options.end.col)
                else
                  setTimeout(->
                    cell = spreadsheetView.hot.getCell(options.end.row, options.end.col)
                    tip = new Opentip($(cell), "Dataset must have at least one column", {style: "alert", target: $(cell), showOn: "creation"})
                    tip.setTimeout(->
                      tip.hide.call(tip)
                      return
                    , 5)
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

      @container.find("td").css('text-align', 'center')

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
      len = if privateMembers.dataset.data.length then privateMembers.dataset.data[0].data().length else 0

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