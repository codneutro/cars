--[[------------------------------------------------------------------
	Project: cars mod                                                
	Author: x[N]ir                                                   
	Date: 20.01.2016                                                 
	File: func_cars.lua                                                   
	Description: Cars mod                                            
--------------------------------------------------------------------]]

--[[------------------------------------------------------------------
	Test                              
--------------------------------------------------------------------]]
function cars.test(id, message)
	--> !spawn command
	if(message == "!spawn") then
		local c = Car.new("gfx/car.png", 0, 0, 32, 64, 0, 50);
		c:spawn(player(id, "x"), player(id, "y"));
	end
end

--[[------------------------------------------------------------------
	Distance                    
--------------------------------------------------------------------]]
function cars.distance(x1, y1, x2, y2)
	return math.sqrt((y2 - y1) ^ 2 + (x2 - x1) ^ 2 );
end

--[[------------------------------------------------------------------
	Sound3
 --------------------------------------------------------------------]]          
function cars.sound3(sfx, x, y, distance)
	--> player living loop
	for _, id in pairs(player(0, "tableliving")) do
		if(cars.distance(x, y, player(id, "x"), player(id, "y")) <= 
			distance) then
			parse("sv_sound2 "..id.." "..sfx);
		end
	end
end

--[[------------------------------------------------------------------
	IsDriving                 
--------------------------------------------------------------------]]
function cars.isDriving(id)
	--> car loop
	for _, car in pairs(cars.list) do
		if(car.driver == id) then
			return true, car;
		end
	end

	return nil;
end

--[[------------------------------------------------------------------
	IsBring 
--------------------------------------------------------------------]]
function cars.isBring(id)
	--> car loop
	for _, car in pairs(cars.list) do
		---> brings loop
		for __, bring in pairs(car.brings) do
			if(id == bring) then
				return true, car;
			end
		end
	end

	return nil;
end

--[[------------------------------------------------------------------
	MS100
--------------------------------------------------------------------]]     
function cars.ms100()
	--> cars loop
	for _, car in pairs(cars.list) do
		--> gear check
		if(car.gear > car.maxGear) then
			car.gear = car.maxGear;
		end

		--> speed check
		if(car.speed < 0) then
			car.speed = car.speed + 0.5;
		end

		--> health check
		if(car.health < 200) then
			car.health = car.health - 2;
			parse('effect "fire" '..car.x..' '..car.y..' 5, 5');

			if(car.health <= 0) then
				car:destroy();
				table.remove(cars.list, car.id);
			end

		end		
	end
end

--[[------------------------------------------------------------------
 	ALWAYS 
--------------------------------------------------------------------]]                
function cars.always()
	--> variables
	local x, y = 0, 0;

	--> cars loop
	for _, car in pairs(cars.list) do
		--> rotation
		if(car.driver ~= 0) then
			car.rot = player(car.driver, "rot");
		end

		--> speed check
		if(car.speed ~= 0) then
			x = car.x + (math.sin(math.rad(car.rot)) * car.speed);
			y = car.y - (math.cos(math.rad(car.rot)) * car.speed);

			--> tile check
			if(tile(math.floor(x / 32), math.floor(y / 32), 
				"walkable")) then
				car.x = x;
				car.y = y;
			else
				--> sfx
				if(car.speed > 0 and car.speed < 20) then
					cars.sound3("cars/car_impact.ogg", car.x, car.y, 256);
				elseif(car.speed > 0 and car.speed > 20) then
					cars.sound3("cars/car_impact_glass.ogg", car.x, car.y, 256);
				end

				--> impact effect
				car.gear = 0;
				car.health = car.health - car.speed * 4;
				car.speed = math.floor(-car.speed / 2);
			end

			--> updating driver + brings
			parse("setpos "..car.driver.." "..car.x.." "..car.y);
			for _, bring in pairs(car.brings) do
				parse("setpos "..bring.." "..car.x.." "..car.y);
			end
		end

		--> update
		car:update();
	end
end

--[[------------------------------------------------------------------
	Server Action                                 
 --------------------------------------------------------------------]]
function cars.serveraction(id, action)
	--> Variables
	local driving, car = cars.isDriving(id);
	local bring, bringCar = cars.isBring(id);

	--> F2 for accelerate, F3 for deccelerate, 
	--> F4 for getting in/out the car
	if(action == 1) then
		if(driving) then
			car:speedUp();
		end
	elseif(action == 2) then
		if(driving) then
			car:speedDown();
		end
	else
		if(not driving) then

			if(not bring) then
				--> cars loop
				for _, car in pairs(cars.list) do
					if(cars.distance(car.x, car.y, player(id, "x"),
						player(id, "y")) < cars.USE_RANGE) then
						car:addBring(id);
						break;
					end
				end

			else
				bringCar:removeBring(id);
			end
		end
	end
end

--[[------------------------------------------------------------------
	Use
--------------------------------------------------------------------]] 
function cars.use(id, event, data, x, y)
	if(event == 0) then
		--> car
		local driving, car = cars.isDriving(id);

		if(driving) then
			--> out of the car
			car.driver = 0;
			parse("speedmod "..id.." 0");

		else
			--> cars loop
			for _, car in pairs(cars.list) do

				--> check distance
				if(cars.distance(car.x, car.y, player(id, "x"), 
						player(id, "y")) < cars.USE_RANGE and 
							car.driver == 0) then

					--> in the car + sfx
					car.driver = id;
					parse("speedmod "..id.." -100");
					parse("setpos "..id.." "..car.x.." "..car.y);
					cars.sound3("cars/engine_start.ogg", player(id, "x"), 
						player(id, "y"), 256);
					break;

				end

			end
		end
	end
end