﻿script "Global | Atopia | Display | Menu"
--> MetaData
-
license: GPLv3
name: Global | Atopia | Display | Menu
type: controller
version: 0.2


--> Menu | Init
-
local LocalArray

getprop menu_Target [tObject]
   put the title_Text of tObject into LocalArray ["titleText"]
   put the displayed_Index of tObject into LocalArray ["displayedIndex"]
   --
   put atopia_ListWelcomeFolders() into LocalArray ["welcomeFolders"]
   put atopia_FetchFolders() into LocalArray ["atopiaFolders"]
   --
   put the display_View of tObject into displayView
   return displayView
end menu_Target

getprop disabled_AtopiaFolders [indexView]
   if LocalArray ["welcomeFolders"] = LocalArray ["atopiaFolders"] then
      return true
   else
      return false
   end if
end disabled_AtopiaFolders

getprop checked_WelcomeAtopiaSites [indexView]
   return LocalArray ["titleText"] = "Welcome Folders"
end checked_WelcomeAtopiaSites

getprop checked_EmptyAtopiaFolders [indexView]
   put LocalArray ["titleText"] = "Empty Pages Folder" into diplayingEmptyFolders
   return diplayingEmptyFolders
end checked_EmptyAtopiaFolders

getprop disabled_TrashUpdateAtopiaDomains [indexView]
   if LocalArray ["titleText"] is not "Empty Pages Folder" then
      return "delete"
   end if
   
   if LocalArray ["displayedIndex"] is empty then
      return true
   else
      return false
   end if
end disabled_TrashUpdateAtopiaDomains

getprop displayAtopiaRoster_Param [indexView]
   get the title_Text of indexView
   return it
end displayAtopiaRoster_Param

getprop displayAtopiaRoster_Params
   return "New Folders,-,Atopia Roster,Domain Array,Atopia Folders,Top Atopia Domains"
end displayAtopiaRoster_Params

getprop topDomainTsv_Params
   return cse_ListNames()
end topDomainTsv_Params



--> Global | Atopia | Display | Menu
-
on menu_NewRosterFolders displayView
   put atopia_ListNewRosterFolders() into atopiaDomains
   set the displayed_Index ["New Roster Folders"] of displayView to atopiaDomains
end menu_NewRosterFolders

on menu_NewCatFolders displayView
   put atopia_ListNewCatFolders() into atopiaDomains
   set the displayed_Index ["New Cat Folders"] of displayView to atopiaDomains
end menu_NewCatFolders

on menu_NewStoredCatFolders displayView
   put atopia_ListNewStoredCatFolders() into atopiaDomains
   set the displayed_Index ["New Stored Cat Folders"] of displayView to atopiaDomains
end menu_NewStoredCatFolders

on _
end _

on menu_TopAtopiaFolders displayView
   set the cursor to watch
   put atopia_ListTopFolders()into atopiaDomains
   set the displayed_Index ["Top Atopia Folders"] of displayView to atopiaDomains
end menu_TopAtopiaFolders

on menu_TodaysAtopiaSites displayView
   display_RecentAtopiaSites "1 day", displayView
end menu_TodaysAtopiaSites

on menu_ThisWeeksAtopiaSites displayView
   display_RecentAtopiaSites "1 week", displayView
end menu_ThisWeeksAtopiaSites

on _
end _

on menu_EmptyAtopiaFolders indexView
   put atopia_ListEmptySites() into wikiDomains
   set the displayed_Index ["Empty Pages Folder"] of indexView to wikiDomains
end menu_EmptyAtopiaFolders

on menu_TrashUpdateAtopiaDomains indexView
   put the displayed_Index of indexView into atopiaDomains
   lcw_Answer "Are you sure you want to trash and update metadata for all these domains?", indexView
   --
   display_TrashUpdateAtopiaDomains indexView, atopiaDomains
end menu_TrashUpdateAtopiaDomains

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on _RecentAtopiaFolders indexView
   put atopia_ListRecentDomains() into recentSites
   set the displayed_Index ["Recent Folders"] of indexView to recentSites
end _RecentAtopiaFolders

on _DisplayAtopiaFarms indexView
   put atopia_FetchOceanFarms() into atopiaFarms
   set the displayed_Index ["Atopia Ocean Farms"] of indexView to atopiaFarms
end _DisplayAtopiaFarms

on _DisplayAtopiaOwners
   display_LocalAuthorNameData
end _DisplayAtopiaOwners

on _
end _

on _TodaysAtopiaSites indexView
   put date_GetSinceSeconds ("1 day") into sinceSeconds 
   put atopia_ListRecentDomains (sinceSeconds) into wikiDomains
   set the displayed_Index ["Todays Sites"] of indexView to wikiDomains
end _TodaysAtopiaSites

on _RecentAtopiaSites indexView
   put lcw_Ask ("List for how many days?", "7 days") into dayNum
   --
   put dayNum && "days" into sincePeriod
   put date_GetSinceSeconds (sincePeriod) into sinceSeconds 
   put atopia_ListRecentDomains (sinceSeconds) into wikiDomains
   --
   if dayNum = 1 then
      put "Todays Sites" into someTitle
   else
      put dayNum && "Days" into someTitle
   end if
   set the displayed_Index ["Todays Sites"] of indexView to wikiDomains
end _RecentAtopiaSites

on _
end _

on _WelcomeAtopiaSites indexView
   set the displayed_Index ["Welcome Folders"] of indexView to LocalArray ["welcomeFolders"]
end _WelcomeAtopiaSites

on _AtopiaFolders indexView
   set the displayed_Index ["Atopia Folders"] of indexView to LocalArray ["atopiaFolders"]
end _AtopiaFolders

on _RecentAtopiaPages
   display_RecentAtopiaPages
end _RecentAtopiaPages

on _RecentFederationPages
   display_RecentScrapePages
end _RecentFederationPages

on _
end _

on _DisplayAtopiaConfig
   display_AtopiaConfigJson
end _DisplayAtopiaConfig

on _DisplayAtopiaRoster indexView, displayHow
   put atopia_FetchRosterDomains() into atopiaDomains
   set the displayed_Index ["Atopia Roster"] of indexView to atopiaDomains
end _DisplayAtopiaRoster

on _AtopiaFedrayDomains indexView
   display_AtopiaFedrayDomains indexView
end _AtopiaFedrayDomains

on _DisplayAtopiaDomainArray indexView, displayHow
   -- put atopia_ListDomainsFromFedray() into atopiaDomains
   put atopia_FetchDomainArray() into atopiaFedray
   -- set the displayed_Index ["Domain Array"] of indexView to atopiaDomains
   display_Data atopiaFedray, "atopia_FetchDomainArray()", "Atopia"
end _DisplayAtopiaDomainArray

on _
end _

on _DisplayAtopiaFedray
   local lineMenuTitle
   put atopia_FetchDomainArray() into fedray
   display_Array fedray, "atopia_FetchDomainArray()", "Global | Federation | Build | Menu", lineMenuTitle
end _DisplayAtopiaFedray

on _DisplayFederationArray
   put fedray_FetchModel() into fedray
   display_Array fedray, "fedray_FetchModel()", "Global | Federation | Build | Menu"
end _DisplayFederationArray

on _
end _

on _DisplayAtopiaConfig
   display_AtopiaConfigJson
end _DisplayAtopiaConfig

on _DisplayDropletInfoArray
   put digitalOcean_GetDropletInfoArray() into DropletInfoArray
   display_Array DropletInfoArray, "digitalOcean_GetDropletInfoArray()"
end _DisplayDropletInfoArray

on _DigitalOceanDomainInfoArray
   put digitalocean_GetDomainInfoArray() into DomainInfoArray
   display_Array DomainInfoArray, "digitalocean_GetDomainInfoArray()"
end _DigitalOceanDomainInfoArray

on _
end _

on _TopDomainTsv indexView, cseName
   put atopia_FetchTopTSV (cseName)
end _TopDomainTsv

on _LocalOwnershipArray indexView   
   put atopia_GetLocalEmailOwnerData() into ownershipArray
   -- put dynadot_FetchIndexedDomainArray() into domainArray
   display_Array ownershipArray, "atopia_GetLocalEmailOwnerData()", "Global | Atopia | Tree | Menu"
end _LocalOwnershipArray
