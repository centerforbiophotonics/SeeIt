@SeeIt.Dataset = (->
	extend = (obj, mixin) ->
		obj[name] = method for name, method of mixin
		obj

	class Dataset
		_.extend(@prototype, Backbone.Events)
		@Validators = {}
		_.extend(@Validators, SeeIt.Modules.Validators)

		constructor: (@app, data, @title = "New Dataset", @isLabeled = false, @editable = true) ->
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
			@types = []
			@rawFormat = Dataset.getFormat(data)
			@data = []
			extend(@, ConverterFactory(@rawFormat))
			@loadData(data)
			@registerListeners()

		getByHeader: (header) ->
			idx = @headers.indexOf(header)

			if idx < 0 then return null else return @data[idx]

		setTitle: (title) ->
			@title = title

			@data.forEach (d) ->
				d.setDatasetTitle.call(d, title)

			@trigger('dataset:title:changed')

		loadData: (data) ->
			if Dataset.validateData(data)
				@rawData = data
				@formatRawData()
				@getColTypes()
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

		getType: (d) ->
			switch typeof d
				when "number"
					return "numeric"
				else
					return "categorical"

		registerListeners: ->
			self = @

			@on 'header:change', (value, idx) ->
				self.headers[idx] = value
				self.trigger('header:changed', value, idx)

				self.data[idx].setHeader(value)

			@on 'label:change', (value, idx) ->
				self.labels[idx] = value
				self.trigger('label:changed', value, idx)

				self.data.forEach (d) ->
					d.setLabel(idx, value)

			@on 'dataColumn:destroy', (col) ->
				self.destroyColumn.call(self, col)

			@on 'dataColumn:create', (col) ->
				self.createColumn.call(self, col)

			@on 'row:destroy', (row) ->
				self.destroyRow.call(self, row)

			@on 'row:create', (row) ->
				self.createRow.call(self, row)

			@on 'dataColumn:type:change', (col, type, callback) ->

				self.data[col].setType(type, (success, msg) ->
					if success then self.types[col] = type

					callback(success, msg)
				)

			@on 'request:columns', (callback) ->
				callback(self.data.slice(0), self.types.slice(0))

			@on 'request:values:unique', (colIdx, callback) ->
				callback self.data[colIdx].uniqueData()

		generateLabel: (labels) ->
			i = 1

			while labels.indexOf(i.toString()) >= 0
				i++

			return i.toString()

		createRow: (row) ->
			label = @generateLabel(@labels)
			for i in [0...@data.length]
				if @data[i].type == 'numeric'
					@data[i].insertElement(row, label, 0)
				else
					@data[i].insertElement(row, label, null)

			console.log @data

			@labels.splice(row, 0, label)
			@trigger('row:created', row)

		createColumn: (col) ->
			self = @

			header = @generateLabel(@headers)

			dataColumn = []

			for i in [0...@labels.length]
				dataColumn.push({label: @labels[i], value: null})

			column = new SeeIt.DataColumn(@app, header, dataColumn, @title, undefined, @editable)
			@data.splice(col, 0, column)
			@listenTo column, 'data:changed', (source, idx) ->
				console.log 'data:changed triggered in dataset'
				self.trigger('data:changed', source, idx)

			@headers.splice(col, 0, header)
			@trigger('dataColumn:created', col)

		destroyRow: (row) ->
			for i in [0...@data.length]
				@data[i].removeElement(row)

			@labels.splice(row, 1)
			@trigger('row:destroyed', row)

		destroyColumn: (col) ->
			destroyedColumn = @data.splice(col, 1)[0]
			@headers.splice(col, 1)

			destroyedColumn.trigger('destroy')
			@trigger('dataColumn:destroyed')

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

				getColTypes: ->
					for i in [1...@rawDataCols()]
						@types.push(@getType(@rawData[1][i]))

				padRows: (maxCols) ->
					for i in [0...@rawDataRows()]
						if @rawData[i].length < maxCols
							@rawData[i] = @fillWithUndefined(@rawData[i], maxCols - @rawData[i].length)

				fillWithUndefined: (arr,count) ->
					for i in [0...count]
						arr.push(undefined)

					arr

				initData: ->
					self = @
					# Assume data is already in array of arrays format and is uniformly padded with 'undefined's
					for i in [1...@rawDataCols()]
						column = SeeIt.DataColumn.new(@app, @rawData, i, @title, @types[i-1], undefined, @editable)
						@data.push(column)
						@listenTo column, 'data:changed', (source, idx) ->
							console.log 'data:changed triggered in dataset'
							self.trigger('data:changed', source, idx)


				rawDataRows: ->
					@rawData.length

				rawDataCols: ->
					if @rawData.length then @rawData[0].length else 0

				initHeaders: ->
					for i in [1...@rawDataCols()]
						@headers.push(@toString(@rawData[0][i]))
			}


			JsonConverter = {
				formatRawData: ->
					if !@isLabeled
						@addLabels()
					else
						@stringifyLabels()

					@initHeaders()

				toString: (val) ->
					return val + ''

				addLabels: ->
					for i in [0...@rawData.columns.length]
						for j in [0...@rawData.columns[i].data.length]
							@labels.push(@toString(j+1))

					@rawData.labels = @labels          
					@isLabeled = true

				stringifyLabels: ->
					for i in [0...@rawData.labels.length]
						@labels.push(@toString(@rawData.labels[i]))

				initHeaders: ->
					for i in [0...@rawData.columns.length]
						@headers.push(@toString(@rawData.columns[i].header))

				getColTypes: ->
					for i in [0...@rawData.columns.length]
						@types.push(@rawData.columns[i].type)

				initData: ->
					self = @
					for i in [0...@rawData.columns.length]
						column = SeeIt.DataColumn.new(@app, @rawData, i, @title, @types[i], undefined, @editable) 
						@data.push(column)
						@listenTo column, 'data:changed', (source, idx) ->
							console.log 'data:changed triggered in dataset'
							self.trigger('data:changed', source, idx)

			}

			if format == "array" then ArrayConverter else JsonConverter

	Dataset
).call(@)