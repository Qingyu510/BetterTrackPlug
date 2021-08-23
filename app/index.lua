-- Creating dirs in case they do not exist
System.createDirectory("ux0:/data/TrackPlug/")
System.createDirectory("ux0:/data/TrackPlug/Records")
System.createDirectory("ux0:/data/TrackPlug/Config")
System.createDirectory("ux0:/data/TrackPlug/Assets")
-- Creating blacklist file if it doesn't exist
if not System.doesFileExist("ux0:/data/TrackPlug/blacklist.txt") then
    local blacklist_file = System.openFile("ux0:/data/TrackPlug/blacklist.txt", FCREATE)
    System.closeFile(blacklist_file)
end
--Reading font
 if System.doesFileExist("app0:/font.ttf") then 
    fnt = Font.load("app0:/font.ttf") 
 end
  if not fnt then
    fnt = Font.load("sa0:/data/font/pvf/cn0.pvf")
end
-- Reading blacklist file
local blacklist_file = System.openFile("ux0:/data/TrackPlug/blacklist.txt", FREAD)
local blacklist_fsize = System.sizeFile(blacklist_file)
local blacklist_var = System.readFile(blacklist_file, blacklist_fsize)
System.closeFile(blacklist_file)
-- Removing blacklisted titles
for line in blacklist_var:gmatch("([^\n]*)\n?") do
   System.deleteFile("ux0:/data/TrackPlug/Records/" .. line .. ".bin")
end
-- Read entries to a table
local tbl = System.listDirectory("ux0:/data/TrackPlug/Records")
if tbl == nil then
    tbl = {}
end

-- Convert a 32 bit binary string to an integer
function bin2int(str)
    local b1, b2, b3, b4 = string.byte(str, 1, 4)
    return bit32.lshift(b4, 24) + bit32.lshift(b3, 16) + bit32.lshift(b2, 8) + b1
end

-- Format raw time data
function FormatTime(val)
    local minutes = math.floor(val/60)
    local seconds = val%60
    local hours = math.floor(minutes/60)
    local minutes = minutes%60
    local res = ""
    if hours > 0 then
        res = hours .. " 时 "
    end
    if minutes > 0 then
        res = res .. minutes .. " 分 "
    end
    res = res .. seconds .. " 秒 "
    return res
end

-- Recover title from homebrew database
function recoverTitle(tid)
    local file = System.openFile("ux0:/data/TrackPlug/Assets/" .. tid .. "/title.txt", FREAD)
    fsize = System.sizeFile(file)
    local title = System.readFile(file, fsize)
    System.closeFile(file)
    return title
end

-- Extracts title name from an SFO file
function extractTitle(file, tid)
    local data = System.extractSfo(file)
    if System.doesFileExist("ux0:/data/TrackPlug/Assets/" .. tid .. "/title.txt") then
        System.deleteFile("ux0:/data/TrackPlug/Assets/" .. tid .. "/title.txt")
    end
    local file = System.openFile("ux0:/data/TrackPlug/Assets/" .. tid .. "/title.txt", FCREATE)
    System.writeFile(file, data.title, string.len(data.title))
    System.closeFile(file)
    return data.title
end

function copyIcon(titleid)
	newFile = System.openFile("ux0:/data/TrackPlug/Assets/" .. titleid .. "/icon0.png", FCREATE)
	oldFile = System.openFile("ur0:/appmeta/" .. titleid .. "/icon0.png", FREAD)
	fileSize = System.sizeFile(oldFile)
    icon = System.readFile(oldFile, fileSize)
	System.writeFile(newFile, icon, fileSize)
end

function getRegion(titleid)
    local regioncode = string.sub(titleid,1,4)
    local prefix = string.sub(regioncode,1,2)
    local region = "未知"

    -- PSV common
    if regioncode == "PCSA" or regioncode == "PCSE" then
        region = "美国"
    elseif regioncode == "PCSB" or regioncode == "PCSF" then
        region = "欧洲"
    elseif regioncode == "PCSC" or regioncode == "PCSG" then
        region = "日本"
    elseif regioncode == "PCSD" or regioncode == "PCSH" then
        region = "亚洲"
    -- Physical & NP releases (PSV/PSP/PS1)
    elseif prefix == "VC" or prefix == "VL" or
            prefix == "UC" or prefix == "UL" or
            prefix == "SC" or prefix == "SL" or
            prefix == "NP" then
        n1 = string.sub(regioncode,1,1)
        n3 = string.sub(regioncode,3,3)
        n4 = string.sub(regioncode,4,4)
        if n3 == "A" then
            region = "亚洲"
        elseif n3 == "C" then
            region = "中国"
        elseif n3 == "E" then
            region = "欧洲"
        elseif n3 == "H" then
            region = "香港"
        elseif n3 == "J" or n3 == "P" then
            region = "日本"
        elseif n3 == "K" then
            region = "韩国"
        elseif n3 == "U" then
            region = "美国"
        end

        if n1 == "S" then
            region = region .. " (PS1)"
        elseif n1 == "U" or
                (prefix == "NP" and (n4 == "G" or n4 == "H")) then
            region = region .. " (PSP)"
        elseif prefix == "NP" then
            if n4 == "E" or n4 == "F" then
                region = region .. " (PS1 - PAL)"
            elseif n4 == "I" or n4 == "J" then
                region = region .. " (PS1 - NTSC)"
            end
        end
    elseif prefix == "PE" then
        region = "欧洲 (PS1)"
    elseif prefix == "PT" then
        region = "亚洲 (PS1)"
    elseif prefix == "PU" then
        region = "美国 (PS1)"
    elseif string.sub(titleid,1,6) == "PSPEMU" then
        region = "PSP/PS1"
    end
    return region
end

-- Loading unknown icon
local unk = Graphics.loadImage("app0:/unk.png")

-- Getting region, playtime, icon and title name for any game
for i, file in pairs(tbl) do
    if file.name == "config.lua" then
        dofile("ux0:/data/TrackPlug/"..file.name)
        cfg_idx = i
    else
        local titleid = string.sub(file.name,1,-5)
        file.region = getRegion(titleid)
        if System.doesFileExist("ux0:/data/TrackPlug/Assets/" .. titleid .. "/icon0.png") then
			file.icon = Graphics.loadImage("ux0:/data/TrackPlug/Assets/" .. titleid .. "/icon0.png")
		else
			System.createDirectory("ux0:/data/TrackPlug/Assets/" .. titleid .. "")
			if System.doesFileExist("ur0:/appmeta/" .. titleid .. "/icon0.png") then
				file.icon = Graphics.loadImage("ur0:/appmeta/" .. titleid .. "/icon0.png")
				copyIcon(titleid)
			else
				file.icon = unk
			end
		end
        
		
	if System.doesFileExist("ux0:/data/TrackPlug/Assets/" .. titleid .. "/title.txt") then
            file.title = recoverTitle(titleid)
        elseif System.doesFileExist("ux0:/app/" .. titleid .. "/sce_sys/param.sfo") then
            file.title = extractTitle("ux0:/app/" .. titleid .. "/sce_sys/param.sfo", titleid)
        else
            file.title = "未知 - " .. titleid
        end
        file.id = titleid
        fd = System.openFile("ux0:/data/TrackPlug/Records/" .. file.name, FREAD)
        file.rtime = bin2int(System.readFile(fd, 4))
        file.ptime = FormatTime(file.rtime)
        System.closeFile(fd)
    end
end

-- Background wave effect
local colors = {
    {Color.new(72,72,72), Color.new(30,20,25), Color.new(200,180,180)},
    {Color.new(72,72,72), Color.new(30,20,25), Color.new(200,180,180)},
    {Color.new(72,72,72), Color.new(30,20,25), Color.new(200,180,180)},
    {Color.new(72,72,72), Color.new(30,20,25), Color.new(200,180,180)},
    {Color.new(72,72,72), Color.new(30,20,25), Color.new(200,180,180)}
}

if col_idx == nil then
	col_idx = 0
end

local function LoadWave(height,dim,f,x_dim)
    f=f or 0.1
    local onda={pi=math.pi,Frec=f,Long_onda=dim,Amplitud=height}
    function onda:color(a,b,c) self.a=a self.b=b self.c=c end
    function onda:init(desfase)
        desfase=desfase or 0
        if not self.contador then
            self.contador=Timer.new()
        end
        if not self.a or not self.b or not self.c then
            self.a = 255
            self.b = 200
            self.c = 220
        end
        local t,x,y,i
        t = Timer.getTime(self.contador)/1000+desfase
        for x = 0,x_dim,8 do
			y = 404+self.Amplitud*math.sin(2*self.pi*(t*self.Frec-x/self.Long_onda))
            i = self.Amplitud*(self.pi/self.Long_onda)*math.cos(2*self.pi*(t*self.Frec-x/self.Long_onda))
			k = self.Amplitud*(1*self.pi/self.Long_onda)*math.sin(-1*self.pi*(t*self.Frec-x/self.Long_onda))
            Graphics.drawLine(x-30,x+30,y-i*30,y+i*30,Color.new(self.a,self.b,self.c,math.floor(x/65)))
			Graphics.drawLine(x-150,x+150,y-k*150,y+k*150,Color.new(self.a-60,self.b-80,self.a-70,math.floor(x/20)))
		end
    end
    function onda:destroy()
        Timer.destroy(self.contador)
    end
    return onda
end

wav = LoadWave(100,1160, 0.1, 1160)

-- Internal stuffs
local list_idx = 1
local order_idx = 1
local orders = {"游戏名称", "游戏ID", "游戏区域", "游戏时间"}

-- Ordering titles
table.sort(tbl, function (a, b) return (a.rtime > b.rtime ) end)

-- Internal stuffs
local white = Color.new(255, 255, 255)
local yellow = Color.new(255, 255, 0)
local grey = Color.new(40, 40, 40)

-- Shows an alarm with selection on screen
local alarm_val = 128
local alarm_decrease = true
function showAlarm(title, select_idx)
    if alarm_decrease then
        alarm_val = alarm_val - 4
        if alarm_val == 40 then
            alarm_decrease = false
        end
    else
        alarm_val = alarm_val + 4
        if alarm_val == 128 then
            alarm_decrease = true
        end
    end
    local sclr = Color.new(alarm_val, alarm_val, alarm_val)
    Graphics.fillRect(200, 760, 200, 300, grey)
    Font.print(fnt, 205, 205, title, yellow)
    Graphics.fillRect(200, 760, 235 + select_idx * 20, 255 + select_idx * 20, sclr)
    Font.print(fnt, 205, 255, "确认", white)
    Font.print(fnt, 205, 275, "取消", white)
end
-- Scroll-list Renderer
local sel_val = 128
local decrease = true
local freeze = false
local freeze_blacklist = false
local mov_y = 0
local mov_step = 0
local new_list_idx = nil
local real_i = 1
local big_tbl = {}
function RenderList()
	local r_max = 0
	local r = 0
	if #tbl < 4 then
		r_max = 8
	else
		r_max = 2
	end
	while r < r_max do
		for k, v in pairs(tbl) do
			table.insert(big_tbl, v)
		end
		r = r + 1
	end
	local y = -124
	local i = list_idx - 1
	if not freeze then
		if decrease then
			sel_val = sel_val - 4
			if sel_val == 0 then
				decrease = false
			end
		else
			sel_val = sel_val + 4
			if sel_val == 128 then
				decrease = true
			end
		end
	end
    if mov_y ~= 0 then
        if math.abs(mov_y) < 104 then
		    mov_y = math.floor(mov_y*1.298)
        else
			mov_y = 0
		    list_idx = new_list_idx
            i = new_list_idx - 1
		end
	end
	while i <= list_idx + 4 do
		if i < 1 then
			real_i = i
			i = #big_tbl - math.abs(i)
		end
		Graphics.fillRect(5, 955, y+mov_y, y+mov_y-4, Color.new(255, 255, 255, 60))
		if i ~= list_idx + 5 then
			Graphics.drawImage(5, y + mov_y, big_tbl[i].icon)
		end
		Font.print(fnt, 150, y + 10 + mov_y, string.gsub(big_tbl[i].title, "\n", " "), Color.new(230,140,175))
		Font.print(fnt, 150, y + 55 + mov_y, "游戏ID: " .. big_tbl[i].id, white)
		Font.print(fnt, 150, y + 75 + mov_y, "游戏区域: " .. big_tbl[i].region, white)
		Font.print(fnt, 150, y + 95 + mov_y, "游玩时间: " .. big_tbl[i].ptime, white)
		local r_idx = i % #tbl
		if r_idx == 0 then
			r_idx = #tbl
		end
		Font.print(fnt, 908, y + 100 + mov_y, "# " .. r_idx, white)
		y = y + 132
		if real_i <= 0 then
			i = real_i
			real_i = 1
		end
		i = i + 1
	end
end

-- Main loop
local f_idx = 1
local f_idx_2 = 1
local useless = 0
local blacklisted_title = "kek"
local blacklisted_title_id = "kek"
local oldpad = Controls.read()
while #tbl > 0 do
	Graphics.initBlend()
    Graphics.fillRect(0,960,0,544,Color.new(10,5,15))
    Graphics.fillRect(0,960,4,140,Color.new(20,20,20))
	wav:init()
	RenderList()
	if freeze then
        showAlarm("您确定要永久删除此游戏记录吗？\n" .. string.gsub(tbl[list_idx].title, "\n", " "), f_idx)
    end
    if freeze_blacklist then
        showAlarm("您确定将此游戏记录列入黑名单吗？\n" .. blacklisted_title, f_idx_2)
    end
	Graphics.termBlend()
	Screen.flip()
	Screen.waitVblankStart()
    local pad = Controls.read()
	if Controls.check(pad, SCE_CTRL_UP) and mov_y == 0 then
		if freeze then
            f_idx = 1
        elseif freeze_blacklist then
            f_idx_2 = 1
		else
			new_list_idx = list_idx - 1
			if new_list_idx == 0 then
				new_list_idx = #tbl
			end
			mov_y = 11
		end
	elseif Controls.check(pad, SCE_CTRL_DOWN) and mov_y == 0 then
		if freeze then
            f_idx = 2
        elseif freeze_blacklist then
            f_idx_2 = 2
		else
			new_list_idx = list_idx + 1
			if new_list_idx > #tbl then
				new_list_idx = 1
			end
			mov_y = -11
		end
	elseif Controls.check(pad, SCE_CTRL_TRIANGLE) and not Controls.check(oldpad, SCE_CTRL_TRIANGLE) and not freeze then
        freeze = true
        f_idx = 2
        f_idx_2 = 2
    elseif Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE) and freeze then
        freeze = false
        if f_idx == 1 then -- Delete
            blacklisted_title_id = tbl[list_idx].id
            blacklisted_title = string.gsub(tbl[list_idx].title, "\n", " ")
            System.deleteFile("ux0:/data/TrackPlug/Records/" .. tbl[list_idx].id .. ".bin")
            freeze_blacklist = true
			table.remove(tbl, list_idx)
			big_tbl = {}
			list_idx = list_idx - 1
        end
    elseif Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE) and freeze_blacklist then
        freeze_blacklist = false
        if f_idx_2 == 1 then -- Blacklist
            local file = System.openFile("ux0:/data/TrackPlug/blacklist.txt", FRDWR)
            local file_size = System.sizeFile(file)
            local file_var = System.readFile(file, file_size)
            System.writeFile(file, blacklisted_title_id .. "\n", string.len(blacklisted_title_id) + 1)
            System.closeFile(file)
        end
    end
	oldpad = pad
end

-- No games played yet apparently
while true do
    Graphics.initBlend()
    Screen.clear()
    Font.print(fnt, 5, 5, "尚未追踪到任何游戏，请确认插件是否安装正常。", white)
    Graphics.termBlend()
    Screen.flip()
    Screen.waitVblankStart()
end
