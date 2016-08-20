@SeeIt.ApplicationView = (->
  class ApplicationView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container) ->
      @layoutContainers = {}
      @initHandlers()

    initHandlers: ->
      self = @

      self.handlers = {
        dragEnterListener: (event) ->
          console.log "enter"
          $(event.target).click()
      }

    initLayout: ->
      @container.html('<div class="SeeIt Globals"></div><div class="SeeIt container-fluid"><div class="SeeIt row">
          <div class="thisdiv">
          <ul class="nav nav-tabs device-small" role="tablist">
            <li class="tab" role="presentation"><a href="#data" aria-controls="data" class="active" role="tab" data-toggle="tab">Data</a></li>
            <li class="tab" role="presentation"><a href="#graphs" aria-controls="data" role="tab" data-toggle="tab">Graphs</a></li>
          </ul>

          <div class="tab-content">
            <div role="tabpanel" class="tab-pane active" id="data"></div>
            <div role="tabpanel" class="tab-pane active" id="graphs"></div>
          </div>
          </div>
        </div>
      </div>')
      @layoutContainers['Globals'] = @container.find(".Globals")

      @container.find('#data').append("<div class='SeeIt Data'></div>")
      @layoutContainers['Data'] = @container.find(".Data")
        
      @container.find('.row').append("<div class='SeeIt Spreadsheet col-md-9'></div>")
      @layoutContainers['Spreadsheet'] = @container.find(".Spreadsheet")

      @container.find('#graphs').append("<div class='SeeIt Graphs'></div>")
      @layoutContainers['Graphs'] = @container.find(".Graphs")

      if $(".Globals").width() < 1003
        $(".SeeIt.Data").addClass("col-md-12")
        $(".SeeIt.Graphs").addClass("col-md-12")
      else
        $(".SeeIt.Data").addClass("col-md-3")
        $(".SeeIt.Graphs").addClass("col-md-9")

      @container.find('.tab').off('dragenter').on('dragenter', @handlers.dragEnterListener)

      return @layoutContainers

  ApplicationView
).call(@)