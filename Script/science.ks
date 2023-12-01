function RunScience {
    declare parameter shouldTransmit.
    DeployAllScience(shouldTransmit).
}.

function RunLowEarthAtmoScience {
    declare parameter shouldTransmit.
    WHEN ship:altitude > 1000 then { 
        DeployAllScience(shouldTransmit).
     }
}.

function RunHighEarthAtmoScience{
    declare parameter shouldTransmit.
    WHEN ship:altitude > 32000 then { DeployAllScience(shouldTransmit). }
}

function RunLowEarthOrbitScience{
    declare parameter shouldTransmit.
    WHEN ship:altitude > 71000 then {DeployAllScience(shouldTransmit).}
}

function RunHighEarthOrbitScience{
    declare parameter shouldTransmit.
    WHEN ship:altitude > 1000000 then { DeployAllScience(shouldTransmit). }
}

function RunHighMoonOrbitScience{
    declare parameter shouldTransmit.
    WHEN ship:body:name = "Moon"then { DeployAllScience(shouldTransmit). }
}
function RunLowMoonOrbitScience{
    declare parameter shouldTransmit.
    WHEN ship:body:name = "Moon" AND ship:altitude < 100000 then { DeployAllScience(shouldTransmit). }
}

function RunHighSunrbitScience{
    declare parameter shouldTransmit.
    WHEN ship:body:name = "Sun" then { DeployAllScience(shouldTransmit). }
}

function DeployAllScience{
    declare parameter shouldTransmit.
    DeployScience("sensorAtmosphere", shouldTransmit).
    DeployScience("GooExperiment", shouldTransmit).
    DeployScience("Magnetometer", shouldTransmit).
    DeployScience("science.module", shouldTransmit).
    DeployScience("sensorAccelerometer", shouldTransmit).
    DeployScience("sensorBarometer", shouldTransmit).
    DeployScience("sensorGravimeter", shouldTransmit).
    DeployScience("sensorThermometer", shouldTransmit).
}


function DeployScience{
    declare parameter sensorName.
    declare parameter shouldTransmit.
    local parts TO ship:partsNamed(sensorName).
    if(parts:length > 0){
        for part in parts{
            local module TO part:getModule("ModuleScienceExperiment").
            if((NOT module:hasData) AND (NOT module:inoperable)){
                module:DEPLOY.
                if(shouldTransmit){
                    when module:hasData then {
                        module:transmit.
                    }.
                }
                return.
            }
	    }.
    }
}