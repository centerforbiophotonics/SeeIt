@SeeIt.Dataset = (->
	extend = (obj, mixin) ->
		obj[name] = method for name, method of mixin
		obj

	class Dataset
		_.extend(@prototype, Backbone.Events)
		@Validators = {}
		_.extend(@Validators, SeeIt.Modules.Validators)

		constructor: (@app, data, @title = "New Dataset", @isLabeled = false) ->
			if !data
				data = {
					labels: ["1", "2", "3", "4", "5"],
					columns: [
						{
							header: "A",
							type: "numeric",
							data: [null,null,null,null,null]
						},
						{
							header: "B",
							type: "numeric",
							data: [null,null,null,null,null]
						},
						{
							header: "C",
							type: "numeric",
							data: [null,null,null,null,null]
						},
						{
							header: "D",
							type: "numeric",
							data: [null,null,null,null,null]
						},
						{
							header: "E",
							type: "numeric",
							data: [null,null,null,null,null]
						},
					]
				}

			#Data will be an array of DataColumns
			@labels = []
			@headers = []
			@rawFormat = Dataset.getFormat(data)
			@data = []
			extend(@, ConverterFactory(@rawFormat))
			@loadData(data)
			@registerListeners()

		loadData: (data) ->
			if Dataset.validateData(data)
				@rawData = data
				@formatRawData()
				@initData()
				@trigger("data:loaded")
			else
				alert "Error: Invalid data format"

		toJson: ->
			obj = {
				title: @title,
				dataset: {
					labels: @labels.slice(0)
					columns: []
				},
				isLabeled: true
			}

			@data.forEach (d) ->
				obj.dataset.columns.push d.toJson()

			return obj

		registerListeners: ->
			self = @

			@on 'header:change', (value, idx) ->
				console.log "header changed"
				self.headers[idx] = value
				self.trigger('header:changed', value, idx)

				self.data[idx].setHeader(value)

			@on 'label:change', (value, idx) ->
				self.labels[idx] = value
				self.trigger('label:changed', value, idx)

				self.data.forEach (d) ->
					d.setLabel(idx, value)

		@validateData: (data) ->
			valid = true

			for key in @Validators
			  valid = valid && @Validators[key](@rawData)

			return valid

		@getFormat: (data) ->
			$.type data



		ConverterFactory = (format) ->
			ArrayConverter = {

			formatRawData: ->
				if !@isLabeled
					@addLabels()
				else
					@stringifyLabels()

				maxCols = @maxNumCols()
				@padRows(maxCols)
				@initHeaders()

			toString: (val) ->
				return val + ''

			stringifyLabels: ->
				for i in [1...@rawDataRows()]
					@rawData[i][0] = @toString(@rawData[i][0])
					@labels.push(@rawData[i][0])

				@isLabeled = true

			addLabels: ->
				@rawData[0].unshift('')

				for i in [1...@rawDataRows()]
					@rawData[i].unshift(@toString(i))
					@labels.push(@rawData[i][0])

				@isLabeled = true

			maxNumCols: ->
				maxCols = @rawData[0].length
				for i in [1...@rawDataRows()]
					if @rawData[i].length > maxCols
						maxCols = @rawData[i].length

				maxCols

			padRows: (maxCols) ->
				for i in [0...@rawDataRows()]
					if @rawData[i].length < maxCols
						@rawData[i] = @fillWithUndefined(@rawData[i], maxCols - @rawData[i].length)

			fillWithUndefined: (arr,count) ->
				for i in [0...count]
					arr.push(undefined)

				arr

			initData: ->
				# Assume data is already in array of arrays format and is uniformly padded with 'undefined's
				for i in [1...@rawDataCols()]
					@data.push(SeeIt.DataColumn.new(@app, @rawData, i, @title))

			rawDataRows: ->
				@rawData.length

			rawDataCols: ->
				if @rawData.length then @rawData[0].length else 0

			initHeaders: ->
				for i in [1...@rawDataCols()]
					@headers.push(@rawData[0][i])
			}


			JsonConverter = {
				formatRawData: ->
					if !@isLabeled
						@addLabels()
					else
						@stringifyLabels()

					@initHeaders()

				addLabels: ->
					for i in [0...@rawData.columns.length]
						for j in [0...@rawData.columns[i].data.length]
							@labels.push(j+1)

					@rawData.labels = @labels          
					@isLabeled = true

				stringifyLabels: ->
					for i in [0...@rawData.labels.length]
						@labels.push(@rawData.labels[i])

				initHeaders: ->
					for i in [0...@rawData.columns.length]
						@headers.push(@rawData.columns[i].header)

				initData: ->
					for i in [0...@rawData.columns.length]
						@data.push(SeeIt.DataColumn.new(@app, @rawData, i, @title))

			}

			if format == "array" then ArrayConverter else JsonConverter

	Dataset
).call(@)