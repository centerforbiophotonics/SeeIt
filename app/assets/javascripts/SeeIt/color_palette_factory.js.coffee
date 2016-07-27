
      color = d3.scale.linear().domain([-1, 0, 1]).range(["red", "white", "green"])
      color2 = d3.scale.linear().domain([0,1]).range(["#000000", "#ffffff"])
      rainBow = d3.scale.linear().domain([0,1,2,3,4,5,6]).range(["red", "orange", "yellow", "green", "blue", "indigo", "violet" ])
      blue = d3.scale.linear().domain([0,1]).range(['white', 'blue'])

      colorRed = []
      colorGreen = []
      blackAndWhite = []
      rainBowColor = []
      colorBlue = []
      # source for this:  http://www.somersault1824.com/tips-for-designing-scientific-figures-for-color-blind-readers/ 
      blindColor = ['#000000', '#004949', '#009292', '#ff6db6', '#ffb677','#490092','#006ddb','#b66dff','#6db6ff','#b6dbff','#920000', '#924900','#dbd100','#24ff24','#ffff6d']

      blackAndWhite.push(color2(num/100)) for num in [0..100]
      colorRed.push(color(-num/100) ) for num in [0..100]
      colorGreen.push(color(num/100) ) for num in [0..100]
      rainBowColor.push(rainBow(6*num/100)) for num in [0..100]
      colorBlue.push(blue(num/100) ) for num in [0..100]
      
      colorBlindness = new SeeIt.ColorPalette('Color Blindness', blindColor)
      redPalette = new SeeIt.ColorPalette('Red', colorRed)
      greenPalette = new SeeIt.ColorPalette('Green', colorGreen)
      blackPalette = new SeeIt.ColorPalette("Black and White", blackAndWhite)
      rainBowPalette = new SeeIt.ColorPalette("Rainbow", rainBowColor)
      bluePalette = new SeeIt.ColorPalette("Blue", colorBlue)

      @paletteTypes = [];
      @paletteTypes.push({name: blackPalette.name, class: blackPalette })
      @paletteTypes.push({name: redPalette.name, class: redPalette })
      @paletteTypes.push({name: greenPalette.name, class: greenPalette })
      @paletteTypes.push({name: rainBowPalette.name, class: rainBowPalette})
      @paletteTypes.push({name: bluePalette.name, class: bluePalette})
      @paletteTypes.push({name: colorBlindness.name, class: colorBlindness})  