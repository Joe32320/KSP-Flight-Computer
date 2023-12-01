function DeployFairings{
   WHEN ship:altitude > 40000 then {
        local parts to ship:modulesnamed("ModuleProceduralFairing").
        for part in parts{
            if(part:hasevent("Deploy")){
                part:doEvent("Deploy").
            }
        }
     }
}