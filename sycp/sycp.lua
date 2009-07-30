#!/usr/bin/env lua

require 'lfs'

function usage()
	print("Usage:")
	print("    cp  DIR1  DIR2 mode.")
	print("    mode can be 0~2.")

end

if not arg[1] or not arg[2] then
	usage()
	os.exit(1)
end

local dir1 = ""
local dir2 = ""
local mode = arg[3] or 0
mode = tonumber(mode)
if mode > 2 then
	usage()
	os.exit(1)
elseif mode == 0 or mode == 2 then
	dir1 = arg[1]
	dir2 = arg[2]
elseif mode == 1 then
	dir1 = arg[2]
	dir2 = arg[1]
end


local pre = ""
local olddir = ""
function recurse_objs(t, d)
        if d ~= '.' then 
        	olddir = pre
        	pre = pre .. d .. '/'
        	lfs.chdir(d) 
        end
        for f in lfs.dir('.') do
                if f ~= '.' and f ~= '..' then
			local aa = lfs.attributes(f)
			if aa then
				if aa.mode == "directory" then
					recurse_objs(t, f)
				elseif aa.mode == "file" then
					table.insert(t, pre..f)
				end     
			else
				print("failed to get file's attributes.")
				os.exit(1)
			end
                end
        end
        if d ~= '.' then 
        	pre = olddir
        	lfs.chdir('..') 
        end
end


local t_dir1 = {}
local t_dir2 = {}

lfs.chdir(dir1)
recurse_objs(t_dir1, '.');
lfs.chdir("..")
lfs.chdir(dir2)
recurse_objs(t_dir2, '.');
lfs.chdir("..")

function reverse_table( t )
	local rt = {}
	for _, v in ipairs(t) do
		rt[v] = true		
	end
	
	return rt
end

local rt_dir1 = reverse_table(t_dir1)
local rt_dir2 = reverse_table(t_dir2)

function do_copy(v1, v2)
	print("cp "..v1.."  -->  "..v2)						
	os.execute("cp "..v1.." "..v2)
end


-- here, file name content should not contain the prefix dir name, 
-- such as 111, 222.
function sycp(t_this, dir1, rt_that, dir2)
	for _, v in ipairs(t_this) do
		local v1 = dir1.."/"..v
		local v2 = dir2.."/"..v
		-- name equal
		if rt_that[v] then
			local aa = lfs.attributes(v1)
			local bb = lfs.attributes(v2)
			if aa and bb then
				-- print("aa", aa.modification)
				-- print("bb", bb.modification)
				if aa.modification > bb.modification then
					-- do copy
					do_copy(v1, v2)
				end
			else
				print("Failed to get attributes of file.")
				os.exit(1)
			end
		else
			-- do copy
			do_copy(v1, v2)
		end
	end
end

function sycp_two(t_this, dir1, rt_that, dir2)
	for _, v in ipairs(t_this) do
		local v1 = dir1.."/"..v
		local v2 = dir2.."/"..v
		-- name equal
		if not rt_that[v] then
			do_copy(v1, v2)
		end		
	end
end

if mode < 2 then
	sycp(t_dir1, dir1, rt_dir2, dir2)
elseif mode == 2 then
	sycp_two(t_dir1, dir1, rt_dir2, dir2)
	sycp_two(t_dir2, dir2, rt_dir1, dir1)
end

print("Syncronization finished.")

-- this program is not satisfied to all cases