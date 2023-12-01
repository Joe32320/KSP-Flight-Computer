function LaunchToOrbit{
    declare parameter targetSemiMajorAxis to body:radius + 90000.
    declare parameter targetEccentricity to 0.
    declare parameter targetInclincation to 0.
    declare parameter targetLongitudeOfAscendingNode to 0.
    declare parameter targetArguementOfPeriapsis to 0.
    declare parameter targetMeanLongitudeAtEpoch to -1.
    declare parameter launchTowardsEquator to 0.
    declare parameter pitchOverSpeed to 1100.

////Launch/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    local toConductInclincationBurn to false. //For when our launch site is above the target inclination.
    if(abs(ship:latitude) > targetInclincation){
        set toConductInclincationBurn to true.
        LaunchProgram((abs(ship:latitude)+0.1), targetLongitudeOfAscendingNode, launchTowardsEquator, pitchOverSpeed).
    }
    else{
        LaunchProgram(targetInclincation, targetLongitudeOfAscendingNode, launchTowardsEquator, pitchOverSpeed).
    }

    wait 5.

////Boost to AP/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    clearScreen.
    print "Boosting apoapsis....".
    local targetApoapsis to (1 + targetEccentricity) * targetSemiMajorAxis.
    BoostApoapsis(targetApoapsis, targetArguementOfPeriapsis).
    RunNodeBurn().
    wait 5.

////Change inclincation/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   
   if(toConductInclincationBurn){
        clearscreen.
        print "Matching inclination...".
        ChangeOrbitInclinationToMatchTarget().
        RunNodeBurn().
        wait 600.
   }
    
////Time orbit if needed/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    if(targetMeanLongitudeAtEpoch > -0.5){
        clearscreen.
        print "Timing orbit...".
        TimeOrbitTest(targetMeanLongitudeAtEpoch, targetSemiMajorAxis, targetArguementOfPeriapsis, targetLongitudeOfAscendingNode).
    }
////Else put into required orbit/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    else{
        BoostPeriapsis(targetSemiMajorAxis).
        RunNodeBurn().
    }
}

function BoostApoapsis{
    declare parameter targetApoapsis.
    declare parameter targetArguementOfPeriapsis to 0.
    declare parameter shipVectors to GetShipVectors().

    local trueAnomalyOfAscendingNode to GetTrueAnomalyOfAscendingNode(-v(0,1,0), shipVectors).
    local trueAnomalyOfBurn to UnsignedModular(trueAnomalyOfAscendingNode + targetArguementOfPeriapsis,360).
    local radiusAtBurn to GetRadiusFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local transferOrbitSemiMajorAxis to (radiusAtBurn + targetApoapsis) / 2.
    local requiredSpeedAfterBurn to sqrt(body:mu *((2/ radiusAtBurn)-(1/transferOrbitSemiMajorAxis))).
    local positionAtBurn to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local CurrentSpecificAngluarMomentum to GetSpecificAngularMomentum(shipVectors).
    local currentVelocityAtBurn to GetVelocityFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local velocityAfterBurn to -vCrs(positionAtBurn,CurrentSpecificAngluarMomentum):normalized * requiredSpeedAfterBurn.
    local burnVector to velocityAfterBurn - currentVelocityAtBurn.

    CreateManoeuvreNodeAtTrueAnomaly(trueAnomalyOfBurn, burnVector, 0, shipVectors).
}

function BoostPeriapsis{
    declare parameter targetSemiMajorAxis.
    declare parameter shipVectors to GetShipVectors().

    local radiusAtBurn to GetRadiusFromTrueAnomaly(180, shipVectors).
    local requiredSpeedAfterBurn to sqrt(body:mu *((2/ radiusAtBurn)-(1/targetSemiMajorAxis))).
    local positionAtBurn to GetPositionFromTrueAnomaly(180, shipVectors).
    local CurrentSpecificAngluarMomentum to GetSpecificAngularMomentum(shipVectors).
    local currentVelocityAtBurn to GetVelocityFromTrueAnomaly(180, shipVectors).
    local velocityAfterBurn to -vCrs(positionAtBurn,CurrentSpecificAngluarMomentum):normalized * requiredSpeedAfterBurn.
    local burnVector to velocityAfterBurn - currentVelocityAtBurn.

    local numOrbits to 0.
    if(GetTimeToTrueAnomaly(180, shipVectors) < 600){
        set numOrbits to 1.
    }
    CreateManoeuvreNodeAtTrueAnomaly(180, burnVector, numOrbits, shipVectors).
}

function TimeOrbitTest{
    declare parameter targetMeanLongitudeAtEpoch.
    declare parameter targetSemiMajorAxis.
    declare parameter targetArguementOfPeriapsis.
    declare parameter targetLongitudeOfAscendingNode.
    declare parameter shipVectors to GetShipVectors().

    clearScreen.

    local positionOfAP to GetPositionFromTrueAnomaly(180,shipVectors).

    local orbitalPeriodOfFinalOrbit to GetOrbitalPeriodFromSemiMajorAxis(targetSemiMajorAxis).
    local currentOrbitalPeriod to GetOrbitalPeriod(shipVectors).
    local timeTillAP to GetTimeToTrueAnomaly(180, shipVectors).

    local timeFromEpochAtAp to timeTillAP + Time:seconds.
    local meanAnomalyAtEpochIfBurnConductedAtAP to UnsignedModular(180 - ((timeFromEpochAtAp/orbitalPeriodOfFinalOrbit)*360),360).

    local targetMeanAnomalyAtEpoch to UnsignedModular(
        targetMeanLongitudeAtEpoch - targetArguementOfPeriapsis - targetLongitudeOfAscendingNode, 360).

    local meanAnomalyDifference to UnsignedModular(
        meanAnomalyAtEpochIfBurnConductedAtAP  - targetMeanAnomalyAtEpoch, 360).

    local timeToMeetFinalBurn to (meanAnomalyDifference*orbitalPeriodOfFinalOrbit/360) + orbitalPeriodOfFinalOrbit.
    local numberOfOrbitsToMatch to floor(timeToMeetFinalBurn/currentOrbitalPeriod).
    local targetApoapsis to positionOfAP:mag.

    local requiredTransferTime to timeToMeetFinalBurn / numberOfOrbitsToMatch. 

    until requiredTransferTime < GetOrbitalPeriodFromSemiMajorAxis(targetApoapsis){
        set timeToMeetFinalBurn to timeToMeetFinalBurn + orbitalPeriodOfFinalOrbit.
        set numberOfOrbitsToMatch to floor(timeToMeetFinalBurn/currentOrbitalPeriod).
        set requiredTransferTime to timeToMeetFinalBurn / numberOfOrbitsToMatch.
    }

    local currentApoapsis to GetRadiusFromTrueAnomaly(180, shipVectors).
    local requiredTransferSemiMajorAxis to GetSemiMajorAxisFromOrbitalPeriod(requiredTransferTime).

    local requiredApoapsisSpeed to sqrt(body:mu*((2/currentApoapsis)-(1/requiredTransferSemiMajorAxis))).
    local currentVelocityAtBurn to GetVelocityFromTrueAnomaly(180, shipVectors).
    local requiredVelocityAtBurn to -vCrs(GetPositionFromTrueAnomaly(180, shipVectors),GetSpecificAngularMomentum(shipVectors)):normalized 
        * requiredApoapsisSpeed.
    
    CreateManoeuvreNodeAtTrueAnomaly(180, requiredVelocityAtBurn - currentVelocityAtBurn).

    clearscreen.
    print "required time: " +  requiredTransferTime * numberOfOrbitsToMatch.
    print "timeToMatch: " + timeToMeetFinalBurn.
    print "Number of orbits: " + numberOfOrbitsToMatch.
    RunNodeBurn().
    

    wait 600.

    
    set shipVectors to GetShipVectors().
    set currentApoapsis to ship:apoapsis+body:radius.
    local finalSemiMajorAxis to targetSemiMajorAxis.
    local finalAPSpeed to sqrt(body:mu*((2/currentApoapsis)-(1/finalSemiMajorAxis))).
    
    local cVelV to GetVelocityFromTrueAnomaly(180, shipVectors).
    local bVelV to vcrs(GetPositionFromTrueAnomaly(180,shipVectors), -getSpecificAngularMomentum(shipVectors)):normalized*finalAPSpeed.
    local burnVec to bVelV-cVelV.
    
    
    CreateManoeuvreNodeAtTrueAnomaly(180, burnVec, numberOfOrbitsToMatch - 1).
    RunNodeBurn().
}