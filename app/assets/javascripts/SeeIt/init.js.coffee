@SeeIt = {}
@SeeIt.Modules = {}
appContext = @

@SeeIt.new = (container) ->
  return new appContext.SeeIt.ApplicationController(container)