@SeeIt.Dataset = (->
  class Dataset
    constructor: (labels, dataset) ->
      @dataset = [new SeeIt.Data(labels[0], dataset[0])]
      console.log "dataset built"

  Dataset
).call(@)