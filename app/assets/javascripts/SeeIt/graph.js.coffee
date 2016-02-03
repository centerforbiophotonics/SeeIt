@SeeIt.Graph = (->
  class Graph
    _.extend(@prototype, Backbone.Events)

    constructor: (@container, @dataset, @chartObject) ->

    draw: ->
      #Abstract
      null

    destroy: ->
      #Abstract
      null


  Graph
).call(@)
console.log @SeeIt