@SeeIt.Utils = (->
	Utils = {
		getRandomColor: ->
			letters = '0123456789ABCDEF'.split('')
			color = '#';

			for i in [0...6]
				color += letters[Math.floor(Math.random() * 16)]

			return color


	}

	Utils
).call(@)