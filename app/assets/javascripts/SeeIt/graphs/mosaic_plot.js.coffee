@SeeIt.Graphs.MosaicPlot = (->
  class MosaicPlot extends SeeIt.Graph

    constructor: ->
      super
      @chartObject = null
      @listenerInitialized = false
      @rendered = false
      @graph = []
      @initListeners()


    initListeners: ->
      self = @

      @eventCallbacks['data:created'] = (options) ->
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
      @eventCallbacks['label:changed'] = @eventCallbacks['data:created']
      @eventCallbacks['header:changed'] = @eventCallbacks['data:created']
      @eventCallbacks['color:changed'] = @eventCallbacks['data:created']
      @eventCallbacks['data:changed'] = @eventCallbacks['data:created']

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

      for independent_variable, dependent_variables of counts 
        if independent_variable != "__total"
          for dependent_variable, total of dependent_variables
            if dependent_variable != "__total"
              @graph.push {
                w: dependent_variables.__total/counts.__total,
                h: total/dependent_variables.__total,
                independent: independent_variable,
                dependent: dependent_variable
              }

      console.log @graph

    refresh: (options) ->
      @container.html("")
      @draw(options)

    draw: (options) ->
      @formatData()

      graph = @
      @container.html("<svg class='SeeIt graph-svg' style='width: 100%; min-height: 270px'></svg>")

      margin = {top: 20, right: 20, bottom: 30, left: 40}
      width = @container.width() - margin.left - margin.right
      height = Math.max(270, @container.height()) - margin.top - margin.bottom

      x = d3.scale.linear().range([0, width])
      y = d3.scale.linear().range([height, 0])
      xAxis = d3.svg.axis().scale(x).orient("bottom").tickFormat(d3.format("%"))
      yAxis = d3.svg.axis().scale(y).orient("left").tickFormat(d3.format("%"))

      color = d3.scale.category10()

      tooltip = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("opacity", 0.5);

      @svg = d3.select(graph.container.find('.graph-svg')[0])
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
        .append('g')
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

      @svg.append('g')
        .attr('class', 'y axis SeeIt')
        .style('fill', 'none')
        .style('stroke', '#000')
        .style('font-size',  "12px")
        .attr('font-family', 'sans-serif')
        .call(yAxis)

      @svg.append('g')
        .attr('class', 'x axis SeeIt')
        .attr("transform", "translate(0," + height + ")")
        .style('fill', 'none')
        .style('stroke', '#000')
        .style('font-size', "12px")
        .attr('font-family', 'sans-serif')
        .call(xAxis)

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

      console.log segments

      @segment = @svg.selectAll('.segment')
        .data(segments).enter().append('g')
        .attr('class', 'segment')
        .attr('data-index', (d,i) -> i)
        .attr('transform', (d,i) -> 
          x_offset = 0
          segments.forEach (seg,seg_i) ->
            if seg_i < i
              x_offset += seg.values[0].w
          
          return 'translate(' + x(x_offset) + ')'
        );

      rects = @segment.selectAll('.rects')
        .data((d) -> d.values).enter()
        .append('rect')
        .attr('class', 'rects')
        .attr('width', (d) -> d.w * width)
        .attr('height', (d) -> d.h * height)
        .style('fill', (d,i) -> color(i))
        .attr('transform', (d,i) -> 
          segment_index = parseInt(this.parentNode.getAttribute('data-index'))
          y_offset = 0
          segments[segment_index].values.forEach (rect,rect_i) ->
            if rect_i < i
              y_offset += rect.h
          
          return 'translate(0,' + y(1 - y_offset) + ')'
        )
        .on("mouseover", (d, i) ->
              this_rect = d3.select(@)
              this_rect.style('opacity', 0.7)
              tooltip.transition()
                 .duration(200)
                 .style("opacity", .9)
                 .style('visibility', 'visible')
              tooltip.html("<br/> [" + d.independent + ": " + d3.round(d.w * 100, 1) + "%, " +
                                       d.dependent + ": "+ d3.round(d.h * 100, 1) + "%]")
                 .style("left", (d3.event.pageX + 5) + "px")
                 .style("top", (d3.event.pageY - 28) + "px")
        )
        .on('mousemove', () -> tooltip.style("top", (d3.event.pageY-10)+"px").style("left",(d3.event.pageX+10)+"px"))
        .on("mouseout", () ->
            this_rect = d3.select(@)
            this_rect.style('opacity', 1)
            tooltip.transition()
                 .duration(500)
                 .style('visibility', 'hidden')
        )
        .attr('opacity', 0.3)
        .transition().duration(300)
        .attr('opacity', 1);


      @graph = []


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