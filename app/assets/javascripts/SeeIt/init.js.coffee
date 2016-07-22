@SeeIt = {}
@SeeIt.Modules = {}
@SeeIt.Graphs = {}
@SeeIt.GraphNames = {}
@SeeIt.ColorPalette ={}
appContext = @

@SeeIt.new = (container) ->
  return new appContext.SeeIt.ApplicationController(container)