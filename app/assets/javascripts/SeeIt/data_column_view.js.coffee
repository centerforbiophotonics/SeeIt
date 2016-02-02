@SeeIt.DataColumnView = (->
  class DataColumnView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container, @data) ->
      @init()

    init: ->
      @container.html("<a class='SeeIt data'>#{@data.header}</a>")

  DataColumnView
).call(@)