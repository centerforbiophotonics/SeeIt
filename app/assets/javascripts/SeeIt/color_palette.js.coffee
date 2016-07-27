@SeeIt.ColorPalette = ( ->
	class ColorPalette
	   _.extend(@prototype, Backbone.Events)

    constructor: (name, colors) ->
      @colors = if colors.length != 0 then colors else ['#000000', '#FFFFFF']
      @name = name

    getRandom :  ->
      @colors[Math.floor(Math.random()*100)]

    makePalette : (len) -> 
      num = Math.floor(@colors.length/len);
      if (num == 0)
        num = 1;
        len = @colors.length
      @palette = []
      @palette.push(@colors[k*num] ) for k in [1..len]
      @cur = -1

    getColor : ->
      @cur = @cur + 1
      @cur = 0 if @cur == @palette.length
      return @palette[@cur]



  ColorPalette
).call(@)