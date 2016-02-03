@SeeIt = {}
@SeeIt.Modules = {}
@SeeIt.Graphs = {}
appContext = @

@SeeIt.new = (container) ->
  return new appContext.SeeIt.ApplicationController(container)