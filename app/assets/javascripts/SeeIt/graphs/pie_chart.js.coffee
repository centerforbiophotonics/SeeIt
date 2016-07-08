@SeeIt.Graphs.PieChart = (->
  class PieChart extends SeeIt.Graph

    constructor: ->
      super
      @chartObject = null
      @listenerInitialized = false
      @rendered = false
      @initListeners()

    initListeners: ->
      self = @

      @eventCallbacks['data:created'] = (options) ->
        if self.allRolesFilled()
          if !self.rendered
            self.rendered = true
            self.draw.call(self, options)
          else
            self.refresh.call(self, options)
        else
          self.clearGraph.call(self)

      @eventCallbacks['data:assigned'] = @eventCallbacks['data:created']
      @eventCallbacks['data:destroyed'] = @eventCallbacks['data:created']
      @eventCallbacks['column:destroyed'] = @eventCallbacks['data:created']
      @eventCallbacks['size:change'] = @eventCallbacks['data:created']
      @eventCallbacks['options:update'] = @eventCallbacks['data:created']
      @eventCallbacks['label:changed'] = @eventCallbacks['data:created']
      @eventCallbacks['header:changed'] = @eventCallbacks['data:created']
      @eventCallbacks['color:changed'] = @eventCallbacks['data:created']
      @eventCallbacks['data:changed'] = @eventCallbacks['data:created']

      for e, cb of @eventCallbacks
        @on e, cb

    formatData: ->
      data = []
      console.log "formatData:"
      console.log @dataset[0]

      @dataset[0].data.forEach (dataColumn) ->
        data = data.concat(dataColumn.data())
        data.forEach (d) ->
          if d.header == undefined
            d.header = dataColumn.header

      return data

    refresh: (options) ->
      @draw(options)

    clearGraph: ->
      @container.html('')
      @rendered = false

    draw: (options) ->
      console.log @dataset[0].data
      graph = @
      @container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")

      nv.addGraph ->
        data = graph.formatData.call(graph)

        #select a specific row
        if options[2].value
          data.forEach (d) ->
            if options[2].value == "default"
              d.disabled = false
            else
              if d.label() != options[2].value
                d.disabled = true
              else
                d.disabled = false

        #header option
        if !options[1].value
          chart = nv.models.pieChart()
            .x( (d) -> d.label())
            .y( (d) -> d.value())
            .showLabels(options[0].value)
        else
          chart = nv.models.pieChart()
            .x( (d) -> d.label() + "~" +d.header)
            .y( (d) -> d.value())
            .showLabels(options[0].value)

        console.log "data"
        console.log data

        d3.select(graph.container.find('.graph-svg')[0])
          .attr('height', '100%')
          .datum(data)
          .call(chart)

        nv.utils.windowResize(chart.update);
        graph.chartObject = chart
        return chart

    destroy: ->

    dataFormat: ->
      [
        {
          name: "default",
          type: "numeric",
          multiple: false
        }
      ]

    options: ->
      self = @
      [
        {
        	label: "Show/Hide Labels"
        	type: "checkbox"
        	default: true
        },
        {
          label: "Show/Hide Headers"
          type: "checkbox"
          default: false
        },
        {
          label: "Specific Row"
          type: "select"
          values: (->
            labels = ["default"]

            self.dataset[0].data.forEach (dataColumn) ->
              labels = labels.concat(dataColumn.data().map((d) -> d.label()))

            return labels
          )()
          default: null
        }
      ]

  PieChart
).call(@)

@SeeIt.GraphNames["PieChart"] = "Pie Chart"