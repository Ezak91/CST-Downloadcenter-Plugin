--Download Center LUA Plugin
--From Ezak for coolstream.to
--READ LICENSE on https://github.com/Ezak91/CST-Downloadcenter-Plugin.git
--2014

--Objekte
function init()
	server = 'http://www.deinehp.de/directory/';  --hier Sever anpassen
	xmldatei = 'download.xml'; --name der xml anpassen
	downloads = {};
	n = neutrino();
end

-- Xml mit Downloadinfos auslesen und in einem Array speichern.
function getDownloads()
	local fname = "/tmp/downloader.xml";

	os.execute("wget -q -O " .. fname .. " '" .. server .. xmldatei .. "'" );
	
	local fp = io.open(fname, "r")
	if fp == nil then
		print("Error opening file '" .. fname .. "'.")
		os.exit(1)
	else
		local s = fp:read("*a")
		fp:close()
		
		i = 1;
		
		for download in string.gmatch(s, "<download>(.-)</download>") do
			downloads[i] = 
			{
				id = i;
				name = download:match("<name>(.-)</name>");
				version = download:match("<version>(.-)</version>");
				categorie = download:match("<categorie>(.-)</categorie>");
				autor = download:match("<autor>(.-)</autor>");
				description = download:match("<description>(.-)</description>");
				screenshot = download:match("<screenshot>(.-)</screenshot>");
				archiv = download:match("<archiv>(.-)</archiv>");
				fileType = download:match("<filetype>(.-)</filetype>");
			};
			
			downloads[i].file = {};
			    j = 1;
				for files in string.gmatch(download,"<file>(.-)</file>") do
					downloads[i].file[j] =
					{
						filename = files:match("<filename>(.-)</filename>");
						installpath = files:match("<installpath>(.-)</installpath>");
						rights = files:match("<rights>(.-)</rights>");
					};
					j = j+1;
				end				

			i = i + 1;
			
		end
		
		m = menu.new{name="Download Center"};
		
		if downloads[1].name ~= nil then
			AddMenueitems();
		end
		
	end
	
end

--Funktion zum hinzufügen der EPG-Daten des aktuellen Channels
function AddMenueitems()
	for index, downloaddetail in pairs(downloads) do 
		m:addItem{type="forwarder", action="ShowInfo", id=index, name=downloaddetail.name};
	end
	m:exec()
end

--Anzeigen der Downloadinfos
function ShowInfo(_index)
	local index = 0 + _index;
	local description = downloads[index].description;
	local info = "Name: " .. downloads[index].name .. "\n" .. "Version: " .. downloads[index].version .. "\n" .. "Autor: " .. downloads[index].autor .. "\n" .. "Kategorie: " .. downloads[index].categorie .. "\n\n" .. "Downloadcenter by Ezak for coolstream.to";
	local spacer = 8;
	local x  = 150;
	local y  = 70;
	local dx = 1000;
	local dy = 600;
	
	getPicture(downloads[index].screenshot);
	
	w = cwindow.new{x=x, y=y, dx=dx, dy=dy, title="Download Center", btnRed="Installieren", btnGreen="Deinstallieren", };
	w:paint();

	ct1 = ctext.new{x=x+220, y=y+50, dx=500, dy=260, text=info,font_text=FONT['MENU']};
	ct1:paint();

	ct2 = ctext.new{x=x+10, y=y+330, dx=dx-20, dy=230, text=description,mode = "ALIGN_SCROLL"};
	ct2:paint();

	n:DisplayImage("/tmp/downloader_" .. downloads[index].screenshot, 160, 130, 190, 260)

	neutrinoExec(index)
	CloseNeutrino()
end

--herunterladen des Bildes
function getPicture(_picture)
	local fname = "/tmp/downloader_" .. _picture
	os.execute("wget -q -U Mozilla -O " .. fname .. " '" .. server .. _picture .. "'");
end

--Fenster anzeigen und auf Tasteneingaben reagieren
function neutrinoExec(_id)
	local id = 0 + _id;
	repeat
		msg, data = n:GetInput(500)
		-- Taste Rot installiert den Download
		if (msg == RC['red']) then
			install(id);
			msg = RC['home'];
		elseif (msg == RC['green']) then
			delete(id);
			msg = RC['home'];
		end
	-- Taste Exit oder Menü beendet das Fenster
	until msg == RC['home'] or msg == RC['setup'];
end

-- Installieren des Downloads
function install(_id)
	local id = 0 + _id;
	
	local i = hintbox.new{ title="Info", text="Wird installiert! Bitte warten....", icon="info"};
	i:exec();
	
	downloadArchiv(downloads[id].archiv);
	
	for index, installFile in pairs(downloads[id].file) do 
		createDir(installFile.installpath);
		unzipArchiv(downloads[id].archiv,installFile.filename,installFile.installpath,downloads[id].fileType);	
		setRights(installFile.installpath,installFile.filename,installFile.rights);
	end
	
	local h = hintbox.new{ title="Info", text="Der Download wurde installiert", icon="info"};
	h:exec();
end

-- Herunterladen des Archivs
function downloadArchiv(_archiv)
	local fname = "/tmp/downloader_" .. _archiv;
	os.execute("wget -q -U Mozilla -O " .. fname .. " '" .. server .. _archiv .. "'");
end

-- Entpacken des Archivs
function unzipArchiv(_archiv,_file,_installpath,_fileType)
	local archiv = "/tmp/downloader_" .. _archiv;
	
	if _fileType == "zip" then
		if _file == '*' then
			os.execute("unzip -o " .. archiv .. " -d " .. _installpath);	
		else
			os.execute("unzip -o " .. archiv .. " " .. _file .. " -d " .. _installpath);
		end
	else
		os.execute("tar xfvz " .. archiv .. " " .. _file .. " --overwrite -C " .. _installpath);
	end
			
end

-- Rechte setzen
function setRights(_installpath,_file,_rights)
	os.execute("chmod " .. _rights .. " " .. _installpath .. "/" .. _file);
end

-- Benötigten Ordner erstellen
function createDir(_installpath)
	os.execute("mkdir -p " .. _installpath);
end

-- Packet löschen
function delete(_id)
	local id = 0 + _id;
	
	local i = hintbox.new{ title="Info", text="Wird deinstalliert! Bitte warten....", icon="info"};
	i:exec();
		
	for index, installFile in pairs(downloads[id].file) do 
		deletePacket(installFile.installpath,installFile.filename);
	end
	
	local h = hintbox.new{ title="Info", text="Das Packet wurde deinstalliert", icon="info"};
	h:exec();
end

function deletePacket(_installpath,_filename)
	os.execute("rm " .. _installpath .. "/" .. _filename);
end


--Fenster schließen
function CloseNeutrino()
	ct1 = nil
	ct2 = nil
	w = nil
	collectgarbage();
end

--[[
MAIN
]]
init();
getDownloads();
--loadPlugins();
os.execute("rm /tmp/downloader_*.*");	
