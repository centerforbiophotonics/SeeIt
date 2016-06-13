@SeeIt.Graphs.CorrelationPlot = (->
  class CorrelationPlot extends SeeIt.Graph
    constructor: ->
      super
      @rendered = false
      @data = []
      @initListeners()

    formatData: ->
      groups = {}

      @dataset.forEach (data) ->
        dataColumn = data.data[0]
        dataColumn.data().forEach (d) ->
          if !groups[d.label()]
            groups[d.label()] = {label: -> d.label()}

          if data.name == "x-axis"
            groups[d.label()].x = -> d.value()
          else
            groups[d.label()].y = -> d.value()

      for key, val of groups
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
      @formatData()

      console.log @data


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

      @svg = d3.select(@container[0]).append("svg")
          .attr("width", width + margin.left + margin.right)
          .attr("height", height + margin.top + margin.bottom)
        .append("g")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

      tooltip = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("opacity", 0)


      xScale.domain([d3.min(@data, xValue)-1, d3.max(@data, xValue)+1])
      yScale.domain([d3.min(@data, yValue)-1, d3.max(@data, yValue)+1])

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
          .attr("r", 3.5)
          .attr("cx", xMap)
          .attr("cy", yMap)
          .style("fill", (d) ->  color(cValue(d))) 
          .on("mouseover", (d) ->
              tooltip.transition()
                 .duration(200)
                 .style("opacity", .9)
              tooltip.html(d.label() + "<br/> (" + xValue(d)  + ", " + yValue(d) + ")")
                 .style("left", (d3.event.pageX + 5) + "px")
                 .style("top", (d3.event.pageY - 28) + "px")
          )
          .on("mouseout", (d) ->
              tooltip.transition()
                   .duration(500)
                   .style("opacity", 0)
          )



    clearGraph: ->
      @container.html("")
      @rendered = false

    refresh: (options = []) ->
      @container.html("")
      @draw(options)

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

    @name = ->
      "Correlation Plot"

  CorrelationPlot
).call(@)

@SeeIt.GraphNames["CorrelationPlot"] = "Correlation Plot"