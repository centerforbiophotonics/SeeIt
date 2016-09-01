@SeeIt.Graphs.CorrelationPlot = (->
  class CorrelationPlot extends SeeIt.Graph
    R = 3.5

    constructor: ->
      super
      @rendered = false
      @data = []
      @ellipsePts = []
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
      @eventCallbacks['filter:changed'] = @eventCallbacks['data:created']

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

          console.log d
          
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

            squaresIdx = options.map((op) -> op.label).indexOf("Show Squares")
            if squaresIdx > -1 && options[squaresIdx].value then squares = true else squares = false
            self.drawLeastSquares.call(self, xScale, yScale, min, max, tooltip, squares, data)
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
      squaresIdx = options.map((op) -> op.label).indexOf("Show Squares")
      squares = false
      if squaresIdx > -1 && options[squaresIdx].value then squares = true
      if regressionIdx > -1 && options[regressionIdx].value
        @drawLeastSquares(xScale, yScale, min, max, tooltip, squares)

      ellipseIdx = options.map((op) -> op.label).indexOf("Show Ellipse")
      if ellipseIdx > -1 && options[ellipseIdx].value
        @drawEllipse(xScale, yScale, min, max)


    drawLeastSquares: (xScale, yScale, min, max, tooltip, squares, data) ->
      self = @
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
        if squares
          squares = []
          if data then myData = data else myData = self.data
          myData.sort((a,b)-> a.x()-b.x())
          myData = myData.map((d)->{"x":d.x(), "y":d.y()})
          for datum in myData
            sideLength = least_squares(datum.x) - datum.y
            xAnchor = datum.x
            yAnchor = least_squares(datum.x)
            above = false
            above = true if sideLength < 0
            absLen = Math.abs(yScale(yAnchor - sideLength) - yScale(yAnchor))
            squares.push({"x":xAnchor,"y":yAnchor,"len":absLen,"above":above})
          @svg.selectAll("#leastSquare").remove()
          @svg.selectAll("#leastSquare")
            .data(squares)
            .enter()
            .append("rect")
              .attr("x", (d)->
                if (d.above && line.m>0)||(!d.above && line.m<0) 
                  return xScale(d.x) - d.len
                else
                  return xScale(d.x)
              )
              .attr("width", (d)->d.len)
              .attr("y", (d)->
                if d.above 
                  return yScale(d.y) - d.len 
                else
                  return yScale(d.y)
              )
              .attr("height", (d)->d.len)
              .style("fill", "green")
              .style("stroke", "green")
              .style("stroke-width", 1)
              .style("fill-opacity", .2)
              .attr("id", "leastSquare")

    drawEllipse: (xScale, yScale, min, max) ->
      self = @
      drag = d3.behavior.drag()
        .on('drag', ->
          oldX = Number(d3.select(this).attr('x'))
          topNewX = oldX + d3.event.dx + 5
          oldY = Number(d3.select(this).attr('y'))
          topNewY = oldY + d3.event.dy + 5
          d3.select(this).attr('x', topNewX-5).attr('y', topNewY-5)

          oldX = Number(self.svg.select("#bottom").attr('x'))
          botNewX = oldX - d3.event.dx+5
          oldY = Number(self.svg.select("#bottom").attr('y'))
          botNewY = oldY - d3.event.dy+5
          self.svg.select("#bottom").attr('x', botNewX-5).attr('y', botNewY-5)

          centerX = Number(self.svg.select("ellipse").attr('cx'))
          centerY = Number(self.svg.select("ellipse").attr('cy'))
          v = {'x': topNewX - centerX, 'y': centerY - topNewY}
          magV = Math.sqrt(v.x**2 + v.y**2)
          normV = {'x': v.x/magV, 'y': v.y/magV}
          perpV = {'x': -normV.y, 'y': normV.x}
          rotAngle = (Math.atan2(normV.y, normV.x) / (2*Math.PI)) * 360 
          rotAngle = -(rotAngle - 90)

          rx = Number(self.svg.select("ellipse").attr('rx'))
          self.svg.select("#left").attr("x", centerX + (perpV.x * rx) - 5).attr("y", centerY - (perpV.y * rx) - 5)
          self.svg.select("#right").attr("x", centerX - (perpV.x * rx) - 5).attr("y", centerY + (perpV.y * rx) - 5)

          self.svg.select("ellipse")
            .attr("ry", magV)
            .attr("transform", "rotate(#{rotAngle}, #{centerX}, #{centerY})")
      )
      if @ellipsePts.length == 0
        xRange = xScale.range()
        yRange = yScale.range()
        xMid = (xRange[1]+xRange[0])/2
        yMid = (yRange[1]+yRange[0])/2
        xQtr = (xRange[0]+xMid)/2
        yQtr = (yRange[0]+yMid)/2
        x3Qt = (xRange[1]+xMid)/2
        y3Qt = (yRange[1]+yMid)/2
        @ellipsePts.push({"x":xScale.invert(xMid),"y":yScale.invert(y3Qt)}) #[0]Top
        @ellipsePts.push({"x":xScale.invert(x3Qt),"y":yScale.invert(yMid)}) #[1]Right
        @ellipsePts.push({"x":xScale.invert(xMid),"y":yScale.invert(yQtr)}) #[2]Bot
        @ellipsePts.push({"x":xScale.invert(xQtr),"y":yScale.invert(yMid)}) #[3]Left
        @ellipsePts.push({"x":xScale.invert(xMid),"y":yScale.invert(yMid)}) #[4]Ellipse Center

        @svg.append("rect")
          .attr("x", xQtr-5)
          .attr("y", yMid-5)
          .attr("width", 10)
          .attr("height", 10)
          .style("fill", "red")
          .attr("id", "left")
        @svg.append("rect")
          .attr("x", x3Qt-5)
          .attr("y", yMid-5)
          .attr("width", 10)
          .attr("height", 10)
          .style("fill", "red")
          .attr("id", "right")      
        @svg.append("rect")
          .attr("x", xMid-5)
          .attr("y", yQtr-5)
          .attr("width", 10)
          .attr("height", 10)
          .style("fill", "red")
          .attr("id", "bottom")
        @svg.append("rect")
          .attr("x", xMid-5)
          .attr("y", y3Qt-5)
          .attr("width", 10)
          .attr("height", 10)
          .style("fill", "red")
          .attr("id", "top")
          .call(drag)
        @svg.append("ellipse")
          .attr("cx", xMid)
          .attr("cy", yMid)
          .attr("rx", xMid-xQtr)
          .attr("ry", yMid-y3Qt)
          .style("stroke", "red")
          .style("stroke-width", 2)
          .style("fill", "none")

      else
        y3Qt = yScale(@ellipsePts[0].y)
        xQtr = xScale(@ellipsePts[3].x)
        for pt, i in @ellipsePts
          if i < 4
            @svg.append("rect")
              .attr("x", xScale(pt.x)-5)
              .attr("y", yScale(pt.y)-5)
              .attr("width", 10)
              .attr("height", 10)
              .style("fill", "red")
              .attr("id", ->
                switch i
                  when 0 then return "top"
                  when 1 then return "right"
                  when 2 then return "bottom"
                  when 3 then return "left"
              )
              .call(drag)
          else
            @svg.append("ellipse")
              .attr("cx", xScale(pt.x))
              .attr("cy", yScale(pt.y))
              .attr("rx", xScale(pt.x)-xQtr)
              .attr("ry", yScale(pt.y)-y3Qt)
              .style("stroke", "red")
              .style("stroke-width", 2)
              .style("fill", "none")

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
          label: "Show Squares",
          type: "checkbox",
          default: false
        },
        {
          label: "Show Ellipse",
          type: "checkbox",
          default: true
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
