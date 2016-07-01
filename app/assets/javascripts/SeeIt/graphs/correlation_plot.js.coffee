@SeeIt.Graphs.CorrelationPlot = (->
  class CorrelationPlot extends SeeIt.Graph
    R = 3.5

    constructor: ->
      super
      @rendered = false
      @data = []
      @initListeners()

    formatData: ->
      groups = {}
      @data = []

      @dataset.forEach (data) ->
        dataColumn = data.data[0]
        dataColumn.data().forEach (d) ->
          if !groups[d.label()]
            groups[d.label()] = {label: -> d.label()}

          if data.name == "x-axis"
            groups[d.label()].x = -> d.value.apply(d, arguments)
          else
            groups[d.label()].y = -> d.value.apply(d, arguments)

      for key, val of groups
        if val.x && val.y && Number(val.x()) && Number(val.y())
          @data.push val

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
      @eventCallbacks['data:changed'] = @eventCallbacks['data:created']

      # @eventCallbacks['label:changed'] = (options) ->
      #   self.updateLabels.call(self, options)

      # @eventCallbacks['header:changed'] = (options) ->
      #   self.updateHeaders.call(self, options)

      # @eventCallbacks['color:changed'] = (options) ->
      #   self.updateColors.call(self, options)

      for e, cb of @eventCallbacks
        @on e, cb

      $(window).on('resize', (event) ->
        self.eventCallbacks['data:created'](prevOptions)
      )

    updateColors: (options) ->
      @svg.selectAll('.dot.SeeIt').style('fill', (d) -> d.color())

    draw: (options = []) ->
      self = @

      @leastSquaresVisible = false

      if @tooltip then @tooltip.remove()

      @formatData()
      opacity = 1

      radiusIdx = options.map((op) -> op.label).indexOf("Dot Radius")
      if radiusIdx > -1 && options[radiusIdx].value then R = options[radiusIdx].value

      opacityIdx = options.map((op) -> op.label).indexOf("Dot Opacity")
      if opacityIdx > -1 && options[opacityIdx].value >= 0 && options[opacityIdx].value <= 1 then opacity = options[opacityIdx].value

      margin = {top: 20, right: 20, bottom: 30, left: 40}
      width = @container.width() - margin.left - margin.right
      height = Math.max(270, @container.height()) - margin.top - margin.bottom

      xValue = (d) -> d.x()
      xScale = d3.scale.linear().range([0, width])
      xMap = (d) -> xScale(xValue(d))
      xAxis = d3.svg.axis().scale(xScale).orient("bottom")
      xAxisLabel = @dataset.filter((d) -> d.name == "x-axis")[0].data[0].header


      yValue = (d) -> d.y()
      yScale = d3.scale.linear().range([height, 0])
      yMap = (d) -> yScale(yValue(d))
      yAxis = d3.svg.axis().scale(yScale).orient("left")
      yAxisLabel = @dataset.filter((d) -> d.name == "y-axis")[0].data[0].header

      cValue = (d) -> d.label()
      color = d3.scale.category10()

      min = {
        x: d3.min(@data, xValue)-1
        y: d3.min(@data, yValue)-1
      }

      max = {
        x: d3.max(@data, xValue)+1
        y: d3.max(@data, yValue)+1
      }

      xScale.domain([min.x, max.x])
      yScale.domain([min.y, max.y])


      @svg = d3.select(@container[0]).append("svg")
          .attr("width", width + margin.left + margin.right)
          .attr("height", height + margin.top + margin.bottom)
        .append("g")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

      @tooltip = tooltip = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("opacity", 0)


      drag = d3.behavior.drag()
        .on('drag', (d) ->
          d3.select(@)
            .attr('cx', Math.min(xScale(max.x),Math.max(xScale(min.x), d3.event.x)))
            .attr('cy', Math.min(yScale(min.y),Math.max(yScale(max.y), d3.event.y)))

          if self.leastSquaresVisible
            idx = self.data.indexOf(d)
            data = []

            self.data.forEach (d) ->
              label = d.label.call(d)
              x = d.x.call(d)
              y = d.y.call(d)

              data.push {
                label: ->
                  label
                x: ->
                  x
                y: ->
                  y
              }

            element = d3.select(@)
            x = xScale.invert(element.attr('cx'))
            y = yScale.invert(element.attr('cy'))              

            data[idx].x = -> x
            data[idx].y = -> y    


            self.drawLeastSquares.call(self, xScale, yScale, min, max, tooltip, data)
        )  
        .on('dragend', (d) -> 
          element = d3.select(@)
          d.x(xScale.invert(element.attr('cx')))
          d.y(yScale.invert(element.attr('cy')))
        )

      @svg.append("g")
          .attr("class", "x axis SeeIt")
          .attr("transform", "translate(0," + height + ")")
          .call(xAxis)
        .append("text")
          .attr("class", "label")
          .attr("x", width)
          .attr("y", -6)
          .style("text-anchor", "end")
          .text(xAxisLabel)

      @svg.append("g")
          .attr("class", "y axis SeeIt")
          .call(yAxis)
        .append("text")
          .attr("class", "label")
          .attr("transform", "rotate(-90)")
          .attr("y", 6)
          .attr("dy", ".71em")
          .style("text-anchor", "end")
          .text(yAxisLabel)

      @svg.selectAll(".SeeIt.dot")
          .data(@data)
        .enter().append("circle")
          .attr("class", "SeeIt dot")
          .attr("r", R)
          .attr("cx", xMap)
          .attr("cy", yMap)
          .style("fill", (d) ->  color(cValue(d))) 
          .style("opacity", opacity)
          .style('cursor', 'move')
          .on("mouseover", (d) ->
              tooltip.transition()
                 .duration(200)
                 .style("opacity", .9)
              tooltip.html("<div><strong>Label</strong>: #{d.label()}<br/><strong>#{xAxisLabel}</strong>: #{xValue(d)}<br><strong>#{yAxisLabel}</strong>: #{yValue(d)}</div>")
                 .style("background-color", "white")
                 .style("border", "1px solid black")
                 .style("padding", "3px")
                 .style("border-radius", "3px")
                 .style("left", (d3.event.pageX + 5) + "px")
                 .style("top", (d3.event.pageY - 28) + "px")
          )
          .on("mouseout", (d) ->
              tooltip.transition()
                   .duration(500)
                   .style("opacity", 0)
          )
          .call(drag)

      regressionIdx = options.map((op) -> op.label).indexOf("Show Least Squares Regression Line")
      if regressionIdx > -1 && options[regressionIdx].value
        @drawLeastSquares(xScale, yScale, min, max, tooltip)


    drawLeastSquares: (xScale, yScale, min, max, tooltip, data) ->
      if @regression_line then @regression_line.remove()

      least_squares = SeeIt.LeastSquares(data || @data)
      @leastSquaresVisible = true


      if !isNaN(least_squares().m)
        minIntersect = (->
          y = least_squares(min.x)

          if y > min.y then return {x: xScale(min.x), y: yScale(y)}

          line = least_squares()

          return {x: xScale((min.y - line.b) / line.m), y: yScale(min.y)}
        )()

        maxIntersect = (->
          y = least_squares(max.x)

          if y < max.y then return {x: xScale(max.x), y: yScale(y)}

          line = least_squares()

          return {x: xScale((max.y - line.b) / line.m), y: yScale(max.y)}
        )()

        line = least_squares()

        @regression_line = @svg.append("line")
          .style("stroke", "green")
          .attr("x1", minIntersect.x)
          .attr("y1", minIntersect.y)
          .attr("x2", maxIntersect.x)
          .attr("y2", maxIntersect.y)
          .attr("stroke-width", 3)
          .on("mouseover", ->
              tooltip.transition()
                 .duration(200)
                 .style("opacity", .9)
              tooltip.html("<div style='background-color: white; color: green; border: 1px solid black; padding: 3px; border-radius: 3px'>y = #{line.m.toFixed(3)}x #{(if line.b >= 0 then '+ ' else '- ') + Math.abs(line.b.toFixed(3))}</div>")
                 .style("left", (d3.event.pageX + 5) + "px")
                 .style("top", (d3.event.pageY - 28) + "px")
              d3.select(@).attr('stroke-width', 5)
          )
          .on("mouseout", ->
              tooltip.transition()
                   .duration(500)
                   .style("opacity", 0)

              d3.select(@).attr('stroke-width', 3)
          )
    clearGraph: ->
      @container.html("")
      @rendered = false

    refresh: (options = []) ->
      @container.html("")
      @draw(options)

    destroy: ->

    options: ->
      [
        {
          label: "Show Least Squares Regression Line",
          type: "checkbox",
          default: false
        },
        {
          label: "Dot Radius",
          type: "numeric",
          default: R
        },
        {
          label: "Dot Opacity",
          type: "numeric",
          default: 1
        }
      ]

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

    @name = ->
      "Correlation Plot"

  CorrelationPlot
).call(@)

@SeeIt.GraphNames["CorrelationPlot"] = "Correlation Plot"