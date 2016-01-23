@SeeIt.Dataset = (->
  class Dataset
    constructor: (labels, dataset) ->
      @dataset = [new SeeIt.Data(labels[0], dataset[0])]
      console.log "dataset built"

    #Static method that validates data format
    @validateData: (data) ->
      if $.isArray(data)
        for i in [0...data.length]
          

  Dataset
).call(@)