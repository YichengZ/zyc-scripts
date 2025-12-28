-- @description Check Data File Paths
-- @version 1.0
-- @author Yicheng Zhu (Ethan)
-- @about
--   Helper script to check where ReaPet and StartupActions save their data files.
--   Run this script to see the actual file paths.

local r = reaper

-- 辅助函数：跨平台路径连接
local function join_path(...)
    local parts = {...}
    local path = table.concat(parts, "/")
    path = path:gsub("/+", "/")
    return path
end

local function get_resource_path()
    return r.GetResourcePath()
end

local resource_path = get_resource_path()

local message = "=== Data File Paths ===\n\n"
message = message .. "REAPER Resource Path:\n" .. (resource_path or "Not available") .. "\n\n"
message = message .. "Platform: " .. (package.config:sub(1,1) == "\\" and "Windows" or "macOS/Linux") .. "\n\n"

-- ReaPet data path
local reapet_data_dir = resource_path and join_path(resource_path, "Data", "ReaPet") or nil
local reapet_data_file = reapet_data_dir and join_path(reapet_data_dir, "companion_data.json") or nil

message = message .. "--- ReaPet ---\n"
message = message .. "Data Directory: " .. (reapet_data_dir or "Not available") .. "\n"
message = message .. "Data File: " .. (reapet_data_file or "Not available") .. "\n"

if reapet_data_file then
    local file_exists = r.file_exists(reapet_data_file)
    message = message .. "File Exists: " .. (file_exists and "Yes" or "No") .. "\n"
    if file_exists then
        local file = io.open(reapet_data_file, "r")
        if file then
            local size = file:seek("end")
            file:close()
            message = message .. "File Size: " .. tostring(size) .. " bytes\n"
        end
    end
end

message = message .. "\n"

-- StartupActions data path
local startup_data_dir = resource_path and join_path(resource_path, "Data", "StartupActions") or nil
local startup_data_file = startup_data_dir and join_path(startup_data_dir, "zyc_startup_actions_cfg.lua") or nil

message = message .. "--- StartupActions ---\n"
message = message .. "Data Directory: " .. (startup_data_dir or "Not available") .. "\n"
message = message .. "Config File: " .. (startup_data_file or "Not available") .. "\n"

if startup_data_file then
    local file_exists = r.file_exists(startup_data_file)
    message = message .. "File Exists: " .. (file_exists and "Yes" or "No") .. "\n"
    if file_exists then
        local file = io.open(startup_data_file, "r")
        if file then
            local size = file:seek("end")
            file:close()
            message = message .. "File Size: " .. tostring(size) .. " bytes\n"
        end
    end
end

message = message .. "\n"
message = message .. "--- Old Locations (for migration check) ---\n"

-- Check old ReaPet locations
local script_path = debug.getinfo(1, "S").source:match("@(.*[\\//])")
local old_reapet_path1 = script_path and (script_path .. "data/companion_data.json") or nil
local old_reapet_path2 = script_path and (script_path .. "../data/companion_data.json") or nil

if old_reapet_path1 then
    local exists = r.file_exists(old_reapet_path1)
    message = message .. "Old ReaPet Path 1: " .. old_reapet_path1 .. " (" .. (exists and "EXISTS" or "not found") .. ")\n"
end
if old_reapet_path2 then
    local exists = r.file_exists(old_reapet_path2)
    message = message .. "Old ReaPet Path 2: " .. old_reapet_path2 .. " (" .. (exists and "EXISTS" or "not found") .. ")\n"
end

-- Check old StartupActions location
local startup_script_path = script_path and script_path:gsub("ReaPet/", "StartupActions/") or nil
local old_startup_path = startup_script_path and (startup_script_path .. "zyc_startup_actions_cfg.lua") or nil

if old_startup_path then
    local exists = r.file_exists(old_startup_path)
    message = message .. "Old StartupActions Path: " .. old_startup_path .. " (" .. (exists and "EXISTS" or "not found") .. ")\n"
end

r.ShowMessageBox(message, "Data File Paths", 0)

