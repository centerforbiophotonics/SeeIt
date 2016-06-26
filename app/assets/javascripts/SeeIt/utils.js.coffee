@SeeIt.Utils = (->
	Utils = {
		getRandomColor: ->
			letters = '0123456789ABCDEF'.split('')
			color = '#';

			for i in [0...6]
				color += letters[Math.floor(Math.random() * 16)]

			return color

		isMobile: ->
			return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
			
	}

	Utils
).call(@)