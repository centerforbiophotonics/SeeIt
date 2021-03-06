@SeeIt.Graphs.MosaicPlot = (->
  class MosaicPlot extends SeeIt.Graph

    constructor: ->
      super
      @chartObject = null
      @listenerInitialized = false
      @rendered = false
      @graph = []
      @initListeners()
      @total_n = 0


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
      @eventCallbacks['label:changed'] = @eventCallbacks['data:created']
      @eventCallbacks['header:changed'] = @eventCallbacks['data:created']
      @eventCallbacks['color:changed'] = @eventCallbacks['data:created']
      @eventCallbacks['data:changed'] = @eventCallbacks['data:created']
      @eventCallbacks['filter:changed'] = @eventCallbacks['data:created']

      for e, cb of @eventCallbacks
        @on e, cb

      $(window).on('resize', (event) ->
        self.eventCallbacks['data:created']()
      )

    clearGraph: ->
      @container.html('')
      @rendered = false

    formatData: ->
      matched_labels = {}
      @dataset.forEach (data_role) ->
        data_role.data[0].data().forEach (d) ->
          if !matched_labels.hasOwnProperty(d.label())
            matched_labels[d.label()] = {}
          
          matched_labels[d.label()][data_role.name] = d.value(); # data_role.name could be indep or dep.
      # make dataColumn in rows to process the data.
      counts = {"__total": 0} #total number of independent variables.

      for label, values of matched_labels
        if !counts.hasOwnProperty(values.Independent)
          counts[values.Independent] = {"__total": 0}

        if !counts[values.Independent].hasOwnProperty(values.Dependent)
          counts[values.Independent][values.Dependent] = 0

        counts["__total"]++ # total number of rows
        counts[values.Independent]["__total"]++ # total number of males or females
        counts[values.Independent][values.Dependent]++ # total number of true/false

      @total_n = counts["__total"]

      for independent_variable, dependent_variables of counts 
        if independent_variable != "__total"
          for dependent_variable, total of dependent_variables
            if dependent_variable != "__total"
              @graph.push {
                w: dependent_variables.__total/counts.__total,
                h: total/dependent_variables.__total,
                total: total,
                overall_total: counts.__total,
                dependent_total: dependent_variables.__total,
                independent: independent_variable,
                dependent: dependent_variable
              }

    refresh: (options) ->
      $('.tooltip').remove()
      @container.html("")
      @draw(options)

    draw: (options) ->
      margin = {top: 25, right: 20, bottom: 40, left: 55}
      width = @container.width() - margin.left - margin.right
      widthOfSvg = width + margin.left + margin.right

      if widthOfSvg > 0
        @formatData()

        graph = @
        @container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")

        height = Math.max(270, @container.height()) - margin.top - margin.bottom

        x = d3.scale.linear().range([0, width])
        y = d3.scale.linear().range([height, 0])
        xAxis = d3.svg.axis().scale(x).orient("bottom").tickFormat(d3.format("%"))
        yAxis = d3.svg.axis().scale(y).orient("left").tickFormat(d3.format("%"))

        color = d3.scale.category10()

        tooltip = d3.select("body").append("div")
          .attr("class", "tooltip")
          .style("opacity", 0);

        @svg = d3.select(graph.container.find('.graph-svg')[0])
          .attr('width', width + margin.left + margin.right)
          .attr('height', height + margin.top + margin.bottom)
          .append('g')
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

        segments = d3.nest() # separate independent variables into nested arrays
          .key((d) -> d.independent).sortKeys(d3.ascending)
          .entries(@graph);

        segments.forEach (d) -> 
          d.values.sort (a, b) -> 
            if a.dependent < b.dependent
              return -1
            if a.dependent > b.dependent
              return 1
            return 0

        columns = @svg.selectAll('.column')
          .data(segments).enter().append('g')
          .attr('class', 'column')
          .attr('data-index', (d,i) -> i)
          .attr('transform', (d,i) -> 
            x_offset = 0
            segments.forEach (seg,seg_i) ->
              if seg_i < i
                x_offset += seg.values[0].w
            
            return 'translate(' + x(x_offset) + ')'
          );

        cell = columns.selectAll(".cell")
          .data((d) -> d.values)
          .enter().append('g')
            .attr('class', 'cell')
            .attr('transform', (d,i) ->
              segment_index = parseInt(this.parentNode.getAttribute('data-index'))
              y_offset = 0
              segments[segment_index].values.forEach (rect,rect_i) ->
                if rect_i < i
                  y_offset += rect.h

              return 'translate(0,' + y(1 - y_offset) + ')'
            );


        cell.append('rect')
          .attr('class', 'rects')
          .attr('width', (d) -> d.w * width)
          .attr('height', (d) -> d.h * height)
          .attr('stroke', 'white')
          .attr('stroke-width', '1px')
          .style('fill', (d,i) -> color(i))
          .on("mouseover", (d, i) ->
                tooltip.style('opacity', 0)
                element = d3.select(@)
                element.transition().duration(200)
                  .style('opacity', 0.95)
                element.style('stroke', 'black')
                element.style('stroke-width', '0.5px')
                tooltip.transition()
                  .duration(300)
                  .style("opacity", .9)
                  .style('visibility', 'visible')
                tooltip.html("<div>
                  <strong>#{d.independent}</strong>: #{d.dependent_total}/#{d.overall_total} (#{d3.round(d.w * 100, 1) + '%'})<br/>
                  <strong>#{d.dependent}</strong>: #{d.total}/#{d.dependent_total} (#{d3.round(d.h * 100, 1) + '%'})<br/>
                  <strong>Total</strong>: #{d.total} (#{d3.round((d.total/d.overall_total) * 100, 1)}%)
                  </div>")
                  .style("background-color", "white")
                  .style("border", "1px solid black")
                  .style("padding", "3px")
                  .style("border-radius", "3px")
                  .style("left", (d3.event.pageX + 5) + "px")
                  .style("top", (d3.event.pageY - 28) + "px")
          
          )
          .on('mousemove', () -> tooltip.style("top", (d3.event.pageY-10)+"px").style("left",(d3.event.pageX+10)+"px"))
          .on("mouseout", () ->
              element = d3.select(@)
              element.transition().duration(200)
                  .style('opacity', 0.75)
              element.style('stroke', 'white')
              tooltip.transition()
                   .duration(500)
                   .style('visibility', 'hidden')
                   
              # $('.tooltip').remove()
          )
          .attr('opacity', 0.3)
          .transition().duration(300)
          .attr('opacity', 0.75);

        cell.append('text')
          .style('pointer-events', 'none')
          .style('text-anchor', 'middle')
          .style('font-family', 'Times')
          .style('opacity', 0.8)
          .attr('x', (d) -> (d.w * width) / 2)
          .attr('y', (d) -> (d.h * height) / 2)
          .text((d) -> d.independent + ', ' + d.dependent + ': ' + d3.round(d.w * d.h * 100, 1) + '%');

        @svg.append('g').append('text')
          .attr('y', -15)
          .style('text-anchor', 'middle')
          .text('n = ' + @total_n);

        xAxisLabel = @dataset.filter((d) -> d.name == "Independent")[0].data[0].header
        yAxisLabel = @dataset.filter((d) -> d.name == "Dependent")[0].data[0].header

        @svg.append('g')
          .attr('class', 'axis SeeIt')
          .call(yAxis)
          .append('text')
          .attr("class", "label")
          .attr('transform', 'rotate(-90)')
          .attr('y', -55)
          .attr('dy', '.71em')
          .attr('x', -height/2)
          .style('text-anchor', 'middle')
          .style('font-size', '15px')
          .text(yAxisLabel);     

        @svg.append('g')
          .attr('class', 'axis SeeIt')
          .attr('transform', 'translate(0,' + height + ')')   
          .call(xAxis)
          .append("text")
          .attr("class", "label")
          .attr('x', width/2)
          .attr('y', 35)
          .style('text-anchor', 'middle')
          .style('font-size', '15px')
          .text(xAxisLabel);

        d3.selectAll('.tick text')
          .style('fill', '#000')
          .style('stroke', 'none')
          .style('font-weight', 'bold');  

        @graph = [];

    destroy: ->

    dataFormat: ->
      [
        {
          name: "Independent",
          type: "categorical",
          multiple: false
        },
        {
          name: "Dependent",
          type: "categorical",
          multiple: false
        }
      ]


    options: ->
      [
        
      ]

    @name = ->
      "Mosaic Plot"


  MosaicPlot
).call(@)

@SeeIt.GraphNames["MosaicPlot"] = "Mosaic Plot"