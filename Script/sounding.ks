function SoundingLaunch
{
    declare parameter inclination.
    //declare parameter pitchRate to 0.1. //deg per second
    declare parameter pitchOverSpeed to 1300.
    declare parameter pitchOverModifer to 1.5.

    local throttleControl to 1.
	lock throttle to throttleControl.

    local pitchControl to 90.
    local headingToFollow to 0.

    stage.
    clearScreen.

    lock steering to heading(headingToFollow,pitchControl).
    addAlarm("Raw",time:seconds + Body("Moon"):orbit:period , "Next Possible Launch","").
    local startTime to time:seconds.
    until 1 < 0 
    {
        local currentTime to time:seconds.
        local timeDiff to currentTime - startTime.
        set headingToFollow to 90 - inclination.
        //set pitchControl to max(90 - (timeDiff * pitchRate), 0).
        set pitchControl to max(0, ((pitchOverSpeed^pitchOverModifer) - (ship:velocity:surface:mag^pitchOverModifer))/(pitchOverSpeed^pitchOverModifer))*90.
        Staging().
        if(stage:number = 0 AND GetActiveEngineCount() = 0){return.}
    }

}