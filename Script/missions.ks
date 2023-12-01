// function LambertSolver{

// }

function FindNextTransferWindow{
    // declare parameter minPhaseAngle to 90.
    // declare parameter maxPhaseAngle to 270.
    declare parameter desiredPhaseAngle to 175.
    declare parameter targetBody to Body("Venus").
    declare parameter leavingBody to Body("Earth").
    declare parameter startTimeForSearch to Body("Earth"):rotationPeriod.

    local sunInfo to Body("Sun").

    wait 0.
    local epochTime to time:seconds.
    local sinkVectors to  GetTargetVectors(targetBody, "BODY", sunInfo).
    local sourceVectors to GetTargetVectors(leavingBody, "BODY", sunInfo).
    if(time:seconds = epochTime){
        print "Vectors good".
    }
    else{
        print epochTime - time:seconds.
        return.
    }

    local sinkEccentricityVector to GetEccentricityVector(sinkVectors, sunInfo).
    local sourceEccentricityVector to GetEccentricityVector(sourceVectors, sunInfo).
    local sinkSpecificAngularMomentum to GetSpecificAngularMomentum(sinkVectors).
    local sourceSpecificAngularMomentum to GetSpecificAngularMomentum(sourceVectors).

    local sinkMeanMotion to GetMeanAngularVelocity(sinkVectors, sunInfo).
    local sourceMeanMotion to GetMeanAngularVelocity(sourceVectors, sunInfo).
    local meanMotionDifference to abs(sourceMeanMotion - sinkMeanMotion).

    local maxTimeOfSearch to 360/meanMotionDifference + startTimeForSearch.

    print "maxTimeOfSearch: " + GetTimeInHumanReadableFormat(maxTimeOfSearch).

    //print "sourceOrbitalPeriod: " + GetTimeInHumanReadableFormat(sourceOrbitalPeriod*3).

    //print "Source vectors" + sourceVectors.

    

    function searchForTrueAnomalyOfSourceAtDeparture{
        declare parameter searchStartTime.

        clearVecDraws().

        // drawVector(sun:position, sourceVectors["Position"], "Earth", blue).
        //drawVector(sun:position, GetPositionFromTrueAnomaly(180, sinkVectors, sunInfo), "Venus", red).

        local projectedSourceTrueAnomaly to GetTrueAnomalyAfterTime(searchStartTime, sourceVectors, sunInfo).

        local projectedSourcePosition to GetPositionFromTrueAnomaly(projectedSourceTrueAnomaly, sourceVectors, sunInfo). //r1

        drawVector(sun:position, projectedSourcePosition, "projectedSourcePosition", blue).
        local projectedSourcePositionTurnedByDesiredTrueAnomaly to 
            RotationFormula(desiredPhaseAngle, projectedSourcePosition, sourceSpecificAngularMomentum). //unit vector

        print vang(projectedSourcePosition, projectedSourcePositionTurnedByDesiredTrueAnomaly).
        
        local projectedSinkTrueAnomaly to 
            vang(vxcl(sinkSpecificAngularMomentum,projectedSourcePositionTurnedByDesiredTrueAnomaly), sinkEccentricityVector).

        print "projectedSinkTrueAnomaly: " + projectedSinkTrueAnomaly.

        local projectedSinkPosition to GetPositionFromTrueAnomaly(projectedSinkTrueAnomaly, sinkVectors, sunInfo). //r2

         drawVector(sun:position, projectedSinkPosition, "projectedSinkPosition", red).

        print vang(sinkEccentricityVector,projectedSinkPosition).

        local updatedPhaseAngle to vang(projectedSinkPosition, projectedSourcePosition).
        print "updatedPhaseAngle: " + updatedPhaseAngle.

        local r1 to projectedSourcePosition:mag.
        local r2 to projectedSinkPosition:mag.

        local projectedEccentricity to (r2-r1) / ((r1*cos(180)) - (r2 * cos(180 + updatedPhaseAngle))).

        print "projectedEccentricity: " + projectedEccentricity.

        local k to projectedSinkPosition:mag * projectedSourcePosition:mag * (1-cos(updatedPhaseAngle)).
        local l to projectedSinkPosition:mag + projectedSourcePosition:mag.
        local m to projectedSinkPosition:mag * projectedSourcePosition:mag * (1+cos(updatedPhaseAngle)).

        local minSemiLactusRectum to k / (l + sqrt(2*m)).
        print minSemiLactusRectum - leavingBody:orbit:semiMajorAxis.

        local semiLactusRectum to r1*(1 + projectedEccentricity* cos(180)).

        print "semiLactusRectum: " + semiLactusRectum.

        drawVector(sun:position, RotationFormula(90, projectedSourcePosition, vCrs(projectedSourcePosition, projectedSinkPosition))*semiLactusRectum, "Lactus", green ).


        local f to 1 - ((projectedSinkPosition:mag/semiLactusRectum)*(1-cos(updatedPhaseAngle))).
        local g to (projectedSinkPosition:mag * projectedSourcePosition:mag * sin(updatedPhaseAngle)) / 
            sqrt(sunInfo:mu*semiLactusRectum).
        
        local departureVelocity to (projectedSinkPosition - projectedSourcePosition*f)/g.
        local projectedSpecificAngularMomentum to vcrs(departureVelocity, projectedSourcePosition).

        print "projectedSpecificAngularMomentum: " + projectedSpecificAngularMomentum:mag.

        print sqrt(semiLactusRectum * sun:mu).



        print "projectedSemiMajorAxis: " + semiLactusRectum / (1+ projectedEccentricity^2).
        local projectedSemiMajorAxis to semiLactusRectum / (1+ projectedEccentricity^2).
        print "projectedDeltaEccentricityAnomaly: " + (1 - ((projectedSourcePosition:mag/projectedSemiMajorAxis)*(1 - f))).

        local projectedDeltaEccentricityAnomaly to arcCos(max(min((1 - (projectedSourcePosition:mag/projectedSemiMajorAxis)*(1 - f)),1),-1)).
        print "projectedDeltaEccentricityAnomaly: " + projectedDeltaEccentricityAnomaly.
        print projectedSemiMajorAxis/sunInfo:mu.
        local projectedTimeOfFlight to g + 
            sqrt((projectedSemiMajorAxis^3)/sunInfo:mu)*
            (projectedDeltaEccentricityAnomaly * constant:degtorad - sin(projectedDeltaEccentricityAnomaly)).
        
        local projectedSinkTrueAnomalyAfterTimeOfFlight to GetTrueAnomalyAfterTime(projectedTimeOfFlight,sinkVectors, sunInfo).
        local projectedSinkPositionAfterTimeOfFlight to 
            GetPositionFromTrueAnomaly(projectedSinkTrueAnomalyAfterTimeOfFlight, sinkVectors, sunInfo).
        print "projectedTimeOfFlight: " + GetTimeInHumanReadableFormat(projectedTimeOfFlight).

        drawVector(sun:position, projectedSinkPositionAfterTimeOfFlight, "projectedSinkPositionAfterTimeOfFlight", red).
        return (projectedSinkPositionAfterTimeOfFlight - projectedSinkPosition):mag.
    }

    //searchForTrueAnomalyOfSourceAtDeparture(0).

    local timeTillDeparture to ModifiedGoldenSectionSearch(searchForTrueAnomalyOfSourceAtDeparture@, startTimeForSearch, maxTimeOfSearch, 1).
    local sourceDepartureTrueAnomaly to GetTrueAnomalyAfterTime(timeTillDeparture, sourceVectors, sunInfo).
    local sourceDeparturePosition to GetPositionFromTrueAnomaly(timeTillDeparture,sourceVectors, sunInfo).
    local sourceDepartureVelocity to GetVelocityFromTrueAnomaly(timeTillDeparture, sourceVectors, sunInfo).

    print GetTimeInHumanReadableFormat(timeTillDeparture).
    print sourceDepartureTrueAnomaly.

}