@SeeIt.Graph = (->
  class Graph
    _.extend(@prototype, Backbone.Events)

    constructor: (@container, @dataset, @chartObject) ->
      self = @

      @dataFormat().forEach (d) ->
        self.dataset.push({
          name: d.name,
          type: d.type,
          multiple: d.multipe,
          data: []
        })

    #draw is supposed to render the visualization in the given container
    #It is called once at least one DataColumn has been assigned to 
    #each data role
    # options is an array of objects of the form {label: "string", value: number, string, or boolean}
    # and specifies the current values of the options in the form created from options()
    draw: (options) ->
      #Abstract
      null

    #destroy is supposed to implement any necessary cleanup that
    #needs to be done before a graph is destroyed (optional)
    destroy: ->
      #Abstract
      null

    #refresh is supposed to re-render the visualization
    #It is called when changes are made to the data, labels,
    #or headers used in the graph
    # options is an array of objects of the form {label: "string", value: number, string, or boolean}
    # and specifies the current values of the options in the form created from options()
    refresh: (options) ->
      null


    #dataFormat should return an array of objects specifying the format
    # of the data.  Example:
    # [
    #   {
    #     name: "x-axis",
    #     type: "numeric",
    #     multiple: true
    #   },
    #   {
    #     name: "y-axis",
    #     type: "numeric",
    #     multiple: true
    #   }
    # ]
    # "name" specifies a data-role, type should be either "numeric" or "categorical" and 
    # specifies whether the data is numerical or categorical, and multiple specifies whether
    # multiple DataColumns can be groupec together in that role
    # ***************** Only numeric data is supported at this time ************
    dataFormat: ->
      #Abstract
      null

    #options should specify 
    options: ->
      #Abstract
      null


  Graph
).call(@)
console.log @SeeIt