//Another Crab's Treasure Autosplitter V2.0 31 May 2024
//Timed via Load Remover - Please compare to Game Time
//Credit to - 
//Jarlyk - Made the original splitter
//Ero - Did most of this rewrite
//TheDementedSalad - Some minor fixes/additions

state("AnotherCrabsTreasure") {}

startup {
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Another Crab's Treasure";
	vars.Helper.LoadSceneManager = true;

    vars.Helper.Settings.CreateFromXml("Components/ACT.Settings.xml");
    vars.Helper.AlertGameTime();

    vars.PendingSplits = 0;
    vars.CompletedSplits = new HashSet<string>();
}

onStart {
    vars.CompletedSplits.Clear();

    timer.IsGameTimePaused = true;
}

init {
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono => {
        vars.Helper["Started"] = mono.Make<bool>("GameManager", "_instance", "startLevelLoad");

        vars.Helper["SkillTreeUnlocks"] = mono.MakeList<IntPtr>("GameManager", "_instance", "activeCrabfile", "unlocks", "skills");
        vars.Helper["SkillWorldUnlocks"] = mono.MakeList<IntPtr>("GameManager", "_instance", "activeCrabfile", "unlocks", "worldSkills");

        vars.Helper["ShallowsProgress"] = mono.MakeList<IntPtr>("GameManager", "_instance", "activeCrabfile", "progressData", "shallowsBools");
        vars.Helper["NewCarciniaProgress"] = mono.MakeList<IntPtr>("GameManager", "_instance", "activeCrabfile", "progressData", "newCarciniaBools");
        vars.Helper["OpenOceanProgress"] = mono.MakeList<IntPtr>("GameManager", "_instance", "activeCrabfile", "progressData", "openOceanBools");
        vars.Helper["ExpiredGroveProgress"] = mono.MakeList<IntPtr>("GameManager", "_instance", "activeCrabfile", "progressData", "expiredGroveBools");
        vars.Helper["ScuttleportProgress"] = mono.MakeList<IntPtr>("GameManager", "_instance", "activeCrabfile", "progressData", "scuttleportBools");
        vars.Helper["TheUnfathomProgress"] = mono.MakeList<IntPtr>("GameManager", "_instance", "activeCrabfile", "progressData", "theUnfathomBools");
        vars.Helper["TheBleachedCityProgress"] = mono.MakeList<IntPtr>("GameManager", "_instance", "activeCrabfile", "progressData", "theBleachedCityBools");
        vars.Helper["TrashIslandProgress"] = mono.MakeList<IntPtr>("GameManager", "_instance", "activeCrabfile", "progressData", "trashIslandBools");

        vars.Helper["Loading"] = mono.Make<bool>("GUIManager", "currentLoadingScreen", "_loading");
        vars.Helper["LoadingString"] = mono.MakeString("GUIManager", "currentLoadingScreen", "loadingString");
		vars.Helper["LoadingString"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

        vars.Helper["EquippedShell"] = mono.MakeString("Player", "singlePlayer", "equippedShell", "prefabName");

        vars.OffsetState = 0x18;
        vars.OffsetId = 0x20;

        return true;
    });

    vars.CheckProgress = (Action<string>)(name => {
        var watcher = vars.Helper[name];

        foreach (var ptr in watcher.Current) {
            var state = vars.Helper.Read<bool>(ptr + vars.OffsetState);
            var id = vars.Helper.Read<int>(ptr + vars.OffsetId);
            var setting = name + "." + id;

            if (state && settings.ContainsKey(setting) && settings[setting] && vars.CompletedSplits.Add(setting)) {
                vars.PendingSplits++;
            }
        }
    });
}

start {
    return !old.Started && current.Started;
}

update{
	//current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;			//creates a function that tracks the games active Scene name
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;	//creates a function that tracks the games currently loading Scene name

    //if(current.activeScene != old.activeScene) vars.Log("active: Old: \"" + old.activeScene + "\", Current: \"" + current.activeScene + "\"");			//Prints when a new scene becomes active
    //if(current.loadingScene != old.loadingScene) vars.Log("loading: Old: \"" + old.loadingScene + "\", Current: \"" + current.loadingScene + "\"");		//Prints when a new scene starts loading
}

split {
	string setting = "";
	
    if (vars.PendingSplits > 0) {
        vars.PendingSplits--;
        return true;
    }

    vars.CheckProgress("SkillTreeUnlocks");
    vars.CheckProgress("SkillWorldUnlocks");

    vars.CheckProgress("ShallowsProgress");
    vars.CheckProgress("NewCarciniaProgress");
    vars.CheckProgress("OpenOceanProgress");
    vars.CheckProgress("ExpiredGroveProgress");
    vars.CheckProgress("ScuttleportProgress");
    vars.CheckProgress("TheUnfathomProgress");
    vars.CheckProgress("TheBleachedCityProgress");
    vars.CheckProgress("TrashIslandProgress");

    if (current.EquippedShell == "Shell_HomeShell" && current.loadingScene == "2_C-NewCarciniaRuins"
        && settings[current.EquippedShell] && vars.CompletedSplits.Add(current.EquippedShell)) {
        return true;
    }
	
	if(current.loadingScene != old.loadingScene){
		setting = "Map_" + old.loadingScene + "_to_" + current.loadingScene;
	}
	
	// Debug. Comment out before release.
	//if (!string.IsNullOrEmpty(setting))
	//vars.Log(setting);

	if (settings.ContainsKey(setting) && settings[setting] && vars.CompletedSplits.Add(setting)){
		return true;
	}
}

isLoading {
    return !current.Started && current.loadingScene != "Title" || current.Loading && !string.IsNullOrEmpty(current.LoadingString);
}

exit
{
    //pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}
