@SeeIt.SpreadsheetContextMenuView = (->

  class SpreadsheetContextMenuView
    _.extend(@prototype, Backbone.Events)

    constructor: (@parent) ->
      @initHandlers()  
 
    initHandlers: ->  
      
    display_row_menu: (key, options) ->

      self = @
      input = 1

      self.parent.container.find('.SeeIt .spreadsheet').append("""
        <div id="myModal" class="modal fade">
            <div class="modal-dialog modal-sm">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                        <h4 class="modal-title">New rows</h4>
                    </div>
                    <div class="modal-header">
                        <div><label>Position:</label></div>
                        <div class="btn-group" data-toggle="buttons">
                            <label class="btn active">
                                <input type="radio" value="below" name="pos_options" id="numeric_radio" autocomplete="off" checked> below
                            </label>
                            <label class="btn">
                                <input type="radio" value="above" name="pos_options" id="categorical_radio" autocomplete="off"> above
                            </label>
                        </div>
                    </div>
                    <div class="modal-header">
                        <form role="form">
                            <div class="form-group">
                                <label for="number_label" class="control-label">Numer of columns:</label>
                                <input type="text" class="form-control" id="number_field">
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                        <button type="button" id="done_button" class="btn btn-primary">Done</button>
                    </div>
                </div>
            </div>
        </div>
      """)

      $('#myModal').insertAfter($('body'))
      $('#myModal').modal('show')      

      $(document).off("keypress").on("keypress", ":input:not(textarea)", (e) ->    
        if e.keyCode == 13
          e.preventDefault()
          $('#done_button').click()
      );
      
      $('label').click( () ->
        $('label').removeClass('selectedBackground')
        $(this).addClass('selectedBackground')
        $('#number_field').focus()
      );    

      $('#myModal').on('shown.bs.modal', () ->
        $('#number_field').val(1)
        $('#number_field').focus()
        self.parent.hot.unlisten() 
      );

      $('#myModal').on('hidden.bs.modal', () ->
        $('#number_field').val(1)
        $(this).remove()
      );
      
      $("#done_button").on("click", () ->
        input = parseInt($('#number_field').val());    

        if input != null
          if $("input[name=pos_options]:checked").val() == 'above'
            for i in [0...input]
              self.parent.dataset.trigger('row:create', options.end.row)
          else
            for i in [0...input]
              self.parent.dataset.trigger('row:create', options.end.row + 1)

        $('#myModal').modal('hide')
      );

    display_column_menu: (key, options) ->

      self = @
      input = 1

      self.parent.container.find('.SeeIt .spreadsheet').append("""
        <div id="myModal" class="modal fade">
          <div class="modal-dialog modal-sm">
              <div class="modal-content">
                  <div class="modal-header">
                      <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                      <h4 class="modal-title">New columns</h4>
                  </div>
                  <div class="modal-header">
                      <div><label>Position:</label></div>
                      <div class="btn-group" data-toggle="buttons">
                          <label class="btn active">
                              <input type="radio" value="left" name="pos_options" id="numeric_radio" autocomplete="off" checked> Left
                          </label>
                          <label class="btn">
                              <input type="radio" value="right" name="pos_options" id="categorical_radio" autocomplete="off"> Right
                          </label>
                      </div>
                  </div>
                  <div class="modal-header">
                      <form role="form">
                          <div><label>Type:</label></div>
                        <div class="btn-group" data-toggle="buttons">
                          <label class="btn active">
                  <input type="radio" value="numeric" name="options" id="numeric_radio" autocomplete="off" checked> Numeric
                </label>
                <label class="btn">
                  <input type="radio" value="categorical" name="options" id="categorical_radio" autocomplete="off"> Categorical
                </label>
                        </div>
                      </form>
                  </div>
                  <div class="modal-header">
                      <form role="form">
                          <div class="form-group">
                              <label for="number_label" class="control-label">Numer of columns:</label>
                              <input type="text" class="form-control" id="number_field">
                          </div>
                      </form>
                  </div>
                  <div class="modal-footer">
                      <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                      <button type="button" id="done_button" class="btn btn-primary">Done</button>
                      </div>
                  </div>
              </div>
          </div>
      """)

      $('#myModal').insertAfter($('body'))
      $('#myModal').modal('show')

      $(document).off("keypress").on("keypress", ":input:not(textarea)", (e) ->       
        if e.keyCode == 13
          e.preventDefault()
          $('#done_button').click()
      );

      $('label').click( () ->
        $('label').removeClass('selectedBackground')
        $(this).addClass('selectedBackground')
        $('#number_field').focus()
      );    

      $('#myModal').on('shown.bs.modal', () ->  

        $('#number_field').val(1)
        $('#number_field').focus()
        self.parent.hot.unlisten()
      );

      $('#myModal').on('hidden.bs.modal', () ->
        $('#number_field').val(1)
        $(this).remove()
      );
      
      $("#done_button").on("click", () ->
        input = parseInt($('#number_field').val());
        type = $("input[name=options]:checked").val();

        if input != null
          if $("input[name=pos_options]:checked").val() == 'left'
            for i in [0...input]
              self.parent.dataset.trigger('dataColumn:create', options.end.col, type)
          else
            for i in [0...input]
              self.parent.dataset.trigger('dataColumn:create', options.end.col + 1, type)

        $('#myModal').modal('hide');
      );

  SpreadsheetContextMenuView
).call(@)