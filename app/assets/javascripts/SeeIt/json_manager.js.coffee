@SeeIt.JsonManager = (->
  class JsonManager
    _.extend(@prototype, Backbone.Events)

    constructor: ->

    downloadFromServer: (url, success, error) ->
      self = @

      current_hostname = document.location.hostname + "#{if document.location.port then ":"+document.location.port else ""}"
      target_hostname = getHostnameFromString(url)

      is_jsonp = current_hostname != target_hostname

      if is_jsonp

        $.ajax({
            timeout: 5000,
            url: url,
            # crossOrigin: true,
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

    handleUpload: (file, callback) ->
      self = @
      data = null

      if window.File && window.FileReader && window.FileList && window.Blob
        filereader = new window.FileReader()

        filereader.onload = ->
          txtRes = filereader.result

          try
            data = JSON.parse txtRes

            if !$.isArray(data) then data = [data]

            callback data
          catch e
            console.log e

        filereader.readAsText file
      else 
        console.log "Error uploading JSON Data"


    handleDownload: (dataCollection) ->
      blob = new Blob([JSON.stringify(dataCollection.toJson())]);
      filename = prompt("Please enter the name of the file you want to save to (will save with .json extension)");

      if filename == "" || (filename != null && filename.trim() == "")
        alert('Filename cannot be blank');
      else if filename && filename != "null" 
        saveAs(blob, filename+".json");

    getJsonTitle: (file, callback) ->
      self = @
      data = null
      jsonTitle = null

      if window.File && window.FileReader && window.FileList && window.Blob
        filereader = new window.FileReader()

        filereader.onload = ->
          txtRes = filereader.result

          try
            data = JSON.parse txtRes
            jsonTitle = data['title']
            callback(jsonTitle)
          catch e
            console.log e
            alert(e)

        filereader.readAsText file

      else 
        console.log "Error reading JSON Data"
    

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


   JsonManager
).call(@)