@SeeIt.Dataset = (->
  class Dataset
    _.extend(@prototype, Backbone.Events)
    
    constructor: (@container, @title, dataset, @hasLabels, @labelKey) ->
      @dataset = dataset || []
      @data = []
      @dataFormat = if @dataIsArray() then "array" else "json"
      @labels = if @hasLabels then @getLabels() else null
      @headers = @getHeaders()
      @initLayout()
      console.log "dataset built"

    initLayout: ->
      @container.html("""
        <li class="SeeIt dataset list-group-item">
          <a class="SeeIt">#{@title}</a>
        </li>
        <div class="SeeIt data-columns list-group-item" style="padding: 5px; display: none">
          <ul class='SeeIt list-group data-list'>
          </ul>
        </div>
      """)

      @initData()
      @registerEvents()

    getLabels: ->
      labels = []
      if @dataset.length
        if @dataFormat == "array"
            for i in [1...@dataset.length]
              labels.push @dataset[i][0]
        else
          for i in [1...@dataset.length]
            labels.push @dataset[i][@labelKey]

      return labels

    getHeaders: ->
      headers = []
      if @dataset.length
        if @dataFormat == "array"
          headers = if @hasLabels then @dataset[0].slice(1, @dataset[0].length) else @dataset[0]
        else
          headers = Object.keys(@dataset[0])

      return headers

    dataIsArray: ->
      return (if @dataset.length then $.isArray(@dataset[0]) else undefined)

    initData: ->
      if @dataFormat == "array"
        start = (if @hasLabels then 1 else 0)
        for i in [start...@dataset[0].length]
          console.log i
          @addData(@headers[i - start], @buildData(i))
      else
        for header in @headers
          @addData(header, @buildData(header))


    #Takes either a key or a column index (depending on data format)
    # and returns array of elements in that column
    buildData: (id) ->
      data = []
      for i in [(if @dataFormat == "array" then 1 else 0)...@dataset.length]
        data.push(@dataset[i][id])

      return data

    addData: (header, data) ->
      console.log "adding data"
      @container.find(".data-list").append("<li class='SeeIt list-group-item data-container'></li>")
      @data.push(new SeeIt.Data(@container.find(".data-container").last(),header, data))

    registerEvents: ->
      toggleData = ->
        $(@).toggleClass('active')
        $(@).find('a').toggleClass('selected')
        $(@).parent().find('.data-columns').slideToggle()


      @container.find('.dataset').off('click', toggleData).on('click', toggleData)

    #Static method that validates data format
    @validateData: (data) ->
      isArray = false
      if $.isArray(data)
        for i in [0...data.length]
          if i == 0
            if $.isArray(data[i])
              isArray = true
            else if !(typeof data[i] == "object")
              return false
          else
            if isArray && !$.isArray(data[i])
              return false
            else if !isArray && !(typeof data[i] == "object") 
              return false

      return true

  Dataset
).call(@)