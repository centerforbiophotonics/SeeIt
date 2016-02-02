@SeeIt.SpreadsheetView = (->
  class SpreadsheetView
    constructor: (@app, @container, @dataset) ->
      @visible = false

    toggleVisible: ->
      @container.toggleClass('hidden')
      @visible = !@visible
      
  SpreadsheetView
).call(@)