state("SuperKiwi64") {
    int PowerCrystals : "mono-2.0-bdwgc.dll",0x00716098, 0xA8 , 0xF7C; 
//stable memory address for the power crystal counter.this is a private int on a nonstatic script that i didnt know how to access otherwise
//weirdly this is the same address for both mode's counters so thats nice. probably dumb luck but i'll take it.
//i would have used a unity call to get the counter but i couldnt get it to work and even the original splitter didnt work right with that setup anymore.
}


startup
{
 
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "SuperKiwi64";
    vars.Helper.LoadSceneManager = true;
    //bool to track if you loaded into doomsday mode or normal. code has to be diffrent for each mode since nextScene doesnt work with doomsday.
    vars.doomsdayToggle = false; 

        string[] levelNames = {
            "Forest Village", "Mushroom Dorf",
            "Train Station", "High Towers",
            "Temple", "Chamber",
            "Pirate Island", "Big Bay",
            "Jungle Course", "Kiwi 64"
        };

        settings.Add("split_enter", false, "Split on enter level");
        settings.Add("split_exit", true, "Split on exit level");
        for (int i=2;i<=11;i++) {
            var description = "" + (i-1) + " - " + levelNames[i-2];
            settings.Add("split_enter_"+i, false, description, "split_enter");
            settings.Add("split_exit_"+i, i <= 9, description, "split_exit");
        }

    settings.Add("Power_Item", false, "Split on powerstone/powerCrystal collected");
    settings.Add("Doom_Enter",false, "Split on DoomsDay Level Enter");
    settings.Add("Doom_Exit",true, "Split on DoomsDay Level Exit");
    settings.Add("Doom_Boss",false,"Split when entering the Boss fight");
}
init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["nextScene"] = mono.Make<int>("GameManager", "singleton", "NextLevelID");
        vars.Helper["titleActive"] = mono.Make<bool>("HubWorldManagerScript", "singleton", "TitleScreenObject", 0x10, 0x56);
        return true;
    });
    vars.prevScene = -1;
}

update
{
    if (vars.Helper.Scenes.Active.Name != "")
    {
        current.scene = vars.Helper.Scenes.Active.Index;
    }

    if (old.scene != current.scene) {
        vars.Log("Scene Change: " + current.scene + ": " + vars.Helper.Scenes.Active.Name);
    }
}

start
{
 
//if was ! normal game (1) hub and now is hub or if was ! Doomsday start(41) and now is than start and toggle doomsday mode
if (old.scene==16&&current.scene==1||old.scene ==16&&current.scene==0){ //so if you skip the cutscene too quick it has to load which is weird to handel. so it will just start the timer on load and be pause since loading
    vars.doomsdayToggle = false;
    vars.Log(vars.doomsdayToggle);
    return true;
}
if (old.scene!=41&&current.scene==41){
    vars.doomsdayToggle = true;
    vars.Log(vars.doomsdayToggle);
    return true;
}
}


split{

    //power stones and power crystals use the same memory address so both work on the same logic.
    if (current.PowerCrystals != old.PowerCrystals&& current.PowerCrystals!=0){
        vars.Log("Trigger PowerItem");
        return settings["Power_Item"];
    }

    //if it started on the doomsday intro than check only doomsday stuff
    if(vars.doomsdayToggle){
        // DoomsDay Level change
        if(current.scene!=old.scene){
            vars.Log("scene: " + current.scene);
            vars.Log("Last Scene:"+ old.scene);
            
            //Boss cutscene
            if (current.scene == 43&&old.scene!=43){
                return true;
            }
            //doomsday bossfight enter split.
            if (current.scene==36&&old.scene!=36){
             return settings["Doom_Boss"];   
            }

            //DoomsDay Level Exit
            if (current.scene == 32&&old.scene!=32){
                vars.Log("Trigger Doomsday Exit");
                return settings["Doom_Exit"];
            }
            //DoomsDay Level Enter
            if (old.scene == 32 && current.scene!=32&&current.scene!=39){
                vars.Log("Trigger Doomsday Enter");
                return settings["Doom_Enter"];
            }
        }
    
    }else{
        //most if not all CaptinRekBeard's code with minor edits so it works again.
        if (current.nextScene != old.nextScene && current.nextScene != 0) {
            vars.Log("scene: " + current.scene);
            vars.Log("nextScene: " + current.nextScene);
            // Enter plane
            if (current.nextScene == 12) {
                return true;
            }

            // Enter hub
            if (current.nextScene == 1) {
                vars.prevScene = 1;
                int target = current.scene != 0 ? current.scene : vars.prevScene;
                return settings["split_exit_"+target];
            }

            // Enter level
            vars.prevScene = current.nextScene;
            return settings["split_enter_"+current.nextScene];
        }
    }
}

reset
{
    return current.scene==18 && old.scene !=18;
}

isLoading
{
    
    if(vars.doomsdayToggle){
        return current.scene==0;
    }
    return current.nextScene != 0 || current.scene == 0;
}

exit
{
    vars.Helper.Timer.Reset();

}
