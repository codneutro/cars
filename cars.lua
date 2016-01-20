--[[------------------------------------------------------------------
	Project: cars mod                                                
	Author: x[N]ir                                                   
	Date: 20.01.2016                                                 
	File: cars.lua                                                   
	Description: Cars mod                                            
--------------------------------------------------------------------]]

--[[------------------------------------------------------------------
	Includes                              
--------------------------------------------------------------------]]
CAR_MOD_FOLDER = "sys/lua/projects/cars/";

dofile(CAR_MOD_FOLDER.."vars_cars.lua");
dofile(CAR_MOD_FOLDER.."class_cars.lua");
dofile(CAR_MOD_FOLDER.."func_cars.lua");

--[[------------------------------------------------------------------
	Main 
--------------------------------------------------------------------]] 
function cars.main()
	if(cars.TEST) then
		addhook("say", "cars.test");
	end

	addhook("serveraction", "cars.serveraction");
	addhook("use", "cars.use");
	addhook("ms100", "cars.ms100");
	addhook("always", "cars.always");
end

cars.main();

