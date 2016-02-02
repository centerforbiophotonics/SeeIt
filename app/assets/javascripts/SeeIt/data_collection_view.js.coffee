@SeeIt.DataCollectionView = (->
  class DataCollectionView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @data) ->
      @datasetViewCollection = []
      @init()
      @visible = true

    init: ->
      @container.html("""
        <ul class="SeeIt dataset-list list-group">
        </ul>
      """)

      @initDatasetViewCollection()

    initDatasetViewCollection: ->
      for i in [0...@data.datasets.length]
        @addDatasetView(@data.datasets[i])

    addDatasetView: (data) ->
      @container.find('.dataset-list').append("<div class='SeeIt dataset-container'></div>")
      @datasetViewCollection.push(new SeeIt.DatasetView(@app, @container.find(".SeeIt.dataset-container").last(), data))


    toggleVisible: ->
      @container.toggle()
      @visible = !@visible

  DataCollectionView
).call(@)