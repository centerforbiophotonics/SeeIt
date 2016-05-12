@SeeIt.Modules.Validators = {
  consistentRowType: (data) ->
    isArray = false
    
    if $.isArray(data)
      for i in [0...data.length]
        if i == 0
          if $.isArray(data[i])
            isArray = true
          else if !(typeof data[i] == "object")
            return false
        else
          if isArray && !$.isArray(data[i])
            return false
          else if !isArray && !(typeof data[i] == "object") 
            return false

    return true


}