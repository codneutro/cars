--[[------------------------------------------------------------------
	Project: cars mod                                                
	Author: x[N]ir                                                   
	Date: 20.01.2016                                                 
	File: class_cars.lua                                                   
	Description: Cars mod                                            
--------------------------------------------------------------------]]

--[[------------------------------------------------------------------
     CAR CLASS      
--------------------------------------------------------------------]]
Car = {};
--> Meta table
Car.meta = {__index = Car};
--> Car id
Car.id = 0;
--> Car driver (player's ID)
Car.driver = 0;
--> Car health points
Car.health = 0;
--> Car maximum number of brings
Car.maxBrings = 0;
--> Table of brings (player's ID)
Car.brings = {};
--> Car fictive speed
Car.speed = 0;
--> Car current gear
Car.gear = 0;
--> Car maximum gear
Car.maxGear = 0;
--> Car image's path
Car.img = "";
--> Car image's ID
Car.imgID = nil;
--> Car x position in pixels
Car.x = 0;
--> Car y position in pixels
Car.y = 0;
--> Car's width /2
Car.offsetX = 0;
--> Car's height /2
Car.offsetY = 0;
--> Car's rotation
Car.rot = 0;

--[[------------------------------------------------------------------
	Car Constructor                                                 
--------------------------------------------------------------------]]                                           
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
	
	return c;
end

--[[------------------------------------------------------------------
	SPAWN                                          
--------------------------------------------------------------------]]
function Car:spawn(x, y)
	--> fixing coordinates
	if(x and y) then
		self.x = x + self.offsetX;
		self.y = y + self.offsetY;
	end

	--> spawning the car
	if(not self.imgID) then
		self.imgID = image(self.img, self.x, self.y, 1);
		table.insert(cars.list, self);
		self.id = #cars.list;
	end
end

--[[------------------------------------------------------------------
	Speed Up                                                
--------------------------------------------------------------------]]
function Car:speedUp()
	if(self.gear < self.maxGear) then
		self.gear = self.gear + 1;
		self.speed = self.speed + 3;
	end
end

--[[------------------------------------------------------------------
	Speed Down                                              
--------------------------------------------------------------------]]
function Car:speedDown()
	if(self.gear > -1) then
		self.gear = self.gear - 1;
		self.speed = self.speed - 3;
	end
end

--[[------------------------------------------------------------------
	Update                                         
--------------------------------------------------------------------]]
function Car:update()
	if(self.imgID) then
		imagepos(self.imgID, self.x, self.y, self.rot);
	end
end

--[[------------------------------------------------------------------
	Remove Bring                                       
 --------------------------------------------------------------------]]
function Car:removeBring(id)
	--> brings loop
	for index, bring in pairs(self.brings) do
		if(bring == id) then
			table.remove(self.brings, index);
			parse("speedmod "..id.." 0");
			break;
		end
	end
end

--[[------------------------------------------------------------------
	Add Bring                                       
--------------------------------------------------------------------]]
function Car:addBring(id)
	if(#self.brings < self.maxBrings) then
		table.insert(self.brings, id);
		parse("speedmod "..id.." -100");
	end
end

--[[------------------------------------------------------------------
	Set Brings Speed
--------------------------------------------------------------------]] 
function Car:setBringsSpeed(speed)
	--> brings loop
	for _, bring in pairs(self.brings) do
		parse("speedmod "..self.driver.." "..speed);
	end

	parse("speedmod "..self.driver.." "..speed);
end

--[[------------------------------------------------------------------
	Destroy                                            
--------------------------------------------------------------------]]
function Car:destroy()
	freeimage(self.imgID);
	parse("explosion "..self.x.." "..self.y.." "..cars.EXPLOSION_RANGE
		.." "..cars.EXPLOSION_DMG.." 0");
	self:setBringsSpeed(0);
end

