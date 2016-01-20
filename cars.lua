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
cars.DEBUG = true;
cars.TEST = true;
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
	return false;
end

----------------------------------------------------------------------
-- Returns true if a player is a bring                              --
--                                                                  --
-- @param id player's id                                            --
-- @return true if a player is a bring                              --
----------------------------------------------------------------------
function cars.isBring(id)
	for _, car in pairs(cars.list) do
		for __, bring in pairs(cars.list.brings) do
			if(id == bring) then
				return true;
			end
		end
	end
	return false;
end

----------------------------------------------------------------------
-- ms100 hook implementation (updating car fields)                  --
----------------------------------------------------------------------
function cars.ms100()
	for _, car in pairs(cars.list) do
		if(car.gear > car.maxGear) then
			car.gear = car.maxGear;
		end
		car.speed = car.gear;
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
			car:update();
		end

		--// updating position
		x = car.x + (math.sin(math.rad(car.rot)) * car.speed);
		y = car.y - (math.cos(math.rad(car.rot)) * car.speed);

		if(tile(math.floor(x / 32), math.floor(y / 32), 
			"walkable")) then
			car.x = x;
			car.y = y;
		else
			car.gear = -1;
		end

		parse("setpos "..car.driver.." "..car.x.." "..car.y);
		for _, bring in pairs(car.brings) do
			parse("setpos "..bring.." "..car.x.." "..car.y);
		end

		car:update();
	end
end


-----------------------
--     CAR CLASS     -- 
-----------------------
Car = {};
Car.meta = {__index = Car};
Car.driver = 0;
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
-- @return the car table                                            --
----------------------------------------------------------------------
function Car.new(img, x, y, offsetX, offsetY, rot, maxGear, maxBrings)
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
		cars.debug("New car added");
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
-- Serveraction hook implementation                                 --
--                                                                  --
-- @param id player's id                                            --
-- @param action numeric key (F2,F3...)                             --
----------------------------------------------------------------------
function cars.serveraction(id, action)
	local b, car = cars.isDriving(id);
	if(action == 1) then
		if(b) then
			car.gear = car.gear + 1;
		end
	elseif(action == 2) then
		if(b) then
			car.gear = car.gear - 1;
		end
	else

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
		cars.testCar = Car.new("gfx/car.png", 0, 0, 32, 64, 0, 10);
	end

	addhook("serveraction", "cars.serveraction");
	addhook("use", "cars.use");
	addhook("ms100", "cars.ms100");
	addhook("always", "cars.always");
end

main();

