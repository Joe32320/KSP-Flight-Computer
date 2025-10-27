function GameGetOrbit{
    declare parameter positionVector to -ship:body:position.
    declare parameter velocityVector to ship:velocity:orbit.
    declare parameter epochTime to time:seconds.
    declare parameter parentBody to ship:body.

    return createOrbit(positionVector, velocityVector, parentBody, epochTime).
}

function GameGetCurrentTrueAnomaly{
    declare parameter orbitObject to GameGetOrbit().

    return orbitObject:trueAnomaly.
}

function GameGetEccentricityVector{
    
}

