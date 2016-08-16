@SeeIt.Graphs.DistributionDotPlot = (->
  R = 4

  class DistributionDotPlot extends SeeIt.Graph
    constructor: ->
      super
      @rendered = false
      @customDivs = []
      @initListeners()

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

      @eventCallbacks['label:changed'] = (options) ->
        self.updateLabels.call(self, options)

      @eventCallbacks['header:changed'] = (options) ->
        self.updateHeaders.call(self, options)

      @eventCallbacks['color:changed'] = (options) ->
        self.updateColors.call(self, options)

      for e, cb of @eventCallbacks
        @on e, cb

      $(window).on('resize', (event) ->
        self.eventCallbacks['data:created'](prevOptions)
      )


    updateColors: (options) ->
      @svg.selectAll('.dot.SeeIt').style('fill', (d) -> d.color())
      @updateHeaders()

    updateHeaders: (options) ->
      @container.find('.legend').remove()
      #@drawLegend(options)

    updateLabels: (options) ->


    minMaxWPadding: (padding) ->
      min = Infinity
      max = -Infinity

      @dataset[0].data.forEach (dataColumn) ->
        dataColumn.data().forEach (d) ->
          max = if d.value() then Math.max(max, d.value()) else max
          min = if d.value() then Math.min(min, d.value()) else min

      adjustment = Math.max(padding*(max - min),0)
      ret = [Math.floor(min) - adjustment,Math.ceil(max) + adjustment]
      if ret[0] == ret[1] then ret[1] += 1
      
      return ret

    formatData: ->

    clearGraph: ->
      @container.html("")
      @rendered = false

    refresh: (options = []) ->
      @container.html("")
      @draw(options)

    setViewMembers: ->
      @style = {}
        
      @style.margin = {top: 20, right: 20, bottom: 30, left: 40}
      @style.width = @container.width() - @style.margin.left - @style.margin.right
      @style.height = Math.max(270, @container.height()) - @style.margin.top - @style.margin.bottom

      @x = d3.scale.linear().range([0,@style.width])
      @y = d3.scale.linear().range([@style.height,0])
      @x.domain(@minMaxWPadding(0))
      @y.domain([0,@style.height])

    placeData: ->
      @graphData = new DistPlotBuilder(@dataset, @x, @y, @style.width, @style.height)


    drawLegend: ->
      if @svg
        legendData = []

        @dataset[0].data.forEach (dataColumn) ->
          legendData.push({color: dataColumn.color, header: dataColumn.header})

        @legend = @svg.selectAll(".legend")
          .data(legendData)
          .enter().append("g")
          .attr("class", "legend")
          .attr("transform", (d, i) -> 
            return "translate(0," + i * 20 + ")"
          )

        @legend.data(legendData)
          .enter().append("rect")
          .attr("x", @style.width - 18)
          .attr("width", 18)
          .attr("height", 18)
          .style("fill", (d) ->
            return d.color
          )

        @legend.data(legendData)
          .enter().append("text")
          .attr("x", @style.width - 24)
          .attr("y", 9)
          .attr("dy", ".35em")
          .style("text-anchor", "end")
          .text((d) -> 
            return d.header
          )

    initSvg: ->
      @xAxis = d3.svg.axis()
        .scale(@x)
        .orient("bottom")

      @svg = d3.select(@container[0]).append("svg")
        .attr("width", @style.width + @style.margin.left + @style.margin.right)
        .attr("height", @style.height + @style.margin.top + @style.margin.bottom)
        .append("g")
        .attr("transform", "translate(" + @style.margin.left + "," + @style.margin.top + ")")

    drawGraph: (options) ->
      self = @

      @initSvg()

      @svg.append("g")
        .attr("class", "x axis SeeIt")
        .attr("transform", "translate(0," + (@style.height - 8) + ")")
        .call(@xAxis)

      histIdx = options.map((option) -> option.label).indexOf('Show Histogram')
      binIdx = options.map((option) -> option.label).indexOf('Number of bins in histogram')

      if histIdx > -1 && options[histIdx].value
        hist = new HistogramBuilder(@dataset, @style, @svg, 
          if binIdx > -1 && options[binIdx].value then options[binIdx].value else 10
        )

      boxPlotIdx = options.map((option) -> option.label).indexOf('Box Plot')

      if boxPlotIdx > -1 && options[boxPlotIdx].value then @drawBoxPlot()

      divIdx = options.map((option) -> option.label).indexOf('Dividers')

      if divIdx > -1 && options[divIdx].value != "None" then @drawDivs(options[divIdx].value)

      fixDivIdx = options.map((option) -> option.label).indexOf('Fixed Size Dividers')

      if fixDivIdx > -1 && options[fixDivIdx].value then @drawDivs(options[fixDivIdx].value, "size")

      fixWidIdx = options.map((option) -> option.label).indexOf('Fixed Width Dividers')

      if fixWidIdx > -1 && options[fixWidIdx].value then @drawDivs(options[fixWidIdx].value, "width")

      mkeYrOwnIdx = options.map((option) -> option.label).indexOf('Make your own Groups')

      if mkeYrOwnIdx > -1 && options[mkeYrOwnIdx].value then @makeYourOwn()

      @svg.selectAll(".dot.SeeIt")
        .data(@graphData.dataArray)
        .enter().append("circle")
        .attr("class", "dot SeeIt")
        .attr("r", R)
        .attr("cx", (d) ->
          return self.x(d.data.value())
        )
        .attr("cy", (d) ->
          return self.y(d.y + 8)
        )
        .style("fill", (d) ->
          return d.color()
        )

      @drawStats(options)

    draw: (options = []) ->
      self = @

      radiusIdx = options.map((option) -> option.label).indexOf("Dot Radius")

      if radiusIdx > -1 && options[radiusIdx].value then R = Math.max(options[radiusIdx].value, 1)

      @setViewMembers()
      @placeData()

      @drawGraph(options)
      @drawLegend(options)

    drawDivs: (choice, widthOrSize) ->
      self = @
      values = @graphData.dataArray.map((arrayMem) -> arrayMem.data.value())
      values.sort((a,b)-> a-b)
      valLen = values.length

      
      if typeof(choice) == "string"
        if choice == "Two Equal"
          midIdx = Math.floor(valLen / 2) - 1
          midVal = (values[midIdx]+values[midIdx+1])/2 
          breaks = [values[0], midVal, values[valLen-1]]
          breakPopulations = [midIdx+1, valLen-midIdx-1]

        if choice == "Four Equal"
          div = Math.floor((valLen)/4)
          mod = valLen%4
          breakIdxs = [0, div-1]
          for i in [2...5]
            if i > 4-mod then breakIdxs[i] = breakIdxs[i-1]+div+1 else breakIdxs[i] = breakIdxs[i-1]+div

          breaks = [values[0]]
          for i in [1...4]
            breaks[i] = (values[breakIdxs[i]] + values[breakIdxs[i] + 1])/2
          breaks[4] = values[breakIdxs[4]]

          breakPopulations = [div]
          for i in [1...4]
            breakPopulations[i] = breakIdxs[i+1] - breakIdxs[i]

      else if typeof(choice) == "number"
        if widthOrSize == "size"
          breakIdxs = [0]
          breaks = [values[0]]
          breakPopulations = [0]
          i=0
          for value, idx in values
            if (idx+1)%choice == 0
              if idx not in breakIdxs
                breakIdxs.push(idx)
                breakPopulations[i]++
                i++
              breakPopulations[i] = 0
            else
              breakPopulations[i]++

          if values.length-1 not in breakIdxs
            breakIdxs.push(values.length-1)

          console.log "breakIdxs", breakIdxs
          console.log "breakPops", breakPopulations

          for j in [1...breakIdxs.length-1]
            breaks[j] = (values[breakIdxs[j]] + values[breakIdxs[j] + 1])/2

          breaks.push( values[breakIdxs[breakIdxs.length-1]] )

        else if widthOrSize == "width"
          breaks = []
          xDomain = self.x.domain()
          spot = xDomain[0]
          while spot <= xDomain[1]
            breaks.push(spot)
            spot += choice
          breakPopulations = [0]

          scanIdx = 0
          for i in [0...breaks.length - 1]
            breakPopulations[i] = 0
            while (values[scanIdx] <= breaks[i+1] && scanIdx < values.length)
              breakPopulations[i]++
              scanIdx++

          if scanIdx < values.length
            runoff = values.length - scanIdx
            self.svg.append("text")
              .attr("x", -> ((self.x(breaks[breaks.length-1]) + self.x(xDomain[1]))/2))
              .attr("y", 12)
              .attr("text-anchor", "middle")
              .text(runoff)
              .attr("fill", "purple")




      @svg.selectAll("divTop")
        .data(breaks)
        .enter()
        .append("rect")
          .attr("x", (d) -> self.x(d) - 1.5)
          .attr("y", 0)
          .attr("width", 3)
          .attr("height", 3)
          .attr("fill", "orange")
      @svg.selectAll("divLine")
        .data(breaks)
        .enter()
        .append("line")
          .attr("x1", (d) -> self.x(d))
          .attr("x2", (d) -> self.x(d))
          .attr("y1", self.y(8))
          .attr("y2", self.y(self.style.height - 3))
          .attr("stroke-width", 1)
          .attr("stroke", "black")
      @svg.selectAll("divLabels")
        .data(breakPopulations)
        .enter()
        .append("text")
          .attr("x", (d,i) -> (self.x(breaks[i+1])+self.x(breaks[i]))/2)
          .attr("y", 12)
          .attr("text-anchor", "middle")
          .text((d) -> d)
          .attr("fill", "purple")
        
    makeYourOwn: () ->
      self = @
      xDomain = @x.domain()
      values = @graphData.dataArray.map((arrayMem) -> arrayMem.data.value())
      values.sort((a,b)-> a-b)
      @customDivNum = @customDivs.length

      displayPops = (breaks) ->
        sortedBreaks = breaks.slice(0).sort((a,b)->a-b)
        scanIdx = 0
        breakPopulations = []
        for i in [0...sortedBreaks.length]
          breakPopulations[i] = 0
          while (values[scanIdx] <= sortedBreaks[i] && scanIdx < values.length)
            breakPopulations[i]++
            scanIdx++
        breakPopulations.push(values.length - scanIdx)
        sortedBreaks.push(xDomain[1])
        sortedBreaks.push(xDomain[0])
        sortedBreaks.sort((a,b)->a-b)
        self.svg.selectAll("#populationTag").remove()
        self.svg.selectAll("#populationTag")
          .data(breakPopulations)
          .enter()
          .append("text")
            .text((d,i) -> breakPopulations[i])
            .attr("x", (d,i) -> self.x((sortedBreaks[i]+sortedBreaks[i+1])/2))
            .attr("id", "populationTag")
            .attr("y", 12)
            .attr("text-anchor", "middle")
            .attr("fill", "purple")

      dragStart = (d,i) ->
        d3.select(this).select("rect").attr("fill", "yellow")
      dragging = (d,i) ->
        d.x += d3.event.dx
        d3.select(this).attr("transform", "translate(#{d.x},0)")
        datum = d3.select(this).datum()
        id = datum["id"]
        self.customDivs[id] = self.x.invert(datum["x"])
        displayPops(self.customDivs)
      dragEnd = (d,i) ->
        d3.select(this).select("rect").attr("fill", "green")

      drag = d3.behavior.drag()
              .on("dragstart", dragStart)
              .on("drag", dragging)
              .on("dragend", dragEnd)


      dragStart2 =  (d,i) ->
        self.customDivs.push(self.x(d3.mouse(this)[0]))
        newDiv = self.svg.append("svg:g")
          .data([{"x":d3.mouse(this)[0]}])  
          .attr("id", "divLine#{self.customDivNum}")
          .attr("transform","translate(#{d3.mouse(this)[0]}, 0)")
          .call(drag)

        newDiv.append("line")
          .attr("x1", 0)
          .attr("x2", 0)
          .attr("y1", self.y(8))
          .attr("y2", 0)
          .attr("stroke-width", 1)
          .attr("stroke", "black")
        newDiv.append("rect")
          .attr("x", self.x(xDomain[0]))
          .attr("y", 0)
          .attr("width", 10)
          .attr("height", 10)
          .attr("fill", "yellow")
          .attr("stroke", "green")
          .attr("stroke-width", 1.5)
      dragging2 = (d,i) ->
        d.x += d3.event.dx
        d3.select("#divLine#{self.customDivNum}").attr("transform", "translate(#{d.x},0)")
        self.customDivs[self.customDivNum] = self.x.invert(d.x)
        displayPops(self.customDivs)
      dragEnd2 = (d,i) ->
        d3.select("#divLine#{self.customDivNum}").datum({"x":d.x,"id":self.customDivNum}).select("rect").attr("fill", "green")
        self.customDivNum++
        d.x = self.x(xDomain[0])

      drag2 = d3.behavior.drag()
              .on("dragstart", dragStart2)
              .on("drag", dragging2) 
              .on("dragend", dragEnd2)

      start = @svg.append("svg:g")
                .data([ { "x":self.x(xDomain[0]) } ])
                .attr("class", "startLine")
                .attr("transform","translate(#{self.x(xDomain[0])}, 0)")
                .call(drag2)

      start.append("line")
        .attr("x1", (d) -> d.x)
        .attr("x2", (d) -> d.x)
        .attr("y1", self.y(8))
        .attr("y2", 0)
        .attr("stroke-width", 1)
        .attr("stroke", "black")
      start.append("rect")
        .attr("x", self.x(xDomain[0]))
        .attr("y", 0)
        .attr("width", 10)
        .attr("height", 10)
        .attr("fill", "green")
        .attr("stroke", "green")
        .attr("stroke-width", 1.5)
      @svg.append("line")
        .attr("x1", self.x(xDomain[1]))
        .attr("x2", self.x(xDomain[1]))
        .attr("y1", self.y(8))
        .attr("y2", 0)
        .attr("stroke-width", 1)
        .attr("stroke", "black")

      if @customDivs.length
        @customDivs.forEach (divCoord, i) ->
          newGuy = self.svg.append("svg:g")
                    .data([{"x":self.x(divCoord), "id":i}])
                    .attr("class", "divLine")
                    .attr("transform","translate(#{self.x(divCoord)},0)")
                    .call(drag)
          newGuy.append("line")
            .attr("x1", 0)
            .attr("x2", 0)
            .attr("y1", self.y(8))
            .attr("y2", 0)
            .attr("stroke-width", 1)
            .attr("stroke", "black")
          newGuy.append("rect")
            .attr("x", 0)
            .attr("y", 0)
            .attr("width", 10)
            .attr("height", 10)
            .attr("fill", "green")
            .attr("stroke", "green")
            .attr("stroke-width", 1.5)
        displayPops(@customDivs)

    drawStats: (options) ->
      self = @
      ops = options.map((option) -> option.label)

      ['Show Mean', 'Show Median', 'Show Mode'].forEach (label) ->
        if (idx = ops.indexOf(label)) > -1 && options[idx].value
          self.drawStatistic.call(self, label.split(' ')[1])

    drawStatistic: (stat) ->
      self = @

      switch stat
        when 'Mean'
          mean = @graphData.dataArray.reduce((sum, d, i) -> 
            if i > 1 then sum + d.data.value() else sum.data.value() + d.data.value()
          )

          mean /= @graphData.dataArray.length

          @svg.selectAll(".mean.SeeIt")
            .data([mean])
            .enter().append("rect")
            .attr("class", "mean SeeIt")
            .attr("width", 16)
            .attr("height", 16)
            .attr("x", (d) ->
              return self.x(mean)
            )
            .attr("y", (d) ->
              return self.y(-4*4 + 2)
            )
            .style("fill", 'red')
            .style("opacity", 0.8)

            msg = "Mean: #{mean}"
            tip = new Opentip(@container.find('.mean.SeeIt'), msg, {showOn: "click"})
        when 'Median'
          cpy = @graphData.dataArray.slice()
          cpy.sort((a,b) -> a.data.value() - b.data.value())

          median = if cpy.length % 2 == 0
            (cpy[cpy.length / 2 - 1].data.value() + cpy[cpy.length / 2 - 1].data.value()) / 2
          else 
            cpy[Math.floor(cpy.length / 2)].data.value()

          @svg.selectAll(".median.SeeIt")
            .data([median])
            .enter().append("circle")
            .attr("class", "median SeeIt")
            .attr("r", 2*4)
            .attr("cx", (d) ->
              self.x(d)
            )
            .attr("cy", self.y(-6*4 + 2))
            .style("fill", "blue")
            .style("opacity", 0.8)

          tip = new Opentip(@container.find('.median.SeeIt'), "Median: #{median}", {showOn: "click"})
        when 'Mode'
          modes = ((array) ->
              modes = []

              if array.length == 0 then return []

              modeMap = {}
              maxEl = array[0].data.value()
              maxCount = 1

              for i in [0...array.length]
                el = array[i].data.value()

                if !modeMap[el]
                  modeMap[el] = 1
                else
                  modeMap[el]++

                if(modeMap[el] > maxCount)
                  maxEl = el
                  maxCount = modeMap[el]
                  modes = [maxEl]
                else if modeMap[el] == maxCount
                  modes.push el

              return modes
          )(@graphData.dataArray)

          @svg.selectAll(".mode.SeeIt")
            .data(modes)
            .enter().append("polyline")
            .attr("class", "mode SeeIt")
            .attr('points', (d) ->
              "#{self.x(d) - 2*4},#{self.y(-8*4 + 2)} #{self.x(d) + 4*R},#{self.y(-8*4 + 2)} #{self.x(d)},#{self.y(-4*4 + 2)}"
            )
            .style("fill", 'green')
            .style("opacity", 0.8)

          @svg.selectAll(".mode.SeeIt").each((d) ->
            tip = new Opentip($(@), "Mode: #{d}", {showOn: "click"})
          )

    drawBoxPlot: ->
      iqr = (k) ->
        return (d, i) ->
          q1 = d.quartiles[0]
          q3 = d.quartiles[2]
          iqr = (q3 - q1) * k
          i = -1
          j = d.length

          while (d[++i] < q1 - iqr)
            i

          while (d[--j] > q3 + iqr)
            j

          return [i, j]

      chart = d3.box()
        .value((d) -> 
          d.data.value()
        )
        .whiskers(iqr(1.5))
        .width(@style.width)
        .height(Math.min(@style.height*.75, 270*.75))
        .domain(@minMaxWPadding(0))

      @svg.selectAll(".box-plot.SeeIt")
        .data([@graphData.dataArray])
        .enter()
        .append("g")
          .attr('class', "box-plot SeeIt")
          .attr('transform', "translate(0, #{Math.max(@style.height - 270, 0) / 2 - (2*R)})")
          .call(chart)

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
      [{
        label: "Box Plot",
        type: "checkbox",
        default: ->
          self.dataset
      },
      {
        label: "Dividers",
        type: "select",
        values: ['None', 'Two Equal', 'Four Equal'],
        default: "None"
      },
      {
        label: "Fixed Size Dividers",
        type: "numeric",
        default: 0
      },
      {
        label: "Fixed Width Dividers",
        type: "numeric",
        default: 0
      },
      {
        label: "Make your own Groups",
        type: "checkbox",
        default: false
      },
      {
        label: "Show Median",
        type: "checkbox",
        default: false
      },
      {
        label: "Show Mean",
        type: "checkbox",
        default: false
      },
      {
        label: "Show Mode",
        type: "checkbox",
        default: false
      },{
        label: "Dot Radius",
        type: "numeric",
        default: 4
      },{
        label: "Show Histogram",
        type: "checkbox",
        default: false
      },{
        label: "Number of bins in histogram",
        type: "numeric",
        default: 10
      }]

    DistributionDotPlot.name = ->
      "Distribution Dot Plot"


  HistogramBuilder = (->
    class HistogramBuilder
      constructor: (@_dataset, @style, @svg, @nBins = 10) ->
        self = @
        @data = []

        @range = @minMaxWPadding(0)
        @x = d3.scale.linear().range([0, @style.width])
        @y = d3.scale.linear().range([@style.height,0])
        @x.domain(@range)

        @_dataset[0].data.forEach (dataColumn) ->
          dataColumn.compact().forEach (d, i) ->
            self.data.push d.value()

        @drawHistogram()

      minMaxWPadding: (padding) ->
        min = Infinity
        max = -Infinity

        @_dataset[0].data.forEach (dataColumn) ->
          dataColumn.data().forEach (d) ->
            max = if d.value() then Math.max(max, d.value()) else max
            min = if d.value() then Math.min(min, d.value()) else min

        adjustment = padding*(max - min)
        ret = [Math.floor(min) - adjustment,Math.ceil(max) + adjustment]
        if ret[0] == ret[1] then ret[1] += 1

        return ret

      drawHistogram: ->
        self = @

        bins = d3.layout.histogram().
          range(@range).
          bins(@nBins)(@data)

        @y.domain([0,d3.max(bins, (d) -> d.length)])

        t = @svg.selectAll('.x.axis .tick')[0].map((d) -> 
          d3.transform(d3.select(d).attr('transform'))
        )


        width = t[t.length - 1].translate[0] - t[0].translate[0]

        xVals = [0..@nBins].map((d) -> d*width / self.nBins )

        bar = @svg.selectAll(".SeeIt.bar")
          .data(bins)
          .enter().append("g")
            .attr('class', 'bar SeeIt')
            .attr('transform', (d, i) -> "translate(#{xVals[i]},#{self.y(d.y) - 8 + 1})")

        bar.append("rect")
          .attr("x", (d,i) -> 
            0
          )
          .attr("width", (d, i) -> 
            xVals[i+1] - xVals[i] - 1
          )
          .attr("height", (d) -> 
            return self.style.height - self.y(d.y)
          )

        formatCount = d3.format(",.0f")

        bar.append("text")
          .attr("dy", ".75em")
          .attr("y", 6)
          .attr("x", (d,i) -> (xVals[i+1] - xVals[i] - 1) / 2)
          .attr("text-anchor", "middle")
          .text((d) -> formatCount(d.length))

  ).call(@)


  DistPlotBuilder = (->
    class DistPlotBuilder
      constructor: (@_dataset, @x, @y, @width, @height) ->
        @data = []
        @dataArray = []
        @nBins = Math.ceil(@height / R)
        @formatData()

      formatData: ->
        self = @

        #Set up the horizontal bins
        for i in [0...@nBins]
          @data.push([])

        @_dataset[0].data.forEach (dataColumn) ->
          dataColumn.compact().forEach (d, i) ->
            point = self.placePoint.call(self, d, dataColumn.header, dataColumn.datasetTitle, dataColumn.getColor.bind(dataColumn))
            if point then self.dataArray.push(point)

      placePoint: (d, header, datasetTitle, color) ->
        self = @
        data = @data
        nBins = @nBins

        idxInBin = (d, idx) ->
          if data[idx].length == 0 then return 0

          start = 0
          end = data[idx].length - 1

          while true
            mid = Math.floor((start + end) / 2)

            if Math.abs(self.x(d.value()) - self.x(data[idx][mid].data.value())) < 2*R then return -1

            if end == start
              if d.value() < data[idx][mid].data.value()
                return start
              else 
                return start + 1

            if d.value() < data[idx][mid].data.value()
              end = mid
            else
              start = mid + 1            


        binBsearch = (d, start, end) ->
          mid = Math.floor((start + end) / 2)
          idx = -1
          ret = null

          lowestPossibleBin = (d, mid) ->
            return mid == 0 || idxInBin(d, mid-1) == -1


          if start == end
            if (idx = idxInBin(d, mid)) > -1 && lowestPossibleBin(d, mid)
              return {bin: mid, idx: idx}
            else
              return null
          else if start < end
            if (idx = idxInBin(d, mid)) > -1
              if lowestPossibleBin(d, mid)
                ret = {bin: mid, idx: idx}
              else
                ret = binBsearch(d, start, mid-1)
            else
              ret = binBsearch(d, mid+1, end)
          else
            alert("ERROR")
            return null

          return ret            


        binLinearSearch = (d) ->
          idx = -1

          for bin in [0...nBins]
            if (idx = idxInBin(d,bin)) > -1
              return {bin: bin, idx: idx}

          return null

        val = binLinearSearch(d, 0)
        # val = binBsearch(d, 0, @data.length - 1)

        if val
          data[val.bin].splice(val.idx, 0, point = self.createDataWrapper.call(self, d, R + val.bin*2*R, header, datasetTitle, color))
          return point

      createDataWrapper: (d, y, header, datasetTitle, color) ->
        {header: header, datasetTitle: datasetTitle, y: y, data: d, color: color}

  ).call(@)

  DistributionDotPlot
).call(@)

@SeeIt.GraphNames["DistributionDotPlot"] = "Distribution Dot Plot"