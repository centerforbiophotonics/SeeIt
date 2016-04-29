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
              row = r.split(',')

              row.forEach (d, i) ->
                row[i] = if !isNaN(parseFloat(d)) then parseFloat(d) else d

              data.push row

            console.log data
            callback data
          catch err
            console.log err
          

        filereader.readAsText file
      else
        console.log "error in handleUpload"

  CSVManager
).call(@)
