function GetShipVectors{
	local shipVectors to lexicon().
	set shipVectors["Position"] to -ship:body:position.
	set shipVectors["Velocity"] to ship:velocity:orbit.
	set shipVectors["Info"] to ship.
	set shipVectors["Type"] to "SHIP".

	//print "GetShipVectors".
	return shipVectors.
}

function CreateShipVectors{
	declare parameter positionVector.
	declare parameter velocityVector.
	declare parameter shipInfo to ship.
	declare parameter type to "SHIP".

	local newShipVectors to lexicon().
	set newShipVectors["Position"] to positionVector.
	set newShipVectors["Velocity"] to velocityVector.
	set newShipVectors["Info"] to shipInfo.
	set newShipVectors["Type"] to type.

	//print "CreateShipVectors".
	return newShipVectors.
}

function GetTargetVectors{
	declare parameter targetObject to target.
	declare parameter type to "BODY".
	declare parameter orbitBody to ship:body.

	local targetVectors to lexicon().
	set targetVectors["Position"] to targetObject:position - orbitBody:position.
	set targetVectors["Velocity"] to targetObject:velocity:orbit - targetObject:body:velocity:orbit.
	set targetVectors["Info"] to targetObject.
	set targetVectors["Type"] to type.

	//print "GetTargetVectors".
	return targetVectors.
}

// function GatherVectors{
// 	declare parameter listOfObjects.

// 	local objectOrbitalElements to lexicon().

// 	wait 0.
// 	local epochTime to time:seconds.
// 	for object in listOfObjects {
// 		local vectors to GetTargetVectors(object, ).
// 	}
// }


function HeadingFromVector{
    declare parameter vector.
	
	local angToNorth to vang(north:vector, vxcl(up:vector, vector)).
	local eastVector to vcrs(up:vector, north:vector).
	local angToEast to vang(eastVector, vxcl(up:vector, vector)).
	local vectorHeading to Choose angToNorth If angToEast < 90 Else 360 - angToNorth.

	return vectorHeading.
}

function GetSpecificAngularMomentum{
	declare parameter shipVectors to GetShipVectors().
	return vCrs(shipVectors["Position"], shipVectors["Velocity"]).
}

function GetEccentricityVector{
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to body.

	local positionVector to shipVectors["Position"].
	local velocityVector to shipVectors["Velocity"].

	// print vDot(positionVector, velocityVector).
	// print vang(positionVector, velocityVector).

	return ((velocityVector:SQRMAGNITUDE/orbitBody:mu) - (1/positionVector:mag))* positionVector - 
	(vDot(positionVector, velocityVector)/orbitBody:mu)*velocityVector.
}

function GetInclinationOfOrbit{
	declare parameter shipVectors to GetShipVectors().
	local specificAngularMomentum to GetSpecificAngularMomentum(shipVectors).
	return arcCos(-specificAngularMomentum:y/specificAngularMomentum:mag).
}

function GetCurrentTrueAnomaly{
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to body.

	local eccentricityVector to GetEccentricityVector(shipVectors, orbitBody).
	local shipPosition to shipVectors["Position"].
	local shipVelocity to shipVectors["Velocity"].
	local trueAnomaly to arcCos(max(min(vDot(eccentricityVector, shipPosition)/(eccentricityVector:mag * shipPosition:mag),1),-1)).

	if(vdot(shipPosition, shipVelocity) < 0){
		set trueAnomaly to 360-trueAnomaly.
	}

	return trueAnomaly.
}

function GetSemiMajorAxis{
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to body.

	local specificAngularMomentum to GetSpecificAngularMomentum(shipVectors):mag.
	local eccentricity to GetEccentricityVector(shipVectors, orbitBody):mag.

	return -(specificAngularMomentum ^ 2) / (((eccentricity^2)-1)*orbitBody:mu).
}

function GetRadiusFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to body.

	local semiMajorAxis to GetSemiMajorAxis(shipVectors, orbitBody).
	local eccentricity to GetEccentricityVector(shipVectors, orbitBody):mag.

	// print "trueAnomaly " + trueAnomaly.
	// print "semiMajorAxis " + semiMajorAxis.
	// print "eccentricity " + eccentricity.

	return semiMajorAxis * (1 - (eccentricity ^ 2)) / (1 + (eccentricity * cos(trueAnomaly))).
}

function GetHeightFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors to GetShipVectors().

	return GetRadiusFromTrueAnomaly(trueAnomaly, shipVectors) - ship:body:radius.
}

//This will return in the range 0-180 degrees, to get second half of orbit value, subtract the answer from 360
function GetTrueAnomalyFromRadius{
	declare parameter radius. //metres
	declare parameter shipVectors to GetShipVectors().
	
	local semiMajorAxis to GetSemiMajorAxis(shipVectors).
	local eccentricity to GetEccentricityVector(shipVectors):mag.

//print "GetTrueAnomalyFromRadius : " + (-(semiMajorAxis * (eccentricity ^ 2)) + semiMajorAxis - radius)/(eccentricity * radius).
	return arcCos(max(-1,min(1,(-(semiMajorAxis * (eccentricity ^ 2)) + semiMajorAxis - radius)/(eccentricity * radius)))).
}

//This will return in the range 0-180 degrees, to get second half of orbit value, subtract the answer from 360
function GetTrueAnomalyFromHeight{
	declare parameter radius. //metres
	declare parameter shipVectors to GetShipVectors().

	set radius to radius + ship:body:radius.
	local semiMajorAxis to GetSemiMajorAxis(shipVectors).
	local eccentricity to GetEccentricityVector(shipVectors):mag.

	return arcCos(max(-1,min(1,(-(semiMajorAxis * (eccentricity ^ 2)) + semiMajorAxis - radius)/(eccentricity * radius)))).
}

function GetPositionFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to body.

	local vectorToPeriapsis to GetEccentricityVector(shipVectors, orbitBody).
	local specificAngularMomentum to GetSpecificAngularMomentum(shipVectors).

	return RotationFormula(trueAnomaly, vectorToPeriapsis, specificAngularMomentum)
	 * GetRadiusFromTrueAnomaly(trueAnomaly,shipVectors, orbitBody).
}

function GetSpeedFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to body.

	local radius to GetRadiusFromTrueAnomaly(trueAnomaly, shipVectors, orbitBody).
	local semiMajorAxis to GetSemiMajorAxis(shipVectors, orbitBody).

	return sqrt(orbitBody:mu * ((2/radius)-(1/semiMajorAxis))).
}

function GetFlightPathAngleFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to body.

	local eccentricity to GetEccentricityVector(shipVectors, orbitBody):mag.
	
	return arcTan((eccentricity * sin(trueAnomaly))/(1 + (eccentricity * cos(trueAnomaly)))).
}

function GetVelocityFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to body.

	local flightPathAngle to GetFlightPathAngleFromTrueAnomaly(trueAnomaly, shipVectors, orbitBody).
	local positionVector to GetPositionFromTrueAnomaly(trueAnomaly, shipVectors, orbitBody).
	local specificAngularMomentumVector to GetSpecificAngularMomentum(shipVectors).
	local velocityScalar to GetSpeedFromTrueAnomaly(trueAnomaly, shipVectors, orbitBody).
	local localHorizonVector to vCrs(specificAngularMomentumVector, positionVector):normalized.

	return RotationFormula(-flightPathAngle,localHorizonVector, specificAngularMomentumVector) * velocityScalar.
}

function GetEccentricAnomalyFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local eccentricity to GetEccentricityVector(shipVectors, orbitBody):mag.
	local a to sqrt((-eccentricity - 1) / (eccentricity - 1)).
	local b to tan(trueAnomaly / 2).

	if(trueAnomaly > 180){
		return 360 + 2 * arcTan((a*b - a*b*eccentricity)/(eccentricity + 1)).
	}

	return 2 * arcTan((a*b - a*b*eccentricity)/(eccentricity + 1)).
}

function GetEccentricAnomalyFromTrueAnomalyCos{
	declare parameter trueAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local eccentricity to GetEccentricityVector(shipVectors, orbitBody):mag.

	if(trueAnomaly > 180){
		return 360 - arcCos(((eccentricity + cos(trueAnomaly)) / (1 + (eccentricity * cos(trueAnomaly))))).
	}

	return arcCos(((eccentricity + cos(trueAnomaly)) / (1 + (eccentricity * cos(trueAnomaly))))).
}

function GetHyperbolicEccentricAnomalyFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local eccentricity to GetEccentricityVector(shipVectors, orbitBody):mag.

	return arcTanH(sqrt((eccentricity - 1)/(eccentricity + 1))*tan(trueAnomaly/2)) * 2.
}

function GetMeanAnomalyFromEccentricAnomaly{
	declare parameter eccentricAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local eccentricity to GetEccentricityVector(shipVectors, orbitBody):mag.
	return ((eccentricAnomaly * constant:DegToRad) - (eccentricity * sin(eccentricAnomaly)))*constant:RadToDeg.
}

function GetHyperbolicMeanAnomalyFromEccentricAnomaly{
	declare parameter eccentricAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local eccentricity to GetEccentricityVector(shipVectors, orbitBody):mag.
	return (eccentricity * sinH(eccentricAnomaly)) - eccentricAnomaly.
}

function GetMeanAnomalyFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local eccentricity to GetEccentricityVector(shipVectors, orbitBody):mag.

	if(eccentricity > 1){
		local eccentricAnomaly to GetHyperbolicEccentricAnomalyFromTrueAnomaly(trueAnomaly, shipVectors, orbitBody).
		return GetHyperbolicMeanAnomalyFromEccentricAnomaly(eccentricAnomaly, shipVectors, orbitBody).
	}

	local eccentricAnomaly to GetEccentricAnomalyFromTrueAnomalyCos(trueAnomaly, shipVectors, orbitBody).
	return GetMeanAnomalyFromEccentricAnomaly(eccentricAnomaly, shipVectors, orbitBody).
}

function GetTimeToTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local eccentricity to GetEccentricityVector(shipVectors, orbitBody):mag.
	local currentTrueAnomaly to GetCurrentTrueAnomaly(shipVectors, orbitBody).
	local currentMeanAnomaly to GetMeanAnomalyFromTrueAnomaly(currentTrueAnomaly, shipVectors, orbitBody).
	local meanAnomalyAtPoint to GetMeanAnomalyFromTrueAnomaly(trueAnomaly, shipVectors, orbitBody).

	// print "currentMeanAnomaly: " + currentMeanAnomaly.
	// print "meanAnomalyAtPoint: " + meanAnomalyAtPoint.
	local meanAnomalyDifference to meanAnomalyAtPoint - currentMeanAnomaly. 

	if(eccentricity < 1){
		if(meanAnomalyDifference < 0){
			set meanAnomalyDifference to 360 + meanAnomalyDifference.
		}
		return meanAnomalyDifference * GetInverseMeanAngularVelocity(shipVectors, orbitBody).
	}

	local semiMajorAxis to GetSemiMajorAxis(shipVectors, orbitBody).
	local timeTillTrueAnomaly to -semiMajorAxis * sqrt(-semiMajorAxis / orbitBody:mu)*(meanAnomalyDifference).

	return timeTillTrueAnomaly.
}

function GetTrueAnomalyAfterTime{
	declare parameter timeVar.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to body.

	local currentTrueAnomaly to GetCurrentTrueAnomaly(shipVectors, orbitBody).
	local currentMeanAnomaly to GetMeanAnomalyFromTrueAnomaly(currentTrueAnomaly, shipVectors, orbitBody).
	local meanAnomalyDiffernce to  timeVar / GetInverseMeanAngularVelocity(shipVectors, orbitBody).
	local meanAnomalyAtTime to UnsignedModular(meanAnomalyDiffernce + currentMeanAnomaly, 360).

	return GetTrueAnomalyFromMeanAnomaly(meanAnomalyAtTime, shipVectors, orbitBody).
}

function GetEccentricAnomalyFromMeanAnomaly{
	declare parameter meanAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	function searchFunc {
		declare parameter eccentricAnomaly.
		return GetMeanAnomalyFromEccentricAnomaly(eccentricAnomaly, shipVectors, orbitBody) - meanAnomaly.
	}

	if(meanAnomaly > 180){
		//print SimpleBisectionSearch(searchFunc@, 180, 360, 0.000000001).
		return ModifiedBisectionSearch(searchFunc@, 180, 360, 0.000000001).
	}
	//print SimpleBisectionSearch(searchFunc@, 0, 180, 0.000000001).
	return ModifiedBisectionSearch(searchFunc@, 0, 180, 0.000000001).
}

function GetTrueAnomalyFromEccentricAnomaly {
	declare parameter eccentricAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local eccentricity to GetEccentricityVector(shipVectors, orbitBody):mag.
	//local beta to eccentricity / (1 + sqrt(1 - (eccentricity ^ 2))).
	local trueAnomaly to choose arcCos((cos(eccentricAnomaly) - eccentricity)/(1 - (eccentricity * cos(eccentricAnomaly))))
	if eccentricAnomaly <=180 else 360 - arcCos((cos(eccentricAnomaly) - eccentricity)/(1 - (eccentricity * cos(eccentricAnomaly)))).
	//  print "Old ecc: " + trueAnomaly.
	//  print "New ecc: " + (((eccentricAnomaly) +
	//  	(2 * arcTan(beta*sin(eccentricAnomaly)/(1-(beta*cos(eccentricAnomaly))))))).

	//local trueAnomaly to (eccentricAnomaly + 2 * arcTan(beta*sin(eccentricAnomaly)/(1-(beta*cos(eccentricAnomaly))))).
	return trueAnomaly.
}

function GetTrueAnomalyFromMeanAnomaly{
	declare parameter meanAnomaly.
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local eccentricAnomaly to GetEccentricAnomalyFromMeanAnomaly(meanAnomaly, shipVectors, orbitBody).
	return GetTrueAnomalyFromEccentricAnomaly(eccentricAnomaly, shipVectors, orbitBody).
}

function GetOrbitalPeriod{
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	if(shipVectors["Type"] = "BODY"){
		return 2 * constant:pi * sqrt((GetSemiMajorAxis(shipVectors,orbitBody)^3) / (shipVectors["Info"]:body:mu + shipVectors["Info"]:mu)).
	}
	return 2 * constant:pi * sqrt((GetSemiMajorAxis(shipVectors, orbitBody)^3) / shipVectors["Info"]:body:mu).
}

function GetOrbitalPeriodFromSemiMajorAxis{
	declare parameter semiMajorAxis.
	declare parameter orbitBody to Body.
	return 2 * constant:pi * sqrt((semiMajorAxis^3) / orbitBody:mu).
}

function GetSemiMajorAxisFromOrbitalPeriod{
	declare parameter targetOrbitalPeriod.
	declare parameter orbitBody to Body.
	return (orbitBody:mu * (targetOrbitalPeriod ^ 2) / (4 * (constant:pi ^ 2)))^(1/3).
}

function GetMeanAngularVelocity{
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.
	return 360 / GetOrbitalPeriod(shipVectors,orbitBody).
}

function GetInverseMeanAngularVelocity{
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.
	return GetOrbitalPeriod(shipVectors, orbitBody)/360.
}

function GetTrueAnomalyOfAscendingNode{
	declare parameter targetAngluarMomentum to -v(0,1,0). //Note the negative here is due to the left hand rule being applied for vector cross products
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local shipSpecificAngularMomentum to GetSpecificAngularMomentum(shipVectors).
	local ascendingNodeVector to vCrs(-targetAngluarMomentum, shipSpecificAngularMomentum).
	local periapsisVector to GetPositionFromTrueAnomaly(0,shipVectors, orbitBody).
	local trueAnomaly to vang(ascendingNodeVector, periapsisVector).

	if(vDot(vCrs(shipSpecificAngularMomentum,periapsisVector),ascendingNodeVector) < 0){
		set trueAnomaly to 360-trueAnomaly.
	}

	return trueAnomaly.
}

function GetLongitudeOfAscendingNode{
	declare parameter shipVectors to GetShipVectors().

	local shipSpecificAngularMomentum to GetSpecificAngularMomentum(shipVectors).
	local ascendingNodeVector to vCrs(v(0,1,0), shipSpecificAngularMomentum):normalized.
	local solarPrimeOrthogonalVector to vCrs(v(0,1,0), solarPrimeVector):normalized.

	if(vang(solarPrimeOrthogonalVector, ascendingNodeVector) > 90){
		return vang(ascendingNodeVector, solarPrimeVector).
	}
	else{
		return 360 - vang(ascendingNodeVector, solarPrimeVector).
	}
}

function GetArguementOfPeriapsis{
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local positionOfAsecendingNode to GetPositionFromTrueAnomaly(GetTrueAnomalyOfAscendingNode(v(0,-1,0),shipVectors), shipVectors, orbitBody).
	local eccentricityVector to GetEccentricityVector(shipVectors, orbitBody).

	if(eccentricityVector:y < 0){
		return 360 - vang(eccentricityVector,positionOfAsecendingNode).
	}
	else{
		return vang(eccentricityVector,positionOfAsecendingNode).
	}
}

function GetMeanAnomalyAtEpoch{
	declare parameter shipVectors to GetShipVectors().
	declare parameter orbitBody to Body.

	local currentTrueAnomaly to GetCurrentTrueAnomaly(shipVectors, orbitBody).
	local currentMeanAnomaly to GetMeanAnomalyFromTrueAnomaly(currentTrueAnomaly, shipVectors, orbitBody).
	local timeSinceEpoch to Time:Seconds.
	local meanAnomalyTravelled to GetMeanAngularVelocity(shipVectors, orbitBody) * timeSinceEpoch.

	return UnsignedModular(currentMeanAnomaly - meanAnomalyTravelled, 360).
}

function GetLongitiudeOfAscendingNodeOfTerminator{
	declare parameter shipVectors to GetShipVectors().
	local sunPosition to body("Sun"):position + shipVectors["Position"].
	local solarPrimeOrthogonalPosition to vCrs(solarPrimeVector, v(0,1,0)).
	if(vang(solarPrimeOrthogonalPosition, vCrs(sunPosition, v(0,1,0))) > 90){
		return 360 - vang(vCrs(sunPosition, v(0,1,0)), solarPrimeVector).
	}
	return vang(vCrs(sunPosition, v(0,1,0)), solarPrimeVector).
}

function GetLongitiudeOfAscendingNodeOfNoon{
	declare parameter shipVectors to GetShipVectors().
	local sunPosition to body("Sun"):position + shipVectors["Position"].
	local solarPrimeOrthogonalPosition to vCrs(solarPrimeVector, v(0,1,0)).
	if(vang(solarPrimeOrthogonalPosition, vxcl(v(0,1,0), sunPosition)) > 90){
		return 360 - vang(vxcl(v(0,1,0), sunPosition), solarPrimeVector).
	}
	return vang(vxcl(v(0,1,0),sunPosition), solarPrimeVector).
}

function GetEscapeSOISpeedAtTrueAnomaly{
    declare parameter trueAnomaly.
    declare parameter shipVectors to GetShipVectors().
    declare parameter orbitBody to ship:body.

    local radius to GetRadiusFromTrueAnomaly(trueAnomaly, shipVectors, orbitBody).
    local transferOrbitSemiMajorAxis to (radius + orbitBody:soiRadius) / 2.
    return sqrt(orbitBody:mu *((2/ radius)-(1/transferOrbitSemiMajorAxis))).
}

function GetTheoreticalEscapeSpeedAtTrueAnomaly{
    declare parameter trueAnomaly.
    declare parameter shipVectors to GetShipVectors().
    declare parameter orbitBody to ship:body.

    local radius to GetRadiusFromTrueAnomaly(trueAnomaly, shipVectors, orbitBody).
    return sqrt(orbitBody:mu *2 / radius).
}

function GetTrueAnomalyOfClosestApproachToTarget{
	declare parameter sourceVectors to GetShipVectors(). // This ship usually
	declare parameter sinkVectors to GetTargetVectors(target). //The target
	//declare parameter orbitsToSearchFrom to 0.
	//declare parameter orbitsOfSourceToSearch to 1.
	declare parameter orbitBody to body.

	local startTimeOfSearch to 0.
	local maxTimeOfSearch to GetOrbitalPeriod(sourceVectors,orbitBody).
	function searchFunction{
		declare parameter timeToSearch.

		local sourceTrueAnomalyAtTime to GetTrueAnomalyAfterTime(timeToSearch, sourceVectors).
		local sourcePositionAtTime to GetPositionFromTrueAnomaly(sourceTrueAnomalyAtTime, sourceVectors).

		local sinkTrueAnomalyAtTime to GetTrueAnomalyAfterTime(timeToSearch, sinkVectors).
		local sinkPositionAtTime to GetPositionFromTrueAnomaly(sinkTrueAnomalyAtTime, sinkVectors).

		return (sourcePositionAtTime - sinkPositionAtTime):mag.
	}
	local timeOfClosestApproach to SimpleGoldenSectionSearch(searchFunction@, startTimeOfSearch, maxTimeOfSearch, 0.01).
	return GetTrueAnomalyAfterTime(timeOfClosestApproach, sourceVectors).
}