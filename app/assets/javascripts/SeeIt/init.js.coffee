@SeeIt = {}
@SeeIt.Modules = {}
@SeeIt.Graphs = {}
@SeeIt.GraphNames = {}
appContext = @

@SeeIt.new = (container) ->
  return new appContext.SeeIt.ApplicationController(container)