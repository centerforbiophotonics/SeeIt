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
      prevOptions = []
      
      @eventCallbacks['data:created'] = (options) ->
        prevOptions = options
        
        if self.allRolesFilled()
          if !self.rendered
            self.rendered = true
            self.draw.call(self, options)
          else
            self.refresh.call(self, options)
        else
          self.container.html("")

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

      $(window).on('resize', (event) ->
        self.eventCallbacks['data:created'](prevOptions)
      )


    formatData: ->
      data = []

      # clear previous data
      if @dataset[0].data.length > 1 
        @dataset[0].data.splice(0,1)

      @dataset[0].data.forEach (dataColumn) ->
        data = dataColumn.data()
        data.forEach (d) ->
          if d.header == undefined
            d.header = dataColumn.header

      return data

    refresh: (options) ->
      @container.html("")
      @draw(options)

    clearGraph: ->
      @container.html('')
      @rendered = false

    draw: (options) ->
      type = @dataset[0].data[@dataset[0].data.length-1].type
      self = @
      @container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")

      nv.addGraph ->
        data = self.formatData.call(self)

        if type == "numeric"
          chart = nv.models.pieChart()
            .x( (d) -> d.label())
            .y( (d) -> d.value())
            .showLabels(options[0].value)

        else
          counts = []
          data.forEach (d) ->
            if !counts[d.value()]
              counts[d.value()] = 0
            counts[d.value()]++

          dat = []
          Object.keys(counts).forEach (key) ->
            dat.push
              label: key,
              count: counts[key]

          total = 0
          dat.forEach (d) ->
            total += d.count

          chart = nv.models.pieChart()
            .x( (d) -> d.label)
            .y( (d) -> d.count/total * 100)
            .valueFormat(d3.format(".0f"))
            .showLabels(options[0].value)
          data = dat

        d3.select(self.container.find('.graph-svg')[0])
        .attr('height', '100%')
        .data([data])
        .call(chart)

        nv.utils.windowResize(chart.update);
        self.chartObject = chart
        return chart

    destroy: ->

    dataFormat: ->
      [
        {
          name: "default",
          type: "any",
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
        }
      ]

  PieChart
).call(@)

@SeeIt.GraphNames["PieChart"] = "Pie Chart"