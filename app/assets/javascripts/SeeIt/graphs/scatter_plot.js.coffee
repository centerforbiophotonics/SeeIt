@SeeIt.Graphs.ScatterPlot = (->
	class ScatterPlot extends SeeIt.Graph
		constructor: ->
			super
			@chartObject = null
			@listenerInitialized = false
			@rendered = false
			@initListeners()

		formatData: ->
			data = []
			groups = {}
			shapes = ['circle', 'cross', 'triangle-up', 'triangle-down', 'diamond', 'square']
			random = d3.random.normal()

			if @datasetValid()
				@dataset.forEach (data) ->
					dataColumn = data.data[0]
					dataColumn.data().forEach (d) ->
						if !groups[d.label()]
							groups[d.label()] = {}

						if data.name == "x-axis"
							groups[d.label()].x = d.value()
						else
							groups[d.label()].y = d.value()

						#getRandomIntInclusive = (min, max) ->
						#	Math.floor(Math.random() * (max - min + 1)) + min

						groups[d.label()].size = Math.random()
						#groups[d.label()].shape = if Math.random() > 0.9 then shapes[getRandomIntInclusive(1,5)] else 'circle'

				for key, val of groups
					data.push {key: key, values: [val]}

			return data

		initListeners: ->
			self = @
			prevOptions = []
			
			@eventCallbacks['data:created'] =  (options) ->
				prevOptions = options

				if self.allRolesFilled()
					if !self.rendered
						self.rendered = true
						self.draw.call(self, options)
					else if self.chartObject != null
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

			$(window).on('resize', (event) ->
        self.eventCallbacks['data:created'](prevOptions)
      )

		datasetValid: ->
			valid = true

			@dataset.forEach (data) ->
				if !data.data.length then valid = false

			return valid


		refresh: (options) ->
			d3.select(@container.find('.graph-svg')[0]).datum(@formatData()).transition().duration(350).call(@chartObject);
			nv.utils.windowResize(@chartObject.update);

		draw: (options) ->
			graph = @
			@container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")

			if !@listenerInitialized
				@on 'graph:maximize', (maximize) ->
					graph.chartObject.update()
					@listenerInitialized = true

			nv.addGraph ->
				chart = nv.models.scatterChart().showLegend(false)
						.showDistX(true)
						.showDistY(true)
						#.color(d3.scale.category10.range())

				chart.tooltip.contentGenerator (data) ->
					"<h3>#{data.series[0].key}</h3>"


				d3.select(graph.container.find('.graph-svg')[0])
						.attr('height', '100%')
						.datum(graph.formatData.call(graph))
						.transition().duration(350)
						.call(chart)

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

		ScatterPlot.name = ->
			"Scatter Plot"

	ScatterPlot
).call(@)

@SeeIt.GraphNames["ScatterPlot"] = "Scatter Plot"
