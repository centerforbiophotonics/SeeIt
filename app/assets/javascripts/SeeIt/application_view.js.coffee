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
      @initHandlers()
      @resizeListener()

    ###*
     * [initLayout description]
     * @return {[type]} [description]
    ###
    initHandlers: ->
      self = @

      self.handlers = {
        dragEnterListener: (event) ->
          event.preventDefault()
          $(event.target).click()
          $("#id-graphs").css("background-color", "")

        triggerResize: (event) ->
          event.preventDefault()
          $(window).trigger 'resize'
      }

    initLayout: ->
      @container.html('<div class="SeeIt Globals"></div><div class="SeeIt container-fluid"><div class="SeeIt row">
          <div class="thisdiv">
            <ul class="nav nav-tabs device-small" role="tablist">
              <li class="tab-button active" id="id-data" role="presentation"><a href="#data_tab" aria-controls="data_tab" role="tab" data-toggle="tab">Data</a></li>
              <li class="tab-button" id="id-graphs" role="presentation"><a href="#graphs_tab" aria-controls="graphs_tab" role="tab" data-toggle="tab">Graphs</a></li>
              <li class="tab-button" id="id-spreadsheets"role="presentation"><a href="#spreadsheets_tab" aria-controls="spreadsheets_tab" role="tab" data-toggle="tab">Spreadsheet</a></li>
            </ul>

            <div class="tab-content"></div>
          </div>
        </div>
      </div>')
      @layoutContainers['Globals'] = @container.find(".Globals")

      @container.find('.tab-content').append("<div role='tabpanel' class='tab-pane SeeIt Data active' id='data_tab'></div>")
      @layoutContainers['Data'] = @container.find(".Data")
        
      @container.find('.tab-content').append("<div role='tabpanel' class='tab-pane SeeIt Spreadsheet pull-right' id='spreadsheets_tab'></div>")
      @layoutContainers['Spreadsheet'] = @container.find(".Spreadsheet")

      @container.find('.tab-content').append("<div role='tabpanel' class='tab-pane SeeIt Graphs' id='graphs_tab'></div>")
      @layoutContainers['Graphs'] = @container.find(".Graphs")

      if $(".Globals").width() < 1003
        $(".device-small").css("display", "block")

        $(".SeeIt.Data").addClass("col-md-12")
        $(".SeeIt.Graphs").addClass("col-md-12")
        $(".SeeIt.Spreadsheet").addClass("col-md-12")

      else
        $(".device-small").css("display", "none")
        $(".tab-content > .tab-pane").css("display", "block")

        $(".SeeIt.Data").addClass("col-md-3")
        $(".SeeIt.Graphs").addClass("col-md-9")
        $(".SeeIt.Spreadsheet").addClass("col-md-9")
        
      @container.find('.tab-button').off('dragenter').on('dragenter', @handlers.dragEnterListener)
      
      @container.find('#id-graphs').off('shown.bs.tab').on('shown.bs.tab', @handlers.triggerResize)
      @container.find('#id-spreadsheets').off('shown.bs.tab').on('shown.bs.tab', @handlers.triggerResize)
      @container.find('#id-data').off('shown.bs.tab').on('shown.bs.tab', @handlers.triggerResize)
      
      return @layoutContainers


    displayTabs: ->
      if $(".Globals").width() < 1003
        $(".device-small").css("display", "block")
        $(".tab-pane").css("display", "")

        $(".SeeIt.Data").removeClass("col-md-3")
        $(".SeeIt.Graphs").removeClass("col-md-9")
        $(".SeeIt.Spreadsheet").removeClass("col-md-9")
        $(".SeeIt.Data").addClass("col-md-12")
        $(".SeeIt.Graphs").addClass("col-md-12")
        $(".SeeIt.Spreadsheet").addClass("col-md-12")

      else if $(".Globals").width() >= 1003
        $(".device-small").css("display", "none")
        $(".tab-pane").css("display", "block")

        $(".SeeIt.Data").removeClass("col-md-12")
        $(".SeeIt.Graphs").removeClass("col-md-12")
        $(".SeeIt.Spreadsheet").removeClass("col-md-12")
        $(".SeeIt.Data").addClass("col-md-3")
        $(".SeeIt.Graphs").addClass("col-md-9")
        $(".SeeIt.Spreadsheet").addClass("col-md-9")

    resizeListener: ->
      self = @
      $(window).on 'resize', ->
        self.displayTabs()

  ApplicationView
).call(@)
