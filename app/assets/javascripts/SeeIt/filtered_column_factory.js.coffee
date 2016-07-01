@SeeIt.FilteredColumnFactory = (parent, filter, manager) ->
	data = parent.data().map((d) ->
		{
			label: d.label()
			value: d.value()
		}
	).filter((d, i) ->
		return filter.indexOf(i) > -1
	)

	child = new SeeIt.DataColumn(
		parent.app, 
		parent.header, 
		data, 
		parent.datasetTitle, 
		parent.type,
		parent.color,
		parent.isEditable()
	)

	class FilteredFactory
		_.extend(@prototype, Backbone.Events)

		contstructor: ->

		updateFilter: (_filter) ->
			filter = _filter
			data = parent.data().map((d) ->
				{
					label: d.label()
					value: d.value()
				}
			).filter((d, i) ->
				return filter.indexOf(i) > -1
			)

			child.changeData(data)

			return child

		build: ->
			self = @
			@register()

			@listenTo child, 'filter:changed', (_filter) ->
				self.updateFilter.call(self, _filter)

			return child

		register: ->
			@listenTo parent, 'data:changed', (source, idx) ->
				child_idx = filter.indexOf(idx)

				console.log source
				if child_idx > -1 && source != child
					child.setValue(child_idx, parent.getValue(idx), parent)

			@listenTo child, 'data:changed', (source, idx) ->
				parent_idx = filter[idx]

				if parent_idx > -1 && source != parent
					parent.setValue(parent_idx, child.getValue(idx), child)

			@listenTo parent, 'type:changed', (type) ->
				child.setType(type)

			@listenTo parent, 'label:changed', (idx) ->
				child_idx = filter.indexOf(idx)

				if child_idx > -1
					child.setLabel(child_idx, parent.getLabel(idx))

			@listenTo parent, 'data:destroyed', (idx) ->
				child_idx = filter.indexOf(idx)

				if child_idx > -1
					for i in [child_idx...filter.length]
						filter[i]--

					child.removeElement(child_idx)

			@listenTo parent, 'data:created', (idx) ->
				child_idx = filter.indexOf(idx)

				if child_idx > -1
					for i in [child_idx...filter.length]
						filter[i]++

					child.insertElement(child_idx, parent.getLabel(idx), parent.getValue(idx))

			@listenTo parent, 'color:changed', ->
				child.setColor(parent.getColor())

			@listenTo parent, 'header:changed', ->
				child.setHeader(parent.getHeader())

			@listenTo parent, 'destroy', ->
				child.trigger 'destroy'

			@listenTo parent, 'request:childLength', (callback) ->
				callback(child.length())

	factory = new FilteredFactory()

	return factory.build()
