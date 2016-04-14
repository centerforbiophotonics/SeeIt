@SeeIt.GraphOptions = (->
	class GraphOptions
		_.extend(@prototype, Backbone.Events)

		constructor: (@button, @container, options = []) ->
			@options = options
			@initLayout()
			@initHandlers()

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
				self.container.find('.panel-body').append(self.generateOption.call(self, d))

			@container.find('.SeeIt.switch').bootstrapSwitch()

		generateOption: (option) ->
			if !option.label || !option.type then return ""

			#Generate random id
			id = GraphOptions.randString(20)

			switch option.type
				when "checkbox"
					#Generate checkbox
					checkBoxStr = "<div class='form-group'><label for='#{id}'>#{option.label}</label><br><input type='checkbox' class='SeeIt form-control switch' id='#{id}'></div>"
					option.id = id
					return checkBoxStr
				when "select"
					#Generate select
					selectStr = "<div class='form-group'><label for='#{id}'>#{option.label}</label><select class='form-control'>"

					option.values.forEach (val) ->
						selectStr += "<option value=#{val}>#{val}</option>"

					selectStr += "</select></div>"

					option.id = id

					return selectStr
				when "numeric"
					#Generate number input
					numericInputStr = "<div class='form-group'><label for='#{id}'>#{option.label}</label><input type='number' class='form-control' id='#{id}'></div>"
					option.id = id

					return numericInputStr
				else return ""

		initHandlers: ->
			self = @

			@button.on 'click', ->
				self.trigger('options:show')

			@container.find('.remove-options').on 'click', ->
				self.trigger('options:hide')

		@randString: (x) ->
			s = ""

			while s.length < x && x > 0
				r = Math.random()
				s += if r < 0.1 then Math.floor(r*100) else String.fromCharCode(Math.floor(r*26) + (if r > 0.5 then 97 else 65))

			return s

	GraphOptions
).call(@)