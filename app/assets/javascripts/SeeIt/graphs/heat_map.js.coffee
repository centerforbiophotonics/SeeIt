@SeeIt.Graphs.HeatMap = (->
  class HeatMap extends SeeIt.Graph

    constructor: ->
      super
      @listenerInitialized = false
      @rendered = false
      @initListeners()


    initListeners: ->
      self = @

      @eventCallbacks['data:created'] =  (options) ->
        if self.allRolesFilled()
          if !self.rendered
            self.rendered = true
            self.draw.call(self, options)
          else
            self.refresh.call(self, options)
        else
          self.draw.call(self, options)
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


    refresh: (options) ->
      

    draw: (options) ->
      graph = @
      @MaxAverage = 4
      @MaxCount = 7
      @MaxTotal = 18
      colors = []
      StartMajors = ["CSE", "BIS", "PHY", "MAT"]
      EndMajors = ["CSE", "BIS", "PHY", "MAT", "EVE"]
      Pairs = {'CSE': {'CSE': {count:5, total:15}, 'BIS': {count:2, total:7}, 'MAT': {count:1, total:4}}, 'BIS': {'BIS': {count:6, total:16}, 'EVE': {count:3, total:11}}, 'PHY': {'PHY': {count:7, total:18}, 'MAT': {count:2, total:6}}, 'MAT': {'MAT': {count:1, total:4}}}
              
      StartMajors.sort()
      EndMajors.sort()
      @xAxis = d3.svg.axis()
                .scale(@x)
                .orient("top")

      @style = {}
        
      @style.margin = {top: 20, right: 20, bottom: 30, left: 40}
      @style.width = @container.width() - @style.margin.left - @style.margin.right
      @style.height = Math.max(270, @container.height()) - @style.margin.top - @style.margin.bottom

      gridSize = @style.height / EndMajors.length
      @svg = d3.select(@container[0]).append("svg")
        .attr("width", @style.width + @style.margin.left + @style.margin.right)
        .attr("height", @style.height + @style.margin.top + @style.margin.bottom)
        .append("g")
        .attr("transform", "translate(" + @style.margin.left + "," + @style.margin.top + ")")

      console.log(gridSize)
      @yLabels = @svg.selectAll(".startLabel")
                      .data(EndMajors)
                      .enter().append("text")
                        .text((d) -> return d)
                        .attr("x", 0)
                        .attr("y", (d,i) -> return i * gridSize)
                        .style("text-anchor", "end")
                        .attr("transform", "translate(-6, " + gridSize / 1.5 + ")")

      @xLabels = @svg.selectAll(".endLabel")
                      .data(StartMajors)
                      .enter().append("text")
                        .text((d) -> return d)
                        .attr("x", (d,i) -> return i*gridSize)
                        .attr("y", 0)
                        .style("text-anchor", "middle")
                        .attr("transform", "translate(" + gridSize / 2 + ", -6)")

      StartMajors.forEach (entry) ->
        console.log Pairs[entry]
        EndMajors.forEach (endEntry) ->
          
          if (Pairs[entry][endEntry])
            console.log "Drawing " + Pairs[entry][endEntry]
            console.log options[0].value
            fillstyle = options[0].value
            console.log "fillstyle " + fillstyle
            #console.log "MAXAVG " + graph.MaxAverage + " MAXTOT "  + graph.MaxTotal + " MAXCOUNT " + graph.MaxCount
            if (fillstyle == "1")
              console.log "Hello?"
              graph.svg
                .append("rect")
                  .attr("x", -> return StartMajors.indexOf(entry) * gridSize)
                  .attr("y", -> return EndMajors.indexOf(endEntry) * gridSize)
                  .attr("rx", 3)
                  .attr("ry", 3)
                  .attr("width", gridSize-2)
                  .attr("height", gridSize-2)
                  .style("fill", "red")
                  .style("fill-opacity", -> return ((Pairs[entry][endEntry].total / Pairs[entry][endEntry].count) / graph.MaxAverage))
                  .style("stroke", "black")
                  .style("stroke-width", "1px")

            else if (fillstyle == "2") 
              graph.svg
                .append("rect")
                  .attr("x", -> return StartMajors.indexOf(entry) * gridSize)
                  .attr("y", -> return EndMajors.indexOf(endEntry) * gridSize)
                  .attr("rx", 3)
                  .attr("ry", 3)
                  .attr("width", gridSize-2)
                  .attr("height", gridSize-2)
                  .style("fill", "red")
                  .style("fill-opacity", Pairs[entry][endEntry].total / graph.MaxTotal)
                  .style("stroke", "black")
                  .style("stroke-width", "1px")

            else if (fillstyle == "3")
              graph.svg
                .append("rect")
                  .attr("x", -> return StartMajors.indexOf(entry) * gridSize)
                  .attr("y", -> return EndMajors.indexOf(endEntry) * gridSize)
                  .attr("rx", 3)
                  .attr("ry", 3)
                  .attr("width", gridSize-2)
                  .attr("height", gridSize-2)
                  .style("fill", "red")
                  .style("fill-opacity", Pairs[entry][endEntry].count / graph.MaxCount)
                  .style("stroke", "black")
                  .style("stroke-width", "1px")
          else 
            #DRAWEMPTYCELL
            graph.svg
              .append("rect")
                .attr("x", -> return StartMajors.indexOf(entry) * gridSize)
                .attr("y", -> return EndMajors.indexOf(endEntry) * gridSize)
                .attr("rx", 3)
                .attr("ry", 3)
                .attr("width", gridSize-2)
                .attr("height", gridSize-2)
                .style("fill", "white")
                .style("stroke", "gray")
                .style("stroke-width", "1px")
    destroy: ->


    dataFormat: ->
      [
        {
          name: "x-axis",
          type: "categorical",
          multiple: false
        },
        {
          name: "y-axis",
          type: "categorical"
          multiple: false
        },
        {
          name: "values",
          type: "numeric"
          multiple: false
        }
      ]


    options: ->
      [
        {
          label: "Average[1]/Total[2]/Count[3]",
          type: "select",
          values: [1,2,3],
          default: 1
        }
      ]

  HeatMap
).call(@)

@SeeIt.GraphNames["HeatMap"] = "Heat Map"