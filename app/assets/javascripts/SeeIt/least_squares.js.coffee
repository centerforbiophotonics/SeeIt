@SeeIt.LeastSquares = (->
  LeastSquares = (data) ->
    sumX = 0
    sumY = 0
    sumXY = 0
    sumXSq = 0
    invalidCount = 0
    N = data.length

    for i in [0...N]
      if Number(data[i].x()) && Number(data[i].y())
        sumX += data[i].x()
        sumY += data[i].y()
        sumXY += data[i].x() * data[i].y()
        sumXSq += data[i].x() * data[i].x()
      else
        invalidCount++
    
    N -= invalidCount

    ret = {}

    ret.m = (sumXY - sumX * sumY / N) / (sumXSq - sumX * sumX / N)
    ret.b = sumY / N - ret.m * sumX / N

    return (x) -> if arguments.length then ret.m * x + ret.b else {m: ret.m, b: ret.b}

).call(@)