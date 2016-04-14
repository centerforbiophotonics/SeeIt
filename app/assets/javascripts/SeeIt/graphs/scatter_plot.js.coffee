@SeeIt.Graphs.ScatterPlot = (->
	class ScatterPlot extends SeeIt.Graph
		constructor: ->
			super

		formatData: ->
			data = []
			groups = {}

			@dataset.forEach (data) ->
				dataColumn = data.data[0]
				dataColumn.data.forEach (d) ->
					if !groups[d.label]
						groups[d.label] = {}

					if data.name == "x-axis"
						groups[d.label].x = d.value
					else
						groups[d.label].y = d.value

			for key, val of groups
				data.push {key: key, values: [val]}

			return data

		refresh: (options) ->
	      d3.select(@container.find('.graph-svg')[0]).datum(@formatData()).transition().duration(350).call(@chartObject);
	      nv.utils.windowResize(@chartObject.update);

		draw: (options) ->
			graph = @
			@container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")

			nv.addGraph ->
				chart = nv.models.scatterChart()
					# .showDistX(true)
					# .showDistY(true)
					# .color(d3.scale.category10.range())

				chart.tooltip.contentGenerator (data) ->
					"<h3>#{data.series[0].key}</h3>"


				d3.select(graph.container.find('.graph-svg')[0]).datum(graph.formatData.call(graph)).transition().duration(350).call(chart)

				nv.utils.windowResize(chart.update)

				graph.chartObject = chart
				return chart

		destroy: ->

		options: ->
			[]

		dataFormat: ->
			[
				{
					name: "x-axis",
					type: "numeric",
					multiple: false
				},
				{
					name: "y-axis",
					type: "numeric",
					multiple: false
				}
			]


	ScatterPlot
).call(@)