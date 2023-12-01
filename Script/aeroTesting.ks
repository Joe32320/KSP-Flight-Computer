print "hi".

wait 0.
clearScreen.

until 0 > 1 {
    set shipMass to ship:mass * 1000.
    set thrustForce to ship:availablethrust  * 1000 * ship:facing:vector.

    set pressure to ship:body:atm:altitudepressure(ship:altitude).

    set gravityAcc to constant:G * body:mass / (ship:body:position:mag * ship:body:position:mag) * ship:body:position:normalized.
    set expectedAccerlation to (thrustForce * (1 / shipMass)) + gravityAcc.

    set observedAccerlation to  ship:sensors:acc.


    set dragForce to (expectedAccerlation-observedAccerlation):mag * shipMass.
    set predictedCoefficent to dragForce /(pressure * ship:velocity:surface:mag * ship:velocity:surface:mag).

    print "observedAccerlation: " + observedAccerlation:mag at(0,0).
    print "expectedAccerlation: " + expectedAccerlation:mag at(0,1).
    print "dragForce: " + (dragForce) at(0,2).
    print "pressure: " + (pressure) at(0,3).
    print "ship:velocity:surface:mag: " + (ship:velocity:surface:mag) at(0,4).
    print "gravityAcc: " + gravityAcc:mag at(0,5).
    print "shipMass: " + shipMass at(0,6).
    

    print "predictedCoefficent: " + (predictedCoefficent) at(0,10).
    
    

    clearScreen.
    wait 0.
}