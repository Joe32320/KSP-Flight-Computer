function Takeoff{
    declare parameter cruisingHeight to 1000.
    declare parameter veeTwoSpeed to 60.


    local throttleControl to 1.
    lock throttle to throttleControl.
    local runwayVector to vxcl(ship:position, ship:facing:vector).

    


    stage.

    until ship:altitude > 1000 {

    }
}