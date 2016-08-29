@SeeIt.ApplicationView = (->
  class ApplicationView
    _.extend(@prototype, Backbone.Events)

    ###*
     * [constructor description]
     * @class
     * @param  {[type]} @app       [description]
     * @param  {[type]} @container [description]
     * @return {[type]}            [description]
    ###
    constructor: (@app, @container) ->
      @layoutContainers = {}

    ###*
     * [initLayout description]
     * @return {[type]} [description]
    ###
    initLayout: ->
      @container.html('<div class="SeeIt Globals"></div><div class="SeeIt container-fluid"><div class="SeeIt row"></div></div>')
      @layoutContainers['Globals'] = @container.find(".Globals")

      @container.find('.row').append("<div class='SeeIt Data col-md-3'></div>")
      @layoutContainers['Data'] = @container.find(".Data")

      @container.find('.row').append("<div class='SeeIt Spreadsheet col-md-9'></div>")
      @layoutContainers['Spreadsheet'] = @container.find(".Spreadsheet")

      @container.find('.row').append("<div class='SeeIt Graphs col-md-9'></div>")
      @layoutContainers['Graphs'] = @container.find(".Graphs")

      return @layoutContainers

  ApplicationView
).call(@)
