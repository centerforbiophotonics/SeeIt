@SeeIt.Graphs.PieChart = (->
	class PieChart extends SeeIt.Graph

		constructor: ->
			super 
			@chartObject = null
			@listenerInitialized = false
			@render = false
			@initListeners()

		initListeners: ->
			self = @

			@eventCallbacks['data:created'] = (options) ->
				console.log "in callback test"
				if self.allRolesFilled()
					if !self.rendered
						self.render = true
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
			data = []
			
			@dataset[0].data.forEach (dataColumn) ->
				data.push({values: dataColumn.data, key: dataColumn.header, color: dataColumn.color})

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
				chart = nv.models.pieChart()
					.x( (d) -> return d.label)
					.y( (d) -> return d.value);

				data = graph.formatData.call(graph)
				#data = graph.exampleData.call(graph)

				d3.select(graph.container.find('.graph-svg')[0])
					.attr('height', '50%')
					.datum(data)
					#.transition().duration(350)
					.call(chart)

				nv.utils.windowResize(chart.update);
        		#graph.chartObject = chart
        		#return chart

		destroy: ->

		dataFormat: ->
			[
				{
					name: "default"
					type: "numeric"
					multiple: true
				}
			]

	PieChart
).call(@)