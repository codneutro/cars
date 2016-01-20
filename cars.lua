----------------------------------------------------------------------
-- Project: cars mod                                                --
-- Author: x[N]ir                                                   --
-- Date: 20.01.2016                                                 --
-- File: cars.lua                                                   --
-- Description: Cars mod                                            --
----------------------------------------------------------------------

-----------------------
--     CONSTANTS     -- 
-----------------------
cars = {};
cars.DEBUG = false;
cars.TEST = false;
cars.USE_RANGE = 64;

-----------------------
--     VARIABLES     -- 
-----------------------
cars.list = {};

----------------------------------------------------------------------
-- Debugging function                                               --
--                                                                  --
-- @param message a debbuging message                               --
----------------------------------------------------------------------
function cars.debug(message)
	if(cars.DEBUG) then
		msg(string.char(169).."255255255[DEBUG] "..message);
	end
end

----------------------------------------------------------------------
-- Test function                                                    --
--                                                                  --
-- @param id player's id                                            --
-- @param message a player message                                  --
----------------------------------------------------------------------
function cars.test(id, message)
	if(message == "!spawn") then
		cars.testCar:spawn(player(id, "x"), player(id, "y"));
	end
end

----------------------------------------------------------------------
-- Returns the distance between two objects                         --
--                                                                  --
-- @param x1 object one x position in pixels                        --
-- @param y1 object one y position in pixels                        --
-- @param x2 object two x position in pixels                        --
-- @param y2 object two y position in pixels                        --
-- @return the distance between the two objects                     --
----------------------------------------------------------------------
function cars.distance(x1, y1, x2, y2)
	return math.sqrt((y2 - y1) ^ 2 + (x2 - x1) ^ 2 );
end

----------------------------------------------------------------------
-- Plays a sound in the surroundings from the specified coordinate  --
--                                                                  --
-- @param sfx sound path                                            --
-- @param x sound x origin position in pixels                       --
-- @param y sound y origin position in pixels                       --
-- @param distance the limit of the sound's propagation             --
----------------------------------------------------------------------
function cars.sound3(sfx, x, y, distance)
	--[[
		For each player alive if the distance between the origin and him
		is lower or equal than the distance the player can hear the sound
	]]--

	for _, id in pairs(player(0, "tableliving")) do
		if(cars.distance(x, y, player(id, "x"), player(id, "y")) <= 
			distance) then
			parse("sv_sound2 "..id.." "..sfx);
		end
	end
end

----------------------------------------------------------------------
-- Returns true if a player is driving a car                        --
--                                                                  --
-- @param id player's id                                            --
-- @return true if a player is driving a car                        --
----------------------------------------------------------------------
function cars.isDriving(id)
	for _, car in pairs(cars.list) do
		if(car.driver == id) then
			return true, car;
		end
	end
	return nil;
end

----------------------------------------------------------------------
-- Returns true if a player is a bring                              --
--                                                                  --
-- @param id player's id                                            --
-- @return true if a player is a bring                              --
----------------------------------------------------------------------
function cars.isBring(id)
	for _, car in pairs(cars.list) do
		for __, bring in pairs(car.brings) do
			if(id == bring) then
				return true, car;
			end
		end
	end
	return nil;
end

----------------------------------------------------------------------
-- ms100 hook implementation (updating car fields)                  --
----------------------------------------------------------------------
function cars.ms100()
	for _, car in pairs(cars.list) do
		if(car.gear > car.maxGear) then
			car.gear = car.maxGear;
		end

		if(car.speed < 0) then
			car.speed = car.speed + 0.5;
		end

		if(car.health < 200) then
			car.health = car.health - 5;
			parse('effect "fire" '..car.x..' '..car.y..' 10, 10');
		end

		if(car.health <= 0) then
			car:destroy();
		end
	end
end

----------------------------------------------------------------------
-- always hook implementation (updating car state)                  --
----------------------------------------------------------------------
function cars.always()
	local x, y = 0, 0;
	for _, car in pairs(cars.list) do
		--// updating rotation
		if(car.driver ~= 0) then
			car.rot = player(car.driver, "rot");
		end

		--// updating position
		if(car.speed ~= 0) then
			x = car.x + (math.sin(math.rad(car.rot)) * car.speed);
			y = car.y - (math.cos(math.rad(car.rot)) * car.speed);

			if(tile(math.floor(x / 32), math.floor(y / 32), 
				"walkable")) then
				car.x = x;
				car.y = y;
			else
				if(car.speed > 10) then
					cars.sound3("cars/car_impact.ogg", car.x, car.y, 256);
				elseif(car.speed > 20) then
					cars.sound3("cars/car_impact_glass.ogg", car.x, car.y, 256);
				end
				car.gear = 0;
				car.health = car.health - car.speed * 4;
				car.speed = math.floor(-car.speed / 2);
				msg(car.health);
			end

			parse("setpos "..car.driver.." "..car.x.." "..car.y);
			for _, bring in pairs(car.brings) do
				parse("setpos "..bring.." "..car.x.." "..car.y);
			end
		end

		car:update();
	end
end


-----------------------
--     CAR CLASS     -- 
-----------------------
Car = {};
Car.id = 0;
Car.meta = {__index = Car};
Car.driver = 0;
Car.health = 0;
Car.maxBrings = 0;
Car.brings = {};
Car.speed = 0;
Car.gear = 0;
Car.maxGear = 0;
Car.img = "";
Car.imgID = nil;
Car.x = 0;
Car.y = 0;
Car.offsetX = 0;
Car.offsetY = 0;
Car.rot = 0;

----------------------------------------------------------------------
-- Car constructor                                                  --
--                                                                  --
-- @param img image path                                            --
-- @param x car x position in pixels                                --
-- @param y car y position in pixels                                --
-- @param offsetX car's width divided by 2                          --
-- @param offsetY car's height divided by 2                         --
-- @param rot car's rotation                                        --
-- @param maxGear maximum number of gears                           --
-- @param maxBrings maximum number of brings                        --
-- @param health car health                                         --
-- @return the car table                                            --
----------------------------------------------------------------------
function Car.new(img, x, y, offsetX, offsetY, rot, maxGear, maxBrings, health)
	local c = {};
	setmetatable(c, Car.meta);
	c.img = img;
	c.x = x;
	c.y = y;
	c.offsetX = offsetX;
	c.offsetY = offsetY;
	c.x = c.x + c.offsetX;
	c.y = c.y + c.offsetY;
	c.rot = rot;
	c.maxGear = maxGear;
	c.maxBrings = maxBrings or 4;
	c.health = health or 500;
	cars.debug("New car created");
	return c;
end

----------------------------------------------------------------------
-- Spawns a car at the specified position (optionnal)               --
--                                                                  --
-- @param x car x position in pixels                                --
-- @param y car y position in pixels                                --
----------------------------------------------------------------------
function Car:spawn(x, y)
	--[[
		Fixing coordinates, and if the car isn't already spawned,
		then we spawn the car and add it into the cars table.
	]]--

	if(x and y) then
		self.x = x + self.offsetX;
		self.y = y + self.offsetY;
	end

	if(not self.imgID) then
		self.imgID = image(self.img, self.x, self.y, 1);
		table.insert(cars.list, self);
		car.id = #cars.list;
		cars.debug("New car added");
	end
end

----------------------------------------------------------------------
-- Speeds up a car                                                  --
----------------------------------------------------------------------
function Car:speedUp()
	if(self.gear < self.maxGear) then
		self.gear = self.gear + 1;
		self.speed = self.speed + 3;
		cars.debug("Current Speed : "..self.speed);
		cars.debug("Current Gear: "..self.gear);
	end
end

----------------------------------------------------------------------
-- Speeds down a car                                                --
----------------------------------------------------------------------
function Car:speedDown()
	if(self.gear > -1) then
		self.gear = self.gear - 1;
		self.speed = self.speed - 3;
		cars.debug("Current Speed : "..self.speed);
		cars.debug("Current Gear: "..self.gear);
	end
end

----------------------------------------------------------------------
-- Updates the car image                                            --
----------------------------------------------------------------------
function Car:update()
	if(self.imgID) then
		imagepos(self.imgID, self.x, self.y, self.rot);
	end
end

----------------------------------------------------------------------
-- Removes the specified bring                                      --
--                                                                  --
-- @param id player's id                                            --
----------------------------------------------------------------------
function Car:removeBring(id)
	for index, bring in pairs(self.brings) do
		if(bring == id) then
			table.remove(self.brings, index);
			parse("speedmod "..id.." 0");
			cars.debug("Player #"..id.." is not anymore a bring");
			break;
		end
	end
end

----------------------------------------------------------------------
-- Adds the specified player into the vehicle if possible !         --
--                                                                  --
-- @param id player's id                                            --
----------------------------------------------------------------------
function Car:addBring(id)
	if(#self.brings < self.maxBrings) then
		table.insert(self.brings, id);
		parse("speedmod "..id.." -100");
		cars.debug("Player #"..id.." is now a bring");
	end
end

----------------------------------------------------------------------
-- Destroys the car !                                               --
----------------------------------------------------------------------
function Car:destroy()
	freeimage(self.imgID);
	parse("explosion "..self.x.." "..self.y.." 150 100 0");
	table.remove(cars.list, cars.id);
end

----------------------------------------------------------------------
-- Serveraction hook implementation                                 --
--                                                                  --
-- @param id player's id                                            --
-- @param action numeric key (F2,F3...)                             --
----------------------------------------------------------------------
function cars.serveraction(id, action)
	local driving, car = cars.isDriving(id);
	local bring, bringCar = cars.isBring(id);

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
	cars.debug("Player #"..id.." has pressed F"..(action + 1));
end

----------------------------------------------------------------------
-- Serveraction hook implementation                                 --
--                                                                  --
-- @param id player's id                                            --
-- @param event use event                                           --
-- @param data additional data                                      --
-- @param x use x (tiles)                                           --
-- @param y use y (tiles)                                           --
----------------------------------------------------------------------
function cars.use(id, event, data, x, y)
	if(event == 0) then
		local b, car = cars.isDriving(id);

		if(b) then
			car.driver = 0;
			parse("speedmod "..id.." 0");
			cars.debug("Player "..id.." has left the car");
		else
			for _, car in pairs(cars.list) do
				if(cars.distance(car.x, car.y, player(id, "x"), 
						player(id, "y")) < cars.USE_RANGE and 
							car.driver == 0) then
					car.driver = id;
					parse("speedmod "..id.." -100");
					parse("setpos "..id.." "..car.x.." "..car.y);
					cars.sound3("cars/engine_start.ogg", player(id, "x"), 
						player(id, "y"), 256);
					cars.debug("Player "..id.." is now a driver !");
					break;
				end
			end
		end
	end
end

----------------------------------------------------------------------
-- Main entry point                                                 --
----------------------------------------------------------------------
function main()
	if(cars.TEST) then
		addhook("say", "cars.test");
		cars.testCar = Car.new("gfx/car.png", 0, 0, 32, 64, 0, 50);
	end

	addhook("serveraction", "cars.serveraction");
	addhook("use", "cars.use");
	addhook("ms100", "cars.ms100");
	addhook("always", "cars.always");
end

main();

