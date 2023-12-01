function CalculateRocketVaccumDeltaV{

    for part in ship:parts{
        if(part:decoupler = "None"){
            print part:name + ": " + part:decoupler.
        }
        else{
            print part:name + ": " + part:decoupler:name.
        }
        
    }

}