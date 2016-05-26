@SeeIt.DataCollectionView = (->
  class DataCollectionView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @data) ->
      @datasetViewCollection = []
      @init()
      @visible = true
      @

    init: ->
      @container.html("""
        <ul class="SeeIt dataset-list list-group">
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
        self.trigger('spreadsheet:load', dataset)
      )

      @listenTo(datasetView, 'graphs:requestIDs', (cb) ->
        self.trigger('graphs:requestIDs', cb)
      )

    newDatasetMaker: ->
      @container.find('.dataset-list').append("""
        <div class='SeeIt dataset-container new-dataset'>
          <li class="SeeIt list-group-item new-dataset-li">
            <a class="SeeIt" style="font-weight: bold">New Dataset</a>
            <span class='glyphicon glyphicon-plus' style='float: right;'></span>
          </li>
        </div>
        <div class="SeeIt new-dataset-form">
          <label for="dataset-select">How do you want to create the dataset?</label>
          <select class="form-control" id="dataset-select">
            <option value="spreadsheet">Fill out spreadsheet</option>
            <option value="google">Load from Google Spreadsheet</option>
          </select>
          <input type="text" placeholder="Dataset Title" class="form-control SeeIt new-dataset-input dataset-name">
          <input type="text" placeholder="Spreadsheet URL" class="form-control SeeIt new-dataset-input dataset-spreadsheet-url hidden">
          <span class="SeeIt new-dataset-msg"></span>
          <button type="button" class="btn btn-primary" id="create-dataset" style='width: 100%' 
                  data-loading-text="<span class='SeeIt glyphicon glyphicon-refresh spin'></span>">
            Create Dataset
          </button>
        </div>
      """)

      self = @
      self.container.find("#dataset-select").on "change", (event) ->
        self.container.find(".new-dataset-input").val("")
        self.container.find(".new-dataset-input").toggleClass("hidden")

      toggleForm = ->
        $(@).toggleClass('active')
        $(@).find('a').toggleClass('selected')
        $(@).parent().parent().find('.new-dataset-form').slideToggle()

      self.container.find(".new-dataset-li").on('click', toggleForm)

      self.container.find("#create-dataset").on 'click', (event) ->
        if self.container.find("#dataset-select").val() == "google"
          url = self.container.find('.dataset-spreadsheet-url').val()

          if url.length
            button = @
            $(button).button('loading')

            # window.onerror = ->
            #   console.log "old onerror callback!"

            oldOnError = window.onerror
            window.onerror = (message, source, lineno, colno, error) ->
              self.container.find(".new-dataset-msg").addClass("error").html("Error loading from spreadsheet")
              $(button).button('reset')
              self.container.find(".new-dataset-input").val("")
              self.container.find(".dataset-name").val("")

              setTimeout(->
                self.container.find(".new-dataset-msg").removeClass("error").html("")
              ,5000)

              #If onerror was previously defined, call it
              if oldOnError && typeof oldOnError == "function"
                oldOnError.apply(window, arguments)

            googleSpreadsheet = new SeeIt.GoogleSpreadsheetManager(self.container.find('.dataset-spreadsheet-url').val(), (collection) ->
              self.trigger('datasets:create', collection)
              $(button).button('reset')
              self.container.find(".new-dataset-input").val("")
              self.container.find(".dataset-name").val("")
              window.onerror = oldOnError
            )
            googleSpreadsheet.getData()

            setTimeout(->
              window.onerror = oldOnError
            ,2500)
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
        else
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

    validateTitle: (title) ->
      for i in [0...@data.datasets.length]
        if @data.datasets[i].title == title then return false

      return true

    initDatasetViewCollection: ->
      @newDatasetMaker()

      for i in [0...@data.datasets.length]
        @addDatasetView(@data.datasets[i])


    addDatasetView: (data) ->
      @container.find('.dataset-list .new-dataset').before("<div class='SeeIt dataset-container'></div>")
      datasetView = new SeeIt.DatasetView(@app, @container.find(".SeeIt.dataset-container:not(.new-dataset)").last(), data)
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