@SeeIt.JsonManager = (->
  class JsonManager
    _.extend(@prototype, Backbone.Events)

    constructor: ->

    handleUpload: (file, callback) ->
      self = @
      data = null

      if window.File && window.FileReader && window.FileList && window.Blob
        filereader = new window.FileReader()

        filereader.onload = ->
        	txtRes = filereader.result
        	console.log txtRes

        	try
        		data = JSON.parse txtRes
        		console.log data, typeof data

        		if !$.isArray(data) then data = [data]

        		callback data
        	catch e
        		console.log e

        filereader.readAsText file
      else 
      	console.log "Error uploading JSON Data"
        	

    handleDownload: (dataCollection) ->
      blob = new Blob([dataCollection.toJsonString()]);
      filename = prompt("Please enter the name of the file you want to save to (will save with .json extension)");

      if filename == "" || (filename != null && filename.trim() == "")
        alert('Filename cannot be blank');
      else if filename && filename != "null" 
        saveAs(blob, filename+".json");
    	
   JsonManager
).call(@)