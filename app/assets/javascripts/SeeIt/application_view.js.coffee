@SeeIt.ApplicationView = (->
  class ApplicationView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container) ->
      @layoutContainers = {}

    initLayout: ->
      @container.html('<div class="SeeIt Globals"></div><div class="SeeIt container-fluid"><div class="SeeIt row"></div></div>')
      @layoutContainers['Globals'] = @container.find(".Globals")

      @container.find('.row').append("<div class='SeeIt Data col-md-2'></div>")
      @layoutContainers['Data'] = @container.find(".Data")
        
      @container.find('.row').append("<div class='SeeIt Spreadsheet hidden col-md-10'></div>")
      @layoutContainers['Spreadsheet'] = @container.find(".Spreadsheet")

      @container.find('.row').append("<div class='SeeIt Graphs col-md-10'></div>")
      @layoutContainers['Graphs'] = @container.find(".Graphs")

      return @layoutContainers

  ApplicationView
).call(@)