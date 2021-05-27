--[[
	This is the config for the taxi job. The job spawn chance is an exponential curve
	that should hit near 100% chance at 12 attempts. You can affect the amount of time
	it takes on average to find a job by either changing the time between attempts or
	adjusting the rate curve. 
	You can add job sites and spawns, as well as editing other properties, such as:
	job rate
	job curve
	job check frequency
	payout  per mile
	payout multiplier

	********NOTE ON EDITING SPAWN CHANCES********
	Remember, THIS IS EXPONENTIAL, so small tweaks will make drastic changes. If you want
	to change this, you can check wolfram alpha using the lim as x -> 12 with the current
	formula to see the current curve. Tweak the curve there to get what you want first.
	Make changes by 0.01 intervals
]]
config = {
	drawDistance = 10.0,
	payment = {
		min = 50,
		max = 150,
		tip = { min = 50, max = 100 }
	},
	job = {
		rate = 0.02,
		curve = 1.4,
		freq = { min = 25000, max = 40000 },
		dropSpeed = 5.0,
		dropDistance = 5.0,
		pickUpDistance = 7.0,
		idle = 10000,
		rentalPrice = 250,
		returnPrice = 150,
		searchDistance = 300.0,
		minDistance = 500.0,
		maxDistance = 2200.0
	},
	authorizedVehicles = {
		'taxi'
	},
	markers = {
		pickup = {
			size = { x = 0.5, y = 0.5, z = 0.5 },
			color = { r = 204, g = 204, b = 0 },
			type = 0, rotate = false, bounce = true
		},
		dropoff = {
			size = { x = 5.0, y = 5.0, z = 2.0 },
			color = { r = 204, g = 204, b = 0 },
			type = 1, rotate = false, bounce = false
		}
	},
	zones = {
		JobSite = {
			pos = { x = 896.329, y = -144.216, z = 76.819 },
			size = { x = 1.0, y = 1.0, z = 1.0 },
			color = { r = 204, g = 204, b = 0 },
			type = 36, rotate = true
		},
		VehicleSpawner = {
			pos = { x = 901.0, y = -144.451, z = 76.659 },
			size = { x = 1.5, y = 1.5, z = 1.0 },
			type = -1, rotate = false,
			heading = 324.33

		}
	},
	-- mine
	locations = {
		vector3(420.5,129.7,100.5),
		vector3(452.2,118.7,98.7),
		vector3(384.6,114.3,102.0),
		vector3(395.9,210.5,102.5),
		vector3(348.0,156.8,102.5),
		vector3(277.8,179.3,104.0),
		vector3(240.4,169.6,104.6),
		vector3(68.3,259.4,108.8),
		vector3(-43.7,66.9,72.0),
		vector3(7.7,-81.3,59.0),
		vector3(-12.5,-144.8,56.2),
		vector3(255.8,-244.3,53.5),
		vector3(207.4,-358.2,43.5),
		vector3(219.6,-609.1,41.2),
		vector3(44.4,-691.7,43.7),
		vector3(-51.3,-785.9,43.7),
		vector3(-105.8,-606.1,35.7),
		vector3(-71.9,-614.5,35.7),
		vector3(-181.7,-841.2,29.6),
		vector3(-216.9,-1011.0,28.8),
		vector3(-275.4,-1066.1,25.3),
		vector3(-291.8,-1318.8,30.7),
		vector3(-315.8,-1842.9,24.0),
		vector3(-208.0,-2000.3,27.2),
		vector3(223.2,-2051.7,17.7),
		vector3(284.5,-2023.9,18.8),
		vector3(395.2,-1892.0,24.8),
		vector3(488.3,-1759.4,28.0),
		vector3(947.3,-1841.4,30.7),
		vector3(854.3,-1582.2,30.5),
		vector3(809.4,-1288.5,25.8),
		vector3(793.3,-971.9,25.7),
		vector3(1037.7,-420.0,65.5),
		vector3(890.5,-573.8,56.8),
		vector3(1017.9,-528.3,60.1),
		vector3(1207.8,-714.9,59.0),
		vector3(1264.2,-604.5,68.5),
		vector3(-1016.6,-2728.2,13.8),
		vector3(-1023.7,-2734.9,20.1),
		vector3(643.7,602.1,128.9),
		vector3(233.6,1174.8,225.5),
		vector3(-409.2,1174.8,325.6),
		vector3(-2297.5,376.0,174.5),
		vector3(-3233.7,969.6,13.0),
		vector3(-1888.8,2045.5,140.9),
		vector3(-844.2,5415.6,34.6),
		vector3(-575.4,5256.7,70.5),
		vector3(-777.5,5582.2,33.1),
		vector3(-396.7,6051.9,31.1),
		vector3(-423.9,6030.8,30.9),
		vector3(-335.6,6147.0,31.1),
		vector3(-294.0,6249.5,30.9),
		vector3(-258.3,6285.4,30.9),
		vector3(-102.5,6406.6,31.1),
		vector3(-117.8,6455.6,31.0),
		vector3(-2.3,6522.0,30.9),
		vector3(-11.3,6639.3,30.6),
		vector3(155.8,6633.4,31.2),
		vector3(424.2,6532.5,27.3),
		vector3(1579.6,6440.4,24.4),
		vector3(1701.8,4943.8,41.8),
		vector3(1672.5,4874.9,41.6),
		vector3(1679.4,4822.2,41.5),
		vector3(1807.8,4588.4,36.4),
		vector3(2453.8,4950.5,44.7),
		vector3(2552.3,4679.4,33.5),
		vector3(2507.6,4110.8,37.9),
		vector3(2486.6,4099.9,37.6),
		vector3(2008.9,3770.2,31.8),
		vector3(1967.7,3735.1,31.9),
		vector3(1697.7,3745.0,33.6),
		vector3(1820.8,3887.5,33.3),
		vector3(922.3,3563.0,33.4),
		vector3(83.3,3633.9,39.3),
		vector3(48.6,3729.3,39.2),
		vector3(352.0,2638.5,44.1),
		vector3(545.1,2681.0,41.8),
		vector3(599.6,2737.5,41.6),
		vector3(1053.4,2670.9,39.1),
		vector3(1137.0,2663.2,37.6),
		vector3(1168.4,2690.0,37.5),
		vector3(1208.6,2671.8,37.3),
		vector3(1855.6,2586.7,45.3),
		vector3(-939.1,295.0,70.3),
		vector3(-1284.0,294.4,64.4),
		vector3(-1371.4,55.6,53.3),
		vector3(-1392.3,-155.3,47.0),
		vector3(-1437.6,-200.3,47.0),
		vector3(-1520.6,-449.6,35.0),
		vector3(-1667.5,-541.3,34.6),
		vector3(-1862.1,-352.9,48.8),
		vector3(-1390.1,-529.8,30.4),
		vector3(-1412.5,-592.4,30.0),
		vector3(-1204.4,-598.1,26.5),
		vector3(-1175.3,-860.2,13.6),
		vector3(-828.0,-1219.6,6.5),
		vector3(-1289.8,-1397.1,4.1),
		vector3(-1636.7,-982.8,12.6),
		vector3(-1076.6,-265.3,36.9),
		vector3(-766.4,-259.5,36.2),
		vector3(-488.4,-387.6,33.5),
		vector3(-459.2,-365.3,33.0),
		vector3(-271.1,-796.9,31.2)
	}
}
