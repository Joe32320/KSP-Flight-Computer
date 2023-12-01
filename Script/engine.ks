//Returns true if staging happens
function Staging{

	List Engines in engList.
	local shouldStage to 0.
	local engineCount to 0.

	for eng in engList{
		if eng:ignition {
			set engineCount to engineCount + 1.
		}.

		if eng:flameout {
			set shouldStage to 1.
		}.
	}.

	if stage:number = 0 {
		set shouldStage to 0.
		return false.
	}.

	if shouldStage = 1 or engineCount = 0 {

		
		stage.
		return true.
	}.

	return false.
}.

function GetActiveEngineCount{
	List Engines in engList.
	local engineCount to 0.

	for eng in engList{
		if eng:ignition {
			set engineCount to engineCount + 1.
		}.

		if eng:flameout {
			set engineCount to engineCount - 1.
		}.
	}.

	return engineCount.
}

function GetCurrentAvailableThrust{
	List Engines in engList.
	local activeEngines to List().

	for eng in engList{
		if eng:ignition {
			activeEngines:add(eng).
		}.
	}.

	local totalEngineThrust to 0.
	for eng in activeEngines{
		local engThrust to eng:availablethrustat(0) * 1000.
		set totalEngineThrust to engThrust.
	}

	return totalEngineThrust.
}

function GetCurrentActiveEnginesCollectiveISP{
	List Engines in engList.
	local activeEngines to List().

	for eng in engList{
		if eng:ignition {
			activeEngines:add(eng).
		}.
	}.

	local totalEngineMassFlowRate to 0.

	for eng in activeEngines{
		local engISP to eng:visp.
		local engThrust to eng:availablethrustat(0) * 1000.

		local engMassFlowRate to engThrust / (constant:g0 * engISP).
		set totalEngineMassFlowRate to totalEngineMassFlowRate + engMassFlowRate.
	}

	local effectiveISP to 0.

	for eng in activeEngines{
		local engISP to eng:visp.
		local engThrust to eng:availablethrustat(0) * 1000.

		local engMassFlowRate to engThrust / (constant:g0 * engISP).
		local engMassFlowPercentage to engMassFlowRate / totalEngineMassFlowRate.

		set effectiveISP to effectiveISP + ((engISP * engMassFlowPercentage) / activeEngines:length).
	}

	return effectiveISP.
}