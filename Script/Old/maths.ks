function UnsignedModular{
    declare parameter a.
    declare parameter b to 360.

    local c to mod(a,b).

    if(c < 0){
        return b + c.
    }
    return c.
}

//Vanilla Bisection Search
function SimpleBisectionSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.001.
    declare parameter maxIterations to 1000.

    return BisectionSearch(func, minPoint, maxPoint, tolerance, maxIterations)["midPoint"].
}

//Bisection search that lerps between the final bracket.
function ModifiedBisectionSearch {
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.1.
    declare parameter maxIterations to 1000.

    local results to BisectionSearch(func, minPoint, maxPoint, tolerance, maxIterations).
    local minValue to results["minValue"].
    local maxValue to func:call(results["maxPoint"]).

    local gradient to (maxValue - minValue) / (results["maxPoint"] - results["minPoint"]).
    return results["minPoint"] - minValue/gradient.
}

//Note this never computes a final maxValue, needs to be done by calling function for lerping purposes
function BisectionSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.001.
    declare parameter maxIterations to 1000.

    local iterationCount to 0.
    local minValue to func:call(minPoint).

    until iterationCount > maxIterations {
        local midPoint to (minPoint + maxPoint) / 2.
        local midValue to func:call(midPoint).
        
        if(midValue = 0 OR (maxPoint - minPoint)/2 < tolerance){
            //print "BisectionSearch Iteration count: " + iterationCount.
            //return midPoint. 
            return lexicon("minPoint", minPoint, "midPoint", midPoint, "maxPoint", maxPoint,
                "minValue", minValue, "midValue", midValue).
        }
        
        if(NOT minValue = 0 AND midValue/minValue > 0){
            set minPoint to midPoint.
            set minValue to midValue.
        }
        else{
            set maxPoint to midPoint.
        }
        set iterationCount to iterationCount + 1.
    }
    return "Could not find solution within given tolerance".
}

function SimpleGoldenSectionSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.001.

    local results to GoldenSectionSearch(func, minPoint, maxPoint, tolerance).
    return (results["minPoint"] + results["maxPoint"]) / 2.
}

//This assumes min possible value is 0.
function ModifiedGoldenSectionSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.1.

    local results to GoldenSectionSearch(func, minPoint, maxPoint, tolerance). 
    local x0 to results["minPoint"].
    local x1 to results["maxPoint"].
    local y0 to func:call(x0).
    local y1 to func:call(x1).

    local ratioOfValues to y1/y0.
    local xn to (x1 - x0)/(ratioOfValues + 1) + x0.

    return xn.
}

function GoldenSectionSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.001.

    local inversePhi to (sqrt(5) - 1) / 2.
    local inversePhiSquared to (3 - sqrt(5)) / 2.

    local pointDifference to maxPoint - minPoint.
    if(pointDifference < tolerance){
        return (maxPoint + minPoint)/2.
    }

    local maxIterations to ceiling(ln(tolerance / pointDifference) / ln(inversePhi)).
    local iterationCount to 0.

    local minThirdPoint to minPoint + inversePhiSquared * pointDifference.
    local maxThirdPoint to minPoint + inversePhi * pointDifference.

    local minThirdValue to func:call(minThirdPoint).
    local maxThirdValue to func:call(maxThirdPoint).

    until iterationCount > maxIterations {
        if(minThirdValue < maxThirdValue){
            set maxPoint to maxThirdPoint.
            set maxThirdPoint to minThirdPoint.
            set maxThirdValue to minThirdValue.
            set pointDifference to inversePhi * pointDifference.
            set minThirdPoint to minPoint + inversePhiSquared * pointDifference.
            set minThirdValue to func:call(minThirdPoint).
        }
        else{
            set minPoint to minThirdPoint.
            set minThirdPoint to maxThirdPoint.
            set minThirdValue to maxThirdValue.
            set pointDifference to inversePhi * pointDifference.
            set maxThirdPoint to minPoint + inversePhi * pointDifference.
            set maxThirdValue to func:call(maxThirdPoint).
        }
        set iterationCount to iterationCount + 1.
    }

    if minThirdValue < maxThirdvalue{
        return lexicon("minPoint", minPoint, "maxPoint", maxThirdPoint).
    }
    else{
        return lexicon("minPoint", minThirdPoint, "maxPoint", maxPoint).
    }
}

function FindZeroValues{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter stepSize to 0.1.

    local totalSteps to (maxPoint - minPoint) / stepSize.
    local iterationCount to 1.
    local previousPoint to minPoint.
    local previousValue to func:call(minPoint).

    local bracketLists to list().


    until(iterationCount = totalSteps){
        print iterationCount.
        local currentPoint to minPoint + stepSize * iterationCount.
        local currentValue to func:call(currentPoint).

        log currentPoint + "," + currentValue to "logs.csv".

        //signs have flipped
        if(currentValue / previousValue < 0){
            bracketLists:add(lexicon("previousPoint", previousPoint, "currentPoint", currentPoint)).
        }

        set previousPoint to currentPoint.
        set previousValue to currentValue.
        set iterationCount to iterationCount + 1.
    }

    return bracketLists.
}

function GetTimeInHumanReadableFormat{
    declare parameter timeToConvert.

    local days to floor(timeToConvert / (24*60*60)).
    local excessAfterDays to timeToConvert - (days*24*60*60).
    local hours to floor(excessAfterDays / (60*60)).
    local excessAfterHours to excessAfterDays - (hours*60*60).
    local minutes to floor(excessAfterHours / 60).
    local excessAfterMinutes to excessAfterHours - (minutes * 60).
    

    return days + " days, " + hours + "h:" + minutes + "m:" + floor(excessAfterMinutes) + "s".
}

function RotationFormula{
    declare parameter angle.
    declare parameter vectorToRotate.
    declare parameter vectorToRotateAround.

    local u to vectorToRotate:normalized.
    local k to vectorToRotateAround:normalized.

    local result to u * cos(angle) + vCrs(k, u)*sin(angle) +
        k * vDot(k, u) * (1 - cos(angle)).

    return result.
}