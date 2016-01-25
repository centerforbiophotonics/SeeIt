@SeeIt.Data = (->
  class Data
    _.extend(@prototype, Backbone.Events)
    
    constructor: (@container, @label, @data) ->
      @init()

    init: ->
      @container.html("<a class='SeeIt data'>#{@label}</a>")

  Data
).call(@)