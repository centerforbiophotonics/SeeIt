@SeeIt.Graphs.BarChart = (->
  class BarChart extends SeeIt.Graph

    constructor: ->
      super

    formatData: ->
      data = []

      @dataset[0].data.forEach (dataColumn) ->
        console.log(dataColumn)
        data.push({values: dataColumn.data, key: dataColumn.header})

      return data

    refresh: (options) ->
      console.log options
      d3.select(@container.find('.graph-svg')[0]).datum(@formatData()).transition().duration(500).call(@chartObject);
      nv.utils.windowResize(@chartObject.update);

    draw: (options) ->
      console.log options
      graph = @
      @container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")

      nv.addGraph ->
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
          values: [1,2,3,4,5],
          default: 3
        },
        {
          label: "Test 4",
          type: "checkbox",
          default: false
        }
      ]

  BarChart
).call(@)