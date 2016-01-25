@SeeIt.DataModel = (->
  class DataModel
    _.extend(@prototype, Backbone.Events)
    @Validators = {}
    _.extend(@Validators, @SeeIt.Modules.Validators)

    constructor: (data) ->
      @loadData(data)

    loadData: (data) ->
      if DataModel.validateData(data)
        @data = data
        @trigger("data:loaded")
      else
        alert "Error: Invalid data format"


    @validateData: (data) ->
      valid = true

      for key in @Validators
        valid = valid && @Validators[key]

      return valid

  DataModel
).call(@)