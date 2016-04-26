@SeeIt.GoogleSpreadsheetManager = (->
	class GoogleSpreadsheetManager
		_.extend(@prototype, Backbone.Events)

		constructor: (@url) ->
			console.log "In GoogleSpreadsheetManager constructor"
			@getData()

		getData: ->
			self = @
			# @url = 'https://spreadsheets.google.com/feeds/worksheets/0AuGPdilGXQlBdEd4SU44cVI5TXJxLXd3a0JqS3lHTUE/public/basic?alt=json'
			
			$.ajax({ 
				url: @url,
				jsonp: "callback",
				dataType: "jsonp",
				success: (data) ->
					console.log(data)
				error: ->
					alert("Could not retrieve worksheets from the spreadsheet. Is it published?")
			})

	GoogleSpreadsheetManager
).call(@)