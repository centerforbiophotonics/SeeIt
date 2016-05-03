@SeeIt.Graphs.PieChart = (->
	class PieChart extends SeeIt.Graph
		constructor: ->
			super 
			@chartObject = null
			@listenerInitialized = false

		formatData: ->
			data = []
			
			@dataset[0].data.ForEach (dataColumn) ->
				data.push({values: dataColumn.data, key: dataColumn.header, color: dataColumn.color})

			return data

		draw: (options) ->
			console.log options
			graph = @
			@container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")

			nv.addGraph ->
				chart = nv.models.pieChart()
					.x( (d) -> return d.label)
					.y( (d) -> return d.value);

				data = graph.formatData.call(graph)

				d3.select(graph.container.find('.graph-svg')[0])
					.attr('height', '100%')
					.datum(data)
					.call(chart);

				#nv.utils.windowResize(chart.update);
        		#graph.chartObject = chart
        		#return chart

		refresh: (options)->

		destroy: ->

		dataFormat: ->
			[
				{
					name: "default"
					type: "numeric"
					multiple: false
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