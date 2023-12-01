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
    local maxValue to results["maxValue"].

    local gradient to (maxValue - minValue) / (results["maxPoint"] - results["minPoint"]).
    if (gradient = 0) {return results["minPoint"]. }.
    return results["minPoint"] - minValue/gradient.
}


local function BisectionSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.001.
    declare parameter maxIterations to 1000.

    local iterationCount to 0.
    local minValue to func:call(minPoint).
    local maxValue to func:call(maxPoint).

    if(minValue * maxValue > 0){
        print "minValue and maxValue have the same sign".
        return 1/0.
    }

    until iterationCount > maxIterations {
        local midPoint to (minPoint + maxPoint) / 2.
        local midValue to func:call(midPoint).
        
        if(midValue = 0 OR (maxPoint - minPoint)/2 < tolerance){
             print "BisectionSearch Iteration count: " + iterationCount.
            // //return midPoint. 
            // print "Tolerance: " + ((maxPoint - minPoint)/2).
            // print "MidValue: " + midValue.
            return lexicon("minPoint", minPoint, "midPoint", midPoint, "maxPoint", maxPoint,
                "maxValue", maxValue, "minValue", minValue, "midValue", midValue).
        }
        
        if(NOT minValue = 0 AND midValue/minValue > 0){
            set minPoint to midPoint.
            set minValue to midValue.
        }
        else{
            set maxPoint to midPoint.
            set maxValue to midValue.
        }
        set iterationCount to iterationCount + 1.
    }
    print "Could not find solution within given tolerance".
    return 1/0.
}

function SimpleBisectionRegulaFalsiCombinedSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.001.
    declare parameter maxIterations to 1000.

    local results to BisectionRegulaFalsiCombinedSearch(func, minPoint, maxPoint, tolerance, maxIterations).
    print results.

    return choose results["midPoint"] if abs(results["midValue"]) < abs(results["falseValue"]) else results["falsePoint"].
}

local function BisectionRegulaFalsiCombinedSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.001.
    declare parameter maxIterations to 1000.

    local iterationCount to 0.
    local minValue to func:call(minPoint).
    local maxValue to func:call(maxPoint).

    if(minValue * maxValue > 0){
        print "minValue and maxValue have the same sign" + minValue + " : " + maxValue.
        return 1/0.
    }

    until iterationCount > maxIterations {
        local falsePoint to (minPoint * maxValue - maxPoint * minValue) / (maxValue - minValue).// (minPoint + maxPoint) / 2.
        local falseValue to func:call(falsePoint).

        local midPoint to (minPoint + maxPoint) / 2.
        local midValue to func:call(midPoint).

        if(falseValue = 0 OR midValue = 0 OR (maxPoint - minPoint)/2 < tolerance){
             print "BisectionRegulaFalsiCombinedSearch Iteration count: " + iterationCount.
            // print "Tolerance: " + ((maxPoint - minPoint)/2).
            // print "MidValue: " + midValue.
            return lexicon("minPoint", minPoint, "falsePoint", falsePoint, "maxPoint", maxPoint,
                "minValue", minValue, "falseValue", falseValue, "maxValue", maxValue, "midPoint", midPoint, "midValue", midValue).
        }

        // If midValue and false value have different signs, use both points as new bracket points
        if(midValue/falseValue < 0){
            print 1.
            set minPoint to choose midPoint if midPoint - falsePoint < 0 else falsePoint.
            set minValue to choose midValue if midPoint - falsePoint < 0 else falseValue.
            set maxPoint to choose midPoint if midPoint - falsePoint > 0 else falsePoint.
            set maxValue to choose midValue if midPoint - falsePoint > 0 else falseValue.
        }     
        // If above is not true then both midValue and false value have the same sign so we only need to test for one
        // in order to change one of the brackets  
        else if(NOT minValue = 0 AND midValue/minValue > 0){
            print 2.
            //Check which is nearer to the root
            if(abs(midValue) < abs(falseValue)){
                set minPoint to midPoint.
                set minValue to minValue.
            }
            else{
                set minPoint to falsePoint.
                set minValue to falseValue.
            }
        }
        else{
            print 3.
            if(abs(midValue) < abs(falseValue)){
                set maxPoint to midPoint.
                set maxValue to minValue.
            }
            else{
                set maxPoint to falsePoint.
                set maxValue to falseValue.
            }
        }
        
        set iterationCount to iterationCount + 1.
    }
    return "Could not find solution within given tolerance".
}

//Vanilla RegulaFalsi Search
function SimpleRegulaFalsiSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.001.
    declare parameter maxIterations to 1000.

    return RegulaFalsiSearch(func, minPoint, maxPoint, tolerance, maxIterations)["midPoint"].
}

//RegulaFalsi search that lerps between the final bracket.
function ModifiedRegulaFalsiSearch {
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.1.
    declare parameter maxIterations to 1000.

    local results to RegulaFalsiSearch(func, minPoint, maxPoint, tolerance, maxIterations).
    local minValue to results["minValue"].
    local maxValue to results["maxValue"].

    local gradient to (maxValue - minValue) / (results["maxPoint"] - results["minPoint"]).
    if (gradient = 0) {return results["minPoint"]. }.
    return results["minPoint"] - minValue/gradient.
}

//Similar to the Bisection method, except the midPoint is an esitmate of f(x) = 0 Implements Anderson–Björck algorithm
local function RegulaFalsiSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.001.
    declare parameter maxIterations to 1000.

    local iterationCount to 0.
    local minValue to func:call(minPoint).
    local maxValue to func:call(maxPoint).

    if(minValue * maxValue > 0){
        print "minValue and maxValue have the same sign" + minValue + " : " + maxValue.
        return 1/0.
    }

    until iterationCount > maxIterations {
        local midPoint to (minPoint * maxValue - maxPoint * minValue) / (maxValue - minValue).// (minPoint + maxPoint) / 2.
        local midValue to func:call(midPoint).
        if(midValue = 0 OR (maxPoint - minPoint)/2 < tolerance){
            print "RegulaFalsiSearch Iteration count: " + iterationCount.
            // print "Tolerance: " + ((maxPoint - minPoint)/2).
            // print "MidValue: " + midValue.
            return lexicon("minPoint", minPoint, "midPoint", midPoint, "maxPoint", maxPoint,
                "minValue", minValue, "midValue", midValue, "maxValue", maxValue).
        }

        // local minRatio to 0.
        // if(minValue = 0){
        //     set minRatio to midValue/GetMaxDoubleValue().
        // }
        // else{
            set minRatio to midValue/minValue.
        // }
        
        
        if(NOT minValue = 0 AND minRatio > 0){
           // print "Here".
            local multi to (choose (1 - minRatio) if minRatio > 0 else 0.5).
            set minPoint to midPoint.
            set minValue to midValue.
            set maxValue to maxValue * multi.
        }
        else{
            //print "No Here".
            local maxRatio to midValue/maxValue.
            local multi to (choose (1 - maxRatio) if maxRatio > 0 else 0.5).
            set maxPoint to midPoint.
            set maxValue to midValue.
            set minValue to minValue * multi.
        }
        
        set iterationCount to iterationCount + 1.
    }
    return "Could not find solution within given tolerance".
}

function SimpleBezierInterpolationSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.001.
    declare parameter maxIterations to 1000.

    return BezierInterpolationSearch(func, minPoint, maxPoint, tolerance, maxIterations)["midPoint"].
}

local function BezierInterpolationSearch{
    declare parameter func.
    declare parameter minPoint.
    declare parameter maxPoint.
    declare parameter tolerance to 0.001.
    declare parameter maxIterations to 1000.

    local minValue to func:call(minPoint).
    local maxValue to func:call(maxPoint).
    local midPoint to (minPoint + maxPoint) / 2.
    local midValue to func:call(midPoint).

    if(minValue * maxValue > 0){
        print "minValue and maxValue have the same sign".
        return 1/0.
    }

    local iterationCount to 0.
    until iterationCount > maxIterations {
        print "midValue: " + midValue.
        if(midValue = 0 OR (maxPoint - minPoint)/2 < tolerance){
            return lexicon("minPoint", minPoint, "midPoint", midPoint, "maxPoint", maxPoint,
                "maxValue", maxValue, "minValue", minValue, "midValue", midValue).
        }
        local tList to QuadaticEquationSolver(-minValue - 2* midValue + maxValue, 2* midValue, minValue).
        local t to -1.
        from {local i to 0.} until  i = 2 step {set i to i + 1.} Do{
            if (tList[i] <= 1 AND tList[i] >= 0){
                set t to tList[i].
            }
        }

        print "t: " + tList.

        if(t > 1 OR t < 0){
            print "t value not between 0 and 1".
            return 1/0.
        }

        

        local predictedZeroPoint to (1-t^2)*minPoint + 2*(1-t)*t*midPoint + t^2 * maxPoint.
        local predictedZeroValue to func:call(predictedZeroPoint).
        
        print "predictedZeroValue: " + predictedZeroValue.

        log minPoint + "," + minValue + "," + midPoint + "," + midValue + "," + maxPoint + "," + maxValue + "," + predictedZeroPoint + "," + predictedZeroValue to "bezier.csv". 

        if(midValue/predictedZeroValue > 0){
           // print "Here".
           // print midPoint + "," + midValue.
            //print minPoint + "," + minValue.
            set minPoint to midPoint.
            set minValue to midValue.
            set midPoint to predictedZeroPoint.
            set midValue to predictedZeroValue.
        }
        else{
            //print "No Here".
            set maxPoint to midPoint.
            set maxValue to midValue.
            set midPoint to predictedZeroPoint.
            set midValue to predictedZeroValue.
        }
    }

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

local function GoldenSectionSearch{
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

function FindBracketContainingMinimumValue{
    declare parameter func.
    declare parameter startPoint.
    declare parameter startingStep to 1. //plus values means increasing, minus values descreasing.

    local previousValue to func:call(startPoint).
    local iterationCount to 1.

    until 1<0 {
        local point to (2 ^ iterationCount) * startingStep + startPoint.
        local value to func:call(point).

        if(value > previousValue){
            return point.
        }
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

function sinH{
    declare parameter x.
    return (constant:e^x - constant:e^(-x)) / 2.
}

function cosH{
    declare parameter x.
    return (constant:e^x + constant:e^(-x)) / 2.
}

function arcSinH{
    declare parameter x.
    return ln(x + sqrt((x*x) + 1)).
}

function arcCosH{
    declare parameter x.
    return ln(x + sqrt((x*x) - 1)).
}

function arcTanH{
    declare parameter x.
    return 0.5*ln((1 + x)/ (1 - x)).
}

function NewtonsMethod{
    declare parameter func.
    declare parameter dFunc.
    declare parameter startPoint.
    declare parameter tolerance.

    local previousPoint to startPoint.



    until 1 < 0 {
        local point to previousPoint - (func:call(previousPoint)/dFunc:call(previousPoint)).
        if(abs(point - previousPoint) < tolerance){
            //print point - previousPoint.
            
            return point.
        }
        else{
            //print "here".
            print point.
            set previousPoint to point.
        }
    }
}

//Will only solve real roots (There will either be no roots, or 2)
function QuadaticEquationSolver{
    declare parameter a.
    declare parameter b.
    declare parameter c.

    local multi to c.
    if(abs(a) > abs(b) AND abs(a) > abs(c)){
        set multi to a.
    }
    else if(abs(b) > abs(c)){
        set multi to b.
    }

    local h to a / multi.
    local i to b / multi.
    local j to c / multi.

    if(i^2 - 4*h*j < 0){
        return list().
    }
    local roots to list().
    local squareRoot to sqrt(i^2 - 4*h*j).
    roots:add((-i-squareRoot)/(2*h)).
    roots:add((-i+squareRoot)/(2*h)).
    return roots.
}

//Will solve only real roots
function CubicEquationSolver{
    declare parameter a.
    declare parameter b.
    declare parameter c.
    declare parameter d.
    declare parameter largestRootOnly to false. //If true return only the largest root.

    local multi to d.
    if(abs(a) > abs(b) AND abs(a) > abs(c) AND abs(a) > abs(d)){
        set multi to a.
    }
    else if(abs(b) > abs(c) AND abs(b) > abs(d)){
        set multi to b.
    }
    else if(abs(c) > abs(d)){
        set multi to c.
    }

    local h to a / multi.
    local i to b / multi.
    local j to c / multi.
    local k to d / multi.

    local tp to ((3*h*j) - (i^2)) / (3 * (h^2)).
    local tq to (2*(i^3) - (9*h*i*j) + (27*(h^2)*k)) / (27*(h^3)).

    local discriminant to -(4*tp^3+27*tq^2).
    local roots to list().
    local maxX to -GetMaxDoubleValue().

    //There are 3 real roots
    if(discriminant > 0){
        from {local it to 0.} until it = 3 step {set it to it + 1.} Do {
            local innerCos to (((1/3)*arccos((3*tq)/(2*tp)*sqrt(-3/tp))*constant:degToRad)-(2*constant:pi * it/3))*constant:radtodeg.
            local t to 2*sqrt(-tp/3)*cos(innerCos).
            local x to (t - i/(3*h)).
            if(x > maxX){
                set maxX to x.
            }
            roots:Add(x).
        }
    }
   //There is only one real root
    else{
        if(tp < 0){
            local absQ to abs(tq).
            local t to -2 * absQ/tq * sqrt(-tp/3)*cosH(1/3 * arcCosH(-3*absQ/(2*tp)*sqrt(-3/tp))).
            local x to (t - b/(3*a)).
            roots:Add(x).
            set maxX to x.
        }
        else{
            local t to -2 * sqrt(tp/3)*cosH(1/3 * arcCosH(-3*tq/(2*tp)*sqrt(3/tp))).
            local x to (t - b/(3*a)).
            roots:Add(x).
            set maxX to x.
        }
    }

    if(largestRootOnly){
        return maxX.
    }
    return roots.
}

function GetMaxDoubleValue{
    return 1.7976931348623157*10^308.
}

//Assumes r1 less than r2 and r1 is periapsis of transfer orbit
function LambertSolver{
    declare parameter r1.
    declare parameter r2.
    declare parameter orbitBody to ship:body.

    local updatedPhaseAngle to vang(r1, r2).
    local angleOffset to 0. //choose 180 if r1: mag > r2:mag else 0.

    local transferEccentricity to (r2:mag - r1:mag) / ((r1:mag * cos(angleOffset)) - (r2:mag*cos(updatedPhaseAngle + angleOffset))).
    local semiLactusRectum to r1:mag*(1 + transferEccentricity*cos(angleOffset)).

    local f to 1 - ((r2:mag/semiLactusRectum)*(1-cos(updatedPhaseAngle))).
    local g to (r1:mag*r2:mag*sin(updatedPhaseAngle))/(sqrt(orbitBody:mu * semiLactusRectum)).

    local v1 to (r2 - (f*r1)) / g.

    local transferSemiMajorAxis to semiLactusRectum / (1 - (transferEccentricity^2)).

    print "transferSemiMajorAxis: " + transferSemiMajorAxis.

    if(transferEccentricity > 1){
        
        local deltaF to arcCosH((1 - (r1:mag / transferSemiMajorAxis * (1-f)))). // radians?

        print "deltaF: " + deltaF.

        local timeOfFlight to g + 
        (sqrt(((-transferSemiMajorAxis)^3) / orbitBody:mu) * (sinH(deltaF) - (deltaF))).
        
        return lexicon("v1", v1, "flightTime", timeOfFlight).
    }
    print "Not here".
    local deltaE to arcCos((1 - (r1:mag / transferSemiMajorAxis * (1-f)))). // radians?

    local timeOfFlight to g + 
        (sqrt((transferSemiMajorAxis ^3) / orbitBody:mu) * (deltaE* constant:degtorad - sin(deltaE))).


    return lexicon("v1", v1, "flightTime", timeOfFlight).  // v1
}
