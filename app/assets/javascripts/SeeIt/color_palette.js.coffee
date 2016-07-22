@SeeIt.ColorPalette = (->
	class ColorPalette
	 
   #console.log(_);
	 #_.extend(@prototype, Backbone.Events)

    constructor: (name, colors) ->
      @colors = if colors.length != 0 then colors else ['#000000', '#FFFFFF']
      @name = name

 		getRandom: ->
      @color = colors[Math.floor(Math.random()*100)]
     

  ColorPalette
).call(@)