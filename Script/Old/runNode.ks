function CreateManoeuvreNodeAtTrueAnomaly {

    declare parameter trueAnomaly.
    declare parameter burnVector to v(0,0,0).
    declare parameter numOfOrbitsAhead to 0.
    declare parameter shipVectors to GetShipVectors().
    declare parameter timeSinceEpoch to time:seconds.
   

    local timeTillNode to GetTimeToTrueAnomaly(trueAnomaly, shipVectors) - 0.02. //Because of sim time step
    local orbitalPeriod to GetOrbitalPeriod(shipVectors).
    print "CreateManoeuvreNodeAtTrueAnomaly timeTillNode: " + GetTimeInHumanReadableFormat(timeSinceEpoch - time:Seconds + timeTillNode + (orbitalPeriod * numOfOrbitsAhead)).
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
    local lock shipMass to ship:mass * 1000.
    local finalMass to shipMass * constant:e ^ (-deltaV / (effectiveEngineISP*constant:g0)).
    local massDiff to shipMass - finalMass.
    local fuelMassRate to GetCurrentAvailableThrust()/(effectiveEngineISP * constant:g0).

    local halfMass to shipMass * constant:e ^ (-(deltaV/2) / (effectiveEngineISP*constant:g0)).
    local halfMassDiff to shipMass - halfMass.
    local timeOfBurn to halfMassDiff / fuelMassRate.

    SAS off.
    lock steering to burnNode:deltaV.
    print "Turning craft to point at node".
    until (burnNode:eta - (timeOfBurn)) < 0 {
        
    }.

    local burnVector to burnNode:deltaV.
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
    }

    set throttleControl to 0.
    unlock steering.
    unlock throttle.
    remove burnNode.
    SAS on.
}