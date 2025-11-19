/*
	A3XAI Custom Spawn Definitions File
	
	Instructions: 
	
		Generate custom spawns and blacklist areas using the included A3XAI Editor Tool (Inside the "Editor Tool" folder of the A3XAI download package).
		
		Instructions on how to use the Editor Tool are located on the A3XAI Wikia page: http://A3XAI.wikia.com/wiki/A3XAI_Editor_Tool
		
		In order for A3XAI to load this file on startup, you must set in @A3XAI/A3XAI_config/config.cpp under the "A3XAI Settings" section:
		
			loadCustomFile = 1;

		 (To follow the guides to the letter you will need A3XAI Editor, but you can easily add new locations by placing a marker in EDEN Editor with desired radius and logging it's position)
		 (The examples show enough information to help you set up Custom Areas. Guide will tell you what the numbers mean)
		
//----------------------------Add your custom spawn and dynamic area blacklist definitions below this line ----------------------------*/

/*	Adding Blacklist Areas

    1. Move or teleport to the location you want to place your blacklist area (Teleport by opening your Map and Left Clicking your destination)
    2. Use the scroll-wheel option menu to select "Editor Mode: Area Blacklists". A template statement will be copied to your clipboard.
    3. Open the Debug Console by pressing Esc. Paste (CTRL+V) the template statement under the Execute text area.
    4. The custom spawn statement should read like so:
        ['AreaName1',100] call A3XAI_generateArea;
		where:
        'AreaName1': The name to assign to the blacklisted area (must be unique).
        100: The radius of the blacklist area (maximum radius is 1499)
		
    5. After you have adjusted the blacklist parameters to your preferences, click the LOCAL EXEC button to generate your spawn. It will be added to your clipboard along with other custom spawns or blacklist areas you have created.
        Tip: If you've accidentally replaced the contents of your clipboard, you can manually re-add all generated spawns/blacklists to your clipboard by using the scroll-wheel menu option and select "Export Spawn Configs" 
    6. If your blacklist area has been successfully created, There should be a System message displayed:
        Total custom spawns generated and saved: [number of spawns generated] 
*/

//[location_name,[x,y,z],radius]
//["Sosovu",[3216.52,9309.85,0],1000] call A3XAI_createBlacklistAreaQueue;


/*	Adding Custom Infantry Spawns

    1. Move or teleport to the location you want to place your custom spawn. (Teleport by opening your Map and Left Clicking your destination)
    2. Use the scroll-wheel option menu to select "Editor Mode: Custom Infantry". A template custom spawn statement will be copied to your clipboard.
    3. Open the Debug Console by pressing Esc. Paste (CTRL+V) the template custom spawn statement under the Execute text area.
    4. The custom spawn statement should read like so:
        ['AreaName1',100,2,1,true,600] call A3XAI_generateArea;
		where:
        'AreaName1': The name to assign to the spawn area (must be unique).
        100: The radius of the patrol area.
        2: Number of AI units to spawn.
        1: Level of AI (0-3).
        true: Respawn setting. true: Enable respawn. false: Disable respawn.
        600: If respawn setting is enabled, this is the respawn timer in seconds. If respawn setting is disabled, either don't add a number or set it to 0. 
    5. After you have adjusted the spawn parameters to your preferences, click the LOCAL EXEC button to generate your spawn. It will be added to your clipboard along with other custom spawns you have created.
        Tip: If you've accidentally replaced the contents of your clipboard, you can manually re-add all generated spawns to your clipboard by using the scroll-wheel menu option and select "Export Spawn Configs" 
    6. If your spawn has been successfully created, There should be a System message displayed:
        Total custom spawns generated and saved: [number of spawns generated] 
*/

//[location_name,[x,y,z],radius,AIcount,AIlevel,respawn?,respawnTimerIfTrue]
//["Hotel Resort",[12448.4,14239.9,0.00156403],50,1,3,true,600] call A3XAI_createCustomInfantryQueue;

/*	Adding Custom Vehicle Patrols

    1. Move or teleport to the location you want to place your custom spawn. (Teleport by opening your Map and Left Clicking your destination)
    2. Use the scroll-wheel option menu to select "Editor Mode: Custom Vehicles". A template custom spawn statement will be copied to your clipboard.
    3. Open the Debug Console by pressing Esc. Paste (CTRL+V) the template custom spawn statement under the Execute text area.
    4. The custom spawn statement should read like so:
        ['AreaName1','VehicleType',100,[1,1],1,true,600] call A3XAI_generateArea;
        'AreaName1': The name to assign to the spawn area (must be unique).
        'VehicleType': The classname of the assigned AI vehicle. Acceptable vehicle types: land or air.
        100: The radius of the patrol area.
        [1,1]: Maximum number of cargo units, maximum number of gunner units. Limited by actual number of cargo/gunner seats available for use by the vehicle.
        1: Level of AI (0-3).
        true: Respawn setting. true: Enable respawn. false: Disable respawn.
        600: If respawn setting is enabled, this is the respawn timer in seconds. If respawn setting is disabled, either don't add a number or set it to 0. 
    5. After you have adjusted the spawn parameters to your preferences, click the LOCAL EXEC button to generate your spawn. It will be added to your clipboard along with other custom spawns you have created.
        Tip: If you've accidentally replaced the contents of your clipboard, you can manually re-add all generated spawns to your clipboard by using the scroll-wheel menu option and select "Export Spawn Configs" 
    6. If your spawn has been successfully created, There should be a System message displayed:
        Total custom spawns generated and saved: [number of spawns generated] 
*/

//[location_name,[x,y,z],vehicle_classname,radius,[passengerCount,gunnerCount],AIlevel,respawn?,respawnTimerIfTrue]
//["Tuvanaka Airbase",[2253.5,13393.1,0.00143909],"CUP_O_T72_RU",100,[2,2],3,true,600] call A3XAI_createCustomVehicleQueue;
