-- console.lua
-- DCRT V3 控制台本地化.
-- Author: CN5-提尔之手-Mizzle

local prefix = "|c00ffff00DCRT V3 控制台使用帮助：|r\n"

local consoleLocale = {
	USAGE = prefix .. "|c0000ff00" .. [[
        help: 显示此帮助。
        raid: 显示活动相关操作。
        dkp: 显示DKP相关操作。
]] .. "|r",
	RAID_USAGE = prefix .. "|c0000ff00" .. [[
        raid help: 显示此帮助。
        raid list: 显示所有保存的活动列表。
        raid use <index>: 激活编号为index的活动。
        raid new <name>: 新建一个名称为name的活动。
        raid delete <index>: 删除编号为index的活动。
        raid changename <index> <newname>: 更改编号为index的活动名称为name。
]] .. "|r"
}

function DCRT_ConsoleLocale()
	return consoleLocale
end