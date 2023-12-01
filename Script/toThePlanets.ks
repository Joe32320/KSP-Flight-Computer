function FindLaunchWindow{
    declare parameter sourceBody to Body("Earth").
    declare parameter targetBody to Body("Venus").
    declare parameter startTrueAnomaly to 185.
    declare parameter deltaTrueAnomaly to 160.

    local epochTime to time:seconds.
    local sourceVectors to GetTargetVectors(sourceBody, "BODY", sun).
    local targetVectors to GetTargetVectors(targetBody, "BODY", sun).
    if(time:seconds = epochTime){
        print "Vectors good".
    }
    else{
        print epochTime - time:seconds.
    }

    local sourceMomentum to GetSpecificAngularMomentum(sourceVectors).

    local sourceMeanMotion to GetMeanAngularVelocity(sourceVectors, sun).
    local sinkMeanMotion to GetMeanAngularVelocity(targetVectors, sun).
    local meanMotionDifference to abs(sourceMeanMotion - sinkMeanMotion).

    local startOfSearch to sourceBody:rotationPeriod * 5.
    local maxTimeOfSearch to startOfSearch + (360/ meanMotionDifference).

    local searchTimeDelegate to searchLaunchTime@.
    set searchTimeDelegate to searchTimeDelegate:bind(startTrueAnomaly, deltaTrueAnomaly, sourceVectors, sourceMomentum, targetVectors).

    SimpleRegulaFalsiSearch(searchTimeDelegate, startOfSearch, maxTimeOfSearch, 0.02).
}

local function searchLaunchTime{
    declare parameter startTrueAnomaly. // bind first
    declare parameter deltaTrueAnomaly. // bind first
    declare parameter sourceVectors. // bind first
    declare parameter sourceMomentum. // bind first
    declare parameter targetVectors. // bind first
    declare parameter timeOfSearch.

    local sourceTrueAnomalyAtTime to GetTrueAnomalyAfterTime(timeOfSearch, sourceVectors, sun).
    local sourcePositionAtTime to GetPositionFromTrueAnomaly(sourceTrueAnomalyAtTime, sourceVectors, sun). // r1
    local sourceOrthongonalPosition to vcrs(sourcePositionAtTime, sourceMomentum).
    local searchForTargetPositionForDeltaTrueAnomalyDelegate to searchForTargetPositionForDeltaTrueAnomaly@.
    set searchForTargetPositionForDeltaTrueAnomalyDelegate to searchForTargetPositionForDeltaTrueAnomalyDelegate:
        bind(sourcePositionAtTime, sourceOrthongonalPosition, targetVectors, deltaTrueAnomaly).

    local targetTrueAnomaly to SimpleRegulaFalsiSearch(searchForTargetPositionForDeltaTrueAnomalyDelegate, 0, 360, 0.000000001).
    local targetPosition to GetPositionFromTrueAnomaly(targetTrueAnomaly, targetVectors, sun). // r2

    local r2 to targetPosition:mag.
    local r1 to sourcePositionAtTime:mag.

    print vang(targetPosition, sourcePositionAtTime).
    
    local v1Vec to 
        GetVelocityVectorFromTwoRadiiAndTrueAnomalies(r1, startTrueAnomaly, r2, UnsignedModular(startTrueAnomaly + deltaTrueAnomaly, 360)).

    local transferVectors to CreateShipVectors(sourcePositionAtTime, v1Vec).

    local trueAnomalyOfR2 to GetTrueAnomalyFromRadius(r2:vec, transferVectors, sun). //Should be same as startTrueAnomaly + deltaTrueAnomaly

    local timeTillR2 to GetTimeToTrueAnomaly(trueAnomalyOfR2, transferVectors, sun).
    





}

local function searchForTargetPositionForDeltaTrueAnomaly{
    declare parameter sourcePosition. // bind first
    declare parameter sourceOrthongonalPosition. // bind first
    declare parameter targetVectors. // bind first
    declare parameter deltaTrueAnomaly. // bind first
    declare parameter trueAnomalyToSearch.

    local targetPosition to GetPositionFromTrueAnomaly(trueAnomalyToSearch, targetVectors, sun).
    if(vang(targetPosition, sourceOrthongonalPosition) < 90){
        return (vang(targetPosition, sourcePosition) - deltaTrueAnomaly).
    }
    else{
        return 360 - (vang(targetPosition, sourcePosition) - deltaTrueAnomaly).
    }
}