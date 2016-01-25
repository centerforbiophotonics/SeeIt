@SeeIt.DataMenu = (->
  class DataMenu
    _.extend(@prototype, Backbone.Events)
    
    constructor: (@container, @data) ->
      @datasets = []
      @init()
      @visible = true

    init: ->
      @container.html("""
        <ul class="SeeIt dataset-list list-group">
        </ul>
      """)

      @initDatasets()

    initDatasets: ->
      for i in [0...@data.length]
        @addDataset(@data[i].title, @data[i].dataset, @data[i].hasLabels)

    addDataset: (title, dataset, hasLabels) ->
      if SeeIt.Dataset.validateData(dataset)
        @container.find('.dataset-list').append("<div class='SeeIt dataset-container'></div>")
        @datasets.push(new SeeIt.Dataset(@container.find(".SeeIt.dataset-container").last(),"Dataset 1", dataset, hasLabels))


    toggleVisible: ->
      @container.toggle()
      @visible = !@visible

  DataMenu
).call(@)