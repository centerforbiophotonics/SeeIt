@SeeIt.DataMenu = (->
  class DataMenu
    constructor: (@container) ->
      @init()
      @visible = true

    init: ->
      @container.html("""
        <ul class="SeeIt list-group">
          <div>
            <li class="SeeIt dataset list-group-item">
              <a class="SeeIt">Dataset 1</a>
            </li>
            <div class="SeeIt data-columns list-group-item" style="padding: 5px; display: none">
              <ul class='SeeIt list-group'>
                <li class='SeeIt list-group-item'><a>Content 1</a></li>
                <li class='SeeIt list-group-item'><a>Content 2</a></li> 
              </ul>
            </div>
          </div>
          <div>
            <li class="SeeIt dataset list-group-item"><a class="SeeIt">Dataset 2</a></li>
          </div>
          <div>
            <li class="SeeIt dataset list-group-item"><a class="SeeIt">Dataset 3</a></li>
          </div>
        </ul>
      """)

      @registerEvents()

    registerEvents: ->
      toggleData = ->
        $(@).toggleClass('active')
        $(@).find('a').toggleClass('selected')
        $(@).parent().find('.data-columns').slideToggle()


      @container.find('.dataset').off('click', toggleData).on('click', toggleData)

    toggleVisible: ->
      @container.toggle()
      @visible = !@visible
      
  DataMenu
).call(@)