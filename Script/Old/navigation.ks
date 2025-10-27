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
	local targetVectors to lexicon().
	set targetVectors["Position"] to targetObject:position - ship:body:position.
	set targetVectors["Velocity"] to targetObject:velocity:orbit.
	set targetVectors["Info"] to targetObject.
	set targetVectors["Type"] to type.

	//print "GetTargetVectors".
	return targetVectors.
}


function HeadingFromVector{
    declare parameter vector.
	
	local angToNorth to vang(north:vector, vxcl(up:vector, vector)).
	local eastVector to vcrs(up:vector, north:vector).
	local angToEast to vang(eastVector, vxcl(up:vector, vector)).
	local vectorHeading to Choose angToNorth If angToEast < 90 Else 360 - angToNorth.

	return vectorHeading.
}

function GetSpecificAngularMomentum{
	declare parameter shipVectors . //to GetShipVectors().
	return vCrs(shipVectors["Position"], shipVectors["Velocity"]).
}

function GetEccentricityVector{
	declare parameter shipVectors . //to GetShipVectors().

	local positionVector to shipVectors["Position"].
	local velocityVector to shipVectors["Velocity"].

	// if(shipVectors["Type"] = "BODY"){
	// 	print shipVectors["Info"]:name.
	// 	return ((velocityVector:SQRMAGNITUDE/(ship:body:mu + shipVectors["Info"]:mu)) - (1/positionVector:mag))* positionVector - 
	// (vDot(positionVector, velocityVector)/(ship:body:mu + shipVectors["Info"]:mu))*velocityVector.
	// }

	return ((velocityVector:SQRMAGNITUDE/ship:body:mu) - (1/positionVector:mag))* positionVector - 
	(vDot(positionVector, velocityVector)/body:mu)*velocityVector.
	// local currentValue to (vCrs(shipVectors["Velocity"], GetSpecificAngularMomentum(shipVectors)) / ship:body:mu) - (shipVectors["Position"]:normalized).

	// print "Difference Ecc Vector: " + vang(currentValue, test).
}

function GetInclinationOfOrbit{
	declare parameter shipVectors . //to GetShipVectors().

	local specificAngularMomentum to GetSpecificAngularMomentum(shipVectors).
	return arcCos(-specificAngularMomentum:y/specificAngularMomentum:mag).
}

function GetCurrentTrueAnomaly{
	declare parameter shipVectors . //to GetShipVectors().

	local eccentricityVector to GetEccentricityVector(shipVectors).
	local shipPosition to shipVectors["Position"].
	local shipVelocity to shipVectors["Velocity"].
	local trueAnomaly to arcCos(max(min(vDot(eccentricityVector, shipPosition)/(eccentricityVector:mag * shipPosition:mag),1),-1)).

	if(vdot(shipPosition, shipVelocity) < 0){
		set trueAnomaly to 360-trueAnomaly.
	}

	return trueAnomaly.
}

function GetSemiMajorAxis{
	declare parameter shipVectors . //to GetShipVectors().

	local specificAngularMomentum to GetSpecificAngularMomentum(shipVectors):mag.
	local eccentricity to GetEccentricityVector(shipVectors):mag.

	return -(specificAngularMomentum ^ 2) / (((eccentricity^2)-1)*ship:body:mu).
}

function GetRadiusFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	local semiMajorAxis to GetSemiMajorAxis(shipVectors).
	local eccentricity to GetEccentricityVector(shipVectors):mag.

	return semiMajorAxis * (1 - (eccentricity ^ 2)) / (1 + (eccentricity * cos(trueAnomaly))).
}

function GetHeightFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	return GetRadiusFromTrueAnomaly(trueAnomaly, shipVectors) - ship:body:radius.
}

//This will return in the range 0-180 degrees, to get second half of orbit value, subtract the answer from 360
function GetTrueAnomalyFromRadius{
	declare parameter radius. //metres
	declare parameter shipVectors . //to GetShipVectors().

	set radius to radius + ship:body:radius.
	local semiMajorAxis to GetSemiMajorAxis(shipVectors).
	local eccentricity to GetEccentricityVector(shipVectors):mag.

	return arcCos( (-(semiMajorAxis * (eccentricity ^ 2)) + semiMajorAxis - radius)/(eccentricity * radius)).
}

function GetPositionFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	local vectorToPeriapsis to GetEccentricityVector(shipVectors).
	local specificAngularMomentum to GetSpecificAngularMomentum(shipVectors).

	//local currentValue to (angleAxis(trueAnomaly, specificAngularMomentum) * vectorToPeriapsis):normalized * GetRadiusFromTrueAnomaly(trueAnomaly, shipVectors).
	local newValue to RotationFormula(trueAnomaly, vectorToPeriapsis, specificAngularMomentum) * GetRadiusFromTrueAnomaly(trueAnomaly,shipVectors).

	return newValue.
}

function GetSpeedFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	local radius to GetRadiusFromTrueAnomaly(trueAnomaly, shipVectors).
	local semiMajorAxis to GetSemiMajorAxis(shipVectors).

	return sqrt(ship:body:mu * ((2/radius)-(1/semiMajorAxis))).
}

function GetFlightPathAngleFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors . //to GetShipVectors().	

	local eccentricity to GetEccentricityVector(shipVectors):mag.
	
	return arcTan((eccentricity * sin(trueAnomaly))/(1 + (eccentricity * cos(trueAnomaly)))).
}

function GetVelocityFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	local flightPathAngle to GetFlightPathAngleFromTrueAnomaly(trueAnomaly, shipVectors).
	local positionVector to GetPositionFromTrueAnomaly(trueAnomaly, shipVectors).
	local specificAngularMomentumVector to GetSpecificAngularMomentum(shipVectors).
	local velocityScalar to GetSpeedFromTrueAnomaly(trueAnomaly, shipVectors).
	local localHorizonVector to vCrs(specificAngularMomentumVector, positionVector):normalized.

	return RotationFormula(-flightPathAngle,localHorizonVector, specificAngularMomentumVector) * velocityScalar.
	//return (angleAxis(-flightPathAngle, specificAngularMomentumVector) * localHorizonVector) * velocityScalar.
}

function GetEccentricAnomalyFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	local eccentricity to GetEccentricityVector(shipVectors):mag.
	local a to sqrt((-eccentricity - 1) / (eccentricity - 1)).
	local b to tan(trueAnomaly / 2).

	if(trueAnomaly > 180){
		return 360 + 2 * arcTan((a*b - a*b*eccentricity)/(eccentricity + 1)).
	}
	return 2 * arcTan((a*b - a*b*eccentricity)/(eccentricity + 1)).
}

function GetEccentricAnomalyFromTrueAnomalyCos{
	declare parameter trueAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	local eccentricity to GetEccentricityVector(shipVectors):mag.

	if(trueAnomaly > 180){
		return 360 - arcCos(((eccentricity + cos(trueAnomaly)) / (1 + (eccentricity * cos(trueAnomaly))))).
	}
	return arcCos(((eccentricity + cos(trueAnomaly)) / (1 + (eccentricity * cos(trueAnomaly))))).
}

function GetMeanAnomalyFromEccentricAnomaly{
	declare parameter eccentricAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	local eccentricity to GetEccentricityVector(shipVectors):mag.
	return ((eccentricAnomaly * constant:DegToRad) - (eccentricity * sin(eccentricAnomaly)))*constant:RadToDeg.

}

function GetMeanAnomalyFromTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	local eccentricAnomaly to GetEccentricAnomalyFromTrueAnomalyCos(trueAnomaly, shipVectors).
	return GetMeanAnomalyFromEccentricAnomaly(eccentricAnomaly, shipVectors).

}

function GetTimeToTrueAnomaly{
	declare parameter trueAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	local currentTrueAnomaly to GetCurrentTrueAnomaly(shipVectors).
	local currentMeanAnomaly to GetMeanAnomalyFromTrueAnomaly(currentTrueAnomaly, shipVectors).
	local meanAnomalyAtPoint to GetMeanAnomalyFromTrueAnomaly(trueAnomaly, shipVectors).
	local meanAnomalyDifference to meanAnomalyAtPoint - currentMeanAnomaly. 

	if(meanAnomalyDifference < 0){
		set meanAnomalyDifference to 360 + meanAnomalyDifference.
	}

	return meanAnomalyDifference * GetInverseMeanAngularVelocity(shipVectors).
}

function GetTrueAnomalyAfterTime{
	declare parameter timeVar.
	declare parameter shipVectors . //to GetShipVectors().

	local currentTrueAnomaly to GetCurrentTrueAnomaly(shipVectors).
	local currentMeanAnomaly to GetMeanAnomalyFromTrueAnomaly(currentTrueAnomaly, shipVectors).

	local meanAnomalyDiffernce to  timeVar / GetInverseMeanAngularVelocity(shipVectors).

	local meanAnomalyAtTime to UnsignedModular(meanAnomalyDiffernce + currentMeanAnomaly, 360).

	// local orbitalPeriod to GetOrbitalPeriod(shipVectors).
	// set timeVar to timeVar - (floor(timeVar / orbitalPeriod))*orbitalPeriod.

	// function searchFunc {
	// 	declare parameter trueAnomaly.
	// 	return GetTimeToTrueAnomaly(UnsignedModular(trueAnomaly + GetCurrentTrueAnomaly(shipVectors),360), shipVectors) - timeVar.
	// }
	
	//print "Old: " + UnsignedModular(ModifiedBisectionSearch(searchFunc@, 0, 360, 0.000001) + GetCurrentTrueAnomaly(shipVectors),360).
	//print  "New: " + GetTrueAnomalyFromMeanAnomaly(meanAnomalyAtTime, shipVectors).
	return GetTrueAnomalyFromMeanAnomaly(meanAnomalyAtTime, shipVectors).

	
}

function GetEccentricAnomalyFromMeanAnomaly{
	declare parameter meanAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	function searchFunc {
		declare parameter eccentricAnomaly.
		return GetMeanAnomalyFromEccentricAnomaly(eccentricAnomaly, shipVectors) - meanAnomaly.
	}
	
	return ModifiedBisectionSearch(searchFunc@, 0, 360, 0.000001).
}

function GetTrueAnomalyFromEccentricAnomaly {
	declare parameter eccentricAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	

	local eccentricity to GetEccentricityVector(shipVectors):mag.
	//local beta to eccentricity / (1 + sqrt(1 - (eccentricity ^ 2))).
	local trueAnomaly to choose arcCos((cos(eccentricAnomaly) - eccentricity)/(1 - (eccentricity * cos(eccentricAnomaly))))
	if eccentricAnomaly <=180 else 360 - arcCos((cos(eccentricAnomaly) - eccentricity)/(1 - (eccentricity * cos(eccentricAnomaly)))).

	//  print "Old ecc: " + trueAnomaly.
	//  print "New ecc: " + (((eccentricAnomaly) +
	//  	(2 * arcTan(beta*sin(eccentricAnomaly)/(1-(beta*cos(eccentricAnomaly))))))).

	//local trueAnomaly to (eccentricAnomaly + 2 * arcTan(beta*sin(eccentricAnomaly)/(1-(beta*cos(eccentricAnomaly))))).
	//print eccentricAnomaly.

	// if(eccentricAnomaly > 180){
	// 	return 360 - trueAnomaly.
	// }

	
	return trueAnomaly.
}

function GetTrueAnomalyFromMeanAnomaly{
	declare parameter meanAnomaly.
	declare parameter shipVectors . //to GetShipVectors().

	local eccentricAnomaly to GetEccentricAnomalyFromMeanAnomaly(meanAnomaly, shipVectors).
	return GetTrueAnomalyFromEccentricAnomaly(eccentricAnomaly, shipVectors).
}

function GetOrbitalPeriod{
	declare parameter shipVectors . //to GetShipVectors().

	if(shipVectors["Type"] = "BODY"){
		return 2 * constant:pi * sqrt((GetSemiMajorAxis(shipVectors)^3) / (ship:body:mu + shipVectors["Info"]:mu)).
	}
	return 2 * constant:pi * sqrt((GetSemiMajorAxis(shipVectors)^3) / ship:body:mu).
}

function GetOrbitalPeriodFromSemiMajorAxis{
	declare parameter semiMajorAxis.
	return 2 * constant:pi * sqrt((semiMajorAxis^3) / ship:body:mu).
}

function GetSemiMajorAxisFromOrbitalPeriod{
	declare parameter targetOrbitalPeriod.
	return (body:mu * (targetOrbitalPeriod ^ 2) / (4 * (constant:pi ^ 2)))^(1/3).
}

function GetMeanAngularVelocity{
	declare parameter shipVectors . //to GetShipVectors().
	return 360 / GetOrbitalPeriod(shipVectors).
}

function GetInverseMeanAngularVelocity{
	declare parameter shipVectors . //to GetShipVectors().
	return GetOrbitalPeriod(shipVectors)/360.
}

function GetTrueAnomalyOfAscendingNode{
	declare parameter targetAngluarMomentum to -v(0,1,0). //Note the negative here is due to the left hand rule being applied for vector cross products
	declare parameter shipVectors to GetShipVectors().

	local shipSpecificAngularMomentum to GetSpecificAngularMomentum(shipVectors).
	local ascendingNodeVector to vCrs(-targetAngluarMomentum, shipSpecificAngularMomentum).
	local periapsisVector to GetPositionFromTrueAnomaly(0,shipVectors).
	local trueAnomaly to vang(ascendingNodeVector, periapsisVector).

	if(vDot(vCrs(shipSpecificAngularMomentum,periapsisVector),ascendingNodeVector) < 0){
		set trueAnomaly to 360-trueAnomaly.
	}

	return trueAnomaly.
}

function GetLongitudeOfAscendingNode{
	declare parameter shipVectors . //to GetShipVectors().

	local shipSpecificAngularMomentum to GetSpecificAngularMomentum(shipVectors).
	local ascendingNodeVector to vCrs(v(0,1,0), shipSpecificAngularMomentum):normalized.
	local solarPrimeOrthogonalVector to vCrs(v(0,1,0), solarPrimeVector):normalized.


	// drawVector(ship:body:position, ascendingNodeVector * body:radius *2, "ascendingNodeVector", blue).
	// drawVector(ship:body:position, solarPrimeOrthogonalVector * body:radius *2, "solarPrimeOrthogonalVector", red).
	// drawVector(ship:body:position, solarPrimeVector * body:radius *2 , "solarPrimeVector", green).
	if(vang(solarPrimeOrthogonalVector, ascendingNodeVector) > 90){
		return vang(ascendingNodeVector, solarPrimeVector).
	}
	else{
		return 360 - vang(ascendingNodeVector, solarPrimeVector).
	}
}

function GetArguementOfPeriapsis{
	declare parameter shipVectors . //to GetShipVectors().

	local positionOfAsecendingNode to GetPositionFromTrueAnomaly(GetTrueAnomalyOfAscendingNode(v(0,-1,0),shipVectors), shipVectors).
	local eccentricityVector to GetEccentricityVector(shipVectors).

	if(eccentricityVector:y < 0){
		return 360 - vang(eccentricityVector,positionOfAsecendingNode).
	}
	else{
		return vang(eccentricityVector,positionOfAsecendingNode).
	}
}

function GetMeanAnomalyAtEpoch{
	declare parameter shipVectors . //to GetShipVectors().

	local currentTrueAnomaly to GetCurrentTrueAnomaly(shipVectors).
	local currentMeanAnomaly to GetMeanAnomalyFromTrueAnomaly(currentTrueAnomaly, shipVectors).
	local timeSinceEpoch to Time:Seconds.

	local meanAnomalyTravelled to GetMeanAngularVelocity(shipVectors) * timeSinceEpoch.
	return UnsignedModular(currentMeanAnomaly - meanAnomalyTravelled, 360).
}

function GetLongitiudeOfAscendingNodeOfTerminator{
	declare parameter shipVectors . //to GetShipVectors().

	local sunPosition to body("Sun"):position - shipVectors["Position"].
	
	return vang(vCrs(sunPosition, v(0,1,0)), solarPrimeVector).
}