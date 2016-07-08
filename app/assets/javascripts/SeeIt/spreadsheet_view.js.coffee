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

            <div class= "info SeeIt" style= "background-color: lightyellow;">N</div>             
            <div class= "info SeeIt" style= "background-color: LimeGreen;">C</div> 
            
            <div class="SeeIt Handsontable-Container" style="position: relative; overflow: hidden; height: 100%; min-height: 100%"></div>
          </div>
        </div>
      """)


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
      @container.find('.panel-heading .title').html(@dataset && @dataset.title || '')


    updateDataset: (dataset) ->
      #Unsubscribe from old dataset
      @stopListening('dataColumn:destroyed dataColumn:created row:destroyed row:created data:changed')

      #Update dataset
      @dataset = dataset
      privateMembers.dataset = @dataset

      #Subscribe to new dataset events
      @subscribeToDataset()

      @updateTitle()
      @resetTable()

    subscribeToDataset: ->
      self = @

      @listenTo(@dataset, 'dataColumn:destroyed dataColumn:created row:destroyed row:created data:changed', ->
        console.log 'spreadsheet reset'
        self.resetTable.call(self)
      )

    initHandlers: ->
      self = @

      @container.click (event) ->
        if self.container.find('.spreadsheet-header-input').length && event.target != self.container.find('.spreadsheet-header-input')[0]
          self.container.find('.spreadsheet-header-input').blur()

      @listenTo(@app, 'spreadsheet:load', (dataset) ->
        if dataset != self.dataset
          self.updateDataset.call(self, dataset)
      )

      @listenTo(@app, 'spreadsheet:unload', ->
        self.updateDataset.call(self, null)
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
            self.container.find("#title-input").blur ->
              self.container.find(".title-edit-icon").trigger 'click'
            self.container.find("#title-input").focus()
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
              height: Math.max(270, self.container.find('.SeeIt.Handsontable-Container').parent().height()),
              colWidths: ->
                (self.container.find('.SeeIt.Handsontable-Container').parent().width() - 50) / self.dataset.headers.length
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
      if !@dataset
        if @hot
          @hot.destroy()
          @hot = null

        return

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

            $(TH).off('dblclick', headerDblclick)

            input = document.createElement('input')
            input.type = 'text'
            input.value = TH.firstChild.textContent
            input.className = 'SeeIt spreadsheet-header-input'

            TH.appendChild(input)

            $(TH.firstChild).toggle()


            $(input).on 'focusout', (event) ->
              e = $.Event("keyup")
              e.which = 13
              e.keyCode = 13
              $(input).trigger e

            $(input).focus()

            $(input).keyup (event) ->
              $(input).focus()
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
                $(TH.firstChild).toggle()

                registerDblclick()
              return false


            return false


          registerDblclick = ->
            $(TH).off('dblclick').on('dblclick', headerDblclick)

          $(TH).off('dblclick').on('dblclick', headerDblclick)


        console.log privateMethods.formatModelData(), privateMethods.formatColumns()

      settings = {
        rowHeaders: @dataset.labels,
        colHeaders: @dataset.headers,
        data: privateMethods.formatModelData(),
        columns: privateMethods.formatColumns(),
        className: "SeeIt-htCenter",
        height: Math.max(270, spreadsheetView.container.find('.SeeIt.Handsontable-Container').parent().height()),
        colWidths: ->
          Math.max(
            (spreadsheetView.container.find('.SeeIt.Handsontable-Container').parent().width() - 50) / spreadsheetView.dataset.headers.length,
            50
          )
        stretchH: "all",
        renderAllRows: SeeIt.Utils.isMobile(),
        afterGetRowHeader: headerCallbackFactory("label"),
        afterGetColHeader: headerCallbackFactory("header")
        manualColumnResize: true,
        manualRowResize: true,
        copyPaste: true,
        maxCols: spreadsheetView.dataset.data.length,
        maxRows: spreadsheetView.dataset.data[0].data().length,
        beforeKeyDown: (event) ->
          if $(event.realTarget).hasClass('spreadsheet-header-input')
            event.stopImmediatePropagation()
            return false
        beforeOnCellMouseDown: (event, coords, TD) ->
          if (coords.row < 0 || coords.col < 0) && $(TD).find("input").length
            event.stopImmediatePropagation()
            event.preventDefault()
            return false
        contextMenu: if !spreadsheetView.dataset.editable then null else {
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
            },
            "change_col_type": {
              key: "change_col_type",
              name: "Change data type",
              "submenu": {
                items: [
                  {
                    key: "change_col_type:numeric"
                    name: "Numeric",
                    callback: (key, options) ->
                      spreadsheetView.dataset.trigger('dataColumn:type:change', options.end.col, "numeric", (success, msg) ->
                        spreadsheetView.displayTypeChangeMsg(options.end.col, success, msg)
                      )
                  },
                  {
                    key: "change_col_type:categorical",
                    name: "Categorical",
                    callback: (key, options) ->
                      spreadsheetView.dataset.trigger('dataColumn:type:change', options.end.col, "categorical", (success, msg) ->
                        spreadsheetView.displayTypeChangeMsg(options.end.col, success, msg)
                      )
                  }
                ]
              }
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

    displayTypeChangeMsg: (col, success, msg) ->
      $anchor = $(@container.find("th")[col])
      if success
        @hot.updateSettings({ columns: privateMethods.formatColumns() })

      setTimeout(->
          tip = new Opentip($anchor, msg, {style: (if success then "standard" else "alert"), target: $anchor, showOn: "creation"})
          tip.setTimeout(->
            tip.hide.call(tip)
            return
          , 5)
        , 100)        
      

    toggleVisible: ->
      @container.toggleClass('hidden')
      @visible = !@visible

  privateMethods = {
    formatColumns: ->
      columns = []

      for i in [0...privateMembers.dataset.data.length]
        column = {data: this.property(i), type: if privateMembers.dataset.data[i].type == "numeric" then "numeric" else "text"}
        if privateMembers.dataset.data[i].type == "numeric" then column.format = '0[.]00000'
        if !privateMembers.dataset.editable then column.editor = false
        columns.push(column)

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