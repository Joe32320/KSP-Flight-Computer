function LaunchToMoonIntercept{
    declare parameter launchTowardsEquator to 0.
    declare parameter pitchOverSpeed to 1100.

    local moonVectors to GetTargetVectors(Body("Moon")).
    local moonLongitudeOfAscendingNode to GetLongitudeOfAscendingNode(moonVectors).
    local moonInclination to GetInclinationOfOrbit(moonVectors).

    LaunchProgram(moonInclination, moonLongitudeOfAscendingNode, launchTowardsEquator, pitchOverSpeed).
    wait 5.

    //PushToMoon().
    //RunNodeBurn().
}

function PushToMoon{
    
    wait 0.
    local epochTime to time:seconds.
    local moonVectors to GetTargetVectors(Body("Moon")).
    local shipVectors to GetShipVectors().
    if(time:seconds = epochTime){
        print "Vectors good".
    }
    else{
        print epochTime - time:seconds.
    }


    
    local moonParameters to Body("Moon").
    local shipOrbitalPeriod to GetOrbitalPeriod(shipVectors).
    local moonEccentricityVector to GetEccentricityVector(moonVectors).
    local shipEccentricityVector to GetEccentricityVector(shipVectors).
    local shipAngularMomentum to GetSpecificAngularMomentum(shipVectors).
    local shipEccentricityOrthongonalVector to vCrs(shipAngularMomentum, shipEccentricityVector):normalized.

    local moonOffsetAngle to vang(moonEccentricityVector, shipEccentricityVector).
    if(vang(moonEccentricityVector, shipEccentricityOrthongonalVector) > 90){
        set moonOffsetAngle to 360 - moonOffsetAngle.
    }

    local moonMeanMotion to GetMeanAngularVelocity(moonVectors).
    local shipMeanMotion to GetMeanAngularVelocity(shipVectors).
    local meanMotionDifference to abs(moonMeanMotion - shipMeanMotion).
    local startTimeOfSearch to shipOrbitalPeriod.
    local maxTimeOfSearch to 360/meanMotionDifference + shipOrbitalPeriod.

    function searchFunction{
        declare parameter timeOfTransferBurn.

        local shipTrueAnomalyAtBurn to GetTrueAnomalyAfterTime(timeOfTransferBurn, shipVectors).
        local shipRadiusAtBurn to GetRadiusFromTrueAnomaly(shipTrueAnomalyAtBurn, shipVectors).

        local targetTrueAnomalyAtShipApoapsis to UnsignedModular(
            shipTrueAnomalyAtBurn + 180 - moonOffsetAngle, 360).

        clearVecDraws().
        
        local targetPositionAtShipApoapsis to GetPositionFromTrueAnomaly(targetTrueAnomalyAtShipApoapsis, moonVectors).
        local transferSemiMajorAxis to (shipRadiusAtBurn + targetPositionAtShipApoapsis:mag-moonParameters:radius*4)/2.
        local transferTime to constant:pi * sqrt((transferSemiMajorAxis ^ 3)/body:mu).

        local actualTargetTrueAnomalyAtShipApoapsis to GetTrueAnomalyAfterTime(transferTime + timeOfTransferBurn, moonVectors).
        local actualTargetPositionAtShipApoapsis to GetPositionFromTrueAnomaly(actualTargetTrueAnomalyAtShipApoapsis, moonVectors).

        // drawVector(ship:body:position, actualTargetPositionAtShipApoapsis , "actualTargetPositionAtShipApoapsis", green).
        // drawVector(ship:body:position, targetPositionAtShipApoapsis , "targetPositionAtShipApoapsis", red).

        return vang(actualTargetPositionAtShipApoapsis, targetPositionAtShipApoapsis).
    }

    local actualTimeToTransferBurn to ModifiedGoldenSectionSearch(searchFunction@, startTimeOfSearch, maxTimeOfSearch, 0.001).
    local trueAnomalyOfBurn to GetTrueAnomalyAfterTime(actualTimeToTransferBurn, shipVectors).
    local positionOfBurn to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local targetTrueAnomaly to UnsignedModular(
            trueAnomalyOfBurn + 180 - moonOffsetAngle, 360).
    local targetPositionAtMeet to GetPositionFromTrueAnomaly(targetTrueAnomaly, moonVectors).
    local finalTransferSemiMajorAxis to (positionOfBurn:mag + targetPositionAtMeet:mag - -moonParameters:radius*4)/2.
    local currentVelocityAtBurn to GetVelocityFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local requiredSpeedAfterBurn to sqrt(body:mu *((2/ positionOfBurn:mag)-(1/finalTransferSemiMajorAxis))).
    local currentSpecificAngluarMomentum to GetSpecificAngularMomentum(shipVectors).
    local velocityAfterBurn to -vCrs(positionOfBurn, currentSpecificAngluarMomentum):normalized * requiredSpeedAfterBurn.
    local burnVector to velocityAfterBurn - currentVelocityAtBurn.
    
    print "actualTimeToTransferBurn: " + GetTimeInHumanReadableFormat(actualTimeToTransferBurn + epochTime - time:seconds).
    CreateManoeuvreNodeAtTrueAnomaly(trueAnomalyOfBurn, burnVector, 1, shipVectors, epochTime).
    print "Node eta: " + GetTimeInHumanReadableFormat(nextNode:eta).
    print "Node eta Diff: " + (actualTimeToTransferBurn + epochTime - time:seconds - nextNode:eta).

    wait 0.
    local transferShipVectors to CreateShipVectors(positionOfBurn, velocityAfterBurn).
    // set moonVectors to GetTargetVectors(Body("Moon")).
    print "Time of function: " + (time:seconds - epochTime).

    FindLunarSOIChange(transferShipVectors, actualTimeToTransferBurn, moonVectors, positionOfBurn, epochTime).
}

function FindLunarSOIChange{
    declare parameter transferShipVectors.
    declare parameter transferBurnTime.
    declare parameter moonVectors.
    declare parameter positionOfBurn.
    declare parameter epochTime.

    print " ".

    local moonParameters to Body("Moon").
    //print (GetPositionFromTrueAnomaly(0, transferShipVectors) -positionOfBurn):mag.

    function searchFunction{
        declare parameter trueAnomaly.

        local positionAtTrueAnomaly to GetPositionFromTrueAnomaly(trueAnomaly, transferShipVectors).
        local timeToTrueAnomaly to GetTimeToTrueAnomaly(trueAnomaly, transferShipVectors) + transferBurnTime.
        local moonTrueAnomalyAtTime to GetTrueAnomalyAfterTime(timeToTrueAnomaly, moonVectors).
        clearVecDraws().
        local moonPositionAtTime to GetPositionFromTrueAnomaly(moonTrueAnomalyAtTime, moonVectors).

        // drawVector(ship:body:position, positionAtTrueAnomaly , "positionAtTrueAnomaly", green).
        // drawVector(ship:body:position, moonPositionAtTime , "moonPositionAtTime", red).
        // drawVector(ship:body:position, positionOfBurn*2 , "positionOfBurn", blue).
        local p to positionAtTrueAnomaly.
        local s to moonPositionAtTime.

        return (p:x - s:x)^2 + (p:y - s:y)^2 + (p:z - s:z)^2 - (moonParameters:SOIRadius)^2.
    }

    //print FindZeroValues(searchFunction@, 177, 178, 0.001).

    local trueAnomalyOfSOIChange to ModifiedBisectionSearch(searchFunction@, 91, 179.5,0.000001).
    local positionOfSOIChange to GetPositionFromTrueAnomaly(trueAnomalyOfSOIChange, transferShipVectors).
    // local velocityAtSOIChange to GetVelocityFromTrueAnomaly(trueAnomalyOfSOIChange, transferShipVectors).
    local timeToSOIChange to GetTimeToTrueAnomaly(trueAnomalyOfSOIChange, transferShipVectors) + transferBurnTime.
    local moonPositionAtSOIChange to GetPositionFromTrueAnomaly(GetTrueAnomalyAfterTime(timeToSOIChange, moonVectors), moonVectors).

    print "timeToSOIChange: " + GetTimeInHumanReadableFormat(timeToSOIChange - time:seconds + epochTime).
    print "time till encounter per the game: " + GetTimeInHumanReadableFormat(nextNode:orbit:nextpatcheta).
    print "time till SOI diff: " + (timeToSOIChange - nextNode:orbit:nextpatcheta - time:seconds + epochTime).
    print "Distance difference: " + ((positionOfSOIChange-moonPositionAtSOIChange):mag - moonParameters:SOIRadius).
    
}

function FindLunarSOIChangePostBurn{

    local moonVars to Body("Moon").
    wait 0.
    local epochTime to time:seconds.
    local shipVectors to GetShipVectors().
    local moonVectors to GetTargetVectors(moonVars).
    if(time:seconds = epochTime){
        print "Vectors good".
    }
    else{
        print epochTime - time:seconds.
    }

    function searchFunction{
        declare parameter trueAnomaly.

        local positionAtTrueAnomaly to GetPositionFromTrueAnomaly(trueAnomaly, shipVectors).
        local timeToTrueAnomaly to GetTimeToTrueAnomaly(trueAnomaly, shipVectors).
        local moonTrueAnomalyAtTime to GetTrueAnomalyAfterTime(timeToTrueAnomaly, moonVectors).
        //clearVecDraws().
        local moonPositionAtTime to GetPositionFromTrueAnomaly(moonTrueAnomalyAtTime, moonVectors).


        // drawVector(ship:body:position, positionAtTrueAnomaly , "positionAtTrueAnomaly", green).
        // drawVector(ship:body:position, moonPositionAtTime , "moonPositionAtTime", red).
        // drawVector(ship:body:position, positionOfBurn*2 , "positionOfBurn", blue).
        local p to positionAtTrueAnomaly.
        local s to moonPositionAtTime.

        //log (p:x - s:x)^2 + (p:x - s:x)^2 + (p:x - s:x)^2 -  moonVars:SOIRadius^2 to "logs.csv".

        //return (positionAtTrueAnomaly - moonPositionAtTime):mag - moonVars:SOIRadius.
        return (p:x - s:x)^2 + (p:y - s:y)^2 + (p:z - s:z)^2 - (moonVars:SOIRadius)^2.
    }

    local trueAnomalyOfSOIChange to ModifiedBisectionSearch(searchFunction@, 90, 180,0.000000001).
    local positionAtSOIChange to GetPositionFromTrueAnomaly(trueAnomalyOfSOIChange, shipVectors).
    local timeToSOIChange to GetTimeToTrueAnomaly(trueAnomalyOfSOIChange, shipVectors).

    local moonPositionAtSOIChange to GetPositionFromTrueAnomaly(GetTrueAnomalyAfterTime(timeToSOIChange, moonVectors), moonVectors).
    

    print "trueAnomalyOfSOIChange: " + trueAnomalyOfSOIChange.
    print "timeToSOIChange: " + GetTimeInHumanReadableFormat(timeToSOIChange + epochTime - time:seconds).
    print "Game encounter time: " + GetTimeInHumanReadableFormat(ship:orbit:nextpatcheta).
    print "timeToSOIChangeRaw: " + (timeToSOIChange).
    print "time till SOI diff: " + (timeToSOIChange + epochTime - time:seconds - ship:orbit:nextpatcheta).

    print "Distance difference: " + ((positionAtSOIChange-moonPositionAtSOIChange):mag - moonVars:SOIRadius).

    //drawVector(ship:body:position, myPositionAtSOIChange , "myPositionAtSOIChange", red).
    //drawVector(ship:body:position, gamePositionAtSOIChange , "gamePositionAtSOIChange", blue).

    // WARPTO( epochTime + timeToSOIChange).
    // until time:seconds > epochTime + timeToSOIChange{
        
    // }.

    // print ship:body:position:mag - body:radius.
}