@SeeIt.CSVManager = (->
  class CSVManager
    _.extend(@prototype, Backbone.Events)

    constructor: ->

    handleUpload: (file, callback) ->
      self = @
      data = []

      if window.File && window.FileReader && window.FileList && window.Blob
        filereader = new window.FileReader()

        filereader.onload = ->
          txtRes = filereader.result

          try
            csvRows = txtRes.split '\n'
            csvData = []

            csvRows.forEach (r) ->
              data.push r.split(',')

            callback data
          catch err
            console.log err
          

        filereader.readAsText file
      else
        console.log "error in handleUpload"

  CSVManager
).call(@)
