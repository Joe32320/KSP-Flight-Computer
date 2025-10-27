//NOTE Need to account for KSP weirdness rotating the XZ plane, using the y axis (axis of spin) and another vector, probably the Moon's ascending node as a set of basis vectors
//Believe that thrust (all force values?) are from previous frame
function AeroLaunchTest{
    set config:ipu to 2000.
    
    local throttleControl to 1.
	lock throttle to throttleControl.
    local pitchControl to 90.
    local headingToFollow to 0.
    lock steering to heading(headingToFollow,pitchControl).
    stage.
    
    log  "Time,Thrust,Orbit Speed,Speed X,Speed Y,Speed Z,Dist,Pos X,Pos Y,Pos Z,Fac X,Fac Y,Fac Z,Mass,Height,Gravity" to "log.csv".
    local mu to Body:mu.
    
    until ship:apoapsis > 200000 {
        local moonVectors to GetTargetVectors(Body("Moon")).
        local moonAng to GetSpecificAngularMomentum(moonVectors).
        local moonAN to vcrs(v(0,1,0), moonAng):normalized.

        local xDirection to moonAN:normalized.
        local yDirection to v(0,1,0).
        local zDirection to vcrs(xDirection, yDirection):normalized.

        local currentTime to time:seconds.
        local currentThrust to ship:thrust.
        local currentSpeedOrbit to ship:velocity:orbit:mag.
        //All in SOI raw coords
        local currentVelocityOrbitX to vDot(ship:velocity:orbit, xDirection).
        local currentVelocityOrbitY to vDot(ship:velocity:orbit, yDirection). //near 0.
        local currentVelocityOrbitZ to vDot(ship:velocity:orbit, zDirection).
        local currentPositionMag to ship:body:position:mag.
        local currentPositionX to vDot(-ship:body:position, xDirection).
        local currentPositionY to vDot(-ship:body:position, yDirection). //Postive
        local currentPositionZ to vDot(-ship:body:position, zDirection).
        local currentFacingX to vDot(ship:facing:vector, xDirection).
        local currentFacingY to vDot(ship:facing:vector, yDirection). //negative
        local currentFacingZ to vDot(ship:facing:vector, zDirection).

        local currentMass to ship:mass.
        local currentHeight to ship:altitude.
        local currentRadius to currentPositionMag.
        //local currentAtmoPressure to ship:body:atm:altitudepressure(currentHeight).
        local currentGravity to mu / (currentRadius * currentRadius).
        //local currentTemp to ship:body:atm:altitudetemperature(currentHeight).
        //local currentDensity to currentAtmoPressure * constant:atmtokpa * 1000 / (currentTemp * constant:IdealGas / ship:body:atm:molarmass).

        //local speedOfSound to sqrt(ship:body:atm:ADBIDX * currentTemp * constant:IdealGas / ship:body:atm:molarmass).

        log currentTime + "," + currentThrust + ","  + currentSpeedOrbit +
        "," + currentVelocityOrbitX + "," + currentVelocityOrbitY + "," + currentVelocityOrbitZ +
        "," + currentPositionMag + "," + currentPositionX + "," + currentPositionY + "," + currentPositionZ +
        "," + currentFacingX + "," + currentFacingY + "," + currentFacingZ +
        ","+ currentMass + "," + currentHeight + "," + currentGravity to "log.csv".
        //drawVector(ship:body:position, moonAN * 10000000).
        wait 0. //To account for the 0.02 delay from wait to next tick
    }
}

function LaunchProgradeCalc{

    local earthParms to body("Earth").
    local earthRadius to earthParms:Radius.

    local shipMass to ship:mass. //metric tons
    local shipThrust to 87. //kilo Newtons

    local delta to 0.02.
    local pitch to 89.9.

    local rX to 0. //Surface
    local rY to earthRadius. //Height
    local uX to 0. //Surface
    local uY to 0. //Height

    //Horizon vector
    local hX to 1.
    local hY to 0.

    local ip to 265.

    local finalApsis to 0.

    until finalApsis = 100000{
        set shipThrust to ship:maxthrustat(earthRadius + rY).
        local shipAcc to shipThrust - shipMass.
        local xFactor to arcCos(pitch).
        local yFactor to arcSin(pitch).
        local r to sqrt(rX^2 + rY^2).
        local g to earthParms:mu / r^2.

        local vX to shipAcc * xFactor.
        local vY to shipAcc * yFactor - g.
        local sX to rX + 0.5 * (uX + vX) * delta.
        local sY to rY + 0.5 * (uY + vY) * delta.

        //set hX to 

        set pitch to tan(vY/vX). //Check order
        
        set massRate to shipThrust/(g * ip).
        set shipMass to shipMass - (massRate * delta).
    }

}