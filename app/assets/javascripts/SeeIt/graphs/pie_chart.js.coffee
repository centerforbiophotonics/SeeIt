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
            self.draw.call(self, options)

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
      
      @dataset[0].data.forEach (dataColumn) ->
        data = data.concat(dataColumn.data())
        #data.push({values: dataColumn.data(), key: dataColumn.header, color: dataColumn.color})

      return data

    refresh: (options) ->
      d3.select(@container.find('.graph-svg')[0]).datum(@formatData()).transition().duration(500).call(@chartObject);
      nv.utils.windowResize(@chartObject.update);

    draw: (options) ->
      console.log @dataset[0].data
      graph = @
      @container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")
      console.log options[0].value

      nv.addGraph ->
        chart = nv.models.pieChart()
          .x( (d) -> return d.label())
          .y( (d) -> return d.value())
          .showLabels(options[0].value);

        data = graph.formatData.call(graph)
        #data = graph.exampleData.call(graph)

        d3.select(graph.container.find('.graph-svg')[0])
          .attr('height', '50%')
          .datum(data)
          #.transition().duration(350)
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
          multiple: true
        }
      ]

    options: ->
      [
        {
        	label: "Show/Hide Labels"
        	type: "checkbox"
        	default: true
        }
      ]

  PieChart
).call(@)

@SeeIt.GraphNames["PieChart"] = "Pie Chart"