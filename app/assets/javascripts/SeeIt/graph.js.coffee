@SeeIt.Graph = (->
  # This is the abstract class that all graph instances should inherit from.
  # The internal structure of the graph implementation is up to the implementer
  # other than that the graph must implement destroy, options, and dataFormat
  # methods (explained below).  The constructor will receive a jquery element 
  # (the element the graph should be contained in) and a data array that is 
  # shared with a class higher in the heirarchy. All interactions with the 
  # class other than calls to destroy, options, and dataFormat will be through
  # event triggers.  The event keys the scenarios that trigger them are 
  # explained below.  The proper way to register listeners to events is

  #         @listenTo('event_key', (arg1, arg2, ..., argn) ->
  #           #Do stuff
  #         )

  # 'label:changed' - 
  #   One or more of data points in a DataColumn referenced
  #   in the graph have had their labels changed

  # 'color:changed' - 
  #   One or more of the data points in a DataColumn referenced
  #   in the graph have had their colors changed

  # 'header:changed' - 
  #   One or more of the DataColumns referenced in the graph
  #   have had their header changed

  # 'data:created' -
  #   One or more of the DataColumns referenced in the graph
  #   have had a data point added

  # 'data:destroyed' - 
  #   One or more of the DataColumns referenced in the graph
  #   have had a data point added

  # 'column:destroyed' - 
  #   One or more of the DataColumns referenced in the graph
  #   have been removed/destroyed

  # 'size:change' - 
  #   Size of the container has changed

  # 'options:update' - 
  #   One or more of the graph's options have been changed  

  # 'data:assigned' - 
  #   A new DataColumn has been assigned to the graph

  # 'data:changed' -
  #   One or more data point in a DataColumn referenced in
  #   the graph has been changed

  # 'filter:changed' -
  #   One or more filters were changed or assigned to the
  #   FilteredColumns referenced by the graph

  # ^EACH HANDLER IS PASSED THE CURRENT GRAPH OPTIONS AS AN ARGUMENT
  # The only event that a graph may need to handle on its own is 
  # window resize
  class Graph
    _.extend(@prototype, Backbone.Events)

    constructor: (@container, @dataset) ->
      self = @
      # Data is to be an array of data-role objects.  DataColumns are
      # assigned to particular data-roles.  Name is the role name,
      # type defines the data to be numeric or categorical, multiple
      # specifies whether mutiple DataColumns can be assigned to the
      # role at a time, and data is an array of FilteredColumns.
      # FilteredColumns should behave the same as DataColumns,
      # only differing in data contents when filters are assigned to a graph.
      if !@dataset.length
        @dataFormat().forEach (d) ->
          self.dataset.push({
            name: d.name,
            type: d.type,
            multiple: d.multiple,
            data: []
          })

      #Events that listeners can be registered for
      @eventCallbacks = {
        'label:changed': null
        'color:changed': null,
        'header:changed': null,
        'data:created': null,
        'data:destroyed': null,
        'column:destroyed': null,
        'size:change': null,
        'options:update': null,
        'data:assigned': null,
        'data:changed': null,
        'filter:changed': null
      }


    # Verifies that all roles in graph have been filled
    allRolesFilled: ->
      rolesFilled = true
      @dataset.forEach (data) ->
        rolesFilled = rolesFilled && data.data.length

      return rolesFilled

    #destroy is supposed to implement any necessary cleanup that
    #needs to be done before a graph is destroyed (optional)
    destroy: ->
      #Abstract
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
      []

    #options should specify the editable options of a graph
    # It should return an array of json objects of the form:
    # {
    #   type: "checkbox" OR "select" OR "numeric", 
    #   label: any string,
    #   values: array of numbers or strings (only used in select),
    #   default: default value of corresponding form element. Should be
    #     true or false for checkbox, a number for numeric, or one of the values
    #     specified in 'values' for select
    # }
    options: ->
      #Abstract
      []

  Graph
).call(@)