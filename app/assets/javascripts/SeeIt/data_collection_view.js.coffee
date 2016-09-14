@SeeIt.DataCollectionView = (->
  class DataCollectionView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @data) ->
      @datasetViewCollection = []
      @init()
      @visible = true
      @dataLoadingMsg = new Opentip(
        @container, '', "Loading",
        {
          showOn: null,
          style:"glass",
          stem: false,
          target:@app.container,
          tipJoint:"center",
          targetJoint: "center",
          showEffectDuration: 0,
          showEffect: "none"
        }
      )

    init: ->
      @container.html("""
        <ul class="SeeIt dataset-list list-group">
          <div class="SeeIt panel-heading">  
            <label id="upload_modal" class="btn btn-primary btn-file SeeIt new-dataset-input">
              <span class='glyphicon glyphicon-upload' style=""></span>
                Upload Data
            </label>
            <button class="SeeIt hide_data btn btn-default" title='Hide Data' style="float:right"><span class="glyphicon glyphicon-arrow-left"></span></button>  
          </div>
        </ul>
      """)

      @initListeners()
      @initDatasetViewCollection()

    initListeners: ->
      self = @

      @listenTo(@app, 'dataset:created', (dataset) ->
        datasetView = self.addDatasetView.call(self, dataset)
        # datasetView.trigger('datasetview:open')
      )

      @listenTo(@app, 'graph:created', (graphId, dataRoles) ->
        self.datasetViewCollection.forEach (d) ->
          d.trigger('graph:created', graphId, dataRoles)
      )

      @listenTo(@app, 'graph:destroyed', (graphId) ->
        self.datasetViewCollection.forEach (d) ->
          d.trigger('graph:destroyed', graphId)
      )

      @listenTo(@app, 'graph:id:change', (oldId, newId) ->
        self.datasetViewCollection.forEach (d) ->
          d.trigger('graph:id:change', oldId, newId)
      )

    initDatasetListeners: (datasetView) ->
      self = @

      @listenTo(datasetView, 'spreadsheet:load', (dataset) ->
        self.datasetViewCollection.forEach (d) ->
          if d != datasetView
            d.trigger('spreadsheet:unloaded')

        self.trigger('spreadsheet:load', dataset)
      )

      @listenTo(datasetView, 'spreadsheet:unload', ->
        self.trigger('spreadsheet:unload')
      )

      @listenTo(datasetView, 'graphs:requestIDs', (cb) ->
        self.trigger('graphs:requestIDs', cb)
      )

    initHandlers: ->
      self = @
      self.handlers = {
        dragStartListener: (event) ->
          event.originalEvent.dataTransfer.setData("text", event.target.id)
          event.originalEvent.dataTransfer.setData("datasetName", $(this).attr('name'))
          $(".data-drop-zone").css("background-color", "#FFAFAF")
          $("#id-graphs").css("background-color", "#FFAFAF")

        dragEndListener: (event) ->
          event.preventDefault()
          $(".data-drop-zone").css("background-color", "")
          $("#id-graphs").css("background-color", "")
      }

    newDatasetMaker: ->
      @container.find('.dataset-list').append("""
        <div class='SeeIt dataset-container new-dataset'>
        </div>
      """)

      @container.find('.dataset-list').append("""
        <div id="newdata_modal" class="modal fade">
          <div class="modal-dialog modal-sm">
              <div class="modal-content">
                <div class="modal-header">
                  <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                  <h4 class="modal-title">How do you want to create the dataset?</h4>
                </div>
                <div class="modal-header">
                  <select class="form-control" id="dataset-select">
                    <option value="spreadsheet">Fill out spreadsheet</option>
                    <option value="google">Load from Google Spreadsheet</option>
                    <option value="json-endpoint">Load from JSON endpoint</option>
                    <option value="json-file">Load from JSON file</option>
                    <option value="csv-endpoint">Load from CSV endpoint</option>
                    <option value="csv-file">Load from CSV file</option>
                  </select>
                </div>
                <div class="modal-header">
                  <input type="text" placeholder="Dataset Title" class="form-control SeeIt new-dataset-input dataset-name spreadsheet">
                  <input type="text" placeholder="Spreadsheet URL" class="form-control SeeIt new-dataset-input dataset-spreadsheet-url hidden google">
                  <input type="text" placeholder="JSON URL" class="form-control SeeIt new-dataset-input dataset-json-url hidden json-endpoint">
                  <input type="text" placeholder="CSV URL" class="form-control SeeIt new-dataset-input dataset-csv-url hidden csv-endpoint">
                  <span class="SeeIt new-dataset-msg"></span>
                </div>
                <div class="modal-footer">
                  <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                  <button type="button" class="SeeIt btn btn-primary" id="create-dataset" data-loading-text="<span class='SeeIt glyphicon glyphicon-refresh spin'></span>">
                    Create Dataset
                  </button>
                  <label class="btn btn-primary btn-file SeeIt new-dataset-input dataset-json-file hidden json-file">
                    <span class='glyphicon glyphicon-upload'></span>
                    Select JSON file <input type="file" class="form-control SeeIt" style='display: none'>
                  </label>
                  <label class="btn btn-primary btn-file SeeIt new-dataset-input dataset-json-file hidden csv-file">
                    <span class='glyphicon glyphicon-upload'></span>
                    Select CSV file <input type="file" placeholder="CSV File" class="form-control SeeIt" style='display: none'>
                  </label>
                </div>
              </div>
          </div>
        </div>
      """)

      self = @
      self.container.find("#dataset-select").on "change", (event) ->
        self.container.find("#create-dataset").show()

        if $(@).val() == "json-file" || $(@).val() == "csv-file"
          self.container.find("#create-dataset").hide()

        selected = self.container.find("#dataset-select").val()
        self.container.find(".new-dataset-input").val("")
        self.container.find(".new-dataset-input:not(.#{selected})").addClass("hidden")
        self.container.find(".#{selected}").removeClass("hidden")
        self.container.find("#upload_modal").removeClass("hidden")

      toggleForm = ->
        $(@).toggleClass('active')
        $(@).find('a').toggleClass('selected')
        $(@).parent().parent().find('.new-dataset-form').slideToggle()

      $(document).off("keypress").on("keypress", ":input:not(textarea)", (e) ->
        selected = self.container.find("#dataset-select").val()
        if e.keyCode == 13 && (selected != 'json-file' || selected != 'csv-file')
          e.preventDefault()
          $('#create-dataset').click()
      );

      self.container.find('.hide_data').on 'click', () ->
        self.app.handlers.toggleDataVisible()

      self.container.find("#create-dataset").on 'click', (event) ->
        $('#newdata_modal').modal('hide')
        return self.handleDatasetCreate.call(self, self.container.find("#dataset-select").val())

      self.container.find(".json-file input, .csv-file input").on 'change', (event) ->
        return self.handleDatasetCreate.call(self, self.container.find("#dataset-select").val(), {file: @files[0]})

      self.container.find("#upload_modal").on 'click', (e) ->
        $('#newdata_modal').modal('show')

      $(".json-file, .csv-file").on "click", () ->
        $('#newdata_modal').modal('hide')

      $('#newdata_modal').on('shown.bs.modal', () ->
        $(this).find('input:text').first().focus()
      );

    handleDatasetCreate: (selected, data = {}) ->
      self = @

      switch selected
        when "google"
          url = self.container.find('.dataset-spreadsheet-url').val()

          if url.length
            button = self.container.find("#create-dataset")[0]
            $(button).button('loading')

            googleSpreadsheet = new SeeIt.GoogleSpreadsheetManager(self.container.find('.dataset-spreadsheet-url').val(), (success, collection) ->
              if success
                self.trigger('datasets:create', collection)
                $(button).button('reset')
                self.container.find(".new-dataset-input").val("")
                self.container.find(".dataset-name").val("")
                # window.onerror = oldOnError
              else
                self.container.find(".new-dataset-msg").addClass("error").html("Error loading from spreadsheet")
                $(button).button('reset')
                self.container.find(".new-dataset-input").val("")
                self.container.find(".dataset-name").val("")

                setTimeout(->
                  self.container.find(".new-dataset-msg").removeClass("error").html("")
                ,5000)
            )
            googleSpreadsheet.getData()

          else
            self.container.find('.dataset-spreadsheet-url').val("")
            msg = "URL cannot be blank"
            tip = new Opentip($(this), msg, {style: "alert", target: self.container.find(".dataset-spreadsheet-url"), showOn: "creation"})
            tip.setTimeout(->
              tip.hide.call(tip)
              return
            , 5)
            return false

          return false
        when "spreadsheet"
          title = self.container.find(".dataset-name").val()
          if title.length && self.validateTitle.call(self, title)
            self.container.find(".new-dataset-input").val("")
            self.container.find(".new-dataset-li").trigger('click')
            self.trigger("dataset:create", title)
          else
            self.container.find(".dataset-name").val("")
            msg = if title.length then "Title must be unique" else "Title cannot be blank"
            tip = new Opentip($(this), msg, {style: "alert", target: self.container.find(".dataset-name"), showOn: "creation"})
            tip.setTimeout(->
              tip.hide.call(tip)
              return
            , 5)
            return false
        when "json-endpoint"
          json_manager = new SeeIt.JsonManager()
          button = self.container.find("#create-dataset")[0]
          $(button).button('loading')

          error_cb = ->
            self.container.find(".new-dataset-msg").addClass("error").html("Error loading JSON")
            self.container.find(".new-dataset-input").val("")

            setTimeout(->
              self.container.find(".new-dataset-msg").removeClass("error").html("")
            ,5000)

            $(button).button('reset')

          try
            json_manager.downloadFromServer(self.container.find(".json-endpoint").val(),
              ((data) ->
                self.trigger 'datasets:create', [data]
                $(button).button('reset')
              ),
              error_cb
            )
          catch error
            error_cb()

          self.container.find(".json-endpoint").val("")
        when "json-file"
          json_manager = new SeeIt.JsonManager()
          self.dataLoadingMsg.show()
          json_manager.handleUpload(data.file, (d) ->
            self.trigger 'datasets:create', d
            self.dataLoadingMsg.hide()
          )
        when "csv-endpoint"
          csv_manager = new SeeIt.CSVManager()
          button = self.container.find("#create-dataset")[0]
          $(button).button('loading')

          error_cb = ->
            self.container.find(".new-dataset-msg").addClass("error").html("Error loading CSV")
            self.container.find(".new-dataset-input").val("")

            setTimeout(->
              self.container.find(".new-dataset-msg").removeClass("error").html("")
            ,5000)

            $(button).button('reset')

          try
            csv_manager.downloadFromServer(self.container.find(".csv-endpoint").val(),
              ((data) ->

                csvData = SeeIt.CSVManager.parseCSV(data.data)

                dataset = {
                  isLabeled: true,
                  title: data.name,
                  dataset: csvData
                }

                self.trigger 'datasets:create', [dataset]
                $(button).button('reset')
              ),
              error_cb
            )
          catch error
            error_cb()


          self.container.find(".csv-endpoint").val("")
        when "csv-file"
          csv_manager = new SeeIt.CSVManager()
          filename = data.file.name.split('.')[0]
          self.dataLoadingMsg.show()
          csv_manager.handleUpload(data.file, (d) ->
            self.trigger 'datasets:create', [{isLabeled: true, title: filename, dataset: d}]
            self.dataLoadingMsg.hide()
          )

    validateTitle: (title) ->
      for i in [0...@data.datasets.length]
        if @data.datasets[i].title == title then return false

      return true

    initDatasetViewCollection: ->
      @newDatasetMaker()

      if !@app.ui.dataset_add_remove
        $('.new-dataset').addClass("hidden")
        $('.new-dataset-form').addClass("hidden")

      for i in [0...@data.datasets.length]
        @addDatasetView(@data.datasets[i])

    addDatasetView: (data) ->
      @container.find('.dataset-list .new-dataset').before("<div class='SeeIt dataset-container'></div>")
      datasetView = new SeeIt.DatasetView(@app, @container.find(".SeeIt.dataset-container:not(.new-dataset)").last(), data)
      @initHandlers()
      @container.find('.source').off('dragstart').on('dragstart', @handlers.dragStartListener)
      @container.find('.source').off('dragend').on('dragend', @handlers.dragEndListener)
      @initDatasetListeners(datasetView)
      datasetView.trigger('populate:dropdowns')
      @datasetViewCollection.push(datasetView)

      self = @
      @listenTo(datasetView, 'graph:addData', (graphData) ->
        self.trigger('graph:addData', graphData)
      )

      return datasetView

    toggleVisible: ->
      @container.toggle()
      @visible = !@visible

  DataCollectionView
).call(@)
