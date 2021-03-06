@SeeIt.CSVManager = (->
  class CSVManager
    _.extend(@prototype, Backbone.Events)

    ###*
     * [constructor description]
     * @return {[type]} [description]
    ###
    constructor: ->

    ###*
     * [downloadFromServer description]
     * @param  {[type]} url     [description]
     * @param  {[type]} success [description]
     * @param  {[type]} error   [description]
     * @return {[type]}         [description]
    ###
    downloadFromServer: (url, success, error) ->
      self = @

      current_hostname = document.location.hostname + "#{if document.location.port then ":"+document.location.port else ""}"
      target_hostname = getHostnameFromString(url)

      is_jsonp = current_hostname != target_hostname

      if is_jsonp

        $.ajax({
            url: url,
            # crossOrigin: true,
            timeout: 5000,
            jsonp: "callback",
            dataType: "jsonp",
            success: success,
            error: error
          })
      else
        relative_path = getPathFromURL(url)

        $.ajax({
          dataType: "json",
          url: relative_path,
          success: success,
          error: error
        });

    ###*
     * [handleUpload description]
     * @param  {[type]}   file     [description]
     * @param  {Function} callback [description]
     * @return {[type]}            [description]
    ###
    handleUpload: (file, callback) ->
      self = @
      data = []

      if window.File && window.FileReader && window.FileList && window.Blob
        filereader = new window.FileReader()

        filereader.onload = ->
          txtRes = filereader.result

          try
            # csvRows = txtRes.split '\n'
            # csvData = []

            # csvRows.forEach (r) ->
            #   row = r.split(',')

            #   row.forEach (d, i) ->
            #     row[i] = if !isNaN(Number(d)) then Number(d) else d

            #   data.push row
            data = CSVManager.parseCSV(txtRes)
            callback data
          catch err


        filereader.readAsText file
      else
        console.log "error in handleUpload"

    @parseCSV = (text) ->
      return Papa.parse(text, {skipEmptyLines: true}).data



  getPathFromURL = (url) ->
    if url[0] == "/"
      return url
    else
      split_url = url.split("/")

      if split_url[0] == "http:" || split_url[0] == "https:"
        split_url.splice(0, 2)
        return "/" + split_url.join("/")
      else
        split_url.splice(0, 1)
        return "/" + split_url.join("/")

  getHostnameFromString = (url) ->
    split_url = url.split("/")

    if !split_url[0].length
      return document.location.hostname + "#{if document.location.port then ":"+document.location.port else ""}"
    else
      if split_url[0] == "http:" || split_url[0] == "https:"
        return split_url[2]
      else
        return split_url[0]

  CSVManager
).call(@)
