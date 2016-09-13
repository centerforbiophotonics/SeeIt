@SeeIt.GraphOptions = (->
	class GraphOptions
		_.extend(@prototype, Backbone.Events)

		constructor: (@button, @container, options = [], @disabled = [], @defaults = []) ->
			@options = []

			@wrapOptions(options)

			@visible = false
			@initLayout()
			@initHandlers()

		wrapOptions: (options) ->
			for _option in options
				@options.push ((_option) ->
					option = {}
					for key, member of _option
						((key, member) ->
							if typeof member != "function"
								option[key] = -> member
							else
								option[key] = member

							return option
						)(key, member)

					return option
				)(_option)


		initLayout: ->
			@container.html("""
				<div class="SeeIt options-panel panel panel-default">
				  <div class="SeeIt panel-heading">
				  	<span class="SeeIt remove-options glyphicon glyphicon-remove"></span>
				  	Graph Options
				  </div>
				  <div class="SeeIt panel-body">
				  </div>
				</div>
			""")

			@populateOptions()

		populateOptions: ->
			self = @
			self.container.find('.panel-body').html('')
			
			@options.forEach (d) ->
				if d.type() == "checkbox"
					self.container.find('.panel-body').append(self.generateOption.call(self, d))
					self.setDefaultValue.call(self, d)

			@options.forEach (d) ->
				if d.type() != "checkbox"
					self.container.find('.panel-body').append(self.generateOption.call(self, d))
					self.setDefaultValue.call(self, d)


			@container.find('.SeeIt.switch').bootstrapSwitch()

			@container.find('.panel-body').append("<button class='option-save btn btn-primary' role='button' style='width: 100%'>Save</button>")

			@container.find('.option-save').click (event) ->
				self.trigger('graph:update')

		setDefaultValue: (option, id) ->
			idx = @defaults.map((op) -> op.label).indexOf(option.label())

			default_value = if idx >= 0 then @defaults[idx].default else option.default()

			switch option.type()
				when "checkbox"
					@container.find("##{option.id}").prop('checked', default_value)
				when "select"
					@container.find("##{option.id}").val(default_value)
				when "numeric"
					@container.find("##{option.id}").val(default_value)

		getValues: ->
			values = []

			@options.forEach (option) ->
				if option.type() == "checkbox"
					values.push {label: option.label(), value: $("##{option.id}").prop('checked')}
				else if option.type() == "select"
					values.push {label: option.label(), value: $("##{option.id}").val()}
				else if option.type() == "numeric"
					values.push {label: option.label(), value: Number($("##{option.id}").val())}

			return values

		generateOption: (option) ->
			if !option.label || !option.type then return ""

			#Generate random id
			id = GraphOptions.randString(20)

			is_disabled = @disabled.indexOf(option.label()) >= 0

			switch option.type()
				when "checkbox"
					#Generate checkbox
					checkBoxStr = "<div class='form-group-checkbox #{if is_disabled then 'hidden' else ''}'><div style='display:inline-block; width:150px;'><label class='checkbox-label' for='#{id}'>#{option.label()}</label></div><input type='checkbox' class='SeeIt form-control switch' data-size='mini' id='#{id}'></div>"
					option.id = id
					return checkBoxStr
				when "select"
					#Generate select
					selectStr = "<div class='form-group #{if is_disabled then 'hidden' else ''}'><label for='#{id}'>#{option.label()}</label><select id='#{id}' class='form-control'>"

					option.values().forEach (val) ->
						selectStr += "<option value="+'"'+val+'"'+">#{val}</option>"

					selectStr += "</select></div>"

					option.id = id

					return selectStr
				when "numeric"
					#Generate number input
					numericInputStr = "<div class='form-group #{if is_disabled then 'hidden' else ''}'><label for='#{id}'>#{option.label()}</label><input type='number' step='any' class='form-control' id='#{id}'></div>"
					option.id = id

					return numericInputStr
				else return ""

		initHandlers: ->
			self = @

			@button.on 'click', ->
				self.container.css('max-height', self.container.next().height())
					
				self.visible = !self.visible

				if self.visible
					self.trigger('options:show')
				else
					self.trigger('options:hide')

			@container.find('.remove-options').on 'click', ->
				self.visible = false
				self.trigger('options:hide')

			@on 'graph:maximize', (maximize) ->
				self.container.css('max-height', self.container.next().height())

			$(window).on 'resize', ->
				self.container.css('max-height', self.container.next().height())

		@randString: (x) ->
			s = ""

			while s.length < x && x > 0
				r = Math.random()
				s += if r < 0.1 then Math.floor(r*100) else String.fromCharCode(Math.floor(r*26) + (if r > 0.5 then 97 else 65))

			return s

	GraphOptions
).call(@)