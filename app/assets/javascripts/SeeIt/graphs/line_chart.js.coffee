@SeeIt.Graphs.LineChart = (->
  class LineChart extends SeeIt.Graph

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
      retdata = []
      groups = {}
      
      @dataset[0].data.forEach (dataColumn) -> #for each dataColumn in the default part of dataset
        vals =[]
        dataColumn.data().forEach (d) -> #for each row in the column
          vals.push({x: d.label(), y: d.value()})
          
        retdata.push({values: vals, key: dataColumn.header, color: dataColumn.getColor()})

      return retdata

    refresh: (options) ->
      #d3.select(@container.find('.graph-svg')[0]).datum(@formatData()).transition().duration(500).call(@chartObject);
      #nv.utils.windowResize(@chartObject.update);
      @draw(options)

    draw: (options) ->
      graph = @
      @container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")

      nv.addGraph ->
        chart = nv.models.lineChart()
                  .margin({left: 100, top: 100})  
                  .useInteractiveGuideline(true)   
                  .showLegend(true)       
                  .showYAxis(true)       
                  .showXAxis(true)        

        data = graph.formatData.call(graph)
        #data = graph.exampleData.call(graph)

        d3.select(graph.container.find('.graph-svg')[0])
          .attr('height', '100%')
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

  LineChart
).call(@)

@SeeIt.GraphNames["LineChart"] = "Line Chart"