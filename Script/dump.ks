declare parameter finalPeriapsis to 40000.

    local moonVars to Body("Moon").
    local earthVars to Body("Earth").

    wait 0.
    local moonVectors to GetTargetVectors(moonVars, "Body", earthVars).
    local shipVectors to GetShipVectors().

    local vm to moonVectors["Velocity"].
    local periapsisVector to GetPositionFromTrueAnomaly(0, shipVectors).
    local shipAngularMomentum to GetSpecificAngularMomentum(shipVectors).
    local trueAnomalyOfVM to vang(periapsisVector,vm)-90.

    if(vang(vcrs(shipAngularMomentum,periapsisVector), vm) > 90) {
        set trueAnomalyOfVM to 360 - trueAnomalyOfVM.
    }
    print trueAnomalyOfVM.


    local rpVec to GetPositionFromTrueAnomaly(trueAnomalyOfVM, shipVectors).
    local rp to rpVec:mag.
    local rs to moonVars:soiRadius.

    drawVector(body:position, -vm:normalized*moonVars:soiradius, "VM", grey).
    drawVector(body:position, rpVec:normalized*moonVars:radius*2, "RP", red).

    local vInf to GetEscapeSOISpeedAtTrueAnomaly(trueAnomalyOfVM, shipVectors).
    local vInfMax to vInf*200.

    function searchFunction{
        declare parameter searchvp.
        local searchvpVec to -vCrs(rpVec,shipAngularMomentum):normalized * (searchvp).

        local searchShipVectors to CreateShipVectors(rpVec, searchvpVec).
        local searchrsTrueAnomaly to  GetTrueAnomalyFromRadius(rs, searchShipVectors).
        local searchvs to GetVelocityFromTrueAnomaly(searchrsTrueAnomaly, searchShipVectors).
        return vang(-vm, searchvs).
        
         }

    local vp to  ModifiedGoldenSectionSearch(searchFunction@, vInf,vInfMax,0.000001).
    local vpVec to -vCrs(rpVec,shipAngularMomentum):normalized * (vp).
    local newShipVectors to CreateShipVectors(rpVec, vpVec).
    print "Actual E: " + GetEccentricityVector(newShipVectors):mag.
    print "Predicted E: " + (rp*vp^2/body:mu - 1).
    
    local rsTrueAnomaly to  GetTrueAnomalyFromRadius(rs, newShipVectors).
    local rsVec to GetPositionFromTrueAnomaly(rsTrueAnomaly, newShipVectors).
    local rsx to vdot(rsVec, -rpVec:normalized).
    print rsx.
    local xAxis to -rpVec:normalized.
    local yAxis to vcrs(shipAngularMomentum, rpVec):normalized.
    local vs to GetVelocityFromTrueAnomaly(rsTrueAnomaly, newShipVectors).

    print vs:mag.
    print sqrt(2*body:mu*rp - 2*body:mu*rs + rp*rs*vp^2)/sqrt(rp*rs).
    local e to (rp*vp^2/body:mu - 1).
    local p to (rp^2*vp^2/body:mu).
    local cO to (rp/rs*(1 + e) - 1)/e.
    local sO to sqrt(1 - cO^2).

    local sinEta to sin(vang(rpVec, -vm)).
    local cosEta to cos(vang(rpVec, -vm)).

    print "eta: " + vang(rpVec, -vm).

    print "SMA: " + GetSemiMajorAxis(newShipVectors).
    print "SMA: " + p/(1-e^2).
    print "SMA: " + ((rp^2*vp^2/body:mu)/(1-(rp*vp^2/body:mu - 1)^2)).
    print "SMA: " + body:mu * rp /(2*body:mu - rp* vp* vp).
    local a to body:mu * rp /(2*body:mu - rp* vp* vp).

    print rp*vp/(rs*(sinEta * cO - cosEta*sO)).

    print "tan: " + tan(180 - vang(rpVec, -vm)).
    print "Tan: " + (vdot(vs, yaxis)/ vdot(vs,xaxis)).
    print "tanTheta: " + tan(180 - rsTrueAnomaly).
    print "TanTheta: " + (vdot(rsVec, yaxis)/ vdot(rsVec,xaxis)).
    print "SAM: " + (rp*vp).
    print "SAM: " + (vdot(rsVec,xaxis)*vdot(vs,yaxis) - vdot(rsVec,yaxis)*vdot(vs,xaxis)).
    print "SAM: " + (rs*sin(180-rsTrueAnomaly) * vs:mag*cos(180-vang(rpVec, -vm)) - rs*cos(180-rsTrueAnomaly) * vs:mag*sin(180-vang(rpVec, -vm))).

    print (vang(rpVec, -vm) - rsTrueAnomaly).
    print 90- GetFlightPathAngleFromTrueAnomaly(rsTrueAnomaly,newShipVectors).

    print vs:mag.
    print sqrt(2*body:mu*(1/rs - 1/rp)+vp^2).

    //local b to -a*sqrt(e^2-1).
    //print "b: " + b.