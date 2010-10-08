-- events.lua
-- DCRT V3 ���ػ�����ʱ���ṩ��������.
-- Author: CN5-���֮��-Mizzle

local localized

if GetLocale() == "zhCN" then
	localized = {
		-- for errors.
		RUNTIME_ERROR = "����ʱ����",
		DUPLICATE_RAID_NAME = "�ظ��Ļ���ơ�",
		NOT_IN_RAID = "�����Ŷ��С�",
		RAID_STARTED = "��ѿ�ʼ��",
		RAID_FINISHED = "��ѽ�����",
		RAID_NOT_START = "�δ��ʼ��",
		RAID_NOT_FINISH = "�δ������",
	}
end

function DCRTLocale()
	return localized
end