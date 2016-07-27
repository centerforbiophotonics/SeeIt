@SeeIt.Graphs.StackedAreaChart = (->
  class StackedAreaChart extends SeeIt.Graph

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
      @eventCallbacks['filter:changed'] = @eventCallbacks['data:created']

      for e, cb of @eventCallbacks
        @on e, cb

    formatData: ->
      data = []
      console.log "formatData:"
      console.log @dataset[0]

      @dataset[0].data.forEach (dataColumn) ->
        each1 = []
        dataColumn.data().forEach (d) ->
          each2 = []
          each2.push(d.label())
          each2.push(d.value())
          each1.push(each2)
        data.push({values:each1, key:dataColumn.header}) 

      return data

    refresh: (options) ->
      @draw(options)

    draw: (options) ->
      self = @
      @container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")

      nv.addGraph ->
        data = self.formatData.call(self)
        console.log data

        chart = nv.models.stackedAreaChart()
                  .margin({right: 100})
                  .x( (d) -> d[0])   
                  .y( (d) -> d[1])  
                  .useInteractiveGuideline(true)  
                  .rightAlignYAxis(true)      
                  .showControls(true)       
                  .clipEdge(true)

        chart.xAxis
            .tickFormat( (d) -> d)         

        chart.yAxis
            .tickFormat(d3.format(',.2f'))

        d3.select(self.container.find('.graph-svg')[0])
          .attr('height', '100%')
          .datum(data)
          .call(chart)


        nv.utils.windowResize(chart.update);
        self.chartObject = chart
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

  StackedAreaChart
).call(@)

@SeeIt.GraphNames["StackedAreaChart"] = "Stacked Area Chart"