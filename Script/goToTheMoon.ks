function TargetMoonSOIChange{
    
    declare parameter finalPeriapsis to 30000.
    declare parameter finalInclincation to 0.

    
    local moonVars to Body("Moon").
    local earthVars to Body("Earth").
    wait 0.
    local epochTime to time:seconds.
    local shipVectors to GetShipVectors().
    local moonVectors to GetTargetVectors(moonVars).
    if(time:seconds = epochTime){
        print "Vectors good".
    }
    else{
        print epochTime - time:seconds.
        return "ERROR".
    }
    local updatedMoonVectors to moonVectors.
    local theta to 180.
    local trueAnomalyOfBurn to 0.
    local radialAngle to 0.
    local normalAngle to 0.

    from {local i to 0.} until  i = 8 step {set i to i + 1.} Do{
        from {local j to 0.} until  j = 8 step {set j to j + 1.} Do{
            set theta to 180.
            set trueAnomalyOfBurn to 0.
            from {local k to 0.} until  k = 8 step {set k to k + 1.} Do{
                set trueAnomalyOfBurn to GetTrueAnomalyOfInsertionBurn(updatedMoonVectors, shipVectors, 180 - theta, radialAngle, normalAngle).
                set theta to GetThetaAngleForInsertion(updatedMoonVectors, shipVectors, trueAnomalyOfBurn, radialAngle, normalAngle).
                //print trueAnomalyOfBurn.
                //print theta.
            }
            set updatedMoonVectors to GetUpdatedMoonVectorsForInsertion(trueAnomalyOfBurn, theta, updatedMoonVectors, moonVectors, shipVectors, epochTime, radialAngle, normalAngle).
        }
        local moonInsertionOrbitVectors to GetMoonOrbitParameters(trueAnomalyOfBurn, theta, updatedMoonVectors, shipVectors, epochTime, radialAngle, normalAngle).
        local vsVec to moonInsertionOrbitVectors["Velocity"].
        local rsVec to moonInsertionOrbitVectors["Position"].

        local vs to vsVec:mag.
        local rs to rsVec:mag.

        local rp to finalPeriapsis + body("Moon"):radius.
        print (rs - body("Moon"):soiradius).
        local mu to body("Moon"):mu.
        local vp to sqrt((mu * 2* (rs -rp) + rp*rs*vs^2)/(rp*rs)).
        print "rp: " + rp.
        print "vp: " + vp.

        print "rs: " + rs.
        print "vs: " + vs.


        local e to ((rp*vp^2)/mu) - 1.

        print "e: " + e.

        set radialAngle to arcSin(rp*vp/(rs*vs)). //related to the flight path angle
        print "Radial: " + radialAngle.
        local moonOrbitMomentum to GetSpecificAngularMomentum(moonInsertionOrbitVectors).
        print arccos(-moonOrbitMomentum:y/moonOrbitMomentum:mag).
        local desiredHy to cos(finalInclincation) * moonOrbitMomentum:mag.

        print "actualHy: " + moonOrbitMomentum:y.
        print "desiredHy: " + desiredHy.
        print "H: " + moonOrbitMomentum:mag.

    if(abs(desiredHy/ moonOrbitMomentum:y) < 1){
        print arccos(desiredHy/ -moonOrbitMomentum:y).
        set normalAngle to arccos(desiredHy/ moonOrbitMomentum:y).
    }
        
    }

    local finalMoonInsertionOrbitVectors to GetMoonOrbitParameters(trueAnomalyOfBurn, theta, updatedMoonVectors, shipVectors, epochTime, radialAngle, normalAngle).
    print (GetRadiusFromTrueAnomaly(0, finalMoonInsertionOrbitVectors, body("Moon")) -  body("Moon"):radius).
    print "Inc: " + GetInclinationOfOrbit(finalMoonInsertionOrbitVectors).
    print vang(finalMoonInsertionOrbitVectors["Velocity"], v(0,-1,0))  - 90.

    CreateInsertionBurnNode(trueAnomalyOfBurn,theta, updatedMoonVectors, shipVectors, radialAngle, normalAngle, epochTime).
            
    
}

local function GetTrueAnomalyOfInsertionBurn{
    declare parameter moonVectors.
    declare parameter shipVectors.
    declare parameter burnOffsetAngle.
    declare parameter radialAngle.
    declare parameter normalAngle.

    local periapsisVector to GetPositionFromTrueAnomaly(0, shipVectors).
    local shipAngularMomentum to GetSpecificAngularMomentum(shipVectors).
    local targetVector to -GetMoonSOIChangePoint(radialAngle, normalAngle, moonVectors). //minus rsVec
    local trueAnomalyOfRM to vang(periapsisVector, targetVector).

    if(vang(vcrs(shipAngularMomentum,periapsisVector), targetVector) > 90) {
        set trueAnomalyOfRM to 360 - trueAnomalyOfRM.
    }
    return UnsignedModular(trueAnomalyOfRM + burnOffsetAngle,360).
}

local function GetMoonSOIChangePoint{
    declare parameter radialAngle.
    declare parameter normalAngle. //For inclination
    declare parameter moonVectors.

    local moonAngularMomentum to GetSpecificAngularMomentum(moonVectors).
    local rotatedMoonVelocityVector to vxcl(moonAngularMomentum,
        RotationFormula(radialAngle, moonVectors["Velocity"]:normalized, moonAngularMomentum)).
clearVecDraws().
    drawVector(body("Moon"):position, ((rotatedMoonVelocityVector:normalized * body("Moon"):soiradius)),"", red).

    local moonOrthongonalVector to vcrs(moonAngularMomentum, moonVectors["Velocity"]):normalized.

    set rotatedMoonVelocityVector to RotationFormula(-normalAngle, rotatedMoonVelocityVector, moonVectors["Velocity"]).

    
    drawVector(body("Moon"):position, ((rotatedMoonVelocityVector:normalized * body("Moon"):soiradius)),"",grey).
    

    return (moonVectors["Position"] + (rotatedMoonVelocityVector:normalized * body("Moon"):soiradius)). //rsVec
}

local function GetUpdatedMoonVectorsForInsertion{
    declare parameter trueAnomalyOfBurn.
    declare parameter theta.
    declare parameter latestMoonVectors.
    declare parameter epochMoonVectors.
    declare parameter shipVectors.
    declare parameter epochTime.
    declare parameter radialAngle.
    declare parameter normalAngle.

    local moonVars to Body("Moon").
    local earthVars to Body("Earth").
    local rmVec to latestMoonVectors["Position"].
    local vmVec to latestMoonVectors["Velocity"].
    local timeTillBurn to GetTimeToTrueAnomaly(trueAnomalyOfBurn, shipVectors) + GetOrbitalPeriod(shipVectors).

    local rpVec to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local rp to rpVec:mag.
    local rsVec to GetMoonSOIChangePoint(radialAngle, normalAngle, latestMoonVectors).
    local rs to rsVec:mag.
    local mu to earthVars:mu.

    local e to (rs - rp) / (rp - rs*cos(theta)).
    local vp to sqrt(mu *(e+1)/rp).

    local currentSpecificAngluarMomentum to -vcrs(rsVec, rpVec).
    local currentVelocityAtBurn to GetVelocityFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local vpVec to -vCrs(rpVec,CurrentSpecificAngluarMomentum):normalized * (vp).
    
    
    local shipTransferVectors to CreateShipVectors(rpVec, vpVec).

    local timeToSOIChange to GetTimeToTrueAnomaly(theta, shipTransferVectors).

    local updatedMoonTrueAnomaly to GetTrueAnomalyAfterTime(timeToSOIChange + timeTillBurn, epochMoonVectors).
    local updatedMoonPosition to GetPositionFromTrueAnomaly(updatedMoonTrueAnomaly, epochMoonVectors).
    local updatedMoonVelocity to GetVelocityFromTrueAnomaly(updatedMoonTrueAnomaly, epochMoonVectors).

    local vsVec to GetVelocityFromTrueAnomaly(theta, shipTransferVectors).
    local usVec to vsVec - vmVec.
    // drawVector(rmVec + ship:body:position, usVec:normalized * moonVars:soiradius , "usVec", yellow).

    return CreateShipVectors(updatedMoonPosition, updatedMoonVelocity, Body("Moon"), "BODY").
}

local function GetMoonOrbitParameters{
    declare parameter trueAnomalyOfBurn.
    declare parameter theta.
    declare parameter moonVectors.
    declare parameter shipVectors.
    declare parameter epochTime.
    declare parameter radialAngle.
    declare parameter normalAngle.

    local moonVars to Body("Moon").
    local earthVars to Body("Earth").
    local rmVec to moonVectors["Position"].
    local vmVec to moonVectors["Velocity"].

    local rpVec to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local rp to rpVec:mag.
    local rsVec to GetMoonSOIChangePoint(radialAngle, normalAngle, moonVectors).
    local rs to rsVec:mag.
    local mu to earthVars:mu.

    local e to (rs - rp) / (rp - rs*cos(theta)).
    local vp to sqrt(mu *(e+1)/rp).

    local currentSpecificAngluarMomentum to -vcrs(rsVec, rpVec).
    local vpVec to -vCrs(rpVec,CurrentSpecificAngluarMomentum):normalized * (vp).
    local shipTransferVectors to CreateShipVectors(rpVec, vpVec).

    local vsVec to GetVelocityFromTrueAnomaly(theta, shipTransferVectors).
    local usVec to vsVec - vmVec.
    local ssVec to rsVec - rmVec.


    local shipMoonOrbitVectors to CreateShipVectors(ssVec, usVec).
    //print "Moon Peri: " + (GetRadiusFromTrueAnomaly(0, shipMoonOrbitVectors, body("Moon"))-body("Moon"):radius).
    //print "Moon Inc: " + GetInclinationOfOrbit(shipMoonOrbitVectors).
    return shipMoonOrbitVectors.
}

local function GetThetaAngleForInsertion{
    declare parameter moonVectors.
    declare parameter shipVectors.
    declare parameter trueAnomalyOfBurn.
    declare parameter radialAngle.
    declare parameter normalAngle.

    local vmVec to moonVectors["Velocity"].
    local rpVec to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local rp to rpVec:mag.
    local rsVec to GetMoonSOIChangePoint(radialAngle, normalAngle, moonVectors).
    local rs to rsVec:mag.
    local et to 360 - (vang(vmVec, rpVec)).
    local a to rs- rp.
    local b to 1/(cos(et)) * rs.
    local c to 1/cos(et) *rp.
    local ns to sin(et).
    local nc to cos(et).

    local quartic to (b*nc + c*nc - a). // equals 2*rp
    local cubic to (-2*b*ns - 2*c*ns).
    local quadatic to (-2*a - 2*b*nc). // equals 2*rp - 4*rs (Divide thru this as it tends to be largest)
    local linear to (2*b*ns - 2*c*ns).

    local x to CubicEquationSolver(quartic,cubic,quadatic,linear,true).
    return arcTan(x)*2. // theta
}

function CreateInsertionBurnNode{
    declare parameter trueAnomalyOfBurn.
    declare parameter theta.
    declare parameter latestMoonVectors.
    declare parameter shipVectors.
    declare parameter radialAngle.
    declare parameter normalAngle.
    declare parameter timeSinceEpoch.

    local earthVars to Body("Earth").

    local rpVec to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local rp to rpVec:mag.
    local rsVec to GetMoonSOIChangePoint(radialAngle, normalAngle, latestMoonVectors).
    local rs to rsVec:mag.
    local mu to earthVars:mu.

    local e to (rs - rp) / (rp - rs*cos(theta)).
    local vp to sqrt(mu *(e+1)/rp).

    local currentSpecificAngluarMomentum to -vcrs(rsVec, rpVec).
    local currentVelocityAtBurn to GetVelocityFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local vpVec to -vCrs(rpVec,CurrentSpecificAngluarMomentum):normalized * (vp).
    local burnVector to vpVec - currentVelocityAtBurn.

    CreateManoeuvreNodeAtTrueAnomaly(trueAnomalyOfBurn, burnVector, 1, shipVectors, timeSinceEpoch).
}