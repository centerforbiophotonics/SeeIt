@SeeIt.ApplicationView = (->
  TAB_TRIGGER = false

  class ApplicationView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container) ->
      @layoutContainers = {}
      @initHandlers()
      @resizeListener()

    initHandlers: ->
      self = @

      self.handlers = {
        dragEnterListener: (event) ->
          event.preventDefault()
          $(event.target).click()

        resizeGraphs: (event) ->
          event.preventDefault()
          TAB_TRIGGER = true
          $(window).trigger 'resize'
          TAB_TRIGGER = false
      }

    initLayout: ->
      @container.html('<div class="SeeIt Globals"></div><div class="SeeIt container-fluid"><div class="SeeIt row">
          <div class="thisdiv">
            <ul class="nav nav-tabs device-small" role="tablist">
              <li class="tab active" id="id-data"role="presentation"><a href="#data_tab" aria-controls="data" role="tab" data-toggle="tab">Data</a></li>
              <li class="tab" id="id-graphs"role="presentation"><a href="#graphs_tab" aria-controls="data" role="tab" data-toggle="tab">Graphs</a></li>
              <li class="tab" id="id-graphs"role="presentation"><a href="#spreadsheets_tab" aria-controls="data" role="tab" data-toggle="tab">Spreadsheet</a></li>
            </ul>

            <div class="tab-content">
              <div role="tabpanel" class="tab-pane" id="spreadsheets_tab"></div>
              <div role="tabpanel" class="tab-pane active" id="data_tab"></div>
              <div role="tabpanel" class="tab-pane" id="graphs_tab"></div>
            </div>
          </div>
        </div>
      </div>')
      @layoutContainers['Globals'] = @container.find(".Globals")

      @container.find('#data_tab').append("<div class='SeeIt Data'></div>")
      @layoutContainers['Data'] = @container.find(".Data")
        
      @container.find('#spreadsheets_tab').append("<div class='SeeIt Spreadsheet pull-right'></div>")
      @layoutContainers['Spreadsheet'] = @container.find(".Spreadsheet")

      @container.find('#graphs_tab').append("<div class='SeeIt Graphs'></div>")
      @layoutContainers['Graphs'] = @container.find(".Graphs")

      if $(".Globals").width() < 1003
        $(".SeeIt.Data").addClass("col-md-12")
        $(".SeeIt.Graphs").addClass("col-md-12")
        $(".SeeIt.Spreadsheet").addClass("col-md-12")

      else
        $(".device-small").css("display","none")
        $(".tab-pane").addClass("active")
        $(".SeeIt.Data").addClass("col-md-3")
        $(".SeeIt.Graphs").addClass("col-md-9")
        $(".SeeIt.Spreadsheet").addClass("col-md-9")
        
      @container.find('.tab').off('dragenter').on('dragenter', @handlers.dragEnterListener)
      @container.find('a[data-toggle="tab"]').off('shown.bs.tab').on('shown.bs.tab', @handlers.resizeGraphs)

      return @layoutContainers


    displayTabs: (tab_trigger)->
      if $("#left-region").width() < 1003 && !tab_trigger
        $(".device-small").css("display","block")
        $(".tab-pane[id='graphs_tab']").removeClass("active")
        $(".tab-pane[id='spreadsheets_tab']").removeClass("active")
        
        $(".SeeIt.Data").removeClass("col-md-3")
        $(".SeeIt.Graphs").removeClass("col-md-9")
        $(".SeeIt.Spreadsheet").removeClass("col-md-9")
        $(".SeeIt.Data").addClass("col-md-12")
        $(".SeeIt.Graphs").addClass("col-md-12")
        $(".SeeIt.Spreadsheet").addClass("col-md-12")

      else if $("#left-region").width() >= 1003 && !tab_trigger
        $(".device-small").css("display","none")
        $(".tab-pane").addClass("active")

        $(".SeeIt.Data").removeClass("col-md-12")
        $(".SeeIt.Graphs").removeClass("col-md-12")
        $(".SeeIt.Spreadsheet").removeClass("col-md-12")
        $(".SeeIt.Data").addClass("col-md-3")
        $(".SeeIt.Graphs").addClass("col-md-9")
        $(".SeeIt.Spreadsheet").addClass("col-md-9")

    resizeListener: ->
      self = @
      $(window).on 'resize', ->
        self.displayTabs(TAB_TRIGGER)


  ApplicationView
).call(@)