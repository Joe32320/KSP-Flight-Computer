function LaunchProgram{
    declare parameter desiredInc to 0.
    declare parameter desiredLAN to 0.
    declare parameter launchTowardsEquator to 0.
    declare parameter pitchOverSpeed to 1100.
    declare parameter targetAltitude to 100.
    declare parameter pitchOverModifer to 1.5.

    set config:ipu to 2000.

    if(desiredInc < abs(ship:latitude)){
        set desiredInc to abs(ship:latitude) + 0.1.
    }

    local timeOfLaunch to time:seconds + GetTimeTillLaunch(desiredInc, desiredLAN, launchTowardsEquator).

    until time:seconds > timeOfLaunch {}.

    Launch(desiredInc, desiredLAN, pitchOverSpeed, targetAltitude, pitchOverModifer).
}

function Launch{
    declare parameter desiredInc to 0.
    declare parameter desiredLAN to 0.
    declare parameter pitchOverSpeed to 1300.
    declare parameter targetAltitude to 100.
    declare parameter pitchOverModifer to 1.5.    

    set targetAltitude to targetAltitude * 1000.
    local throttleControl to 1.
	lock throttle to throttleControl.

    local pitchControl to 90.
    local headingToFollow to 0.
    lock steering to heading(headingToFollow,pitchControl).
    stage.
    clearScreen.
    wait 1.

    print "Flying program: " + pitchOverSpeed + ":" + pitchOverModifer at(0,15).

    until ship:apoapsis > targetAltitude {
        local shipVectors to GetShipVectors(false).

        local targetAngularMomuntumVector to 
        (angleaxis(-desiredInc, (angleaxis(-desiredLAN, v(0,1,0))*solarPrimeVector))*v(0,1,0)).

        local positionOnTargetPlane to vxcl(targetAngularMomuntumVector, shipVectors["Position"]).
        local distanceToTargetPlane to vdot(-(positionOnTargetPlane - shipVectors["Position"]), targetAngularMomuntumVector:normalized).
        local velocityToTargetPlane to vDot(shipVectors["Velocity"], targetAngularMomuntumVector:normalized).

        local targetAccerlationToTargetPlane to choose (velocityToTargetPlane ^ 2)/(2*distanceToTargetPlane) 
        if velocityToTargetPlane/abs(velocityToTargetPlane) * distanceToTargetPlane/abs(distanceToTargetPlane) < 0 
        else -(velocityToTargetPlane ^ 2)/(2*distanceToTargetPlane).
        local shipAccerlationVector to throttleControl * ship:availableThrust / mass * ship:facing:vector:normalized.

        if abs(distanceToTargetPlane) < 100 {
            set targetAccerlationToTargetPlane to (-velocityToTargetPlane/2.5-distanceToTargetPlane/25).
        }

        local targetAccerlationToPlaneVector to targetAccerlationToTargetPlane * targetAngularMomuntumVector:normalized.
        
        local targetAccerlationVectorToFollow to sqrt(max(shipAccerlationVector:sqrmagnitude - 
            vdot(up:vector, shipAccerlationVector)^2
             - targetAccerlationToTargetPlane^2 ,0))
        * -vcrs(targetAngularMomuntumVector, positionOnTargetPlane):normalized
         + targetAccerlationToPlaneVector.

        

        //print targetAccerlationVectorToFollow at (0,25).

        set pitchControl to max(0, ((pitchOverSpeed^pitchOverModifer) - (ship:velocity:surface:mag^pitchOverModifer))/(pitchOverSpeed^pitchOverModifer))*90.
        set headingToFollow to HeadingFromVector(targetAccerlationVectorToFollow).

        print "distanceToTargetPlane: " + distanceToTargetPlane at (0,2).
        print "velocityToTargetPlane: " + velocityToTargetPlane at (0,3).
        print "targetAccerlationToTargetPlane: " + targetAccerlationToTargetPlane at (0,4).
        Staging().
    }.

    set throttleTarget to 0.
    lock throttle to throttleTarget.
    lock steering to ship:velocity:orbit.

    until ship:altitude > 87500 {
        if(ship:apoapsis < targetAltitude){
            set throttleTarget to 0.1.
        }
        else{
            set throttleTarget to 0.
        }
    }

    set throttleTarget to 0.
    wait 0.5.

    unlock throttle.

    wait 1.

    circulariseOrbitAtTrueAnomaly(180).

    wait 1.

    RunNodeBurn().
}

function GetTimeTillLaunch{
    declare parameter desiredInc to 90.0.
    declare parameter desiredLAN to 00.
    declare parameter launchTowardsEquator to 0.
    declare parameter leadTime to 100.
     // -1 is away, 0 is launch at nearest time 1 is launch towards equator
    local earthRotationPeriod to ship:body:rotationperiod.
    local shipVectors to GetShipVectors().
    //drawVector(ship:body:position, moonAscendingNodeVector, "moonAscendingNodeVector",yellow).
    local desiredLongitiudeAsecendingNode to (angleaxis(-desiredLAN, v(0,1,0))*solarPrimeVector).
    //drawVector(ship:body:position, desiredLongitiudeAsecendingNode, "desiredLongitiudeAsecendingNode", blue).
    local targetAngularMomuntumVector to (angleaxis(-desiredInc, desiredLongitiudeAsecendingNode)*v(0,1,0)).
    //drawVector(ship:body:position, targetAngularMomuntumVector*10000000, "targetAngularMomuntumVector", red).
    local launchSitePosition to shipVectors["Position"].
    //drawVector(ship:body:position, launchSitePosition*1.1, "launchSitePosition", green).
    local launchSiteRotationCentre to vdot(v(0,1,0), launchSitePosition) * v(0,1,0).
    //drawVector(ship:body:position, launchSiteRotationCentre, "launchSiteRotationCentre", green).
    local launchSiteOrthogonalVector to vCrs(-v(0,1,0), launchSitePosition).
    //drawVector(ship:body:position + launchSiteRotationCentre, launchSiteOrthogonalVector*1.1, "launchSiteOrthogonalVector", green).
    local launchSiteRadialVector to (launchSitePosition - launchSiteRotationCentre).
    //drawVector(ship:body:position + launchSiteRotationCentre, launchSiteRadialVector*1.1, "launchSiteRadialVector", green).
    local radius to launchSitePosition:mag.
    local a to targetAngularMomuntumVector:x.
    local b to targetAngularMomuntumVector:y.
    local c to targetAngularMomuntumVector:z.
    local y to vdot(v(0,1,0),launchSiteRotationCentre).
    local x1 to (-sqrt(4*a^2*b^2*y^2-4*(a^2+c^2)*(b^2*y^2-c^2*radius^2+c^2*y^2))-2*a*b*y)/(2*(a^2+c^2)).
    local x2 to (sqrt(4*a^2*b^2*y^2-4*(a^2+c^2)*(b^2*y^2-c^2*radius^2+c^2*y^2))-2*a*b*y)/(2*(a^2+c^2)).
    local z1 to (-(a*x1)-(b*y))/(c).
    local z2 to (-(a*x2)-(b*y))/(c).
    local launchPointOne to v(x1,y,z1).
    local launchPointTwo to v(x2, y, z2).
    //drawVector(ship:body:position, launchPointOne*1.1, "launchPointOne", blue).
    //drawVector(ship:body:position, launchPointTwo*1.1, "launchPointTwo", red).
    print launchSitePosition:mag.
    print launchPointOne:mag.
    print launchPointTwo:mag.
    //print vang(launchPointOne, targetAngularMomuntumVector).
    local finalLaunchPointAngle to 0.
    local launchPointOneRadial to launchPointOne - launchSiteRotationCentre.
    local launchPointOneAngle to vang(launchPointOneRadial, launchSiteRadialVector).
    if(vang(launchPointOneRadial, launchSiteOrthogonalVector) > 90){
        set launchPointOneAngle to 360 - launchPointOneAngle.
    }
    local launchPointTwoRadial to launchPointTwo - launchSiteRotationCentre.
    local launchPointTwoAngle to vang(launchPointTwoRadial, launchSiteRadialVector).
    if(vang(launchPointTwoRadial, launchSiteOrthogonalVector) > 90){
        set launchPointTwoAngle to 360 - launchPointTwoAngle.
    }
    if(launchTowardsEquator = 1){
        set finalLaunchPointAngle to launchPointOneAngle.
    }
    else if(launchTowardsEquator = -1){
        set finalLaunchPointAngle to launchPointTwoAngle.
    }
    else{
        if(launchPointOneAngle < launchPointTwoAngle){
            set finalLaunchPointAngle to launchPointOneAngle.
            print "launchPointOneAngle: " + launchPointOneAngle.
        }
        else{
            set finalLaunchPointAngle to launchPointTwoAngle.
            print "launchPointTwoAngle: " + launchPointTwoAngle.
        }
    }
    local timeTillLaunch to finalLaunchPointAngle * earthRotationPeriod / 360.
    //print "timeTillLaunch: " + timeTillLaunch.
    addAlarm("Raw",timeTillLaunch + time:seconds - leadTime, "LaunchWindow","").
    return timeTillLaunch - leadTime.
}