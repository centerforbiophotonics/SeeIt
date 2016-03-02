@SeeIt.Graphs.DistributionDotPlot = (->
  R = 4

  class DistributionDotPlot extends SeeIt.Graph
    constructor: ->
      super

      @style = {}
        
      @style.margin = {top: 20, right: 20, bottom: 30, left: 40}
      @style.width = @container.width() - @style.margin.left - @style.margin.right
      @style.height = @container.height() - @style.margin.top - @style.margin.bottom
      @style.color = d3.scale.category10()

      @x = d3.scale.linear().range([0,@style.width])
      @y = d3.scale.linear().range([@style.height,0])
      @x.domain(@minMaxWPadding(.05))
      @y.domain([0,@style.height])

      @sortedSet = new SortedSet(@dataset, @x, @y, @style.width, @style.height)

      @draw()

    formatData: ->

    minMaxWPadding: (padding) ->
      min = Infinity
      max = -Infinity

      @dataset.forEach (dataColumn) ->
        dataColumn.data.forEach (d) ->
          max = Math.max(max, d.value)
          min = Math.min(min, d.value)

      adjustment = Math.max(padding*(max - min),0.05)
      console.log min, max, adjustment
      return [min - adjustment,max + adjustment]

    draw: ->
      xAxis = d3.svg.axis()
        .scale(@x)
        .orient("bottom")

      yAxis = d3.svg.axis()
        .scale(@y)
        .orient("left")

      svg = d3.select(@container[0]).append("svg")
        .attr("width", @style.width + @style.margin.left + @style.margin.right)
        .attr("height", @style.height + @style.margin.top + @style.margin.bottom)
        .append("g")
        .attr("transform", "translate(" + @style.margin.left + "," + @style.margin.top + ")")

      svg.append("g")
        .attr("class", "x axis SeeIt")
        .attr("transform", "translate(0," + @style.height + ")")
        .call(xAxis)
        .append("text")
        .attr("class", "label")
        .attr("x", @style.width)
        .attr("y", -6)
        .style("text-anchor", "end")
        .text("X axis")


      svg.append("g")
        .attr("class", "y axis SeeIt")
        .call(yAxis)
        .append("text")
        .attr("class", "label")
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text("Y axis")

      graph = @
      svg.selectAll(".dot.SeeIt")
        .data(graph.sortedSet.dataArray)
        .enter().append("circle")
        .attr("class", "dot SeeIt")
        .attr("r", R)
        .attr("cx", (d) ->
          return graph.x(d.data.value)
        )
        .attr("cy", (d) ->
          console.log d, graph.y(d.y)
          return graph.y(d.y)
        )
        .style("fill", (d) ->
          #return color(d.species)
          return 0
        )

      legend = svg.selectAll(".legend")
        .data(@style.color.domain())
        .enter().append("g")
        .attr("class", "legend")
        .attr("transform", (d, i) -> 
          return "translate(0," + i * 20 + ")"
        )

      legend.append("rect")
        .attr("x", @style.width - 18)
        .attr("width", 18)
        .attr("height", 18)
        .style("fill", @style.color)

      legend.append("text")
        .attr("x", @style.width - 24)
        .attr("y", 9)
        .attr("dy", ".35em")
        .style("text-anchor", "end")
        .text((d) -> 
          return d
        )

    destroy: ->



  SortedSet = (->

    class Stack
      data = []

      constructor: (_data) ->
        data = if _data && _data.length then _data.splice 0 else []

      push: (d) ->
        data.push d

      pop: ->
        if data.length then data.pop() else null

      peek: ->
        if data.length then data[data.length - 1] else null

      size: ->
        data.length

    class SortedSet
      data = []
      dataset = []

      constructor: (_dataset, @xMap, @yMap, @width, @height) ->
        @dataArray = []
        data = new Array(Math.ceil(@width / (2*R)))
        console.log data.length

        #Initialize data array
        for i in [0...data.length]
          data[i] = new Stack()

        console.log data
        dataset = _dataset.splice 0
        fillSet.call(@)

      fillSet = ->
        self = @
        dataset.forEach (dataColumn) ->
          header = dataColumn.header
          datasetTitle = dataColumn.datasetTitle

          dataColumn.data.forEach (d) ->
            self.dataArray.push createDataWrapper(d, header, datasetTitle)

          #Fill array of stacks
          self.dataArray.forEach (d) ->
            addToStack.call(self, d)

      addToStack = (d) ->
        #Find what stack element needs to be added to
        idx = @valToIdx(d.data.value)

        #Set y value of element
        setY.call(@, d, idx)

        #Push to stack
        data[idx].push(d)

      setY = (d, idx) ->
        console.log idx
        d.y = if data[idx].size() then @solvePythagorean(d, data[idx].peek()) else R
        d.y = Math.max(
          d.y,
          if idx > 0 && data[idx - 1].size() && @collision(d, data[idx - 1].peek()) then @solvePythagorean(d, data[idx - 1].peek()) else -Infinity,
          if idx < data.length - 1 && data[idx + 1].size() && @collision(d, data[idx + 1].peek()) then @solvePythagorean(d, data[idx + 1].peek()) else -Infinity
        )

      solvePythagorean: (p1,p2) ->
        c = -(Math.pow(2*R,2) - Math.pow(@xMap(p1.data.value) - @xMap(p2.data.value),2) - Math.pow(p2.y,2))
        b = -2*p2.y
        #a = 1

        sqrt_b2_4ac = Math.sqrt(Math.pow(b,2) - 4*c)

        t1 = (-b + sqrt_b2_4ac) / 2
        t2 = (-b - sqrt_b2_4ac) / 2

        max = Math.max(
          if isNaN(t1) then -Infinity else t1, 
          if isNaN(t2) then -Infinity else t2
        )

        return max

      collision: (p1,p2) ->
        collide = @euclidDist(p1,p2) < 2*R
        console.log collide
        collide

      euclidDist: (p1,p2) ->
        Math.sqrt(Math.pow(@xMap(p1.data.value) - @xMap(p2.data.value),2) + Math.pow(p1.y - p2.y,2))

      createDataWrapper = (d, header, datasetTitle) ->
        {header: header, datasetTitle: datasetTitle, y: R, data: d}

      #Returns the index in the sortedset that a given value would map to
      valToIdx: (val) ->
        Math.floor(@xMap(val) / (2*R))

    SortedSet
  ).call(@)

  # SortedSet = (->
  #   class SortedSet
  #     _dataset = []
  #     _data = []
  #     _x = null
  #     _y = null

  #     constructor: (dataset, x, y) ->
  #       _x = x
  #       _y = y
  #       _dataset = dataset
  #       @fillSet(dataset[0])

  #     fillSet: (dataColumn) ->
  #       _data = createDataWrapper dataColumn.data.slice 0
  #       _data.data.sort (a,b) -> a.value < b.value
  #       @setHeights()
  #       return

  #     setHeights: ->
  #       _data.data.forEach (d, i) ->
  #         console.log "solving for index #{i}"
  #         if i > 0
  #           for j in [i-1..collisionLowerBoundIndex(i)]
  #             console.log "j: #{j}"
  #             if collision(i,j)
  #               console.log "collision!"
  #               _data.yValues[i] = solvePythagorean(i,j)
  #               if i < _data.data.length - 1
  #                 _data.yValues[i+1] = _data.yValues[i]

  #     addToSet: (dataColumn) ->

  #     get: ->
  #       _data

  #     clear: ->
  #       _data = []
  #       _dataset = []

  #     createDataWrapper = (data) ->
  #       size = data.length
  #       wrapper = {data: data, yValues: new Array(size)}

  #       while(size--) 
  #         wrapper.yValues[size] = R

  #       return wrapper


  #     collisionLowerBoundIndex = (i) ->
  #       j = i - 1

  #       while(j >= 0 && Math.abs(_x(_data.data[i].value) - _x(_data.data[j].value)) < 2*R)
  #         j--

  #       return Math.max(j,0)

  #     collision = (i,j) ->
  #       euclidDist(i,j) < 2*R

  #     euclidDist = (i,j) ->
  #       dist = Math.sqrt(Math.pow(_x(_data.data[i].value) - _x(_data.data[j].value),2) + Math.pow(_y(_data.yValues[i]) - _y(_data.yValues[j]),2))
  #       console.log dist
  #       dist

  #     solvePythagorean = (i,j) ->
  #       c = -(Math.pow(2*R,2) - Math.pow(_x(_data.data[i].value) - _x(_data.data[j].value),2) - Math.pow(_y(_data.yValues[j]),2))
  #       b = -2*_y(_data.yValues[j])
  #       #a = 1

  #       sqrt_b2_4ac = Math.sqrt(Math.pow(b,2) - 4*c)
  #       return Math.max(
  #         (-b + sqrt_b2_4ac) / 2, 
  #         (-b - sqrt_b2_4ac) / 2
  #       )

  #   SortedSet
  # ).call(@)


  DistributionDotPlot
).call(@)