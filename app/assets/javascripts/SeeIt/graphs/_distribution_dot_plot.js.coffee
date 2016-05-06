_DistributionDotPlot = (->
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

    # class SortedArray

    #   constructor: (_data) ->
    #     data = if _data && _data.length then _data.splice 0 else []
    #     data.sort()

    #     @insert = (d) ->

    #       data.push d

    #     @pop = ->
    #       if data.length then data.pop() else null

    #     @peek = ->
    #       if data.length then data[data.length - 1] else null

    #     @size = ->
    #       data.length

    class IterativeArray

      constructor: (data) ->
        @it = 0
        @_data = if data && data.length then data.splice 0 else []

      push: (d) ->
        @_data.push d

      pop: (d) ->
        @_data.pop d

      set: (d, idx) ->
        if idx >= 0 && idx <= @_data.length 
          if idx == @_data.length then @_data.push d else @_data[idx] = d 
        else 
          undefined

      remove: (idx) ->
        if idx >= 0 && idx < @_data.length then @_data.splice idx else undefined

      at: (idx) ->
        if idx >= 0 && idx < @_data.length then @_data[idx] else undefined

      first: ->
        if @_data.length
          return @_data[0] 
        else 
          return undefined

      last: ->
        if @_data.length then @_data[@_data.length - 1] else undefined

      next: ->
        if !@_data.length || @it > @_data.length-1 then undefined else @_data[@it]

      iterate: ->
        @it++

    class SortedSet
      data = []
      dataset = []

      constructor: (_dataset, @xMap, @yMap, @width, @height) ->
        @dataArray = []
        data = new Array(Math.ceil(@width / (2*R)))

        #Initialize data array
        for i in [0...data.length]
          data[i] = new IterativeArray()

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
            self.placeInArray.call(self, d)


      placeInArray: (d) ->
        #Find what member array the element should be added to
        idx = @valToIdx(d.data.value)

        left = @findPossibleCollisions(d.data.value, idx-1)
        right = @findPossibleCollisions(d.data.value, idx+1)        
        mine = data[idx]

        while(collideLeft = @collision(d, l = left.next()) || collideMiddle = @collision(d, c = mine.next()) || collideRight = @collision(d, r = right.next()))
          if collideMiddle
            d.y = Math.max(@solvePythagorean(d,c), d.y)
            mine.iterate()

          if l != undefined && @collision(d, l = left.next())
            d.y = Math.max(@solvePythagorean(d,l), d.y)
            left.iterate()

          if r != undefined && @collision(d, r = right.next())
            d.y = Math(@solvePythagorean(d,r), d.y)
            right.iterate()

        mine.set(d, mine.it)

      findPossibleCollisions: (val, idx) ->
        if idx < 0 || idx >= data.length then return new IterativeArray()

        possibleCollisions = new IterativeArray()

        for d in data[idx]
          if Math.abs(d.data.value - val) < 2*R then possibleCollisions.push d

        return possibleCollisions

      # addToStack = (d) ->
      #   #Find what stack element needs to be added to
      #   idx = @valToIdx(d.data.value)

      #   #Set y value of element
      #   setY.call(@, d, idx)

      #   #Push to stack
      #   data[idx].push(d)

      # setY = (d, idx) ->
      #   d.y = if data[idx].size() then @solvePythagorean(d, data[idx].peek()) else R
      #   d.y = Math.max(
      #     d.y,
      #     if idx > 0 && data[idx - 1].size() && @collision(d, data[idx - 1].peek()) then @solvePythagorean(d, data[idx - 1].peek()) else -Infinity,
      #     if idx < data.length - 1 && data[idx + 1].size() && @collision(d, data[idx + 1].peek()) then @solvePythagorean(d, data[idx + 1].peek()) else -Infinity
      #   )

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
        if !p1 || !p2 then return false

        collide = @euclidDist(p1,p2) < 2*R
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


  DistributionDotPlot
).call(@)