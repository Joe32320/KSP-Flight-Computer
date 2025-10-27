function CirculariseOrbitAtTrueAnomaly{
    declare parameter trueAnomaly.
    declare parameter shipVectors to GetShipVectors().

    local positionAtPoint to GetPositionFromTrueAnomaly(trueAnomaly, shipVectors).
    local velocityAtPoint to GetVelocityFromTrueAnomaly(trueAnomaly, shipVectors).
    local specifcAngularMomentum to GetSpecificAngularMomentum(shipVectors).
    local desiredSpeed to sqrt(ship:body:mu / positionAtPoint:mag).
    local desiredSpeedDirection to vCrs(specifcAngularMomentum, positionAtPoint):normalized.
    local desiredVelocity to desiredSpeed * desiredSpeedDirection.
    local burnVector to desiredVelocity - velocityAtPoint.

    CreateManoeuvreNodeAtTrueAnomaly(trueAnomaly, burnVector, 0, shipVectors).
}

function ChangeOrbitInclinationToMatchTarget{
    declare parameter targetAngluarMomentum to v(0,-1,0).
    declare parameter doBurnAtAsecndingNode to 0. //1 = AN, 0 = nearest, -1 = DN
    declare parameter shipVectors to GetShipVectors().

    local trueAnomalyOfAscendingNode to GetTrueAnomalyOfAscendingNode(targetAngluarMomentum, shipVectors).
    local trueAnomalyOfDescendingNode to mod(trueAnomalyOfAscendingNode + 180, 360).
    local positionOfAscendingNode to GetPositionFromTrueAnomaly(trueAnomalyOfAscendingNode).
    local shipSpecificAngularMomentum to GetSpecificAngularMomentum(shipVectors).
    local shipOrthongonalVector to vCrs(shipSpecificAngularMomentum, shipVectors["Position"]).
    local trueAnomalyOfBurn to 0.
    
    if(vang(positionOfAscendingNode, shipOrthongonalVector) < 90 OR doBurnAtAsecndingNode > 0.5){
       set trueAnomalyOfBurn to trueAnomalyOfAscendingNode.
    }
    else{
       set trueAnomalyOfBurn to trueAnomalyOfDescendingNode.
    }

    local positionOfBurn to GetPositionFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local velocityAtBurnPosition to GetVelocityFromTrueAnomaly(trueAnomalyOfBurn, shipVectors).
    local shipOrthongonalVectorAtBurn to vCrs(shipSpecificAngularMomentum, positionOfBurn).
    local targetOrthongonalVectorToBurn to vCrs(targetAngluarMomentum, positionOfBurn).
    local angleToRotate to vang(shipOrthongonalVectorAtBurn, targetOrthongonalVectorToBurn).

    if(vang(targetOrthongonalVectorToBurn, shipSpecificAngularMomentum) > 90){
        set angleToRotate to 360 - angleToRotate.
    }

    local burnVector to angleAxis(angleToRotate, positionOfBurn) * velocityAtBurnPosition.
    
    CreateManoeuvreNodeAtTrueAnomaly(trueAnomalyOfBurn, burnVector-velocityAtBurnPosition).
}

function HohmannTransfer{
    declare parameter targetSemiMajorAxis.
    declare parameter shipVectors to GetShipVectors().

    local radiusAtBurn to GetRadiusFromTrueAnomaly(0, shipVectors).
    local transferOrbitSemiMajorAxis to (radiusAtBurn + targetSemiMajorAxis) / 2.
    local requiredSpeedAfterBurn to sqrt(body:mu *((2/ radiusAtBurn)-(1/transferOrbitSemiMajorAxis))).
    local positionAtBurn to GetPositionFromTrueAnomaly(0, shipVectors).
    local CurrentSpecificAngluarMomentum to GetSpecificAngularMomentum(shipVectors).
    local currentVelocityAtBurn to GetVelocityFromTrueAnomaly(0, shipVectors).
    local velocityAfterBurn to -vCrs(positionAtBurn,CurrentSpecificAngluarMomentum):normalized * requiredSpeedAfterBurn.
    local burnVector to velocityAfterBurn - currentVelocityAtBurn.

    CreateManoeuvreNodeAtTrueAnomaly(0, burnVector, 0, shipVectors).
    RunNodeBurn().

    wait 5.

    set shipVectors to GetShipVectors().

    local radiusAtAPBurn to GetRadiusFromTrueAnomaly(180, shipVectors).
    local requiredFinalSpeed to sqrt(body:mu *((2/ radiusAtAPBurn)-(1/targetSemiMajorAxis))).
    local positionAtAPBurn to GetPositionFromTrueAnomaly(180, shipVectors).
    local CurrentTransferSpecificAngluarMomentum to GetSpecificAngularMomentum(shipVectors).
    local currentTransferVelocityAtBurn to GetVelocityFromTrueAnomaly(180, shipVectors).
    local finalVelocityAfterBurn to -vCrs(positionAtAPBurn,CurrentTransferSpecificAngluarMomentum):normalized * requiredFinalSpeed.
    local finalBurnVector to finalVelocityAfterBurn - currentTransferVelocityAtBurn.

    local numOrbits to 0.
    if(GetTimeToTrueAnomaly(180, shipVectors) < 600){
        set numOrbits to 1.
    }
    CreateManoeuvreNodeAtTrueAnomaly(180, finalBurnVector, numOrbits, shipVectors).
    RunNodeBurn().
}



