function RendezvousAndDockWithTarget{
    declare parameter targetToRendezvous to target.
    declare parameter desiredPhaseAngle to 179.
    declare parameter orientation to 0.

    SetUpRendezvous(targetToRendezvous, desiredPhaseAngle).
    wait 5.
    RendezvousBurn(targetToRendezvous).
}

function DockWithTarget{
    declare parameter targetToRendezvous to target.
    declare parameter orientation to 0.
    declare parameter avoidanceDistance to 100. // Distance to avoid target object by
    declare parameter speedLimit to 5. // metres per second
    declare parameter approachConeOffset to 10. 


    SAS off.

    lock steering to LOOKDIRUP(-targetToRendezvous:facing:vector, targetToRendezvous:facing:topVector).

    wait until vang(ship:facing:vector, -targetToRendezvous:facing:vector) < 5 AND 
        vang(ship:facing:topVector, -targetToRendezvous:facing:topVector) < 5. //Wait for ship to align with target

    local timeOfLastDraw to 0.

    until 1 < 0 {
        local targetFacing to targetToRendezvous:facing:vector.
        local targetPosition to targetToRendezvous:position.
        local relativeVelocity to ship:velocity:orbit - targetToRendezvous:velocity:orbit.

        local vectorToDockingPlane to -targetFacing:normalized * vDot(targetPosition, -targetFacing).
        local vectorToDockingLine to vxcl(targetFacing, targetPosition).

        local velocityToDockingLine to vxcl(targetFacing, relativeVelocity).

        //We need to push out before getting in front of the port
        if(vectorToDockingPlane:mag < 0 AND vectorToDockingLine:mag < avoidanceDistance){
            
        }
        // We need to get in front of the docking port
        else if(vectorToDockingPlane:mag < 0 AND vectorToDockingLine:mag > avoidanceDistance){

        }

        print "vectorToDockingPlane: " + vectorToDockingPlane:mag at(0,0).  
        print "vectorToDockingLine: " + vectorToDockingLine:mag at (0,1).

        if(time:seconds > timeOfLastDraw + 5){
            clearVecDraws().
            set timeOfLastDraw to time:seconds.

            drawVector(ship:Position, targetPosition, "Target Position", red). 
            drawVector(ship:Position, vectorToDockingPlane, "vectorToDockingPlane", blue). 
            drawVector(ship:Position, vectorToDockingLine, "vectorToDockingLine", green). 
        }
    }
}




function SetUpRendezvous{
    declare parameter targetToRendezvous to target.
    declare parameter desiredPhaseAngle to 179.

    wait 0.
    local epochTime to time:seconds.
    local sinkVectors to GetTargetVectors(targetToRendezvous, "SHIP").
    local sourceVectors to GetShipVectors().
    if(time:seconds = epochTime){
        print "Vectors good".
    }
    else{
        print epochTime - time:seconds.
    }

    local sourceMeanMotion to GetMeanAngularVelocity(sourceVectors).
    local sinkMeanMotion to GetMeanAngularVelocity(sinkVectors).

    local meanMotionDifference to abs(sourceMeanMotion - sinkMeanMotion).
    local startTimeOfSearch to GetOrbitalPeriod(sourceVectors).
    local maxTimeOfSearch to 360/meanMotionDifference + startTimeOfSearch.

    local sourceAngularMomentum to GetSpecificAngularMomentum(sourceVectors).
    local sinkAngularMomentum to GetSpecificAngularMomentum(sinkVectors).

    local sinkEccentricityVector to GetEccentricityVector(sinkVectors).
    local sinkOrthgonalVector to RotationFormula(90, sinkEccentricityVector, sinkAngularMomentum).

    function searchFunction{
        declare parameter projectedTimeOfBurn.

        local projectedSourceTrueAnomaly to GetTrueAnomalyAfterTime(projectedTimeOfBurn, sourceVectors).
        local projectedSourcePosition to GetPositionFromTrueAnomaly(projectedSourceTrueAnomaly, sourceVectors).
        local projectedRotatedSourcePosition to 
            RotationFormula(desiredPhaseAngle, projectedSourcePosition, sourceAngularMomentum) * projectedSourcePosition:mag.
        local projectedSinkTrueAnomaly to vang(sinkEccentricityVector, vxcl(sinkAngularMomentum, projectedRotatedSourcePosition)).
        if(vang(sinkOrthgonalVector, vxcl(sinkAngularMomentum, projectedRotatedSourcePosition)) > 90){
            set projectedSinkTrueAnomaly to 360 - projectedSinkTrueAnomaly.
        }
        local projectedSinkPosition to GetPositionFromTrueAnomaly(projectedSinkTrueAnomaly, sinkVectors).
        local projectedLambertInfo to LambertSolver(projectedSourcePosition, projectedSinkPosition).
        local actualSinkTrueAnomaly to GetTrueAnomalyAfterTime(projectedTimeOfBurn + projectedLambertInfo["flightTime"], sinkVectors).
        local projectedActualSinkPosition to GetPositionFromTrueAnomaly(actualSinkTrueAnomaly, sinkVectors).

        return (projectedActualSinkPosition - projectedSinkPosition):mag.
    }

    local timeOfTransferBurn to SimpleGoldenSectionSearch(searchFunction@, startTimeOfSearch, maxTimeOfSearch, 0.01).
    local orbitsNeeded to  timeOfTransferBurn/GetOrbitalPeriod(sourceVectors).
    local sourceTrueAnomaly to GetTrueAnomalyAfterTime(timeOfTransferBurn, sourceVectors).
    local sourcePosition to GetPositionFromTrueAnomaly(sourceTrueAnomaly, sourceVectors).
    local rotatedSourcePosition to 
        RotationFormula(desiredPhaseAngle, sourcePosition, sourceAngularMomentum) * sourcePosition:mag.
    local sinkTrueAnomaly to vang(sinkEccentricityVector, vxcl(sinkAngularMomentum, rotatedSourcePosition)).
    if(vang(sinkOrthgonalVector, vxcl(sinkAngularMomentum, rotatedSourcePosition)) > 90){
        set sinkTrueAnomaly to 360 - sinkTrueAnomaly.
    }
    local sinkPosition to GetPositionFromTrueAnomaly(sinkTrueAnomaly, sinkVectors).
    local lambertInfo to LambertSolver(sourcePosition, sinkPosition).
    local burnVector to lambertInfo["v1"] - GetVelocityFromTrueAnomaly(sourceTrueAnomaly, sourceVectors).
    CreateManoeuvreNodeAtTrueAnomaly(sourceTrueAnomaly, burnVector, floor(orbitsNeeded)).
    RunNodeBurn().
}

function RendezvousBurn{
    declare parameter targetToRendezvous to target.

    wait 0.
    local epochTime to time:seconds.
    local sinkVectors to GetTargetVectors(targetToRendezvous, "SHIP").
    local sourceVectors to GetShipVectors().
    if(time:seconds = epochTime){
        print "Vectors good".
    }
    else{
        print epochTime - time:seconds.
    }

    local sourceTrueAnomalyOfClosestApproach to GetTrueAnomalyOfClosestApproachToTarget(sourceVectors, sinkVectors).
    local sinkTrueAnomalyOfClosestApproach to GetTrueAnomalyOfClosestApproachToTarget(sinkVectors, sourceVectors).

    local sourceVelocityAtClosestApproach to GetVelocityFromTrueAnomaly(sourceTrueAnomalyOfClosestApproach, sourceVectors).
    local sinkVelocityAtClosestApproach to GetVelocityFromTrueAnomaly(sinkTrueAnomalyOfClosestApproach, sinkVectors).

    local burnVector to sinkVelocityAtClosestApproach - sourceVelocityAtClosestApproach.

    CreateManoeuvreNodeAtTrueAnomaly(sourceTrueAnomalyOfClosestApproach, burnVector, 0).

    RunNodeBurn().
}

function GetWithinPhysicsRangeOfTarget{
    declare parameter targetToRendezvous to target.
}