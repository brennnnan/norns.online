-- norns.online v0.1.0
-- remote control for your norns
--
-- llllllll.co/t/norns.online
-- note!
-- this script opens your norns to
-- to the net - use with caution.
--    ▼ instructions below ▼
--
--

local json=include("lib/json")
local textentry=require 'textentry'

-- default files / directories
CODE_DIR="/home/we/dust/code/norns.online/"
CONFIG_FILE=CODE_DIR.."config.json"
KILL_FILE="/tmp/norns.online.kill"
START_FILE=CODE_DIR.."start.sh"
SERVER_FILE=CODE_DIR.."norns.online"
LATEST_RELEASE="https://github.com/schollz/norns.online/releases/download/v0.0.1/norns.online"

-- default settings
settings={
  name="",
  allowmenu=true,
  allowencs=true,
  allowkeys=true,
  allowtwitch=false,
  keepawake=false,
  framerate=5,
}
uimessage=""
ui=1
uishift=false

function init()
  params:add_option("allowmenu","menu",{"disabled","allowed"},1)
  params:set_action("allowmenu",function(v)
    settings.allowmenu=v==1
    redraw()
  end)
  
  settings.name=randomString(5)
  load_settings()
  write_settings()
  redraw()
end

function key(n,z)
  if n==1 then
    uishift=z
  elseif uishift==1 and n==3 then
    update()
  elseif n==3 then
    textentry.enter(function(x)
      if x~=nil then
        settings.name=x
      end
    end,settings.name,"norns.online/")
  elseif n==2 and z==1 then
    toggle()
  end
  redraw()
end

function enc(n,z)
  redraw()
end

function redraw()
  screen.clear()
  screen.level(4)
  screen.font_face(3)
  screen.font_size(12)
  screen.move(64,8)
  screen.text_center("you are")
  screen.move(64,22)
  screen.font_face(3)
  screen.font_size(12)
  screen.level(15)
  print(util.file_exists(KILL_FILE))
  if util.file_exists(KILL_FILE) then
    screen.text_center("online")
    
    screen.level(4)
    screen.move(64,36)
    screen.font_face(3)
    screen.font_size(12)
    screen.text_center("norns.online/")
    
    screen.level(15)
    screen.move(64,58)
    screen.font_face(7)
    screen.font_size(24)
    screen.text_center(settings.name)
  else
    screen.level(15)
    screen.text_center("offline")
  end
  
  screen.font_face(1)
  screen.font_size(8)
  if uimessage~="" then
    screen.level(15)
    x=64
    y=28
    w=string.len(uimessage)*6
    screen.rect(x-w/2,y,w,10)
    screen.fill()
    screen.level(15)
    screen.rect(x-w/2,y,w,10)
    screen.stroke()
    screen.move(x,y+7)
    screen.level(0)
    screen.text_center(uimessage)
  end
  
  screen.update()
end

--
-- norns.online stuff
--

function write_settings()
  jsondata=json.encode(settings)
  f=io.open(CONFIG_FILE,"w")
  f:write(jsondata)
  f:close(f)
end

function load_settings()
  if not util.file_exists(CONFIG_FILE) then
    do return end
  end
  data=readAll(CONFIG_FILE)
  settings=json.decode(data)
  tab.print(settings)
  if settings.allowmenu then
    params:set("allowmenu",1)
  else
    params:set("allowmenu",0)
  end
end

function update()
  uimessage="updating"
  redraw()
  os.execute("cd "..CODE_DIR.." && git pull")
  os.execute("cd "..CODE_DIR.."; /usr/local/go/bin/go build")
  uimessage=""
  redraw()
  if not util.file_exists(SERVER_FILE) then
    uimessage="downloading"
    redraw()
    os.execute("curl "..LATEST_RELEASE.." -o "..SERVER_FILE)
    uimessage=""
    redraw()
  end
  if util.file_exists(SERVER_FILE) then
    show_message("updated.")
  end
end

function toggle()
  if util.file_exists(KILL_FILE) then
    uimessage="stopping"
    redraw()
    clock.run(function()
      for i=1,10000 do
        if not util.file_exists(KILL_FILE) then
          uimessage=""
          redraw()
          break
        end
        clock.sleep(0.1)
      end
    end)
    stop()
  else
    uimessage="starting"
    redraw()
    clock.run(function()
      for i=1,10000 do
        if util.file_exists(KILL_FILE) then
          uimessage=""
          redraw()
          break
        end
        clock.sleep(0.1)
      end
    end)
    start()
  end
end

function start()
  write_settings()
  if not util.file_exists(SERVER_FILE) then
    update()
  end
  make_start_sh()
  os.execute(START_FILE)
  redraw()
end

function stop()
  os.execute(KILL_FILE)
  redraw()
end

function make_start_sh()
  startsh="#!/bin/bash\n"
  startsh=startsh..CODE_DIR.."norns.online --config "..CODE_DIR.."config.json > /dev/null &\n"
  f=io.open(START_FILE,"w")
  f:write(startsh)
  f:close(f)
  os.execute("chmod +x "..START_FILE)
end

--
-- utils
--

function sign(x)
  if x>0 then
    return 1
  elseif x<0 then
    return-1
  else
    return 0
  end
end

function show_message(message)
  uimessage=message
  redraw()
  clock.run(function()
    clock.sleep(0.5)
    uimessage=""
    redraw()
  end)
end

function readAll(file)
  local f=assert(io.open(file,"rb"))
  local content=f:read("*all")
  f:close()
  return content
end

local charset={} do -- [a-z]
  for c=97,122 do table.insert(charset,string.char(c)) end
end

function randomString(length)
  if not length or length<=0 then return '' end
  math.randomseed(os.clock()^5)
  return randomString(length-1)..charset[math.random(1,#charset)]
end
