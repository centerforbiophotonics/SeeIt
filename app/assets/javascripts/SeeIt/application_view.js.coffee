@SeeIt.ApplicationView = (->
  class ApplicationView
    _.extend(@prototype, Backbone.Events)

    constructor: (@app, @container) ->
      @layoutContainers = {}

    initLayout: ->
      @container.html('<div class="SeeIt Globals"></div><div class="SeeIt container-fluid"><div class="SeeIt row"></div></div>')
      @layoutContainers['Globals'] = @container.find(".Globals")

      @container.find('.row').append("<div class='SeeIt Data col-md-3'>hello</div>")
      @layoutContainers['Data'] = @container.find(".Data")
        
      @container.find('.row').append("<div class='SeeIt Spreadsheet col-md-9'></div>")
      @layoutContainers['Spreadsheet'] = @container.find(".Spreadsheet")

      @container.find('.row').append("<div class='SeeIt Graphs col-md-9'></div>")
      @layoutContainers['Graphs'] = @container.find(".Graphs")

      # window.onresize = (event) ->
      #   console.log $(".Globals").width()
      #   $(".SeeIt.navbar.navbar-default").hide()

      # else
      #   $("nav.navbar-nav").show()
          

        # # if $(".btn-group-vertical.dataset-view-group.SeeIt").width()
        # else 
        #   $(".Globals").show() 


      return @layoutContainers

  ApplicationView
).call(@)