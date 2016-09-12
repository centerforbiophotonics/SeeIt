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

      medMedIdx = options.map((op) -> op.label).indexOf("Median-Median")
      if medMedIdx > -1 && options[medMedIdx].value
        @drawMedianMedian(xScale, yScale)

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
      midDrag = d3.behavior.drag()
        .on('drag', ->
            deltX = d3.event.dx
            deltY = d3.event.dy
            mdOldX = Number(d3.select(this).attr('x'))
            mdOldY = Number(d3.select(this).attr('y'))
            d3.select(this).attr('x', mdOldX+deltX).attr('y', mdOldY+deltY)

            top = self.svg.select("#top")
            right = self.svg.select("#right")
            bot = self.svg.select("#bottom")
            left = self.svg.select("#left")
            ellipse = self.svg.select("ellipse")

            oldX = Number(top.attr('x'))
            oldY = Number(top.attr('y'))
            top.attr('x', oldX+deltX).attr('y', oldY+deltY)

            rtOldX = Number(right.attr('x'))
            rtOldY = Number(right.attr('y'))
            right.attr('x', rtOldX+deltX).attr('y', rtOldY+deltY)

            xDiff = rtOldX - mdOldX
            yDiff = mdOldY - rtOldY
            angleRad = Math.atan2(yDiff, xDiff)
            angle = -(angleRad / (2*Math.PI)) * 360

            oldX = Number(bot.attr('x'))
            oldY = Number(bot.attr('y'))
            bot.attr('x', oldX+deltX).attr('y', oldY+deltY) 

            oldX = Number(left.attr('x'))
            oldY = Number(left.attr('y'))
            left.attr('x', oldX+deltX).attr('y', oldY+deltY) 

            oldX = Number(ellipse.attr('cx'))
            oldY = Number(ellipse.attr('cy'))
            ellipse.attr('transform', null)
            ellipse.attr('cx', oldX+deltX).attr('cy', oldY+deltY)
            ellipse.attr('transform', "rotate(#{angle},#{oldX+deltX},#{oldY+deltY})")

            rx = Number(ellipse.attr('rx'))
            ry = Number(ellipse.attr('ry'))

            self.findPointsInEllipse({'x':oldX+deltX,'y':oldY+deltY}, rx, ry, angleRad, xScale, yScale)
          )

      drag = d3.behavior.drag()
        .on('drag', ->
          thisId = d3.select(this).attr("id")
          switch thisId
            when "top"
              oppId = "bottom"
              leftId = "left"
              rightId = "right"
            when "right"
              oppId = "left"
              leftId = "top"
              rightId = "bottom"
            when "bottom"
              oppId = "top"
              leftId = "right"
              rightId = "left"
            when "left"
              oppId = "right"
              leftId = "bottom"
              rightId = "top"

          oldX = Number(d3.select(this).attr('x'))
          topNewX = oldX + d3.event.dx + 5
          oldY = Number(d3.select(this).attr('y'))
          topNewY = oldY + d3.event.dy + 5
          d3.select(this).attr('x', topNewX-5).attr('y', topNewY-5)

          oldX = Number(self.svg.select("##{oppId}").attr('x'))
          botNewX = oldX - d3.event.dx+5
          oldY = Number(self.svg.select("##{oppId}").attr('y'))
          botNewY = oldY - d3.event.dy+5
          self.svg.select("##{oppId}").attr('x', botNewX-5).attr('y', botNewY-5)

          centerX = Number(self.svg.select("ellipse").attr('cx'))
          centerY = Number(self.svg.select("ellipse").attr('cy'))
          v = {'x': topNewX - centerX, 'y': centerY - topNewY}
          magV = Math.sqrt(v.x**2 + v.y**2)
          normV = {'x': v.x/magV, 'y': v.y/magV}
          perpV = {'x': -normV.y, 'y': normV.x}
          rotAngleRad = Math.atan2(normV.y, normV.x)
          rotAngle = (rotAngleRad / (2*Math.PI)) * 360 
          if thisId == "top" || thisId == "bottom"
            rotAngleRad -= Math.PI/2
            rotAngle -= 90

          switch thisId
            when "top", "bottom"
              stableRadius = Number(self.svg.select("ellipse").attr('rx'))
              radiusLabel = "ry"
            when "right", "left"
              stableRadius = Number(self.svg.select("ellipse").attr('ry'))
              radiusLabel = "rx"

          self.svg.select("##{leftId}").attr("x", centerX + (perpV.x * stableRadius) - 5).attr("y", centerY - (perpV.y * stableRadius) - 5)
          self.svg.select("##{rightId}").attr("x", centerX - (perpV.x * stableRadius) - 5).attr("y", centerY + (perpV.y * stableRadius) - 5)

          self.svg.select("ellipse")
            .attr(radiusLabel, magV)
            .attr("transform", "rotate(#{-rotAngle}, #{centerX}, #{centerY})")
          if radiusLabel == "rx"
            rx = magV
            ry = stableRadius
          else
            rx = stableRadius
            ry = magV
          self.findPointsInEllipse({'x':centerX, 'y':centerY}, rx, ry, rotAngleRad, xScale, yScale)
      )
    
      xRange = xScale.range()
      yRange = yScale.range()
      xMid = (xRange[1]+xRange[0])/2
      yMid = (yRange[1]+yRange[0])/2
      xQtr = (xRange[0]+xMid)/2
      yQtr = (yRange[0]+yMid)/2
      x3Qt = (xRange[1]+xMid)/2
      y3Qt = (yRange[1]+yMid)/2

      @svg.append("ellipse")
        .attr("cx", xMid)
        .attr("cy", yMid)
        .attr("rx", xMid-xQtr)
        .attr("ry", yMid-y3Qt)
        .style("stroke", "red")
        .style("stroke-width", 2)
        .style("fill", "none")
      @svg.append("rect")
        .attr("x", xQtr-5)
        .attr("y", yMid-5)
        .attr("width", 10)
        .attr("height", 10)
        .style("fill", "red")
        .attr("id", "left")
        .call(drag)
      @svg.append("rect")
        .attr("x", x3Qt-5)
        .attr("y", yMid-5)
        .attr("width", 10)
        .attr("height", 10)
        .style("fill", "red")
        .attr("id", "right")      
        .call(drag)
      @svg.append("rect")
        .attr("x", xMid-5)
        .attr("y", yQtr-5)
        .attr("width", 10)
        .attr("height", 10)
        .style("fill", "red")
        .attr("id", "bottom")
        .call(drag)
      @svg.append("rect")
        .attr("x", xMid-5)
        .attr("y", y3Qt-5)
        .attr("width", 10)
        .attr("height", 10)
        .style("fill", "red")
        .attr("id", "top")
        .call(drag)
      @svg.append("rect")
        .attr("x", xMid-5)
        .attr("y", yMid-5)
        .attr("width", 10)
        .attr("height", 10)
        .style("fill", "red")
        .style("fill-opacity", 0.3)
        .style("stroke", "red")
        .style("stroke-width", 1)
        .attr("id", "anchor")
        .call(midDrag)

      @findPointsInEllipse({'x':xMid, 'y':yMid}, xMid-xQtr, yMid-y3Qt, 0, xScale, yScale)

    findPointsInEllipse: (center, rx, ry, angle, xScale, yScale) -> #center in form {'x':Number, 'y':Number}, angle is counterclockwise from x-axis in radians
      data = @data.map((d)->{'x':d.x(), 'y':d.y()})
      includedPts = 0
      angle = -angle
      data.forEach (d, i) ->
        scaledX = xScale(d.x)
        scaledY = yScale(d.y)
        ctrdX = scaledX - center.x
        ctrdY = scaledY - center.y
        cos = Math.cos(angle)
        sin = Math.sin(angle)

        ANum = ((ctrdX * cos) + (ctrdY * sin))**2
        A = ANum/(rx**2)
        BNum = ((ctrdX * sin) - (ctrdY * cos))**2
        B = BNum/(ry**2)

        if (A+B <= 1)
          includedPts++

      @svg.select("#counter").remove()
      @svg.append("text")
        .attr("id", "counter")
        .attr("x", center.x)
        .attr("y", center.y-ry-20)
        .text("# of Points Inside = #{includedPts}")
        .style("fill", "red")
        .attr("text-anchor", "middle")
        .style("font-weight", "bold") 

    drawMedianMedian: (xScale, yScale) ->
      data = @data.map((d)->{'x':d.x(), 'y':d.y()})
      data.sort((a,b)->a.x-b.x)

      groups = [[],[],[]]
      div = data.length / 3
      
      data.forEach (d, i) ->
        if i < Math.round(div)
          groups[0].push(d)
        else if i < Math.round(div*2)
          groups[1].push(d)
        else 
          groups[2].push(d)

      medians = [{},{},{}]
      groups.forEach (grp, i) ->
        middle = Math.floor(grp.length/2)
        exes = grp.map((pt) -> pt.x).sort((a,b)->a-b)
        whys = grp.map((pt) -> pt.y).sort((a,b)->a-b)
        console.log exes
        console.log whys
        if grp.length % 2
          medians[i]['x'] = exes[middle]
          medians[i]['y'] = whys[middle]
        else
          medians[i]['x'] = (exes[middle-1] + exes[middle]) / 2
          medians[i]['y'] = (whys[middle-1] + whys[middle]) / 2

        medians[i]['minX'] = Math.min.apply(null,exes)
        medians[i]['maxX'] = Math.max.apply(null,exes)
        medians[i]['minY'] = Math.min.apply(null,whys)
        medians[i]['maxY'] = Math.max.apply(null,whys)

      console.log medians

      medMedSlope = (medians[2].y-medians[0].y)/(medians[2].x - medians[0].x)
      medXSum = medians[0].x + medians[1].x + medians[2].x
      medYSum = medians[0].y + medians[1].y + medians[2].y
      medMedB = (medYSum - (medMedSlope * medXSum)) / 3

      medMedLine = (x) -> (medMedSlope*x) + medMedB
      minX = medians[0].minX
      minY = medMedLine(minX)
      maxX = medians[2].maxX
      maxY = medMedLine(maxX)
#      @svg.remove("#medMedLine")
      @svg.append("line")
        .attr("x1", xScale(minX))
        .attr("x2", xScale(maxX))
        .attr("y1", yScale(minY))
        .attr("y2", yScale(maxY))
        .attr("stroke", "blue")
        .attr("stroke-width", 2)
        .attr("id", "#medMedLine")

      @svg.selectAll("#medianPt")
        .data(medians)
        .enter()
        .append("path")
          .attr("d","M-10,-10L10,10M10,-10,L-10,10")
          .attr("transform",(d)->"translate(#{xScale(d.x)},#{yScale(d.y)}) rotate(45)")
          .attr("stroke","blue")
          .attr("stroke-width",1)

      @svg.selectAll("#medianGrp")
        .data(medians)
        .enter()
        .append("rect")
          .attr("x", (d)->xScale(d.minX))
          .attr("y", (d)->yScale(d.maxY))
          .attr("width", (d)->xScale(d.maxX)-xScale(d.minX))
          .attr("height", (d)->yScale(d.minY)-yScale(d.maxY))
          .attr("id", "medianGrp")
          .attr("fill", "blue")
          .attr("fill-opacity", 0.05)
          .attr("stroke", "blue")
          .attr("stroke-width", .5)


      


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
          default: false
        },
        {
          label: "Median-Median",
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
