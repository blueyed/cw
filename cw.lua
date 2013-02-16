-- FIXME: use list.elems instead of ipairs with dummy loop var

require "std"
local posix = require "posix"
local rex = require "rex_posix"
local cw = require "consolewrap"

print (arg)

local scrname = arg[1]
local base_scrname = posix.basename(scrname or arg[0])

if #arg < 1 or arg[1] == "--help" then
  io.stderr:write ("Usage: not for direct use; use via definition files (see cw(1)):\n" ..
                   "  --version             display version information and exit\n" ..
                   "  --help                display this help and exit\n")
  os.exit ()
elseif arg[1] == "--version" then
  die ("cw (color wrapper) v") -- FIXME .. version)
end

-- Filter a directory out of a PATH-like colon-separated path list.
local function remove_dir_from_path(path, dir)
  local canon_dir = cw.canonicalize_file_name (dir)
  if not canon_dir then return path end
  return table.concat (list.filter (function (s) return cw.canonicalize_file_name (s) ~= canon_dir end,
                                    path:split (":")), ":")
end

posix.setenv ("PATH", remove_dir_from_path (os.getenv("PATH"), SCRIPTSDIR)) -- FIXME: interpolate by configure

local color_name
local color_name_real = {"black","blue","green","cyan","red","purple","brown",
                         "grey+","grey","blue+","green+","cyan+","red+","purple+","yellow","white",
                         "default"}
local color_name_real_invert = {"white","blue+","green+","cyan+","red+","purple+",
                                "yellow","grey","grey+","blue","green","cyan","red","purple","brown","black",
                                "default"}
local colors = #color_name_real
local default_color = colors
local color_code = {"\x1b[00;30m","\x1b[00;34m","\x1b[00;32m",
                    "\x1b[00;36m","\x1b[00;31m","\x1b[00;35m","\x1b[00;33m","\x1b[00;37m",
                    "\x1b[01;30m","\x1b[01;34m","\x1b[01;32m","\x1b[01;36m","\x1b[01;31m",
                    "\x1b[01;35m","\x1b[01;33m","\x1b[01;37m","\x1b[00m"}

color_name = os.getenv ("CW_INVERT") and color_name_real_invert or color_name_real

local colormap = {}

-- Convert a logical color string to a physical color array index. (1..colors).
-- Returns -1 if color type undefined and no base color defined.
local function color_atoi (color)
  local phys = colormap[color] or colormap["base"]
  if phys then
    for i = 1, colors do
      if color_name[i] == phys then
        return i
      end
    end
  end
  return -1
end

local default_colormap = "base=cyan:bright=cyan+:highlight=green+:lowlight=green:neutral=white:warning=yellow:error=red+:punctuation=blue+"

-- Set user color map.
local function setcolors (str)
  local tmp = str
  for _, ass in ipairs (str:split (":")) do
    local t = ass:split ("=")
    local log, phys = t[1], t[2]
    if log and #log > 0 then
      if phys and #phys > 0 then
        colormap[log] = phys
      else
        die ("physical color missing or invalid.")
      end
    else
      die ("logical color missing or invalid.")
    end
  end
  base_color = color_atoi ("base")
  if base_color == -1 then
    setcolors ("base=default")
  end
end

setcolors (os.getenv ("CW_COLORS") or default_colormap)

local matches = {}

function match (col, regex)
  table.insert (matches, {col = color_atoi (col), regex = regex})
end

-- Create a coloring array for a string.
local rex_flags = rex.flags ()
local function make_colors (s)
  local buf = string.rep (string.char (base_color), #s) -- Fill color array with base color.
  local m
  for _, m in ipairs (matches) do
    local r = rex.new (m.regex)
    if r then
      local j = 1
      while j < #s do
        local from, to = r:find (s, j, j > 1 and rex_flags.NOTBOL or 0)
        if not from then break end
        buf = buf:sub (1, from - 1) .. string.rep (string.char (m.col), to - from + 1) .. buf:sub (to + 1)
        if to == from then
          to = to + 1 -- Make sure we advance at least one character.
        end
        j = to
      end
    end
  end
 return buf
end

-- Color a string given a coloring array.
local function apply_colors (s, color)
  local tbuf = ""
  local col = 255 -- Invalid value to guarantee immediate change of color.
  for i = 1, #s do
    if col ~= color[i] then
      col = color[i]
      tbuf = tbuf .. color_code[string.byte (col)]
    end
    tbuf = tbuf .. s[i]
  end
  if string.byte (col) ~= default_color then
    tbuf = tbuf .. color_code[default_color]
  end
  return tbuf
end

-- Color a string based on the definition file.
local function convert_string (s)
  return apply_colors (s, make_colors (s))
end

dofile (scrname) -- FIXME: catch errors

local nocolor = os.getenv("NOCOLOR")
local nocolor_stdout = false -- FIXME not posix.isatty (posix.STDOUT_FILENO)
local nocolor_stderr = false -- FIXME not posix.isatty (posix.STDERR_FILENO)
if not nocolor and not (nocolor_stdout and nocolor_stderr) then
  cw.wrap_child(convert_string)
end

local cmd = base_scrname

if command then
  local cmdline = tostring (command)
  if not cmdline then
    die ("invalid command given.")
  end
  cmd = "/bin/sh"
  arg = {[0] = base_scrname, "-c", cmdline} -- FIXME: needs argv[0]-setting support in luaposix to work
else
  table.remove (arg, 1)
end
posix.execp (cmd, unpack (arg))
