#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================
; PROJECT NYX V1.2.4 - CLIENT COORDS FIX
; ==========================================
global CURRENT_VER := "Project NyX V1.2.4"
global FOOTER_TEXT := CURRENT_VER
global LIGHTNING_ICON_URL := "https://cdn-icons-png.flaticon.com/512/1163/1163657.png"
global IniFile := "nyx_config.ini"

; --- State Variables ---
global IsRunning := false
global IsPaused := false
global StartTick := 0
global GuiVisible := true
global IsPopping := false
global LogLastPos := 0
global LogActiveBiome := ""
global LogCurrentFile := ""
global InventoryToggleState := 0
global PoppedBiomesTracker := Map()

; --- Custom Hotkeys ---
global HkStart := IniRead(IniFile, "Hotkeys", "Start", "F1")
global HkPause := IniRead(IniFile, "Hotkeys", "Pause", "F2")
global HkStop  := IniRead(IniFile, "Hotkeys", "Stop", "F3")
global HkGui   := IniRead(IniFile, "Hotkeys", "ToggleGui", "F4")

global OldHkStart := HkStart
global OldHkPause := HkPause
global OldHkStop  := HkStop
global OldHkGui   := HkGui

; --- 6-Step Coordinates (Assumes Inventory is ALWAYS OPEN) ---
global StepCoords := Map(
    1, {x: Integer(IniRead(IniFile, "Coordinates", "Step1_X", 1272)), y: Integer(IniRead(IniFile, "Coordinates", "Step1_Y", 329))}, ; Items Tab
    2, {x: Integer(IniRead(IniFile, "Coordinates", "Step2_X", 855)),  y: Integer(IniRead(IniFile, "Coordinates", "Step2_Y", 358))}, ; Search Bar
    3, {x: Integer(IniRead(IniFile, "Coordinates", "Step3_X", 845)),  y: Integer(IniRead(IniFile, "Coordinates", "Step3_Y", 460))}, ; First Slot
    4, {x: Integer(IniRead(IniFile, "Coordinates", "Step4_X", 594)),  y: Integer(IniRead(IniFile, "Coordinates", "Step4_Y", 570))}, ; Quantity Box
    5, {x: Integer(IniRead(IniFile, "Coordinates", "Step5_X", 710)),  y: Integer(IniRead(IniFile, "Coordinates", "Step5_Y", 573))}  ; Use Button
)

; ==========================================
; THEMES & DATA DICTIONARIES
; ==========================================
global ThemePresets := Map(
    "Cyberpunk Cyan", {accent: "00F0FF", group: "00FFCC", bg: "0E1117"},
    "Royal Violet",   {accent: "A855F7", group: "D8B4FE", bg: "110E1A"},
    "Emerald Matrix", {accent: "10B981", group: "6EE7B7", bg: "0A1612"},
    "Crimson Blade",  {accent: "EF4444", group: "FCA5A5", bg: "180C0C"},
    "Imperial Gold",  {accent: "F59E0B", group: "FDE68A", bg: "17140B"}
)

global SelectedTheme := IniRead(IniFile, "Settings", "Theme", "Cyberpunk Cyan")
if !ThemePresets.Has(SelectedTheme)
    SelectedTheme := "Cyberpunk Cyan"
global CurrentTheme := ThemePresets[SelectedTheme]

global BiomeData := Map(
    "NORMAL",      {color: "00FFCC", image: "https://static.wikia.nocookie.net/sol-rng/images/c/c9/Daytime_img.png"},
    "WINDY",       {color: "38BDF8", image: "https://static.wikia.nocookie.net/sol-rng/images/c/c9/Daytime_img.png"},
    "RAINY",       {color: "10B981", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ4jrbtgFLDivta_Vdw-P1x0Uyk1B16IRRbmI2EHF3Jaw&s=10"},
    "SNOWY",       {color: "FFFFFF", image: "https://static0.thegamerimages.com/wordpress/wp-content/uploads/wm/2025/02/winter-forest-in-sol-s-rng-1.jpg"},
    "SANDSTORM",   {color: "F59E0B", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRe3u_-Dx4ioGSxB97c108_q_WwfGfd9IsZWi9DCudsOQ&s=10"},
    "BLAZING SUN", {color: "FFBB00", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQnOwtPaYGYOZ-pa7NenFu1VFyATtxwoPNWbALTjlf8DDVeyd7PrzdEIGLX&s=10"},
    "HELL",        {color: "FF3300", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSfZ_ojtPs4DOuF6XOL5B4h-d64TZ43-p8ERWfVMX7NJVmBjKNzxE6zU1k&s=10"},
    "HEAVEN",      {color: "FFFF55", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQzAe-xAmt7PlhmxXfmc3CDx8dmsXaPXgFz2aMp_5nlYA&s"},
    "STARFALL",    {color: "38BDF8", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRCecnufgzGJHYTdQLXLqugYrVumwcSty_brAymPSsDKg&s=10"},
    "CORRUPTION",  {color: "AA00AA", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTj5oSJyewPlF6uYx-0DgMtfR06pfGRDLzn2RfqeBMiL-CR_KdTC8dNhLHN&s=10"},
    "NULL",        {color: "AAAAAA", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS5XeQvNZtLhXzo8x2N-hYpm61TgbcECwxHSWYiQrmW3A&s=10"},
    "AURORA",      {color: "00FF87", image: "https://static.wikia.nocookie.net/sol-rng/images/c/c9/Daytime_img.png"},
    "EGGLAND",     {color: "00FFFF", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTwLhCATdaobzpQlVWP1w6Wqns_O7lbO_o1BGeshZZqeg&s=10"},
    "SINGULARITY", {color: "FF8800", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTwLhCATdaobzpQlVWP1w6Wqns_O7lbO_o1BGeshZZqeg&s=10"},
    "GLITCHED",    {color: "FFFF00", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRVESenY9jm99WKhQaAGbwCQHXPeCkm_m-sEgl6mD2uxA&s"},
    "DREAMSPACE",  {color: "FF00FF", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ6CQBEjtFn9V6rWutOgKQ4KfHwaqS05YDXSY9ApTydBA&s=10"},
    "CYBERSPACE",  {color: "00FFFF", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQSXjCDnj21Cy1vUKeaAv2XZvcrP-gkItL_wWGveraQng&s=10"}
)

global BiomeAliases := Map(
    "GLITCHED",    ["GLITCHED", "GLITCH"],
    "DREAMSPACE",  ["DREAMSPACE", "DREAM SPACE", "DREAM"],
    "CYBERSPACE",  ["CYBERSPACE", "CYBER SPACE", "CYBER"],
    "SINGULARITY", ["SINGULARITY", "SINGULAR"],
    "BLAZING SUN", ["BLAZING SUN", "BLAZING", "SUNNY"],
    "SANDSTORM",   ["SANDSTORM", "SAND"],
    "STARFALL",    ["STARFALL", "STAR"],
    "CORRUPTION",  ["CORRUPTION", "CORRUPT"],
    "HELL",        ["HELL"],
    "HEAVEN",      ["HEAVEN"],
    "NULL",        ["NULL"],
    "AURORA",      ["AURORA"],
    "EGGLAND",     ["EGGLAND", "EGG"],
    "RAINY",       ["RAINY", "RAIN"],
    "SNOWY",       ["SNOWY", "SNOW"],
    "WINDY",       ["WINDY", "WIND"],
    "NORMAL",      ["NORMAL", "DAY", "DAYTIME"]
)

global RareBiomes := ["GLITCHED", "DREAMSPACE", "CYBERSPACE"]
global AllBiomes := ["NORMAL", "WINDY", "RAINY", "SNOWY", "SANDSTORM", "BLAZING SUN", "HELL", "HEAVEN", "STARFALL", "CORRUPTION", "NULL", "AURORA", "EGGLAND", "SINGULARITY", "GLITCHED", "DREAMSPACE", "CYBERSPACE"]

global PotionList := [
    "Lucky Potion", "Heavenly Potion", "Potion of Bound",
    "Transcendent Potion", "Warp Potion", "Tidal Shifter Potion", "Oblivion Potion"
]

; --- Load Configurations ---
global WebhookURL := IniRead(IniFile, "Settings", "Webhook", "")
global Username := IniRead(IniFile, "Settings", "Username", "Player1")
global PSLink := IniRead(IniFile, "Settings", "PSLink", "")
global InvCooldown := IniRead(IniFile, "Settings", "InvCooldown", 10)

global BiomeCounts := Map()
for b in AllBiomes {
    BiomeCounts[b] := Integer(IniRead(IniFile, "Counters", b, 0))
    PoppedBiomesTracker[b] := false
}

global PotionControlsPerBiome := Map()
global BiomeWebhookControls := Map()

; ==========================================
; USER INTERFACE SETUP
; ==========================================
myGui := Gui("+Resize", CURRENT_VER)
myGui.BackColor := CurrentTheme.bg
myGui.SetFont("s9", "Segoe UI")

tabs := myGui.Add("Tab3", "x10 y10 w760 h730", ["⚡ Dashboard", "🎒 Auto Pop", "📂 Logs", "⚙️ Settings", "🌐 Webhooks", "👑 Developer"])

; --- TAB 1: DASHBOARD ---
tabs.UseTab(1)
myGui.SetFont("s10 Bold", "Segoe UI")
global BtnStart := myGui.Add("Button", "x25 y40 w120 h35 c00FF00", "▶ START (" HkStart ")")
BtnStart.OnEvent("Click", GUI_StartMacro)

global BtnPause := myGui.Add("Button", "x155 y40 w120 h35 cFFFF00", "⏸ PAUSE (" HkPause ")")
BtnPause.OnEvent("Click", GUI_PauseMacro)

global BtnStop := myGui.Add("Button", "x285 y40 w120 h35 cFF0000", "⏹ STOP (" HkStop ")")
BtnStop.OnEvent("Click", GUI_StopMacro)

global LblStatus := myGui.Add("Text", "x25 y82 w280 +0x800 cFF0000", "STATUS: STOPPED")
global LblTimer := myGui.Add("Text", "x320 y82 w200 +0x800 c" CurrentTheme.accent, "RUNNING: 00:00:00")
global LblCurrentBiome := myGui.Add("Text", "x25 y105 w500 +0x800 cFFFF00", "Current: NONE")

myGui.Add("GroupBox", "x25 y125 w710 h560 c" CurrentTheme.group, " 📊 Biome Counter Dashboard ")
global LblTotalCount := myGui.Add("Text", "x40 y150 w200 +0x800 c00FF00", "Total Detected: 0")
global LblRareCount := myGui.Add("Text", "x250 y150 w200 +0x800 cFF00FF", "Rare Biomes: 0")
myGui.Add("Button", "x595 y146 w125 h26", "🔄 Reset Counts").OnEvent("Click", GUI_ResetCounts)

global BiomeLabels := Map()
yPos := 185
xPos := 35
loop AllBiomes.Length {
    bName := AllBiomes[A_Index]
    bHex := BiomeData.Has(bName) ? BiomeData[bName].color : "FFFFFF"
    
    myGui.Add("GroupBox", "x" xPos " y" yPos " w162 h50 c" bHex, "")
    myGui.SetFont("s8 Bold", "Segoe UI")
    myGui.Add("Text", "x" (xPos + 6) " y" (yPos + 15) " w105 h18 +0x800 c" bHex, bName)
    
    myGui.SetFont("s9 Bold", "Consolas")
    BiomeLabels[bName] := myGui.Add("Text", "x" (xPos + 115) " y" (yPos + 14) " w40 h18 +0x800 cFFFFFF", BiomeCounts[bName])
    
    xPos += 172
    if (Mod(A_Index, 4) == 0) {
        xPos := 35
        yPos += 56
    }
}

; --- TAB 2: AUTO POP & CALIBRATION ---
tabs.UseTab(2)
myGui.SetFont("s10 Bold", "Segoe UI")
myGui.Add("Text", "x25 y38 w710 +0x800 cFFFF00", "🎒 AUTO ITEM SCANNER (BIOME RANDOMIZER / STRANGE CONTROLLER)")

myGui.SetFont("s9", "Segoe UI")
global CbBiomeRand := myGui.Add("CheckBox", "x25 y62 w190 c" CurrentTheme.accent, "🎲 Biome Randomizer")
CbBiomeRand.Value := Integer(IniRead(IniFile, "Settings", "CbBiomeRand", 1))
global CbStrangeCtrl := myGui.Add("CheckBox", "x220 y62 w190 cFF00FF", "🕹️ Strange Controller")
CbStrangeCtrl.Value := Integer(IniRead(IniFile, "Settings", "CbStrangeCtrl", 0))

myGui.Add("Text", "x435 y64 w70 +0x800 cFFFFFF", "⏱️ CD (s):")
global EdInvCooldown := myGui.Add("Edit", "x505 y60 w50", InvCooldown)
myGui.Add("Button", "x580 y58 w145 h28 c00FF00", "💾 Save All Pop").OnEvent("Click", GUI_SaveInvSettings)

; Auto Potion configuration
myGui.Add("GroupBox", "x25 y95 w710 h225 c" CurrentTheme.group, " 🧪 PER-BIOME AUTO POTION CONFIGURATION ")
myGui.Add("Text", "x40 y120 w100 +0x800 cFFFF00", "Select Biome:")

global DdlBiomes := myGui.Add("DropDownList", "x130 y117 w180 Choose1", AllBiomes)
DdlBiomes.OnEvent("Change", GUI_OnBiomeSelectionChanged)

global BtnResetOneShot := myGui.Add("Button", "x325 y116 w140 h28 cFF00FF", "🔄 Reset One-Shot")
BtnResetOneShot.OnEvent("Click", GUI_ResetOneShotTrackers)

global LblBiomeOneShotStatus := myGui.Add("Text", "x480 y120 w180 +0x800 c00FF00", "Status: Waiting")

for bName in AllBiomes {
    sectionName := "BiomeConfig_" . bName
    pMap := Map()
    yOff := 155
    loop PotionList.Length {
        pName := PotionList[A_Index]
        keySanitized := StrReplace(pName, " ", "")
        
        pEnable := Integer(IniRead(IniFile, sectionName, keySanitized "_Enable", 0))
        pQty := Integer(IniRead(IniFile, sectionName, keySanitized "_Qty", 1))
        
        colX := (A_Index <= 4) ? 45 : 390
        rowY := (A_Index <= 4) ? (yOff + (A_Index - 1) * 30) : (yOff + (A_Index - 5) * 30)
        
        cb := myGui.Add("CheckBox", "x" colX " y" rowY " w200 cFFFFFF Hidden", pName)
        cb.Value := pEnable
        cb.OnEvent("Click", GUI_UpdateStep5State)
        
        lbl := myGui.Add("Text", "x" (colX + 210) " y" (rowY + 2) " w35 +0x800 c" CurrentTheme.accent " Hidden", "Qty:")
        ed := myGui.Add("Edit", "x" (colX + 245) " y" (rowY - 2) " w55 Number Hidden", pQty)
        
        pMap[pName] := {cb: cb, ed: ed}
    }
    PotionControlsPerBiome[bName] := pMap
}
ShowControlsForBiome("NORMAL")

; Coordinates Calibration
myGui.Add("GroupBox", "x25 y330 w710 h345 c" CurrentTheme.group, " 🛠️ INVENTORY COORDINATES CALIBRATION ")
myGui.SetFont("s9 Bold", "Segoe UI")
myGui.Add("Text", "x40 y350 w650 h20 +0x800 cFF0000", "⚠️ CRITICAL: YOU MUST KEEP THE ROBLOX INVENTORY OPEN BEFORE STARTING!")
myGui.SetFont("s9", "Segoe UI")

global BtnSteps := Map()
global LblXYZs := Map()
stepData := [
    {desc: "1. Items Tab"},
    {desc: "2. Search Bar"},
    {desc: "3. First Item Slot"},
    {desc: "4. Quantity Box (Disabled if no potion selected)"},
    {desc: "5. Use Button"}
]

currY := 380
loop stepData.Length {
    i := A_Index
    d := stepData[i]
    coords := StepCoords[i]
    
    myGui.Add("Text", "x40 y" currY " w350 h20 +0x800 cFFFF00", d.desc)
    btn := myGui.Add("Button", "x400 y" (currY - 2) " w130 h24", "📍 Calibrate Step " i)
    lblXYZ := myGui.Add("Text", "x545 y" (currY + 2) " w180 h20 +0x800 c00FF00", "X: " coords.x ", Y: " coords.y)
    
    btn.OnEvent("Click", BindTestStep(i, btn, lblXYZ))
    BtnSteps[i] := btn
    LblXYZs[i] := lblXYZ
    
    currY += 38
}
UpdateStep5State()

myGui.SetFont("s9", "Segoe UI")
myGui.Add("Button", "x210 y625 w320 h30 c" CurrentTheme.accent, "▶ Test All Steps (Safe Clipboard Paste)").OnEvent("Click", GUI_RunFullSteps)

; --- TAB 3: LOG MONITOR ---
tabs.UseTab(3)
myGui.SetFont("s10 Bold", "Segoe UI")
myGui.Add("Text", "x25 y40 w710 +0x800 c" CurrentTheme.accent, "📂 ROBLOX LOG FILE MONITOR & DIAGNOSTICS")
myGui.SetFont("s9", "Segoe UI")
global LblLogPath := myGui.Add("Text", "x25 y70 w710 h40 +0x800 cFFFF00", "Pointing to log file...")

myGui.Add("Button", "x25 y115 w160 h28 c00FF00", "🔍 Refresh Log Path").OnEvent("Click", GUI_RefreshLogPath)
myGui.Add("Button", "x195 y115 w180 h28 cFF00FF", "🐛 Scan Current Log Now").OnEvent("Click", GUI_ForceScanLogNow)

global EdLogs := myGui.Add("Edit", "x25 y155 w710 h530 ReadOnly VScroll Background111111 c00FFCC", "")

; --- TAB 4: SETTINGS & HOTKEYS ---
tabs.UseTab(4)
myGui.SetFont("s10 Bold", "Segoe UI")
myGui.Add("Text", "x25 y35 w380 +0x800 c00FF00", "⚙️ GENERAL SETTINGS & HOTKEYS")

myGui.SetFont("s9 Bold", "Segoe UI")
myGui.Add("Text", "x25 y68 w120 +0x800 c" CurrentTheme.accent, "🎨 Theme Color:")
global DdlTheme := myGui.Add("DropDownList", "x145 y65 w240 Choose1", ["Cyberpunk Cyan", "Royal Violet", "Emerald Matrix", "Crimson Blade", "Imperial Gold"])
DdlTheme.Text := SelectedTheme
DdlTheme.OnEvent("Change", GUI_OnThemeChanged)

myGui.Add("GroupBox", "x25 y110 w710 h150 c" CurrentTheme.group, " ⌨️ Macro Hotkeys ")
myGui.SetFont("s9", "Segoe UI")

myGui.Add("Text", "x45 y140 w100 cFFFFFF", "Start Macro:")
global CtrlStart := myGui.Add("Edit", "x150 y136 w180", HkStart)

myGui.Add("Text", "x45 y180 w100 cFFFFFF", "Pause Macro:")
global CtrlPause := myGui.Add("Edit", "x150 y176 w180", HkPause)

myGui.Add("Text", "x380 y140 w100 cFFFFFF", "Stop Macro:")
global CtrlStop := myGui.Add("Edit", "x485 y136 w180", HkStop)

myGui.Add("Text", "x380 y180 w100 cFFFFFF", "Toggle GUI:")
global CtrlGui := myGui.Add("Edit", "x485 y176 w180", HkGui)

myGui.SetFont("s8 Italic", "Segoe UI")
myGui.Add("Text", "x45 y220 w600 cFFBB00", "💡 Tip: Type the key name directly (e.g., F1, H, Home, End, ^H for Ctrl+H).")
myGui.SetFont("s9", "Segoe UI")

myGui.Add("Button", "x25 y280 w150 h28 c00FF00", "💾 Save Settings").OnEvent("Click", GUI_SaveHotkeysSettings)

; --- TAB 5: DISCORD WEBHOOKS & 16 BIOMES ---
tabs.UseTab(5)
myGui.SetFont("s10 Bold", "Segoe UI")
myGui.Add("Text", "x25 y35 w380 +0x800 c00FF00", "🌐 DISCORD WEBHOOK & PROFILES")

myGui.SetFont("s9", "Segoe UI")
myGui.Add("Text", "x25 y65 w120 +0x800 c" CurrentTheme.accent, "Webhook URL:")
global EdWebhook := myGui.Add("Edit", "x145 y62 w580 h40", WebhookURL)
myGui.Add("Text", "x25 y112 w120 +0x800 c" CurrentTheme.accent, "Roblox Username:")
global EdUsername := myGui.Add("Edit", "x145 y109 w240", Username)
myGui.Add("Text", "x25 y145 w120 +0x800 c" CurrentTheme.accent, "Private Server:")
global EdPS := myGui.Add("Edit", "x145 y142 w580", PSLink)

myGui.Add("Button", "x145 y175 w140 h28 c00FF00", "💾 Save Webhooks").OnEvent("Click", GUI_SaveWebhookSettings)
myGui.Add("Button", "x295 y175 w140 h28 cFF00FF", "🧪 Test Webhook").OnEvent("Click", GUI_TestWebhookAction)

myGui.Add("GroupBox", "x25 y210 w710 h475 c" CurrentTheme.group, " 🔔 BIOME NOTIFICATIONS & PING SETTINGS (16 BIOMES) ")

myGui.SetFont("s8", "Segoe UI")
yW := 230
loop AllBiomes.Length {
    b := AllBiomes[A_Index]
    isRare := (b == "GLITCHED" || b == "DREAMSPACE" || b == "CYBERSPACE")
    bColor := BiomeData.Has(b) ? BiomeData[b].color : "FFFFFF"
    
    sSend := isRare ? 1 : Integer(IniRead(IniFile, "WebhookBiomes", b "_Send", 1))
    sPing := isRare ? 1 : Integer(IniRead(IniFile, "WebhookBiomes", b "_PingEnable", 0))
    sId := isRare ? "@everyone" : IniRead(IniFile, "WebhookBiomes", b "_PingID", "")
    
    col := (A_Index <= 9) ? 1 : 2
    rowInCol := (A_Index <= 9) ? A_Index : (A_Index - 9)
    baseX := (col == 1) ? 35 : 390
    baseY := 230 + (rowInCol - 1) * 27
    
    myGui.Add("Text", "x" baseX " y" (baseY + 3) " w85 h18 +0x800 c" bColor, "● " b)
    cbSend := myGui.Add("CheckBox", "x" (baseX + 85) " y" baseY " w55 cFFFFFF", isRare ? "LOCKED" : "Send")
    cbSend.Value := sSend
    if isRare
        cbSend.Enabled := false
        
    cbPing := myGui.Add("CheckBox", "x" (baseX + 145) " y" baseY " w50 c" CurrentTheme.accent, "Ping")
    cbPing.Value := sPing
    if isRare
        cbPing.Enabled := false
        
    edId := myGui.Add("Edit", "x" (baseX + 195) " y" (baseY - 2) " w135", sId)
    if isRare
        edId.Enabled := false
        
    BiomeWebhookControls[b] := {send: cbSend, ping: cbPing, id: edId, isRare: isRare}
}

; --- TAB 6: DEVELOPER GROUP ---
tabs.UseTab(6)
myGui.SetFont("s12 Bold", "Segoe UI")
myGui.Add("Text", "x45 y45 w620 +0x800 cFF00FF", "👑 DEVELOPER GROUP - PROJECT NYX")
myGui.SetFont("s10", "Segoe UI")
myGui.Add("GroupBox", "x45 y80 w640 h560 c" CurrentTheme.group, " 📌 Author & Development Info ")
myGui.SetFont("s11 Bold", "Segoe UI")
myGui.Add("Text", "x75 y120 w560 +0x800 cFFFF00", "• Display Name: [ N.y.X ]")
myGui.SetFont("s10", "Segoe UI")
myGui.Add("Text", "x75 y155 w560 +0x800 c00FF00", "• Account / Discord: justlingg.3")
myGui.Add("Text", "x75 y190 w560 +0x800 cFFFFFF", "• Role: Main Developer & Project Creator")
myGui.Add("Text", "x75 y225 w560 +0x800 c00FFCC", "• Official Tester: lordchym5129")
myGui.Add("Text", "x75 y260 w560 +0x800 c" CurrentTheme.accent, "• Group Status: Exclusive for Sol's RNG Macro.")
myGui.Add("GroupBox", "x75 y310 w580 h200 cFF00FF", " 💬 Message from Dev ")
myGui.SetFont("s9 Italic", "Segoe UI")
myGui.Add("Text", "x95 y350 w540 +0x800 cFFFF00", "Project NyX V1.2.4: Fixed Client Coordinates drift in Calibration!")

myGui.Show("w780 h750")
ApplyHotkeys()
RefreshLogPath()
UpdateDashboardUI()

; ==========================================
; GUI EVENT WRAPPERS (CLEAN ARCHITECTURE)
; ==========================================
GUI_StartMacro(ctrl, info) {
    StartMacro()
}
GUI_PauseMacro(ctrl, info) {
    PauseMacro()
}
GUI_StopMacro(ctrl, info) {
    StopMacro()
}
GUI_ResetCounts(ctrl, info) {
    ResetCounts()
}
GUI_SaveInvSettings(ctrl, info) {
    SaveInvSettings()
}
GUI_OnBiomeSelectionChanged(ctrl, info) {
    OnBiomeSelectionChanged(ctrl, info)
}
GUI_ResetOneShotTrackers(ctrl, info) {
    ResetOneShotTrackers()
}
GUI_UpdateStep5State(ctrl, info) {
    UpdateStep5State()
}
GUI_RunFullSteps(ctrl, info) {
    RunFullStepsWithCountdown()
}
GUI_RefreshLogPath(ctrl, info) {
    RefreshLogPath()
}
GUI_ForceScanLogNow(ctrl, info) {
    ForceScanLogNow()
}
GUI_OnThemeChanged(ctrl, info) {
    OnThemeChanged(ctrl, info)
}
GUI_SaveHotkeysSettings(ctrl, info) {
    SaveHotkeysSettings()
}
GUI_SaveWebhookSettings(ctrl, info) {
    SaveWebhookSettings()
}
GUI_TestWebhookAction(ctrl, info) {
    TestWebhookAction()
}

; --- HOTKEY WRAPPERS ---
HkWrapper_StartMacro(hk) {
    StartMacro()
}
HkWrapper_PauseMacro(hk) {
    PauseMacro()
}
HkWrapper_StopMacro(hk) {
    StopMacro()
}
HkWrapper_ToggleGui(hk) {
    ToggleGuiVisibility()
}

; ==========================================
; CALIBRATION & STEP FUNCTIONS
; ==========================================
HasActivePotionsForCurrentBiome() {
    global DdlBiomes, PotionControlsPerBiome
    currBiome := DdlBiomes.Text
    if !PotionControlsPerBiome.Has(currBiome)
        return false
    pMap := PotionControlsPerBiome[currBiome]
    for pName, ctrls in pMap {
        if (ctrls.cb.Value == 1)
            return true
    }
    return false
}

UpdateStep5State() {
    global BtnSteps, LblXYZs, StepCoords
    if !IsSet(BtnSteps) || !BtnSteps.Has(4)
        return
        
    if HasActivePotionsForCurrentBiome() {
        BtnSteps[4].Enabled := true
        LblXYZs[4].Value := "X: " StepCoords[4].x ", Y: " StepCoords[4].y
        LblXYZs[4].Opt("c00FF00")
    } else {
        BtnSteps[4].Enabled := false
        LblXYZs[4].Value := "(Disabled - No potion selected)"
        LblXYZs[4].Opt("c888888")
    }
}

BindTestStep(stepNum, btnCtrl, lblXYZCtrl) {
    return (ctrl, info) => RunStepWithCountdown(stepNum, btnCtrl, lblXYZCtrl)
}

RunStepWithCountdown(stepNum, btnCtrl, lblXYZCtrl) {
    global StepCoords, IniFile
    LogMsg("[Calibration] Preparing to get coordinates for Step " stepNum " in 3 seconds...")
    
    Loop 3 {
        remaining := 4 - A_Index
        btnCtrl.Text := "⏳ " remaining "s"
        Sleep(1000)
    }
    
    ; Chuyển sang Roblox lấy Client Coords
    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinActivate("ahk_exe RobloxPlayerBeta.exe")
        Sleep(150)
        CoordMode("Mouse", "Client")
        MouseGetPos(&relX, &relY)
    } else {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&relX, &relY)
    }
    
    StepCoords[stepNum] := {x: relX, y: relY}
    lblXYZCtrl.Value := "X: " relX ", Y: " relY
    btnCtrl.Text := "📍 Calibrate Step " stepNum
    
    IniWrite(relX, IniFile, "Coordinates", "Step" stepNum "_X")
    IniWrite(relY, IniFile, "Coordinates", "Step" stepNum "_Y")
    
    LogMsg("[Calibration] Saved CLIENT coordinates for Step " stepNum ": [X: " relX ", Y: " relY "]")
}

SmoothMove(targetX, targetY) {
    if !WinActive("ahk_exe RobloxPlayerBeta.exe")
        WinActivate("ahk_exe RobloxPlayerBeta.exe")
    Sleep(50)
    CoordMode("Mouse", "Client")
    MouseGetPos(&startX, &startY)
    steps := 15
    loop steps {
        if (!IsRunning || IsPaused || !WinActive("ahk_exe RobloxPlayerBeta.exe"))
            break
        currX := startX + (targetX - startX) * A_Index / steps
        currY := startY + (targetY - startY) * A_Index / steps
        MouseMove(currX, currY, 0)
        Sleep(10)
    }
}

RunFullStepsWithCountdown() {
    if !WinExist("ahk_exe RobloxPlayerBeta.exe") {
        LogMsg("[Test Error] Roblox window not found! Open your inventory first.")
        return
    }
    WinActivate("ahk_exe RobloxPlayerBeta.exe")
    Sleep(300)
    
    hasPotions := HasActivePotionsForCurrentBiome()
    stepsToRun := hasPotions ? [1, 2, 3, 4, 5] : [1, 2, 3, 5]
    searchKeyword := hasPotions ? "Lucky Potion" : "Biome Randomizer"
    
    for stepIdx in stepsToRun {
        coords := StepCoords[stepIdx]
        SmoothMove(coords.x, coords.y)
        Sleep(250)
        Click()
        Sleep(200)
        
        if (stepIdx == 2) {
            SafeClipboardPaste(searchKeyword)
            Sleep(250)
        } else if (stepIdx == 4 && hasPotions) {
            SafeClipboardPaste("1")
            Sleep(200)
        }
    }
    LogMsg("[Test] Completed test sequence! (Inventory left open)")
}

; ==========================================
; THEME & HOTKEY LOGIC
; ==========================================
OnThemeChanged(ctrl, info) {
    global SelectedTheme, IniFile
    SelectedTheme := ctrl.Text
    IniWrite(SelectedTheme, IniFile, "Settings", "Theme")
    Reload()
}

SaveHotkeysSettings() {
    global HkStart, HkPause, HkStop, HkGui
    global CtrlStart, CtrlPause, CtrlStop, CtrlGui
    
    HkStart := Trim(CtrlStart.Value)
    HkPause := Trim(CtrlPause.Value)
    HkStop  := Trim(CtrlStop.Value)
    HkGui   := Trim(CtrlGui.Value)
    
    IniWrite(HkStart, IniFile, "Hotkeys", "Start")
    IniWrite(HkPause, IniFile, "Hotkeys", "Pause")
    IniWrite(HkStop,  IniFile, "Hotkeys", "Stop")
    IniWrite(HkGui,   IniFile, "Hotkeys", "ToggleGui")
    
    ApplyHotkeys()
    
    BtnStart.Text := "▶ START (" HkStart ")"
    BtnPause.Text := "⏸ PAUSE (" HkPause ")"
    BtnStop.Text  := "⏹ STOP (" HkStop ")"
    
    LogMsg("[Settings] Hotkeys saved!")
}

ApplyHotkeys() {
    global HkStart, HkPause, HkStop, HkGui
    global OldHkStart, OldHkPause, OldHkStop, OldHkGui
    
    if (OldHkStart != "")
        try Hotkey("~" . OldHkStart, "Off")
    if (OldHkPause != "")
        try Hotkey("~" . OldHkPause, "Off")
    if (OldHkStop != "")
        try Hotkey("~" . OldHkStop, "Off")
    if (OldHkGui != "")
        try Hotkey("~" . OldHkGui, "Off")
    
    if (HkStart != "")
        try Hotkey("~" . HkStart, HkWrapper_StartMacro, "On")
    if (HkPause != "")
        try Hotkey("~" . HkPause, HkWrapper_PauseMacro, "On")
    if (HkStop != "")
        try Hotkey("~" . HkStop,  HkWrapper_StopMacro, "On")
    if (HkGui != "")
        try Hotkey("~" . HkGui,   HkWrapper_ToggleGui, "On")
    
    OldHkStart := HkStart
    OldHkPause := HkPause
    OldHkStop  := HkStop
    OldHkGui   := HkGui
}

ToggleGuiVisibility() {
    global GuiVisible
    GuiVisible := !GuiVisible
    if GuiVisible
        myGui.Show()
    else
        myGui.Hide()
}

; ==========================================
; HELPER & STATE FUNCTIONS
; ==========================================
ShowControlsForBiome(biomeName) {
    global PotionControlsPerBiome, PoppedBiomesTracker, LblBiomeOneShotStatus
    
    for b, pMap in PotionControlsPerBiome {
        showFlag := (b == biomeName)
        for pName, ctrls in pMap {
            ctrls.cb.Visible := showFlag
            ctrls.ed.Visible := showFlag
        }
    }
    
    if PoppedBiomesTracker.Has(biomeName) && PoppedBiomesTracker[biomeName] {
        LblBiomeOneShotStatus.Value := "Status: ALREADY POPPED"
        LblBiomeOneShotStatus.Opt("cFF0000")
    } else {
        LblBiomeOneShotStatus.Value := "Status: Waiting"
        LblBiomeOneShotStatus.Opt("c00FF00")
    }
    UpdateStep5State()
}

OnBiomeSelectionChanged(ctrl, info) {
    ShowControlsForBiome(ctrl.Text)
}

ResetOneShotTrackers() {
    global PoppedBiomesTracker, DdlBiomes, LblBiomeOneShotStatus
    currentBiome := DdlBiomes.Text
    PoppedBiomesTracker[currentBiome] := false
    LblBiomeOneShotStatus.Value := "Status: Waiting"
    LblBiomeOneShotStatus.Opt("c00FF00")
    LogMsg("[One-Shot] Reset status for Biome [" currentBiome "].")
}

; ==========================================
; MACRO RUNNER FUNCTIONS
; ==========================================
StartMacro() {
    global IsRunning, IsPaused, StartTick
    if IsRunning && !IsPaused
        return
        
    if IsPaused {
        IsPaused := false
        LblStatus.Value := "STATUS: RUNNING"
        LblStatus.Opt("cLime")
        LogMsg("▶ Macro RESUMED.")
    } else {
        IsRunning := true
        IsPaused := false
        StartTick := A_TickCount
        
        LblStatus.Value := "STATUS: RUNNING"
        LblStatus.Opt("cLime")
        LogMsg("🚀 Project NyX Macro system STARTED!")
        LogMsg("⚠️ CRITICAL: KEEP ROBLOX INVENTORY OPEN AT ALL TIMES!")
        SendMacroStatusWebhook("started")
        
        InitLogStateOnStart()
        
        SetTimer(LogMonitorLoop, 800)
        SetTimer(TimerLoop, 1000)
        if (CbBiomeRand.Value || CbStrangeCtrl.Value)
            SetTimer(AutoInventoryLoop, 1000)
    }
}

PauseMacro() {
    global IsRunning, IsPaused
    if IsRunning && !IsPaused {
        IsPaused := true
        LblStatus.Value := "STATUS: PAUSED"
        LblStatus.Opt("cYellow")
        LogMsg("⏸ Macro PAUSED.")
        SetTimer(LogMonitorLoop, 0)
        SetTimer(TimerLoop, 0)
        SetTimer(AutoInventoryLoop, 0)
    } else if IsPaused {
        StartMacro()
    }
}

StopMacro() {
    global IsRunning, IsPaused, IsPopping
    wasRunning := IsRunning
    IsRunning := false
    IsPaused := false
    IsPopping := false
    LblStatus.Value := "STATUS: STOPPED"
    LblStatus.Opt("cRed")
    LogMsg("⏹ Macro STOPPED.")
    if (wasRunning) {
        SendMacroStatusWebhook("stopped")
    }
    SetTimer(LogMonitorLoop, 0)
    SetTimer(TimerLoop, 0)
    SetTimer(AutoInventoryLoop, 0)
}

LogMsg(text) {
    timestamp := FormatTime(, "[HH:mm:ss]")
    EdLogs.Value := EdLogs.Value timestamp " " text "`n"
    PostMessage(0x0115, 7, 0, EdLogs.Hwnd)
}

SaveWebhookSettings() {
    global WebhookURL, Username, PSLink, BiomeWebhookControls
    WebhookURL := EdWebhook.Value
    Username := EdUsername.Value
    PSLink := EdPS.Value
    
    IniWrite(WebhookURL, IniFile, "Settings", "Webhook")
    IniWrite(Username, IniFile, "Settings", "Username")
    IniWrite(PSLink, IniFile, "Settings", "PSLink")
    
    for bName, ctrls in BiomeWebhookControls {
        if !ctrls.isRare {
            IniWrite(ctrls.send.Value, IniFile, "WebhookBiomes", bName "_Send")
            IniWrite(ctrls.ping.Value, IniFile, "WebhookBiomes", bName "_PingEnable")
            IniWrite(ctrls.id.Value, IniFile, "WebhookBiomes", bName "_PingID")
        }
    }
    LogMsg("[Webhooks] Discord & Biome Webhooks saved!")
}

SaveInvSettings() {
    global InvCooldown, PotionControlsPerBiome
    InvCooldown := EdInvCooldown.Value
    IniWrite(InvCooldown, IniFile, "Settings", "InvCooldown")
    IniWrite(CbBiomeRand.Value, IniFile, "Settings", "CbBiomeRand")
    IniWrite(CbStrangeCtrl.Value, IniFile, "Settings", "CbStrangeCtrl")
    
    for bName, pMap in PotionControlsPerBiome {
        sectionName := "BiomeConfig_" . bName
        for pName, ctrls in pMap {
            keySanitized := StrReplace(pName, " ", "")
            qVal := Integer(ctrls.ed.Value)
            if (qVal < 1)
                qVal := 1
            ctrls.ed.Value := qVal
            
            IniWrite(ctrls.cb.Value, IniFile, sectionName, keySanitized "_Enable")
            IniWrite(qVal, IniFile, sectionName, keySanitized "_Qty")
        }
    }
    UpdateStep5State()
    LogMsg("[Inventory & Pop] Potion settings saved!")
}

SafeClipboardPaste(textToPaste) {
    if !WinActive("ahk_exe RobloxPlayerBeta.exe")
        return false
    ClipSaved := ClipboardAll() 
    A_Clipboard := ""
    A_Clipboard := textToPaste
    if !ClipWait(1) {
        A_Clipboard := ClipSaved
        return false
    }
    SendInput("^{a}")
    Sleep(50)
    SendInput("{Backspace}")
    Sleep(50)
    SendInput("^{v}")
    Sleep(150)
    A_Clipboard := ClipSaved
    return true
}

AutoInventoryLoop() {
    global InventoryToggleState, InvCooldown, IsPopping, StepCoords
    static lastRunTick := 0
    
    if (IsPopping || !IsRunning || IsPaused)
        return
        
    if !WinExist("ahk_exe RobloxPlayerBeta.exe") {
        LogMsg("[Failsafe] Roblox window lost! Stopping macro.")
        StopMacro()
        return
    }
    
    if (CbBiomeRand.Value || CbStrangeCtrl.Value) {
        currentTick := A_TickCount
        cooldownMs := Integer(InvCooldown) * 1000
        
        if ((currentTick - lastRunTick) < cooldownMs && lastRunTick != 0)
            return
            
        lastRunTick := currentTick
        if (CbBiomeRand.Value && CbStrangeCtrl.Value) {
            searchKeyword := (InventoryToggleState == 0) ? "Biome Randomizer" : "Strange Controller"
            InventoryToggleState := 1 - InventoryToggleState
        } else if (CbStrangeCtrl.Value) {
            searchKeyword := "Strange Controller"
        } else {
            searchKeyword := "Biome Randomizer"
        }
        
        if !WinActive("ahk_exe RobloxPlayerBeta.exe")
            WinActivate("ahk_exe RobloxPlayerBeta.exe")
            
        stepsToRun := [1, 2, 3, 5]
        for stepIdx in stepsToRun {
            if (!IsRunning || IsPaused || IsPopping || !WinActive("ahk_exe RobloxPlayerBeta.exe"))
                break
                
            coords := StepCoords[stepIdx]
            SmoothMove(coords.x, coords.y)
            Sleep(200)
            Click()
            Sleep(150)
            
            if (stepIdx == 2) {
                SafeClipboardPaste(searchKeyword)
                Sleep(200)
            }
        }
    }
}

ExecutePerBiomeAutoPop(currentBiome) {
    global IsPopping, PotionControlsPerBiome, PoppedBiomesTracker, DdlBiomes, LblBiomeOneShotStatus, StepCoords
    
    if !PotionControlsPerBiome.Has(currentBiome)
        return
        
    pMap := PotionControlsPerBiome[currentBiome]
    activeQueue := []
    
    for pName, ctrls in pMap {
        if (ctrls.cb.Value == 1) {
            qtyVal := Integer(ctrls.ed.Value)
            activeQueue.Push({name: pName, qty: qtyVal})
        }
    }
    
    if (activeQueue.Length == 0) {
        LogMsg("ℹ️ [Auto Pop] No potions configured for [" currentBiome "]. Skipping.")
        return
    }
        
    IsPopping := true
    LogMsg("🧪 [Auto Pop] Popping potions for [" currentBiome "]... BR/SC locked.")
    
    if !WinActive("ahk_exe RobloxPlayerBeta.exe")
        WinActivate("ahk_exe RobloxPlayerBeta.exe")
    Sleep(500)
    
    for item in activeQueue {
        if (!IsRunning || IsPaused || !WinActive("ahk_exe RobloxPlayerBeta.exe"))
            break
            
        LogMsg("🧪 [Auto Pop] Using: " item.name " | Qty: " item.qty "...")
        
        stepsToRun := [1, 2, 3, 4, 5]
        for stepIdx in stepsToRun {
            if (!IsRunning || IsPaused || !WinActive("ahk_exe RobloxPlayerBeta.exe"))
                break
                
            coords := StepCoords[stepIdx]
            SmoothMove(coords.x, coords.y)
            Sleep(200)
            Click()
            Sleep(150)
            
            if (stepIdx == 2) {
                SafeClipboardPaste(item.name)
                Sleep(200)
            } else if (stepIdx == 4) {
                SafeClipboardPaste(String(item.qty))
                Sleep(200)
            }
        }
        Sleep(400)
    }
    
    PoppedBiomesTracker[currentBiome] := true
    if (DdlBiomes.Text == currentBiome) {
        LblBiomeOneShotStatus.Value := "Status: ALREADY POPPED"
        LblBiomeOneShotStatus.Opt("cFF0000")
    }
    
    LogMsg("🛑 [Auto Pop] Finished popping for [" currentBiome "]. BR/SC unlocked.")
    IsPopping := false
}

GetLatestPlayerLogFile() {
    logDir := EnvGet("LOCALAPPDATA") "\Roblox\logs"
    latestFile := ""
    latestTime := 0
    
    Loop Files logDir "\*.log" {
        if (InStr(A_LoopFileName, "Launcher") || InStr(A_LoopFileName, "Crash"))
            continue
            
        if (A_LoopFileTimeModified > latestTime) {
            latestTime := A_LoopFileTimeModified
            latestFile := A_LoopFilePath
        }
    }
    return latestFile
}

RefreshLogPath() {
    latestFile := GetLatestPlayerLogFile()
    if latestFile
        LblLogPath.Value := "Monitoring log file:`n" latestFile
    else
        LblLogPath.Value := "⚠️ No Roblox Player Log file found!"
}

ForceScanLogNow() {
    latestFile := GetLatestPlayerLogFile()
    if !latestFile {
        LogMsg("[Debug Check] ROBLOX PLAYER LOG FILE NOT FOUND!")
        return
    }
    
    try {
        f := FileOpen(latestFile, "r", "UTF-8")
        if !f {
            LogMsg("[Debug Check] Failed to open log file!")
            return
        }
        
        fileSize := f.Length
        readSize := (fileSize > 150000) ? 150000 : fileSize
        f.Seek(fileSize - readSize, 0)
        text := f.Read()
        f.Close()
        
        foundBiome := DetectBiomeFromText(text)
        LogMsg("----------------------------------------")
        LogMsg("🐛 [FORCE SCAN RESULT]")
        LogMsg("📄 File: " latestFile)
        LogMsg("🎯 Detected Biome: " . (foundBiome != "" ? foundBiome : "NONE/NORMAL"))
        LogMsg("----------------------------------------")
    } catch as err {
        LogMsg("[Debug Error] " err.Message)
    }
}

TestWebhookAction() {
    SaveWebhookSettings()
    if WebhookURL {
        TestWebhookEmbed()
    } else {
        LogMsg("[Webhook Error] Discord Webhook URL is empty!")
    }
}

TestWebhookEmbed() {
    if !WebhookURL
        return
    
    colorDec := Integer("0x" CurrentTheme.accent)
    timeStr := FormatTime(, "HH:mm:ss - dd/MM/yyyy")
    
    jsonPayload := '{"embeds": [{"title": "🧪 ' . CURRENT_VER . ' – Test Webhook OK!", "description": "Discord Webhook connection is working perfectly!", "color": ' . colorDec . ', "fields": [{"name": "User :", "value": "' . Username . '", "inline": true}, {"name": "Time :", "value": "' . timeStr . '", "inline": true}], "footer": {"text": "' . CURRENT_VER . '", "icon_url": "' . LIGHTNING_ICON_URL . '"}}]}'
    try {
        wh := ComObject("WinHttp.WinHttpRequest.5.1")
        wh.Open("POST", WebhookURL, false)
        wh.SetRequestHeader("Content-Type", "application/json; charset=UTF-8")
        wh.Send(jsonPayload)
        
        status := wh.Status
        if (status >= 200 && status < 300)
            LogMsg("[Webhook Test] Test notification sent successfully!")
        else
            LogMsg("[Webhook Error] Discord rejected (Status: " status ")")
    } catch Error as err {
        LogMsg("[Webhook Connection Error] " err.Message)
    }
}

SendWebhookEmbed(biomeName, eventType, startTime := "") {
    if !WebhookURL
        return
    
    bKey := StrUpper(biomeName)
    bData := BiomeData.Has(bKey) ? BiomeData[bKey] : {color: "00FF87", image: ""}
    
    isRare := (bKey == "GLITCHED" || bKey == "DREAMSPACE" || bKey == "CYBERSPACE")
    sendEnabled := true
    pingEnabled := false
    pingTarget := ""
    
    if isRare {
        sendEnabled := true
        pingEnabled := true
        pingTarget := "@everyone"
    } else if BiomeWebhookControls.Has(bKey) {
        ctrls := BiomeWebhookControls[bKey]
        sendEnabled := (ctrls.send.Value == 1)
        pingEnabled := (ctrls.ping.Value == 1)
        rawId := Trim(ctrls.id.Value)
        
        if (rawId != "") {
            if RegExMatch(rawId, "^\d{17,20}$") {
                pingTarget := "<@&" . rawId . ">" 
            } else {
                pingTarget := rawId
            }
        }
    }
    
    if (!sendEnabled)
        return
    
    colorHex := bData.color
    colorDec := Integer("0x" colorHex)
    imgUrl := bData.image
    timeStr := FormatTime(, "HH:mm:ss - dd/MM/yyyy")
    
    contentJson := ""
    if (eventType == "started" && pingEnabled && pingTarget != "") {
        contentJson := '"content": "' . pingTarget . '", '
    }
    
    serverText := (PSLink != "") ? PSLink : "N/A"
    
    if (eventType == "started") {
        titleText := "⚡ Biome Started - [ " . bKey . " ]"
        descJson := '"description": "Server : ' . serverText . '", '
        fieldsJson := '[{"name": "User :", "value": "' . Username . '", "inline": true}, {"name": "Start Time :", "value": "' . timeStr . '", "inline": true}]'
    } else {
        titleText := "🛑 Biome Ended - [ " . bKey . " ]"
        descJson := '""'
        fieldsJson := '[{"name": "End Time :", "value": "' . timeStr . '", "inline": true}, {"name": "Duration :", "value": "' . (startTime ? startTime : "Unknown") . '", "inline": true}]'
    }
    
    jsonPayload := '{' . contentJson . '"embeds": [{"title": "' . titleText . '", "color": ' . colorDec . ', ' . (descJson != '""' ? descJson : "") . '"fields": ' . fieldsJson . ', "thumbnail": {"url": "' . imgUrl . '"}, "footer": {"text": "' . FOOTER_TEXT . '", "icon_url": "' . LIGHTNING_ICON_URL . '"}}]}'
    
    try {
        wh := ComObject("WinHttp.WinHttpRequest.5.1")
        wh.Open("POST", WebhookURL, false)
        wh.SetRequestHeader("Content-Type", "application/json; charset=UTF-8")
        wh.Send(jsonPayload)
        LogMsg("[Webhook] Biome [" biomeName "] (" eventType ") sent to Discord.")
    } catch Error as err {
        LogMsg("[Webhook Connection Error] " err.Message)
    }
}

SendMacroStatusWebhook(state) {
    if !WebhookURL
        return
    
    colorHex := (state == "started") ? "00FF00" : "FF0000"
    colorDec := Integer("0x" colorHex)
    titleText := (state == "started") ? "🚀 Project NyX - Macro Started" : "⏹ Project NyX - Macro Stopped"
    descText := (state == "started") ? "Macro system successfully activated!" : "Macro system has stopped all processes."
    timeStr := FormatTime(, "HH:mm:ss - dd/MM/yyyy")
    
    jsonPayload := '{"embeds": [{"title": "' . titleText . '", "description": "' . descText . '", "color": ' . colorDec . ', "fields": [{"name": "User :", "value": "' . Username . '", "inline": true}, {"name": "Time :", "value": "' . timeStr . '", "inline": true}], "footer": {"text": "' . FOOTER_TEXT . '", "icon_url": "' . LIGHTNING_ICON_URL . '"}}]}'
    
    try {
        wh := ComObject("WinHttp.WinHttpRequest.5.1")
        wh.Open("POST", WebhookURL, false)
        wh.SetRequestHeader("Content-Type", "application/json; charset=UTF-8")
        wh.Send(jsonPayload)
    } catch Error as err {
        LogMsg("[Webhook Error] " err.Message)
    }
}

JsonEscape(str) {
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`r", "\r")
    return '"' . str . '"'
}

TimerLoop() {
    elapsed := Integer((A_TickCount - StartTick) / 1000)
    h := Format("{:02}", Floor(elapsed / 3600))
    m := Format("{:02}", Floor(Mod(elapsed, 3600) / 60))
    s := Format("{:02}", Mod(elapsed, 60))
    LblTimer.Value := "RUNNING: " h ":" m ":" s
}

ResetCounts() {
    global BiomeCounts
    for b in AllBiomes {
        BiomeCounts[b] := 0
        IniWrite(0, IniFile, "Counters", b)
    }
    UpdateDashboardUI()
    LogMsg("[Dashboard] Biome counts reset.")
}

UpdateDashboardUI() {
    total := 0
    rareTot := 0
    for b, count in BiomeCounts {
        total += count
        for rb in RareBiomes {
            if (rb == b)
                rareTot += count
        }
        if BiomeLabels.Has(b)
            BiomeLabels[b].Value := count
    }
    LblTotalCount.Value := "Total Detected: " total
    LblRareCount.Value := "Rare Biomes: " rareTot
}

; ==========================================
; LOG SCANNER ENGINE
; ==========================================
InitLogStateOnStart() {
    global LogLastPos, LogActiveBiome, LogCurrentFile, LblCurrentBiome
    
    latestFile := GetLatestPlayerLogFile()
    if !latestFile {
        LogActiveBiome := "NORMAL"
        LblCurrentBiome.Value := "Current: NORMAL"
        return
    }
    
    LogCurrentFile := latestFile
    
    try {
        f := FileOpen(latestFile, "r", "UTF-8")
        if !f
            return
            
        fileSize := f.Length
        LogLastPos := fileSize
        
        readSize := (fileSize > 150000) ? 150000 : fileSize
        f.Seek(fileSize - readSize, 0)
        text := f.Read()
        f.Close()
        
        foundBiome := DetectBiomeFromText(text)
        if (foundBiome == "")
            foundBiome := "NORMAL"
            
        LogActiveBiome := foundBiome
        LblCurrentBiome.Value := "Current: " . foundBiome
        HandleBiomeStarted(foundBiome)
    } catch as err {
        LogActiveBiome := "NORMAL"
        LblCurrentBiome.Value := "Current: NORMAL"
    }
}

DetectBiomeFromText(textBlock) {
    global BiomeAliases
    lines := StrSplit(textBlock, "`n", "`r")
    
    loop lines.Length {
        idx := lines.Length - A_Index + 1
        line := lines[idx]
        if (line == "")
            continue
            
        lineUpper := StrUpper(line)
        for targetBiome, aliases in BiomeAliases {
            for alias in aliases {
                if RegExMatch(lineUpper, "i)\b" . alias . "\b") {
                    return targetBiome
                }
            }
        }
    }
    return ""
}

LogMonitorLoop() {
    global LogLastPos, LogActiveBiome, LogCurrentFile
    static biomeStartTime := 0
    
    latestFile := GetLatestPlayerLogFile()
    if !latestFile
        return
        
    if (LogCurrentFile != latestFile) {
        InitLogStateOnStart()
        return
    }
    
    try {
        f := FileOpen(latestFile, "r", "UTF-8")
        if !f
            return
            
        currLen := f.Length
        
        if (currLen < LogLastPos) {
            LogLastPos := currLen
            f.Close()
            return
        }
        
        if (currLen > LogLastPos) {
            f.Seek(LogLastPos, 0)
            text := f.Read()
            f.Close()
            LogLastPos := currLen
            
            foundBiome := DetectBiomeFromText(text)
            
            if (foundBiome != "" && foundBiome != LogActiveBiome) {
                if (LogActiveBiome != "" && LogActiveBiome != "NONE") {
                    durationSec := Integer((A_TickCount - biomeStartTime) / 1000)
                    durFormatted := Format("{:02}m {:02}s", Floor(durationSec / 60), Mod(durationSec, 60))
                    HandleBiomeEnded(LogActiveBiome, durFormatted)
                }
                LogActiveBiome := foundBiome
                biomeStartTime := A_TickCount
                HandleBiomeStarted(foundBiome)
            }
        } else {
            f.Close()
        }
    } catch as err {
        try f.Close()
    }
}

HandleBiomeStarted(biome) {
    global BiomeCounts, PoppedBiomesTracker
    
    BiomeCounts[biome] := BiomeCounts[biome] + 1
    IniWrite(BiomeCounts[biome], IniFile, "Counters", biome)
    
    LogMsg("⚡ DETECTED: Biome [" . biome . "]!")
    LblCurrentBiome.Value := "Current: " biome
    UpdateDashboardUI()
    
    SendWebhookEmbed(biome, "started")
    
    if PoppedBiomesTracker.Has(biome) && PoppedBiomesTracker[biome] {
        LogMsg("ℹ️ Biome [" biome "] ALREADY POPPED. Skipping (One-Shot Rule).")
        return
    }
    
    if IsRunning && !IsPaused {
        ExecutePerBiomeAutoPop(biome)
    }
}

HandleBiomeEnded(biome, durationStr) {
    global IsPopping
    LogMsg("🛑 Biome [" . biome . "] ended. Duration: " . durationStr)
    SendWebhookEmbed(biome, "ended", durationStr)
    LblCurrentBiome.Value := "Current: NONE"
    IsPopping := false
}
