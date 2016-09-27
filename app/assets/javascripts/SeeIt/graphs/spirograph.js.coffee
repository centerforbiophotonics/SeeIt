@SeeIt.Graphs.Spirograph = (->
	class Spirograph extends SeeIt.Graph
		constructor: ->
			super
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
					self.clearGraph.call(self)

			@eventCallbacks['data:assigned'] = @eventCallbacks['data:created']
			@eventCallbacks['data:destroyed'] = @eventCallbacks['data:created']
			@eventCallbacks['column:destroyed'] = @eventCallbacks['data:created']
			@eventCallbacks['size:change'] = @eventCallbacks['data:created']
			@eventCallbacks['options:update'] = @eventCallbacks['data:created']
			@eventCallbacks['data:changed'] = @eventCallbacks['data:created']
			@eventCallbacks['filter:changed'] = @eventCallbacks['data:created']
			@eventCallbacks['label:changed'] = @eventCallbacks['data:created']
			@eventCallbacks['header:changed'] = @eventCallbacks['data:created']
			@eventCallbacks['color:changed'] = @eventCallbacks['data:created']

			for e, cb of @eventCallbacks
				@on e, cb

			$(window).on('resize', (event) ->
				self.eventCallbacks['data:created'](prevOptions)
			)

		draw: (options) ->
			self = @

			orbits1Idx = options.map((op)->op.label).indexOf("#1 Orbits")
			orbits2Idx = options.map((op)->op.label).indexOf("#2 Orbits")

			orbits1 = 0
			orbits2 = 0

			if orbits1Idx > -1 && options[orbits1Idx].value then orbits1 = Number(options[orbits1Idx].value)
			if orbits2Idx > -1 && options[orbits2Idx].value then orbits2 = Number(options[orbits2Idx].value)

			@container.html("<svg class='SeeIt graph-svg' style='width:100%; min-height: 270px; background-color: #000000'></svg>")
			
			width = @container.width()	
			height = Math.max(270, @container.height())

			@svg = d3.select(self.container.find('.graph-svg')[0])
				.attr("width", width)
				.attr("height", height)
			

			@svg.append("circle")
				.attr("r", 10)
				.attr("cx", width/2)
				.attr("cy", height/2)
				.attr("fill", "yellow")
				.attr("id", "sol")


			outerRadius = 3*height/7
			@svg.append("circle")
				.attr("r", 5)
				.attr("cx", (width/2) + outerRadius)
				.attr("cy", height/2)
				.attr("fill", "blue")
				.attr("id", "aquas")

			innerRadius = height/3
			@svg.append("circle")
				.attr("r", 4)
				.attr("cx", (width/2) + innerRadius)
				.attr("cy", height/2)
				.attr("fill", "green")
				.attr("id", "terra")

			ticks = Math.min(orbits1, orbits2) * 180
			perTick1 = (orbits1 * 360)/ticks
			perTick2 = (orbits2 * 360)/ticks

			circle1 = (deg) ->
				x = (outerRadius * Math.cos((deg/360)*2*Math.PI)) + (width/2)
				y = (outerRadius * Math.sin((deg/360)*2*Math.PI)) + (height/2)
				return [x,y]

			circle2 = (deg) ->
				x = (innerRadius * Math.cos((deg/360)*2*Math.PI)) + (width/2)
				y = (innerRadius * Math.sin((deg/360)*2*Math.PI)) + (height/2)
				return [x,y]

			for i in [1..ticks]
				aquasRot = (perTick1*i)%360
				terraRot = (perTick2*i)%360
				aquasPos = circle1(aquasRot)
				terraPos = circle2(terraRot)

				endCall = (aquasPos, terraPos) ->
					console.log "An End!"
					self.svg.append("line")
						.attr("x1", aquasPos[0])
						.attr("x2", terraPos[0])
						.attr("y1", aquasPos[1])
						.attr("y2", terraPos[1])
						.attr("stroke", "white")
						.attr("stroke-width", "0.2")

				@svg.select("#aquas")
					.transition()
						.duration(20)
						.delay(i*20)
						.ease((t)->t)
						.attr("cx", aquasPos[0]).attr("cy", aquasPos[1])

				@svg.select("#terra")
					.on("end", endCall(aquasPos, terraPos))
					.transition()
					.duration(20)
					.delay(i*20)
					.ease((t)->t)
					.attr("cx",terraPos[0]).attr("cy", terraPos[1])

#				t = d3.transition()
					
#				@svg.select("#aquas")
#					.transition(t)
#						.attr("transform", "rotate(#{aquasRot}, #{width/2}, #{height/2})")

#				@svg.select("#terra")
#					.transition(t)
#						.attr("transform", "rotate(#{terraRot}, #{width/2}, #{height/2})")


		refresh: (options) ->
			@container.html("")
			@draw(options)
		dataFormat: ->
			[
				{
					name: "default",
					type: "numeric",
					multiple: false
				}
			]

		options: ->
			[
				{
					label: "#1 Orbits",
					type: "numeric",
					default: 3
				},
				{
					label: "#2 Orbits", 
					type: "numeric",
					default: 5
				}
			]

	Spirograph
).call(@)

@SeeIt.GraphNames["Spirograph"] = "Spirograph"