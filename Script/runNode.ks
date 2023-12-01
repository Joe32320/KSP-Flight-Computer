function CreateManoeuvreNodeAtTrueAnomaly {
    declare parameter trueAnomaly.
    declare parameter burnVector to v(0,0,0).
    declare parameter numOfOrbitsAhead to 0.
    declare parameter shipVectors to GetShipVectors().
    declare parameter timeSinceEpoch to time:seconds.
   
    local timeTillNode to GetTimeToTrueAnomaly(trueAnomaly, shipVectors) - 0.02. //Because of sim time step
    local eccentricity to GetEccentricityVector(shipVectors):mag.
    local orbitalPeriod to choose GetOrbitalPeriod(shipVectors) if eccentricity < 1 else 0.
    local velocityAtNode to GetVelocityFromTrueAnomaly(trueAnomaly, shipVectors).
    local positionAtNode to GetPositionFromTrueAnomaly(trueAnomaly, shipVectors).
    local normalVector to vCrs(velocityAtNode, positionAtNode).
    local radialVector to vCrs(normalVector, velocityAtNode).

    local progradeScalar to vDot(burnVector, velocityAtNode:normalized).
    local radialScalar to vDot(burnVector, radialVector:normalized).
    local normalScalar to vDot(burnVector, normalVector:normalized).

    local burnNode to Node(timeSinceEpoch + timeTillNode + (orbitalPeriod * numOfOrbitsAhead),radialScalar,normalScalar,progradeScalar).
    add burnNode.
}

function RunNodeBurn{
    declare parameter burnNode to nextNode.

    local deltaV to burnNode:deltaV:mag.
    local effectiveEngineISP to GetCurrentActiveEnginesCollectiveISP().
    if(effectiveEngineISP = 0){return.}
    local lock shipMass to ship:mass * 1000.
    local fuelMassRate to GetCurrentAvailableThrust()/(effectiveEngineISP * constant:g0).

    local halfMass to shipMass * constant:e ^ (-(deltaV/2) / (effectiveEngineISP*constant:g0)).
    local halfMassDiff to shipMass - halfMass.
    local timeOfBurn to halfMassDiff / fuelMassRate.

    SAS off.
    local burnVector to burnNode:deltaV.
    lock steering to burnVector.
    print "Turning craft to point at node".
    until (burnNode:eta - (timeOfBurn)) < 0 {
        wait 0.
    }.

    
    local thrustInStage to GetCurrentAvailableThrust().
    local throttleControl to 0.
    
    lock throttle to throttleControl.

    until (vdot(burnNode:deltaV, burnVector) < 0) {

        if(not thrustInStage = 0){
            local shipAcc to thrustInStage / shipMass.
            set throttleControl to burnNode:deltaV:mag / (shipAcc). 
        }
        
        if(Staging()){
            set thrustInStage to GetCurrentAvailableThrust().
        }
        wait 0.
    }

    set throttleControl to 0.
    unlock steering.
    unlock throttle.
    remove burnNode.
    SAS on.
}