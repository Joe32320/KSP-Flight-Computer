function DeployComms{
    WHEN ship:altitude > ship:body:atm:height then {
        Panels on.
        local parts to ship:modulesnamed("ModuleDeployableAntenna").
        for part in parts{
            if(part:hasevent("Extend Antenna")){
                part:doEvent("Extend Antenna").
            }
        }
     }
}