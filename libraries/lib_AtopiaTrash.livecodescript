script "lib_AtopiaTrash"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_AtopiaTrash
type: library
version: 0.1

/*
This library is all about trashing folders on the Atopia Server.

For now we also include all new handlers for updating:

- 1) Atopia Domain Array (ie atopia fedray)
- 2) Atopia Domain Roster
- 3) Federation Fedray
- 4) Fedwiki Sites Index
*/


--> To Organise
-
command fedray_UpdateWikiDomainArray @wikiDomainArray, wikiDomain, pSitemapArray, pUpdateIP
   if pSitemapArray is empty then put fedwiki_FetchSitemapArray (wikiDomain) into pSitemapArray
   --
   put item 2 of the extents of pSitemapArray into pageNum
   put pageNum into wikiDomainArray ["pages"]
   --
   put fedwiki_SitemapLastModified (pSitemapArray) into sitemapLastModified
   put sitemapLastModified into wikiDomainArray ["last modified"]
   --
   if pUpdateIP is true then
      put dig_GetIP (wikiDomain) into someIP
      put someIP into wikiDomainArray ["ipAddress"]
   end if
end fedray_UpdateWikiDomainArray

function dig_GetIP someDomain
   put merge ("dig [[someDomain]] +short") into someShell
   put shell (someShell) into someIP
   return word 1 to -1 of someIP
end dig_GetIP


--> Federation | LastUpdate
-
function federation_GetLastUpDate
   put pageArray_FetchLastUpdated ("fedwiki.org", "last-federation-update") into lastUpdate
   return lastUpdate
end federation_GetLastUpDate

command federation_SetLastUpDate pDateInSeconds
   pageArray_StoreLastUpdated "fedwiki.org", "last-federation-update", pDateInSeconds
   put the result into pageArray
   return pageArray
end federation_SetLastUpDate


--> Working on
-
command atopia_TrashAndIndex atopiaCatModel     
   put the milliseconds into milliStart
   
   # Fetch both fedrays so we can update them
   put atopia_FetchDomainArray() into atopiaFedray
   put fedray_FetchModel() into fedray
   put the seconds into lastUpdateSeconds
   
   # Trash empty sites (don't delete site pages)
   _EmptySites atopiaCatModel, resultArray, atopiaFedray, fedray
   put the result into addedEmpty
   
   # Update time of early sites
   _EarlySites atopiaCatModel, resultArray, atopiaFedray, fedray
   put the result into addedEarly
   
   # Not creatig new sites yet
   -- atopia_UpdateNewSites atopiaCatModel, atopiaFedray, fedray, resultArray
   
   # Store Fedrays
   if addedEmpty OR addedEarly is true then
      atopia_StoreDomainArray atopiaFedray
      fedray_StoreModel fedray
   end if
   
   # Store time of update
   put the milliseconds - milliStart into resultArray  ["trashAndIndexTime"]
   atopia_SetLastUpDate lastUpdateSeconds, resultArray, false, milliStart
   put the result into statusData
   return statusData 
end atopia_TrashAndIndex

command atopia_UpdateNewSites atopiaCatModel, pAtopiaFedray, pFedray, pResultArray
   if pAtopiaFedray is empty then put atopia_FetchDomainArray() into pAtopiaFedray
   if pFedray is empty then put fedray_FetchModel() into pFedray
   if pResultArray is empty then put atopia_FetchStatusModel() into pResultArray
   
   # Add new sites
   _NewSites atopiaCatModel, pAtopiaFedray, pFedray, pResultArray
   put the result into addedNew
   
   # Delete site pages
   -- not done yet
   
   # Store Fedrays
   if addedNew is true then
      atopia_StoreDomainArray pAtopiaFedray
      fedray_StoreModel pFedray
   end if
   atopia_SetLastUpDate lastUpdateSeconds, resultArray, false, milliStart
   put the result into statusData
   
   return statusData
end atopia_UpdateNewSites


--> Atopia | Trash
-
command atopia_UpdateRoster atopiaFedray
   # Update atopia roster
   put keys (atopiaFedray) into atopiaDomains
   url_SortDomainIndex atopiaDomains
   atopia_StoreRosterDomains atopiaDomains
end atopia_UpdateRoster

command transport_TrashEmptyDomains emptyDomains
   local resultArray
   if emptyDomains is empty then return "Error, nothing to trash or update!"
   put atopia_FetchDomainArray() into atopiaFedray
   --
   repeat for each line emptyDomain in emptyDomains
      atopia_MoveToTrash emptyDomain
      put atopiaFedray [emptyDomain] into resultArray ["trashed"][emptyDomain]
      delete variable atopiaFedray [emptyDomain]
   end repeat
   --
   atopia_StoreDomainArray atopiaFedray
   --
   put atopiaFedray into resultArray ["atopiaFedray"]
   return resultArray   
end transport_TrashEmptyDomains

command atopia_AddNewDomainToFedrays newDomain
   -- create new wikiDomainArray
   put fedray_FetchNewCreateDomainArray (newDomain) into wikiDomainArray
   fedray_UpdateWikiDomainArray wikiDomainArray, newDomain
   
   -- update atopiaFedray and fedray
   put atopia_FetchDomainArray() into newAtopiaDomainArray
   put wikiDomainArray into newAtopiaDomainArray [newDomain]   
   atopia_UpdateDomainArrayAndRoster newAtopiaDomainArray
   --
   put fedray_FetchModel() into fedray
   put wikiDomainArray into fedray [newDomain]   
   fedray_StoreModel fedray
end atopia_AddNewDomainToFedrays

function atopia_FetchServerIP
   -- put digitalocean_FetchDropletIP ("Atopia") into atopiaSererIP
   return "46.101.23.193"
end atopia_FetchServerIP

function atopia_ConstructNewSiteButton newDomain
   put newDomain into inputKeyValueArray ["wikiDomain"]
   put "https://rest.livecode.world/update/createSite" into postURL
   put fedwiki_ConstructButtonForm (newDomain, postURL, inputKeyValueArray) into someHTML
   return someHTML
end atopia_ConstructNewSiteButton



--> Atopia | LastUpdate
-
function atopia_GetLaterThanSeconds pSincePeriod
   -- converts user-friendly pSincePeriod to seconds
   switch pSincePeriod
      case "last update"
         put atopia_GetLastUpDate() into laterThanSeconds
         break
      case empty
         put date_GetSinceSeconds ("1 week") into laterThanSeconds
         break
      default
         put date_GetSinceSeconds (pSincePeriod) into laterThanSeconds
   end switch
   return laterThanSeconds
end atopia_GetLaterThanSeconds


--> Atopia | Update | CatModel
-
command atopia_TrashAndUpdateModified
   put transport_FetchAtopiaCatModel() into atopiaCatModel
   atopia_TrashSpam atopiaCatModel
   atopia_UpdateModified atopiaCatModel
   return atopiaCatModel
end atopia_TrashAndUpdateModified

command atopia_TrashSpam atopiaCatModel
   put atopiaCatModel ["empty sites"] into emptyFedray
   --
   put keys (emptyFedray) into emptyDomains
   --
   transport_TrashEmptyDomains emptyDomains
   put the result into resultArray
   put resultArray ["atopiaFedray"] into atopiaFedray
   --
   put pageArray_Fetch ("fedwiki.org", "last-atopia-update") into pageArray
   pageArray_SetItemText pageArray, "e88ba1f3f71092cf", empty
   --
   return pageArray
end atopia_TrashSpam

command atopia_UpdateModified @atopiaCatModel  
   put atopia_FetchDomainArray() into atopiaFedray
   put fedray_FetchModel() into fedray
   --
   _EarlySites atopiaCatModel, resultArray, atopiaFedray, fedray
   --
   put atopiaCatModel ["earlier"] into earlyArray
   put empty into atopiaCatModel ["earlier"]
   put atopiaCatModel ["later"] into laterArray
   union laterArray with earlyArray
   put laterArray into atopiaCatModel ["later"]
   -- 
   -- store Fedrays
   transport_StoreAtopiaCatModel atopiaCatModel
   atopia_StoreDomainArray atopiaFedray
   fedray_StoreModel fedray
   --  
   return resultArray 
end atopia_UpdateModified

command atopia_UpdateNewSites @atopiaCatModel
   put atopia_FetchDomainArray() into atopiaFedray
   put fedray_FetchModel() into fedray
   --
   _NewSites atopiaCatModel, resultArray, atopiaFedray, fedray
   --   -- store Fedrays
   transport_StoreAtopiaCatModel atopiaCatModel
   atopia_StoreDomainArray atopiaFedray
   fedray_StoreModel fedray
   --  
   return resultArray 
end atopia_UpdateNewSites

command atopia_SetLastAtopiaUpdateRosters atopiaCatModel
   put atopia_ConstructLastAtopiaUpdatePageArray (atopiaCatModel) into pageArray
   --
   pageArray_Store "fedwiki.org", "last-atopia-update", pageArray, true
   return pageArray
end atopia_SetLastAtopiaUpdateRosters

function atopia_ConstructLastAtopiaUpdatePageArray atopiaCatModel
   if atopiaCatModel is not an array then return empty
   --
   put pageArray_Fetch ("fedwiki.org", "last-atopia-update") into pageArray
   --
   put "Last Atopia Update:" && the internet date into dateString
   pageArray_SetFirstItem pageArray, "code", dateString
   --
   _SetRosterFromCatDateArray pageArray, "earlier", atopiaCatModel, "Recent Atopia Sites", "b0b5ac1acfb9bf61"
   _SetRosterFromCatDateArray pageArray, "new sites", atopiaCatModel, "New Atopia Sites", "bbbbc6dbd1923cff"
   --
   put the keys of atopiaCatModel ["empty sites"] into emptyDomains
   url_SortDomainIndex emptyDomains
   put fedwiki_MarkdownIndex (emptyDomains) into rosterText
   pageArray_SetItemText pageArray, "e88ba1f3f71092cf", rosterText
   --
   return pageArray
end atopia_ConstructLastAtopiaUpdatePageArray

command atopia_UpdateDomainArrayAndRoster atopiaFedray
   atopia_StoreDomainArray atopiaFedray
   -- update Atopia roster
   put the keys of atopiaFedray into atopiaDomains
   atopia_StoreRosterDomains atopiaDomains
   --
   put the result into pageArray
   return pageArray
end atopia_UpdateDomainArrayAndRoster


--> Transport | Trash | Atopia
-
command transport_TrashAtopiaDomains emptyDomains
   local resultArray
   if emptyDomains is empty then return "Error, nothing to trash or update!"
   put atopia_FetchServerIP() into dropletIP
   put atopia_FetchDomainArray() into atopiaFedray
   --
   repeat for each line emptyDomain in emptyDomains
      _MoveOrTrash emptyDomain, atopiaFedray, resultArray
   end repeat
   --
   put atopiaFedray into resultArray ["atopiaFedray"]
   return resultArray   
end transport_TrashAtopiaDomains


--> Atopia | Trash
-
command atopia_MoveToTrash shortWikiFolder
   if shortWikiFolder is empty then return "Error, shortWikiFolder is empty"
   put atopia_WikiDomainFolder (shortWikiFolder) into remoteWikiFolderPath
   if remoteWikiFolderPath begins with "/root/.wiki/" is false then return empty   
   --
   atopia_DeleteFolderInTrash shortWikiFolder
   --
   put atopia_TrashFolder() into trashFolder
   put "mv -f" && kwote (remoteWikiFolderPath) && kwote (trashFolder) into remoteShell
   --
   put "ssh root@fedwiki.org" && remoteShell into someShell
   put shell (someShell) into moveResult
   --    
   return moveResult
end atopia_MoveToTrash

command atopia_DeleteFolderInTrash trashDomain
   set the itemdelimiter to slash
   put item -1 of trashDomain into trashDomain
   --
   put atopia_TrashFolderExists (trashDomain) into alreadyThere
   if alreadyThere is false then return empty
   --
   put atopia_FolderInTrashFolder (trashDomain) into folderInTrashFolder
   put "rm -rf" && folderInTrashFolder into remoteShell
   --
   put "ssh root@fedwiki.org" && remoteShell into someShell
   put shell (someShell) into shellResult
   --
   put the result into deleteResult
   return deleteResult
end atopia_DeleteFolderInTrash

command atopia_SimpleMoveToUnhosted domainFolder
   put atopia_UnhostedFolder() into unhostedFolder
   put "mv" && domainFolder && unhostedFolder into remoteShell
   --
   put "ssh root@fedwiki.org" && remoteShell into someShell
   put shell (someShell) into shellResult
   --
   put the result into moveResult
   return moveResult
end atopia_SimpleMoveToUnhosted

function atopia_TrashFolderExists trashDomain
   put atopia_FolderInTrashFolder (trashDomain) into folderInTrashFolder
   put "ls -la" && folderInTrashFolder into remoteShell
   --
   put "ssh root@fedwiki.org" && remoteShell into someShell
   put shell (someShell) into shellResult
   --
   if the result begins with "ls: cannot access" then
      return false
   else
      return true
   end if
end atopia_TrashFolderExists


--> Private
-
private command _EmptySites atopiaCatModel, @resultArray, @atopiaFedray, @fedray
   put atopiaCatModel ["empty sites"] into emptyArray
   if emptyArray is empty then return false
   
   put the milliseconds into milliStart
   repeat for each key emptyDomain in emptyArray
      set the cursor to busy
      
      # Delete the metadata
      put fedray [emptyDomain] into resultArray ["removed"][emptyDomain]
      delete variable atopiaFedray [emptyDomain]
      delete variable fedray [emptyDomain]
      
      # Trash the domain
      atopia_MoveToTrash emptyDomain
   end repeat
   put the milliseconds - milliStart into resultArray  ["emptyTime"]
   return true
end _EmptySites

private command _EarlySites atopiaCatModel, @resultArray, @atopiaFedray, @fedray
   put atopiaCatModel ["earlier"] into earlyArray
   if earlyArray is empty then return false
   
   put the milliseconds into milliStart
   repeat for each key modifiedDomain in earlyArray
      set the cursor to busy
      
      # Update wikiDomainArray for early site
      put atopiaFedray [modifiedDomain] into wikiDomainArray
      if wikiDomainArray is empty then
         -- should not be
         put fedray_FetchNewCreateDomainArray (modifiedDomain) into wikiDomainArray
      end if
      fedray_UpdateWikiDomainArray wikiDomainArray, modifiedDomain
      
      # Update atopiaFedray and fedray
      put wikiDomainArray into atopiaFedray [modifiedDomain]
      put wikiDomainArray into fedray [modifiedDomain]
      put wikiDomainArray into resultArray ["updated"][modifiedDomain]
   end repeat
   put the milliseconds - milliStart into resultArray  ["earlyTime"]
   return true
end _EarlySites

private command _NewSites atopiaCatModel, @atopiaFedray, @fedray, @pResultArray
   put atopiaCatModel ["new sites"] into newSiteArray
   if newSiteArray is empty then return false
   
   put the milliseconds into milliStart
   put fedwiki_ListSitemapPages ("sites.fedwiki.org") into fedSitePages
   repeat for each key newSite in newSiteArray
      set the cursor to busy
      
      -- create new wikiDomainArray
      put fedray_FetchNewCreateDomainArray (newSite) into wikiDomainArray
      fedray_UpdateWikiDomainArray wikiDomainArray, newSite
      
      -- create site wiki page
      if newSite is not among the lines of fedSitePages then
         atopia_CreateFederationSitePage newSite, false
      end if
      
      -- update atopiaFedray and fedray
      put wikiDomainArray into atopiaFedray [newSite]
      put wikiDomainArray into fedray [newSite]
      put wikiDomainArray into pResultArray ["new site"][newSite]
   end repeat
   --
   atopia_DeleteFederationSitesMap
   put the milliseconds - milliStart into resultArray  ["newTime"]
   return true
end _NewSites

private command _SetRosterFromCatDateArray @pageArray, someKey, atopiaCatModel, rosterTitle, rosterItemID
   put the keys of atopiaCatModel [someKey] into rosterDomains
   if rosterDomains is empty then
      put rosterTitle into rosterText
   else
      url_SortDomainIndex rosterDomains
      put rosterTitle & CR&CR & rosterDomains into rosterText
   end if
   pageArray_SetItemText pageArray, rosterItemID, rosterText
end _SetRosterFromCatDateArray

private command _MoveOrTrash emptyDomain, atopiaFedray, resultArray
   put atopia_WikiHasPages (emptyDomain) into hasPages
   switch
      case hasPages is false
         -- wiki has no pages
         _TrashNoPages emptyDomain, atopiaFedray, resultArray
         break
      case dig_GetIP (emptyDomain) = dropletIP
         _UpdateLastModified emptyDomain, atopiaFedray, resultArray
         break
      default
         -- wiki is not hosted!
         atopia_SimpleMoveToUnhosted emptyDomain
   end switch 
end _MoveOrTrash

private command _TrashNoPages emptyDomain, @atopiaFedray, @resultArray
   atopia_MoveToTrash emptyDomain
   put atopiaFedray [emptyDomain] into resultArray ["trashed"][emptyDomain]
   delete variable atopiaFedray [emptyDomain]
end _TrashNoPages

private command _UpdateLastModified emptyDomain, @atopiaFedray, @resultArray
   fedray_UpdateLastModified atopiaFedray, emptyDomain
   put the result into sitemapArray
   if sitemapArray is empty then
      put atopiaFedray [emptyDomain] into resultArray ["bad"][emptyDomain]
   else
      put atopiaFedray [emptyDomain] into resultArray ["good"][emptyDomain]
   end if
end _UpdateLastModified

private function date_GetSinceSeconds sincePeriod, pSinceSeconds
   -- used for user friendly dispay / input
   if pSinceSeconds is empty then
      put the seconds into pSinceSeconds
   end if
   --
   put word 1 of sincePeriod into sinceNum
   put word 2 of sincePeriod into sinceWord
   --
   switch sinceWord
      case "min"
      case "mins"
      case "minute"
      case "minutes"
         put sinceNum * 60 into periodInSeconds
         break
      case "hour"
      case "hours"
         put sinceNum * 60 * 60 into periodInSeconds
         break
      case "day"
      case "days"
         put sinceNum * 24 * 60 * 60 into periodInSeconds
         break
      case "week"
      case "weeks"
         put sinceNum * 7 * 24 * 60 * 60 into periodInSeconds
         break
   end switch
   subtract periodInSeconds from pSinceSeconds
   --
   return pSinceSeconds
end date_GetSinceSeconds


