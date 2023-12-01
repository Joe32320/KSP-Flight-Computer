function LaunchToMoonIntercept{
    declare parameter finalOrbitHeight to 30000.
    declare parameter launchTowardsEquator to 0.
    declare parameter pitchOverSpeed to 900.

    LaunchIntoMoonPlane(launchTowardsEquator, pitchOverSpeed).
    wait 5.
    PushToMoon(finalOrbitHeight).
    wait 5.
    RunNodeBurn().
}

function LaunchToMoonOrbit{
    declare parameter finalOrbitHeight to 30000.
    declare parameter launchTowardsEquator to 0.
    declare parameter pitchOverSpeed to 900.

    LaunchToMoonIntercept(finalOrbitHeight, launchTowardsEquator, pitchOverSpeed).
    wait until ship:body:name = "Moon".
    wait 5.
    CirculariseOrbitAtTrueAnomaly(0).
    wait 5.
    RunNodeBurn().
}

function LaunchIntoMoonPlane {
    declare parameter launchTowardsEquator to 0.
    declare parameter pitchOverSpeed to 1100.
    declare parameter targetAlt to 80.

    local moonVectors to GetTargetVectors(Body("Moon")).
    local moonLongitudeOfAscendingNode to GetLongitudeOfAscendingNode(moonVectors).
    local moonInclination to GetInclinationOfOrbit(moonVectors).

    LaunchProgram(moonInclination, moonLongitudeOfAscendingNode, launchTowardsEquator, pitchOverSpeed, targetAlt).
}

function PushToMoon{
    declare parameter finalOrbitHeight to 30000.
    
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

    function searchForFinalPeriapsis{
        declare parameter sTransferOrbitOffset.

        function searchFunction{
            declare parameter timeOfTransferBurn.

            local shipTrueAnomalyAtBurn to GetTrueAnomalyAfterTime(timeOfTransferBurn, shipVectors).
            local shipRadiusAtBurn to GetRadiusFromTrueAnomaly(shipTrueAnomalyAtBurn, shipVectors).
            local targetTrueAnomalyAtShipApoapsis to UnsignedModular(
                shipTrueAnomalyAtBurn + 180 - moonOffsetAngle, 360).
            local targetPositionAtShipApoapsis to GetPositionFromTrueAnomaly(targetTrueAnomalyAtShipApoapsis, moonVectors).
            local transferSemiMajorAxis to (shipRadiusAtBurn + targetPositionAtShipApoapsis:mag-sTransferOrbitOffset)/2.
            local transferTime to constant:pi * sqrt((transferSemiMajorAxis ^ 3)/body:mu).
            local actualTargetTrueAnomalyAtShipApoapsis to GetTrueAnomalyAfterTime(transferTime + timeOfTransferBurn, moonVectors).
            local actualTargetPositionAtShipApoapsis to GetPositionFromTrueAnomaly(actualTargetTrueAnomalyAtShipApoapsis, moonVectors).

            return vang(actualTargetPositionAtShipApoapsis, targetPositionAtShipApoapsis).
        }

        local sActualTimeToTransferBurn to ModifiedGoldenSectionSearch(searchFunction@, startTimeOfSearch, maxTimeOfSearch, 1).
        local sTrueAnomalyOfBurn to GetTrueAnomalyAfterTime(sActualTimeToTransferBurn, shipVectors).
        local sPositionOfBurn to GetPositionFromTrueAnomaly(sTrueAnomalyOfBurn, shipVectors).
        local sTargetTrueAnomaly to UnsignedModular(
                sTrueAnomalyOfBurn + 180 - moonOffsetAngle, 360).
        local sTargetPositionAtMeet to GetPositionFromTrueAnomaly(sTargetTrueAnomaly, moonVectors).
        local sFinalTransferSemiMajorAxis to (sPositionOfBurn:mag + sTargetPositionAtMeet:mag - sTransferOrbitOffset)/2.
        local sRequiredSpeedAfterBurn to sqrt(body:mu *((2/ sPositionOfBurn:mag)-(1/sFinalTransferSemiMajorAxis))).
        local sCurrentSpecificAngluarMomentum to GetSpecificAngularMomentum(shipVectors).
        local sVelocityAfterBurn to -vCrs(sPositionOfBurn, sCurrentSpecificAngluarMomentum):normalized * sRequiredSpeedAfterBurn.

        //CreateManoeuvreNodeAtTrueAnomaly(trueAnomalyOfBurn, burnVector, 1, shipVectors, epochTime).
        local transferShipVectors to CreateShipVectors(sPositionOfBurn, sVelocityAfterBurn).
        local result to FindLunarSOIChange(transferShipVectors, sActualTimeToTransferBurn, moonVectors) - finalOrbitHeight.
        print result.
        return result.
    }
    local transferOrbitOffset to ModifiedBisectionSearch(searchForFinalPeriapsis@, 0, moonParameters:SOIRadius/2, 1).
    print transferOrbitOffset.

    function searchFunction{
            declare parameter timeOfTransferBurn.

            local shipTrueAnomalyAtBurn to GetTrueAnomalyAfterTime(timeOfTransferBurn, shipVectors).
            local shipRadiusAtBurn to GetRadiusFromTrueAnomaly(shipTrueAnomalyAtBurn, shipVectors).
            local targetTrueAnomalyAtShipApoapsis to UnsignedModular(
                shipTrueAnomalyAtBurn + 180 - moonOffsetAngle, 360).
            local targetPositionAtShipApoapsis to GetPositionFromTrueAnomaly(targetTrueAnomalyAtShipApoapsis, moonVectors).
            local transferSemiMajorAxis to (shipRadiusAtBurn + targetPositionAtShipApoapsis:mag-transferOrbitOffset)/2.
            local transferTime to constant:pi * sqrt((transferSemiMajorAxis ^ 3)/body:mu).
            local actualTargetTrueAnomalyAtShipApoapsis to GetTrueAnomalyAfterTime(transferTime + timeOfTransferBurn, moonVectors).
            local actualTargetPositionAtShipApoapsis to GetPositionFromTrueAnomaly(actualTargetTrueAnomalyAtShipApoapsis, moonVectors).

            return vang(actualTargetPositionAtShipApoapsis, targetPositionAtShipApoapsis).
        }

    local actualTimeToTransferBurn to ModifiedGoldenSectionSearch(searchFunction@, startTimeOfSearch, maxTimeOfSearch, 0.01).
    local trueAnomalyOfBurn to GetTrueAnomalyAfterTime(actualTimeToTransferBurn, shipVectors).
    local positionOfBurn to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local targetTrueAnomaly to UnsignedModular(
            trueAnomalyOfBurn + 180 - moonOffsetAngle, 360).
    local targetPositionAtMeet to GetPositionFromTrueAnomaly(targetTrueAnomaly, moonVectors).
    local finalTransferSemiMajorAxis to (positionOfBurn:mag + targetPositionAtMeet:mag - transferOrbitOffset)/2.
    local requiredSpeedAfterBurn to sqrt(body:mu *((2/ positionOfBurn:mag)-(1/finalTransferSemiMajorAxis))).
    local currentSpecificAngluarMomentum to GetSpecificAngularMomentum(shipVectors).
    local currentVelocityAtBurn to GetVelocityFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local velocityAfterBurn to -vCrs(positionOfBurn, currentSpecificAngluarMomentum):normalized * requiredSpeedAfterBurn.
    local burnVector to velocityAfterBurn - currentVelocityAtBurn.

    CreateManoeuvreNodeAtTrueAnomaly(trueAnomalyOfBurn, burnVector, 1, shipVectors, epochTime).
}

local function FindLunarSOIChange{
    declare parameter transferShipVectors.
    declare parameter transferBurnTime.
    declare parameter moonVectors.

    local moonParameters to Body("Moon").

    function searchFunction{
        declare parameter trueAnomaly.

        local p to GetPositionFromTrueAnomaly(trueAnomaly, transferShipVectors).
        local timeToTrueAnomaly to GetTimeToTrueAnomaly(trueAnomaly, transferShipVectors) + transferBurnTime.
        local moonTrueAnomalyAtTime to GetTrueAnomalyAfterTime(timeToTrueAnomaly, moonVectors).
        local s to GetPositionFromTrueAnomaly(moonTrueAnomalyAtTime, moonVectors).

        return (p:x - s:x)^2 + (p:y - s:y)^2 + (p:z - s:z)^2 - (moonParameters:SOIRadius)^2.
    }

    local trueAnomalyOfSOIChange to ModifiedBisectionSearch(searchFunction@, 91, 180,0.01).
    local positionOfSOIChange to GetPositionFromTrueAnomaly(trueAnomalyOfSOIChange, transferShipVectors).
    local velocityAtSOIChange to GetVelocityFromTrueAnomaly(trueAnomalyOfSOIChange, transferShipVectors).
    local timeToSOIChange to GetTimeToTrueAnomaly(trueAnomalyOfSOIChange, transferShipVectors) + transferBurnTime.
    local moonPositionAtSOIChange to GetPositionFromTrueAnomaly(GetTrueAnomalyAfterTime(timeToSOIChange, moonVectors), moonVectors).
    local moonVelocityAtSOIChange to GetVelocityFromTrueAnomaly(GetTrueAnomalyAfterTime(timeToSOIChange, moonVectors), moonVectors).
    local positionOfSOIChangeRelativeToMoon to positionOfSOIChange - moonPositionAtSOIChange.
    local velocityAtSOIChangeRelativeToMoon to velocityAtSOIChange - moonVelocityAtSOIChange.
    local moonOrbitVectors to CreateShipVectors(positionOfSOIChangeRelativeToMoon,velocityAtSOIChangeRelativeToMoon).

    return GetPositionFromTrueAnomaly(0, moonOrbitVectors, moonParameters):mag - moonParameters:radius.
}

function ReturnToEarth{
    declare parameter finalPeriapsis to 40000.

    local moonVars to Body("Moon").
    local earthVars to Body("Earth").

    wait 0.
    local epochTime to time:Seconds.
    local moonVectors to GetTargetVectors(moonVars, "Body", earthVars).
    local shipVectors to GetShipVectors().
    
    if(time:seconds = epochTime){
        print "Vectors good".
    }
    else{
        print "ERROR!".
        print epochTime - time:seconds.
        return.
    }

    function searchFunction{
        declare parameter burnOffsetAngle.
        local updatedMoonVectors to moonVectors.
        from {local i to 0.} until  i = 3 step {set i to i + 1.} Do{
            set updatedMoonVectors to GetUpdatedMoonVectorsForReturn(updatedMoonVectors, shipVectors, moonVectors, burnOffsetAngle).
        }
        return GetReturnToEarthPeriapsis(updatedMoonVectors, shipVectors, burnOffsetAngle, epochTime, finalPeriapsis).
    }

    local finalBurnOffsetAngle to SimpleGoldenSectionSearch(searchFunction@, 0, 90, 0.000001).
    local finalUpdatedMoonVectors to moonVectors.
    from {local i to 0.} until  i = 3 step {set i to i + 1.} Do{
        set finalUpdatedMoonVectors to GetUpdatedMoonVectorsForReturn(finalUpdatedMoonVectors, shipVectors, moonVectors, finalBurnOffsetAngle).
    }

    return SetupReturnToEarthNode(finalUpdatedMoonVectors, shipVectors, finalBurnOffsetAngle, epochTime).
}

local function GetTrueAnomalyOfReturnBurn{
    declare parameter moonVectors.
    declare parameter shipVectors.
    declare parameter burnOffsetAngle.

    local periapsisVector to GetPositionFromTrueAnomaly(0, shipVectors).
    local shipAngularMomentum to GetSpecificAngularMomentum(shipVectors).
    local trueAnomalyOfVM to vang(periapsisVector,moonVectors["Velocity"]).

    if(vang(vcrs(shipAngularMomentum,periapsisVector), moonVectors["Velocity"]) > 90) {
        set trueAnomalyOfVM to 360 - trueAnomalyOfVM.
    }
    return UnsignedModular(trueAnomalyOfVM + burnOffsetAngle,360).
}

local function GetUpdatedMoonVectorsForReturn{
    declare parameter moonVectors.
    declare parameter shipVectors.
    declare parameter epochMoonVectors.
    declare parameter burnOffsetAngle.

    local moonVars to Body("Moon").
    local earthVars to Body("Earth").
    local shipAngularMomentum to GetSpecificAngularMomentum(shipVectors).
    local trueAnomalyOfBurn to GetTrueAnomalyOfReturnBurn(moonVectors, shipVectors, burnOffsetAngle).
    local rpVec to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local rs to moonVars:soiRadius.
    local vp to GetMoonPeriapsisSpeed(moonVectors, shipVectors, trueAnomalyOfBurn, burnOffsetAngle).
    local vpVec to -vCrs(rpVec,shipAngularMomentum):normalized * (vp).
    local newShipVectors to CreateShipVectors(rpVec, vpVec).
    local rsTrueAnomaly to GetTrueAnomalyFromRadius(rs,newShipVectors).
    local timeTillBurn to GetTimeToTrueAnomaly(trueAnomalyOfBurn, shipVectors) + GetOrbitalPeriod(shipVectors).
    local timeFromBurnToSOI to GetTimeToTrueAnomaly(rsTrueAnomaly, newShipVectors).
    local timeTillSOIChange to timeFromBurnToSOI + timeTillBurn.
    local updatedMoonTrueAnomaly to GetTrueAnomalyAfterTime(timeTillSOIChange, epochMoonVectors, earthVars).
    local updatedMoonVelocity to GetVelocityFromTrueAnomaly(updatedMoonTrueAnomaly, epochMoonVectors, earthVars).
    local updatedMoonPosition to GetPositionFromTrueAnomaly(updatedMoonTrueAnomaly, epochMoonVectors, earthVars).

    return CreateShipVectors(updatedMoonPosition, updatedMoonVelocity, Body("Moon"), "BODY").
}

//New method solves theta, then solves vp, old method takes predicted flight after burn and looks at the angular difference
//between velocity at SOI and the moons velocity.
local function GetMoonPeriapsisSpeed{
    declare parameter moonVectors.
    declare parameter shipVectors.
    declare parameter trueAnomalyOfBurn.
    declare parameter burnOffsetAngle.

    local moonVars to Body("Moon").
    local rpVec to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local rp to rpVec:mag.
    local rs to moonVars:soiRadius.
    local mu to  Body("moon"):mu.
    local et to (180 - burnOffsetAngle).
    local a to rs- rp.
    local b to 1/(cos(et)) * rs.
    local c to 1/cos(et) *rp.
    local ns to sin(et).
    local nc to cos(et).

    local quadatic to (-2*a - 2*b*nc). // equals 2*rp - 4*rs (Divide thru this as it tends to be largest)
    local quartic to (b*nc + c*nc - a)/quadatic. // equals 2*rp
    local cubic to (-2*b*ns - 2*c*ns)/quadatic.
    local linear to (2*b*ns - 2*c*ns)/quadatic.

    function fFunc{
        declare parameter x.
        return (quartic * (x^4)) + (cubic * (x^3)) + (x^2) + (linear *x).
    }
    local theta to arcTan(ModifiedBisectionSearch(fFunc@, 1, 60, 0.000001))*2.
    local e to (rs - rp) / (rp - rs*cos(theta)).
    local newVP to sqrt(mu *(e+1)/rp).

    return newVP.
}

local function SetupReturnToEarthNode{
    declare parameter moonVectors.
    declare parameter shipVectors.
    declare parameter burnOffsetAngle.
    declare parameter epochTime.

    local trueAnomalyOfBurn to GetTrueAnomalyOfReturnBurn(moonVectors, shipVectors, burnOffsetAngle).
    local rpVec to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local vp to GetMoonPeriapsisSpeed(moonVectors, shipVectors, trueAnomalyOfBurn, burnOffsetAngle).
    local CurrentSpecificAngluarMomentum to GetSpecificAngularMomentum(shipVectors).
    local currentVelocityAtBurn to GetVelocityFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local vpVec to -vCrs(rpVec,CurrentSpecificAngluarMomentum):normalized * (vp).
    local burnVector to vpVec - currentVelocityAtBurn.
    if(hasnode){
        remove nextNode.
    }
    CreateManoeuvreNodeAtTrueAnomaly(trueAnomalyOfBurn, burnVector, 1, shipVectors, epochTime).
}

local function GetReturnToEarthPeriapsis{
    declare parameter moonVectors.
    declare parameter shipVectors.
    declare parameter burnOffsetAngle.
    declare parameter epochTime.
    declare parameter desiredEarthPeriapsis.

    local trueAnomalyOfBurn to GetTrueAnomalyOfReturnBurn(moonVectors, shipVectors, burnOffsetAngle).
    local rpVec to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local vp to GetMoonPeriapsisSpeed(moonVectors, shipVectors, trueAnomalyOfBurn, burnOffsetAngle).
    local CurrentSpecificAngluarMomentum to GetSpecificAngularMomentum(shipVectors).
    local vpVec to -vCrs(rpVec,CurrentSpecificAngluarMomentum):normalized * (vp).
    if(hasnode){
        remove nextNode.
    }
    local rs to  Body("Moon"):soiRadius.
    local newShipVectors to CreateShipVectors(rpVec, vpVec).
    local rsTrueAnomaly to GetTrueAnomalyFromRadius(rs,newShipVectors).
    local rsVec to GetPositionFromTrueAnomaly(rsTrueAnomaly, newShipVectors).
    local vsVec to GetVelocityFromTrueAnomaly(rsTrueAnomaly, newShipVectors).
    local reVec to moonVectors["Position"] + rsVec.
    local veVec to moonVectors["Velocity"] + vsVec.
    local earthSOIVectors to CreateShipVectors(reVec, veVec).

    print "Final radius: " + (GetRadiusFromTrueAnomaly(0, earthSOIVectors, Body("Earth")) - Body("Earth"):radius - desiredEarthPeriapsis).

    return abs(GetRadiusFromTrueAnomaly(0, earthSOIVectors, Body("Earth")) - Body("Earth"):radius - desiredEarthPeriapsis).
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



