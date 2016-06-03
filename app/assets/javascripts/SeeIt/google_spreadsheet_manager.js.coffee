@SeeIt.GoogleSpreadsheetManager = (->
	class GoogleSpreadsheetManager
		_.extend(@prototype, Backbone.Events)

		constructor: (@url, @callback) ->


		getData: ->
			# url = "1Fd67EnWcTb4Ibkm9XvUU62_MkXg2FITPtje7_YewuGE"
			# url = "https://docs.google.com/spreadsheets/d/1Fd67EnWcTb4Ibkm9XvUU62_MkXg2FITPtje7_YewuGE/pubhtml" <- has description at bottom
			# url = "https://docs.google.com/spreadsheets/d/1DHbcvH_HOk5O8Y8uDW2ESrxWFSuOTAk2519TgzeFAUM/pubhtml"

			Tabletop.init({
				key: @url,
				callback: ((data, tabletop, error) -> @proccessSpreadsheet(data, tabletop, error)).bind(@)
			})

		proccessSpreadsheet: (data, tabletop, error) ->
			self = @
			collection = []

			if error
				@callback false
				return

			for name, dataset of data
				types = @resolveTypes(dataset)

				new_dataset = {
					title: dataset.name
					dataset: {
						labels: dataset.elements.map((element) -> element[dataset.column_names[0]])
						columns: new Array(dataset.column_names.length - 1)
					}
					isLabeled: true
				}

				dataset.column_names.forEach (column_name, i) ->
					if i > 0
						new_dataset.dataset.columns[i-1] = {
							header: column_name,
							type: types[i-1],
							data: []
						}

						for element in dataset.elements
							new_dataset.dataset.columns[i-1].data.push(
								if types[i-1] == "categorical"
									element[column_name] 
								else 
									if element[column_name].trim().length then Number(element[column_name]) else undefined
							)

				collection.push new_dataset

			@callback true, collection

		resolveTypes: (dataset) ->
			types = []

			for i in [1...dataset.column_names.length]
				column_name = dataset.column_names[i]
				types.push "numeric"

				for element in dataset.elements
					if isNaN(Number(element[column_name])) && element[column_name].trim().length > 0
						types[i-1] = "categorical"
						break

			return types



	GoogleSpreadsheetManager
).call(@)