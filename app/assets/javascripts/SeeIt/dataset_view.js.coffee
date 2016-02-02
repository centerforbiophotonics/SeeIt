@SeeIt.DatasetView = (->
  class DatasetView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @dataset) ->
      @dataColumnViews = []
      @initLayout()

    initLayout: ->
      @container.html("""
        <li class="SeeIt dataset list-group-item">
          <a class="SeeIt">#{@dataset.title}</a>
        </li>
        <div class="SeeIt data-columns list-group-item" style="padding: 5px; display: none">
          <ul class='SeeIt list-group data-list'>
          </ul>
        </div>
      """)

      @initDataColumnViews()
      @registerEvents()


    initDataColumnViews: ->
      for i in [0...@dataset.data.length]
        @addData(@dataset.data[i])

    addData: (dataColumn) ->
      @container.find(".data-list").append("<li class='SeeIt list-group-item data-container'></li>")
      @dataColumnViews.push(new SeeIt.DataColumnView(@app, @container.find(".data-container").last(), dataColumn))

    registerEvents: ->
      toggleData = ->
        $(@).toggleClass('active')
        $(@).find('a').toggleClass('selected')
        $(@).parent().find('.data-columns').slideToggle()


      @container.find('.dataset').off('click', toggleData).on('click', toggleData)

  DatasetView
).call(@)