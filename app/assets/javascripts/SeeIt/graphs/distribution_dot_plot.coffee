@SeeIt.Graphs.DistributionDotPlot = (->
  R = 4

  class DistributionDotPlot extends SeeIt.Graph
    constructor: ->
      super
      @rendered = false
      @initListeners()

    initListeners: ->
      self = @

      @eventCallbacks['data:created'] =  (options) ->
        console.log "in callback"
        if self.allRolesFilled()
          if !self.rendered
            self.rendered = true
            self.draw.call(self, options)
          else
            self.refresh.call(self, options)

      @eventCallbacks['data:assigned'] = @eventCallbacks['data:created']
      @eventCallbacks['data:destroyed'] = @eventCallbacks['data:created']
      @eventCallbacks['column:destroyed'] = @eventCallbacks['data:created']
      @eventCallbacks['size:change'] = @eventCallbacks['data:created']
      @eventCallbacks['options:update'] = @eventCallbacks['data:created']
      @eventCallbacks['data:changed'] = @eventCallbacks['data:created']
      
      @eventCallbacks['label:changed'] = (options) ->
        self.updateLabels.call(self, options)

      @eventCallbacks['header:changed'] = (options) ->
        self.updateHeaders.call(self, options)

      @eventCallbacks['color:changed'] = (options) ->
        self.updateColors.call(self, options)

      for e, cb of @eventCallbacks
        @on e, cb


    updateColors: (options) ->
      @svg.selectAll('.dot.SeeIt').style('fill', (d) -> d.color())
      @updateHeaders()
      # @container.html('')
      # @drawGraph(options)
      # @drawLegend(options)

    updateHeaders: (options) ->
      @container.find('.legend').remove()
      @drawLegend(options)

    updateLabels: (options) ->


    minMaxWPadding: (padding) ->
      min = Infinity
      max = -Infinity

      @dataset[0].data.forEach (dataColumn) ->
        dataColumn.data.forEach (d) ->
          max = Math.max(max, d.value)
          min = Math.min(min, d.value)

      adjustment = Math.max(padding*(max - min),0.05)
      return [min - adjustment,max + adjustment]

    formatData: ->

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
      @x.domain(@minMaxWPadding(.05))
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

        @legend.append("rect")
          .attr("x", @style.width - 18)
          .attr("width", 18)
          .attr("height", 18)
          .style("fill", (d) ->
            return d.color
          )

        @legend.append("text")
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
      graph = @

      @initSvg()

      console.log options
      boxPlotIdx = options.map((option) -> option.label).indexOf('Box Plot')

      if boxPlotIdx > -1 && options[boxPlotIdx].value then @drawBoxPlot()

      @svg.append("g")
        .attr("class", "x axis SeeIt")
        .attr("transform", "translate(0," + @style.height + ")")
        .call(@xAxis)

      @svg.selectAll(".dot.SeeIt")
        .data(@graphData.dataArray)
        .enter().append("circle")
        .attr("class", "dot SeeIt")
        .attr("r", R)
        .attr("cx", (d) ->
          return graph.x(d.data.value)
        )
        .attr("cy", (d) ->
          return graph.y(d.y)
        )
        .style("fill", (d) ->
          return d.color()
        )

    draw: (options = []) ->
      graph = @

      @setViewMembers()
      @placeData()

      @drawGraph(options)
      @drawLegend(options)
      # @drawBoxPlot()

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
          d.data.value
        )
        .whiskers(iqr(1.5))
        .width(@style.width)
        .height(@style.height)
        .domain(@minMaxWPadding(.05))

      @svg.selectAll(".box-plot.SeeIt")
        .data([@graphData.dataArray])
        .enter()
        .append("g")
          .attr('class', "box-plot SeeIt")
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
        default: false
      }]

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
          dataColumn.data.forEach (d, i) ->
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

            if Math.abs(self.x(d.value) - self.x(data[idx][mid].data.value)) < 2*R then return -1

            if end == start
              if d.value < data[idx][mid].data.value
                return start
              else 
                return start + 1

            if d.value < data[idx][mid].data.value
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