@SeeIt.Graphs.BarChart = (->
  class BarChart extends SeeIt.Graph

    constructor: ->
      super
      @draw()

    formatData: ->
      data = []

      @dataset.forEach (dataColumn) ->
        console.log(dataColumn)
        data.push({values: dataColumn.data, key: dataColumn.header})

      return data

    refresh: ->
      d3.select(@container.find('.graph-svg')[0]).datum(@formatData()).transition().duration(500).call(@chartObject);
      nv.utils.windowResize(@chartObject.update);

    draw: ->
      graph = @
      @container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")
      console.log(@container.html())
      nv.addGraph ->
        console.log "drawing"
        chart = nv.models.multiBarChart()
            .x((d) -> d.label )
            .y((d) -> d.value )

        data = graph.formatData.call(graph)
        console.log data
        d3.select(graph.container.find('.graph-svg')[0])
            .datum(data)
            .call(chart);

        nv.utils.windowResize(chart.update)
        graph.chartObject = chart
        return chart
      
    destroy: ->

  BarChart
).call(@)