@SeeIt.Graphs.BarChart = (->
  class BarChart extends SeeIt.Graph

    constructor: ->
      super
      @chartObject = null
      @listenerInitialized = false
      @rendered = false
      @initListeners()

    initListeners: ->
      self = @
      prevOptions = []
      
      @eventCallbacks['data:created'] =  (options) ->
        prevOptions = options
        
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
      @eventCallbacks['filter:changed'] = @eventCallbacks['data:created']

      for e, cb of @eventCallbacks
        @on e, cb

      $(window).on('resize', (event) ->
        self.eventCallbacks['data:created'](prevOptions)
      )


    clearGraph: ->
      @container.html("")
      @rendered = false

    formatData: ->
      data = []

      @dataset[0].data.forEach (dataColumn) ->
        data.push({values: dataColumn.data(), key: dataColumn.header, color: dataColumn.getColor()})

      return data

    refresh: (options) ->
      d3.select(@container.find('.graph-svg')[0]).datum(@formatData()).transition().duration(500).call(@chartObject);
      nv.utils.windowResize(@chartObject.update);

    draw: (options) ->
      self = @
      @container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")
          
      nv.addGraph ->
        chart = nv.models.multiBarChart()
            .x((d) -> d.label() )
            .y((d) -> d.value() )
        
        data = self.formatData.call(self)

        d3.select(self.container.find('.graph-svg')[0])
            .attr('height', '100%')
            .datum(data)
            .call(chart);

        nv.utils.windowResize(chart.update)
        self.chartObject = chart
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
      self = @

      [
        {
          label: "Test",
          type: "checkbox",
          default: true
        },
        {
          label: "Test 2",
          type: "numeric",
          default: 1
        },
        {
          label: "Test 3",
          type: "select",
          values: ->
            _.unique(_.flatten(self.dataset.map((role) ->
              role.data.map((d) -> d.data.labels) || []
            )))
          default: ->
            if this.values().length then this.values()[0] else null
        },
        {
          label: "Test 4",
          type: "checkbox",
          default: false
        }
      ]

  BarChart
).call(@)

@SeeIt.GraphNames["BarChart"] = "Bar Chart"